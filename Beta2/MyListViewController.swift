//
//  MyListViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 8/7/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Foundation

class MyListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate      {

    var placesArr = [String]()
    var tableData = [String]()
    var placeObj = placeNode()
    var myPlaceNodes = [placeNode()]
    var placeNodeTreeRoot = PlaceNodeTree()
    var objArr = [placeNode()]
    var namePlaceNodeDict = [String: placeNode]()
    var cityPlaceNodeDict = [String: [placeNode]]()
    var citySortedDict = [String: [String:[String]]]()  //[Detroit: [bar: [this,that]], DC: [bar [those]]]
    var citySortedArr = [String]()  //Sorted list of the cities in an array
    var cityDict = [String: Int]()
    var tableDataArr = [String]()
    var arrSize = Int()
    var ref: FIRDatabaseReference!
    var placesRef: FIRDatabaseReference!
    var selectedCollection = [Int]()
    var selectedFilters = [String]()
    var headerCount = 0
    var catButtonList = ["Bar", "Breakfast", "Brewery", "Brunch", "Beaches", "Coffee Shop", "Dessert", "Dinner", "Food Truck", "Hikes", "Lunch", "Museums", "Night Club", "Parks", "Site Seeing", "Winery"]
    var userRef: FIRDatabaseReference!
   
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var myListHeaderLabel: UILabel!
    
    let currUserDefaultKey = "FBloginVC.currUser"
    fileprivate let sharedFbUser = UserDefaults.standard
    
    //Store the user that the list items will be retrieved for
    var currUsers: [NSString]?
    var currUser: String = ""
    
    //retrieve the current app user from NSUserDefaults
    var defaultUser: NSString {
        get{
            return (sharedFbUser.object(forKey: currUserDefaultKey) as? NSString)!
        }
    }
    
//    Variables set by another view controller
    //Store the user ID whose list is requested by the CheckoutPeopleVc
    var requestedUser: NSString?
    //Header text indicates is this my List, or pass in the header label from another user's list or their city
    var headerText: String?   //Also store user's first name for header label
    var myFriendIds:[NSString]?
    var showAllCities: Bool?
    
    override func viewDidLoad() {
        var currRef: FIRDatabaseReference!
        var userRetrievalCount:Int = 0     //Count the number of user's with their info pulled from the dataBase
        super.viewDidLoad()
//        userRef = Firebase(url:"https://check-inout.firebaseio.com/checked/\(defaultUser)")
        userRef = FIRDatabase.database().reference().child("checked/\(defaultUser)")
        //If another user's list was requested then requestedUser will be set
        if let userIds = myFriendIds{
            self.currUsers = userIds
            if let unwrapHeader = headerText{
                myListHeaderLabel.text = unwrapHeader
            }
        }else{  //If no alternate user's list was requested then display the app owner's list
            self.currUsers = [defaultUser]
        }

        //setup tableView delegates
        self.tableView.dataSource=self;
        self.tableView.delegate=self;
        //remove left padding from tableview seperators
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "TableViewSectionHeaderViewIdentifier")
//        tableView.registerClass(HeaderTableViewCell.self,forCellReuseIdentifier: "headerCell")
//        tableView.registerClass(SubheaderTableViewCell.self,forCellReuseIdentifier: "subheaderCell")
//        tableView.registerClass(TestTableViewCell.self,forCellReuseIdentifier: "dataCell")
        self.tableView.backgroundColor=UIColor.clear
        collectionView?.allowsMultipleSelection = true
//        placesRef = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
        placesRef = FIRDatabase.database().reference().child("checked/places")
        
        //Create container view then loading for activity indicator to prevent background from overshadowing white color
        let loadingView: UIView = UIView()
        
        loadingView.frame = CGRect(x: 0,y: 0,width: 80,height: 80)
        loadingView.center = view.center
        loadingView.backgroundColor = UIColor(red: 0x44/255, green: 0x44/255, blue: 0x44/255, alpha: 0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        //Start activity indicator while making Firebase request
        let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50, height: 50)) as UIActivityIndicatorView
        activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2,y: loadingView.frame.size.height / 2);
//        activityIndicator.backgroundColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 0.3)
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.hidesWhenStopped = true
        
        loadingView.addSubview(activityIndicator)
        view.addSubview(loadingView)
        activityIndicator.startAnimating()
        
        //Loop over all the current users that are expected (1 if viewing my list or a friend's list, all friends if viewing a city only list)
        for friendId in self.currUsers!{
//            currRef = Firebase(url:"https://check-inout.firebaseio.com/checked/\(friendId)")
            currRef = FIRDatabase.database().reference().child("checked/\(friendId)")
            retrieveWithRef(currRef){ (placeNodeArr: [placeNode]) in
                userRetrievalCount += 1     //finished retrieving current user's check in info
                for node in placeNodeArr{
                    self.myPlaceNodes.append(node)
                }
                if(userRetrievalCount == (self.currUsers?.count)! ){  //When data from all friendIds is gathered then generate tree
                        self.generateTree(self.myPlaceNodes)
                        self.placeNodeTreeRoot.sortChildNodes()
                        self.tableView.reloadData()
                        self.myPlaceNodes.removeAll()
                        activityIndicator.stopAnimating()
                        loadingView.removeFromSuperview()
                }

            }

        }
        
    }
    
    
    //Retrieve list of all checked in places for curr user
    func retrieveWithRef(_ myRef: FIRDatabaseReference, completionClosure: @escaping (_ placeNodeArr: [placeNode]) -> Void) {
        var locPlaceNodeArr = [placeNode]()
        var locPlaceNodeObj:placeNode = placeNode()

        //Retrieve a list of the user's current check in list
        myRef.observeSingleEvent(of: .value, with: { snapshot in
            
            //rootNode now contains a list of all the places from the current user's Reference
            let rootNode = snapshot as FIRDataSnapshot
            //force downcast only works if root node has children, otherwise value will only be a string
            //each entry in nodeDict now has a key of the check in's place name and a value of the city/category attributes
            let nodeDict = rootNode.value as! NSDictionary
            //Loop over each check in Place and parse its attributes
            for (key, _ ) in nodeDict{
                //Create new place node to store the current place's info
                locPlaceNodeObj = placeNode()
                locPlaceNodeObj.place = key as? String
                //Get a snapshot of the current place to iterate over its attributes
                let placeSnap = snapshot.childSnapshot(forPath: key as! String)
                    //Iterate over each city and category child of the place's check in
                    for placeChild in placeSnap.children{
                        let currNode = placeChild as! FIRDataSnapshot
                         //If Place dict can be unwrapped as NSDictionary then it now has key of the city or cat attribute, and the value is always "true"
                        //If place Dict can't be unwrapped then the key value pair is the google place id
                        if let placeDict = currNode.value as? NSDictionary{
                            //The placeChild key tells us which type of attribute data we are currently looping over
                            for (attrKey, _ ) in placeDict{
                                if((placeChild as AnyObject).key == "city"){
                                    locPlaceNodeObj.addCity(attrKey as! String)
                                }
                                else if((placeChild as AnyObject).key == "category"){
                                    locPlaceNodeObj.addCategory(attrKey as! String)
                                }
                            }
                        }else{
                            if let placeId = currNode.value as? String{
                                locPlaceNodeObj.placeId = placeId
                            }else{
                                print("Malformed firebase entry for \(locPlaceNodeObj.place)")
                            }
                            
                        }
                    }
                    
                    locPlaceNodeArr.append(locPlaceNodeObj)
                //Previous code block was in an if let optional chain block, but now FIR snaps are not optionals
//                else{
//                    print("Created place node with no attributes. Child snapshot of \(key as!String) was nil")
//                }
            }
            //Call Completion cloures on completed list of place nodes from the current user's checkins
            completionClosure(locPlaceNodeArr)
        })
    }
    
    
//Tree generation functions
    func generateTree(_ nodeArr: [placeNode]){
        var siblings:[String]? = nil
        //Loop through all place nodes, and iterate over array of categories and cities
        for placeNode in nodeArr{
            //I can have multiple cities for a single placeNode, or city can be nil
            if let cities = placeNode.city{
                for city in cities{
                   //Don't add city to tree if only displaying a certain city
                    //First case: if showing only certain city then the city must match the header label, if show all cities is nil then just falisfy this side of the expression to remove it from being considered
                    //Second case: show all cities is nil, then evaluate to true and print all cities
                    //Second case: show all cities is true, then evaluate to false to put the burden on the left expression
                    if( ((showAllCities ?? false) && (headerText! == city)) || !(showAllCities ?? false) ){
                        if (cities.count > 1){  //If multiple cities exist keep a reference to all cities
                            if let currCityIndex = cities.index(of: city){
                                var mySiblings = cities
                                mySiblings.remove(at: currCityIndex)
                                siblings = mySiblings
                            }
                        }
                        if let existingCity = placeNodeTreeRoot.search(city)
                        {
                            addTreeNodeToCity(placeNode, cityNode: existingCity, siblings: siblings)
                        }else{//Currenty city does not exist
                            let newCityNode = PlaceNodeTree(nodeVal: city)
                            placeNodeTreeRoot.addChild(newCityNode)
                            addTreeNodeToCity(placeNode, cityNode: newCityNode, siblings: siblings)
                            
                        }
                    }
                }
            }
        }
    }
    
    func addTreeNodeToCity(_ nodeStruct: placeNode, cityNode: PlaceNodeTree, siblings: [String]?){
        var childNode: PlaceNodeTree
        
        //Add place to existing city for each category
        if let categories = nodeStruct.category{
            for category in categories{
                if let existingCategory = cityNode.search(category){
                    //create PlaceNodeTree object depending on whether the user used google Autocomplete which provides a google place id
                    //Couldn't create the placeNodeTree obj as variable or the generate tree func was failing 
                    if let placeId = nodeStruct.placeId{
                        childNode = existingCategory.addChild(PlaceNodeTree(nodeVal: nodeStruct.place!, placeId: placeId))
                    }else{
                        childNode = existingCategory.addChild(PlaceNodeTree(nodeVal: nodeStruct.place!))
                    }
                }else{//category does not exist
                    let newCategoryNode = PlaceNodeTree(nodeVal: category)
                    cityNode.addChild(newCategoryNode)
                    if let placeId = nodeStruct.placeId{
                        childNode = newCategoryNode.addChild(PlaceNodeTree(nodeVal: nodeStruct.place!, placeId: placeId))
                    }else{
                        childNode = newCategoryNode.addChild(PlaceNodeTree(nodeVal: nodeStruct.place!))
                    }
                }
                if(siblings != nil){
                    childNode.addSibling(siblings!)
                }
            }
        }
    }
    
    
//    Unused dict func
    //Iterate over Dictionary of String:PlaceNode array and create a sorted Dict of the same type
    func sortRetrievedDataByCity(){
        var categoryDict = [String: [String]]()
        var placeArr = [String]()
        var locPlaceNodeObj:placeNode
        var match = false
        //namePlaceNodeDict is a dictionary of [String:array of placeNodes]
        for(key,value) in self.namePlaceNodeDict{
            categoryDict.removeAll()
            //add place name to array to keep types consistent in self.citySortedDict
            placeArr.removeAll()
            placeArr.append(key)
            locPlaceNodeObj = value     //current place obj
            //perform a check of all categories in each city and update in self.citySortedDict
            for city in locPlaceNodeObj.city!{
                //if the city key doesn't exist yet, create new dict entry
                if(self.citySortedDict[city] == nil){
                    //create a nested dict for each category [category:[places]]
                    for category in locPlaceNodeObj.category!{
                        categoryDict[category]=placeArr
                    }
                    //store [category:[places]]() in new city entry of city sorted dict
                    self.citySortedDict[city]=categoryDict
                }
                    //else city already exists in self.citySortedDict
                else{
                    for catObj in locPlaceNodeObj.category!{
                        match = false //find out if new Place fits into existing category
                        //iterate over existing categories as string and places as [String]
                        for (existCategory,_) in self.citySortedDict[city]!{
                            if(catObj == existCategory){
                                match=true
                                break
                            }
                        }
                        if(match == true){  //category already exists for this city
                            self.citySortedDict[city]![catObj]!.append(key)  //key is new place [city:[category:[existing..,key]]
                        }
                        else{
                            self.citySortedDict[city]![catObj] = placeArr
                            
                        }
                        
                    }
                }
            }
        }
        self.citySortedArr = [String] (self.citySortedDict.keys)
        self.citySortedArr.sort(by: <)
        
    }
    
    //Unused firebase functions that retrieved all places from one user and looked them up in the master list
    //function receives the name of the place to look up its city and place attributes
    func retrievePlaceAttributes(_ myRef: FIRDatabaseReference, place: String, completionClosure: @escaping (_ categoryArr: [String], _ cityArr: [String]) -> Void)
    {
        let currPlacesRef: FIRDatabaseReference!
        var completedAttrArr = [String]()
        var cityArrLoc = [String]()
        var categoryArrLoc = [String]()
//        print(place)
        currPlacesRef = myRef.child(byAppendingPath: place)
        currPlacesRef.observeSingleEvent(of: .value, with: { childSnapshot in
            if !(childSnapshot.value is NSNull)
            {
                //get category and city key then retreive the attribute's children
                for attribute in (childSnapshot.children) {
                    //check if multiple children exist beneath currrent node, will return nil if path is not only a key:value
                    if let singleEntry = childSnapshot.childSnapshot(forPath: (attribute as AnyObject).key).value as? String{
                        if ((attribute as AnyObject).key == "city"){
                            cityArrLoc.append(singleEntry)   //append singld child
                        }
                        else if ((attribute as AnyObject).key == "category"){
                            categoryArrLoc.append(singleEntry)   //append singld child
                        }
                        else{
                            completedAttrArr.append(singleEntry)   //append singld child
                        }
                    }
                    else{
                        //loop over each entry in child snapshot and store in array
                        let rootNode = attribute as! FIRDataSnapshot
                        //force downcast only works if root node has children, otherwise value will only be a string
                        let nodeDict = rootNode.value as! NSDictionary
                        for (key, _ ) in nodeDict{
                            if((attribute as AnyObject).key == "city"){
                                cityArrLoc.append(key as! String)
                            }
                            if((attribute as AnyObject).key == "category"){
                                categoryArrLoc.append(key as! String)
                            }
                            else{
                                completedAttrArr.append(key as! String)
                            }
                        }
                    }
                }
            }
            else
            {
                print("attribute \(childSnapshot.key) found but contained no children")
            }
            print("calling retrieve attributes completion")
            completionClosure(categoryArrLoc, cityArrLoc)
        })
        
    }

    //Unused firebase functions that retrieved all places from one user and looked them up in the master list
    //Funtion is passed the list of checked in places and retrieves the city and category attributes for each place
    func retrieveAttributesFromMaster(_ myRef: FIRDatabaseReference, retrievedPlaces: [String], completionClosure: @escaping (_ placeNodeArr: [placeNode]) -> Void)
    {
        var localTableDataArr = [String]()
        var locPlaceNodeArr = [placeNode]()
        var locPlaceNodeObj:placeNode = placeNode()
        for (index,place) in retrievedPlaces.enumerated()
        {
            retrievePlaceAttributes(myRef, place: place, completionClosure: { (categoryArr: [String], cityArr: [String]) in
                locPlaceNodeObj = placeNode()
                locPlaceNodeObj.place = place
                localTableDataArr.append(place)
                //store data in the place node
                locPlaceNodeObj.category = categoryArr
                locPlaceNodeObj.city = cityArr
                locPlaceNodeArr.append(locPlaceNodeObj)
                self.namePlaceNodeDict[place] = locPlaceNodeObj
                for attribute in cityArr{
                    //localTableDataArr is concatenated list of all data, currently unused
                    localTableDataArr.append(attribute)
                }
                //call completion closure for viewDidLoad calling function if this closure is called on last array item
                if(index == (retrievedPlaces.count - 1)){
                    print("calling retrieve from master completion")
                    completionClosure(locPlaceNodeArr)
                }
            })
        }
    }

    //Unused firebase functions that retrieved all places from one user and looked them up in the master list
    //Retrieve list of all checked in places for curr user
    func retrieveUserPlaces(_ myRef: FIRDatabaseReference, completionClosure: @escaping (_ completedArr: [String]) -> Void) {
        var localPlacesArr = [String]()
        
        if(showAllCities ?? false){     //Use value of showAllCities if not nil, otherwise evaluate to false
            //Only retrieve check ins from matching cities in the user's list
            myRef.queryOrdered(byChild: "city").observe(.childAdded, with: { snapshot in
                let nsSnapDict = snapshot.value as? NSDictionary     //Swift 3 returns snapshot as Any? instead of ID
                //If the city is a single dict pair this snap.value will return the city name
                if let city = nsSnapDict?["city"] as? String {
                    //Check if the city name matches the requested city
                    if(city == self.headerText!){
                        //Then store the place's name
                        localPlacesArr.append((snapshot.key))
                    }
                }else{  //The current city entry has a multi entry list
                    for child in (snapshot.children) {    //each child is either city or cat
                        let rootNode = child as! FIRDataSnapshot
                        //force downcast only works if root node has children, otherwise value will only be a string
                        let nodeDict = rootNode.value as! NSDictionary
                        for (key, _ ) in nodeDict{
                            if((child as AnyObject).key == "city"){
                                //Check if the city name matches the requested city
                                if((key as! String) == self.headerText!){
                                    //Then store the place's name 
//                                    print("userplace: \(snapshot.key)")
                                    localPlacesArr.append((snapshot.key))
                                }
                            }
                        }
                    }
                }
                completionClosure(localPlacesArr)
            })
        }else{
            //Retrieve a list of the user's current check in list
            myRef.observeSingleEvent(of: .value, with: { snapshot in
                let rootNode = snapshot as FIRDataSnapshot
                //force downcast only works if root node has children, otherwise value will only be a string
                //each entry in nodeDict now has a key of the check in's place name and a value of the city/category attributes
                let nodeDict = rootNode.value as! NSDictionary
                //Loop over each check in Place and parse its attributes
                for (key, _ ) in nodeDict{
                //                for child in (snapshot.children) {
                    //true if child key in the snapshot is not nil (e.g. attributes about the place exist), then unwrap and store in array
                        localPlacesArr.append(key as! String)
                    
                }
                completionClosure(localPlacesArr)
            })
        }
    }
        
//  Table view methods

    //Setup section header attributes
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        
        //Create table view top seperator
        let px = 1 / UIScreen.main.scale    //determinte 1 pixel size instead of using 1 point
        let frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: px)
        let topLine: UIView = UIView(frame: frame)
        let bottomframe = CGRect(x: 0, y: header.frame.size.height-px, width: tableView.frame.size.width, height: px)
        let bottomLine: UIView = UIView(frame: bottomframe)
        //Add table view top seperator
        header.contentView.addSubview(topLine)
        header.contentView.addSubview(bottomLine)
        topLine.backgroundColor = UIColor.white
        bottomLine.backgroundColor = UIColor.white
        
        //Set text size, color, and background color of header view before loading
        header.contentView.backgroundColor = UIColor(red: 0x40/255, green: 0x40/255, blue: 0x40/255, alpha: 1.0)
        if let textLabel = header.textLabel {
            textLabel.font = UIFont(name: "Avenir-HeavyOblique", size: 24)
            textLabel.textColor = UIColor.white
        }else{
            print("label not ready")
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TableViewSectionHeaderViewIdentifier")

        headerView?.textLabel?.text = " \(placeNodeTreeRoot.children![section].nodeValue!)"

        return headerView
        
    }
    
    //Setup subheader and data cell attributes
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let treeRet = self.placeNodeTreeRoot.children![indexPath.section].returnNodeAtIndex(indexPath.row)
        if let treeNode = treeRet{
            if(treeNode.depth == 2){ //return height for subheader
                return 33.0
            }else{
                return 50
            }
        }else{
            return 50
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
    }
    
    //Return number of top level entries from the first depth of the tree (Number of cities by default)
    func numberOfSections(in tableView: UITableView) -> Int {
        return placeNodeTreeRoot.nodeCountAtDepth(1)
    }
    
//    Unused Function used as a dict lookup for table data
    func getItemWithIndexPath(_ indexPath: IndexPath) -> (place: String,isHeader: Bool)
    {
        var subIndexRow = indexPath.row
        var currPlace: String = ""
        var header = false
        let currCityAttrDict = self.citySortedDict[self.citySortedArr[indexPath.section]]     //get [Category: [Places]] for current city
        
        //Iterate over each category, map indexPath through the category keys to find a Place value
        for (category,placeArr) in currCityAttrDict!{
            //Decrement index row to find where the IndexPath should point to since all category:[Place] items were combined when calculating num items
            if(subIndexRow <= placeArr.count){
                if(subIndexRow == 0){
                    currPlace = category
                    header = true
                }
                else{
                    currPlace = placeArr[subIndexRow - 1]   //Since category is defined as entry 0, all future entries have to be decremented
                }
                break;
            }
            else{
                //Finished loop over current category and its places, need to modify subIndex to look at next category 
                subIndexRow -= placeArr.count + 1
            }
        }
        if(currPlace == ""){currPlace="table parsing failed"}
        return(currPlace,header)
        
        
    }
    
    
    //return the number of rows per section in the table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //Count all of the children for the current section
        return placeNodeTreeRoot.children![section].nodeCountAtDepth(-1)
    }
    
    //configures and provides a cell to display for a given row
    //gets called once for each cell that can be displayed on the current screen
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cellIdentifier:String

        //the root's children are the setion headers, or cities
        //The city becomes the root and is traversed depth first iteratively for the nth item (n=indexPath.row)
        let treeRet = self.placeNodeTreeRoot.children![indexPath.section].returnNodeAtIndex(indexPath.row)
        if let treeNode = treeRet{
            if(treeNode.depth == 2){  //subheader depth
                cellIdentifier = "subheaderCell"
                //asks the table view for a cell with my cellidentifier which is the name of my custom cell class
                let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SubheaderTableViewCell   //downcast to my cell class type
                if let cellText = treeNode.nodeValue {
                    cell.tableCellValue.text="  \(cellText)"
                }else{
                    print("category treeNode was nil")
                }
                cell.tableCellValue.font = UIFont(name: "Avenir-Heavy", size: 24)
                cell.tableCellValue.textColor = UIColor.white
                //Remove seperator insets
                cell.layoutMargins = UIEdgeInsets.zero
                return cell
            }
            else if(treeNode.depth == 3){
                // Configure the cell if not Header
                cellIdentifier = "dataCell"
                //asks the table view for a cell with my cellidentifier which is the name of my custom cell class
                let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! TestTableViewCell   //downcast to my cell class type
                if let cellText = treeNode.nodeValue {
                    cell.tableCellValue.text="    \(cellText)"
                }else{
                    print("data treeNode was nil")
                }
                cell.tableCellValue.font = UIFont(name: "Avenir-Light", size: 24)
                cell.tableCellValue.textColor = UIColor.white
                //Remove seperator insets
                cell.layoutMargins = UIEdgeInsets.zero
                return cell
            }
        }

        //Below section only executes if the tree is malformed
        cellIdentifier = "subheaderCell"
        //asks the table view for a cell with my cellidentifier which is the name of my custom cell class
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SubheaderTableViewCell   //downcast to my cell class type
        cell.tableCellValue.text="Failed to retrieve Check In"

        return cell

    }
    
    //Swipe to delete implementation
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        var indexPaths = [indexPath]
        if editingStyle == .delete {
            let itemToDelete = placeNodeTreeRoot.children![indexPath.section].returnNodeAtIndex(indexPath.row)!
//            confirmDelete(itemToDelete, index: indexPath)
            //Delete item without providing UI alert for confirmation
//            let refToDelete: Firebase! = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.defaultUser)/\(itemToDelete.nodeValue!)")
            let refToDelete: FIRDatabaseReference = FIRDatabase.database().reference().child("checked/\(self.defaultUser)/\(itemToDelete.nodeValue!)")
            self.tableView.beginUpdates()
            //Remove deleted item from Firebase,the tree and then table
            if(itemToDelete.sibling != nil)
            {
                let cityRef = refToDelete.child(byAppendingPath: "city").child(byAppendingPath: (itemToDelete.parent)!.parent!.nodeValue!)
                cityRef.removeValue()
            }else{
                refToDelete.removeValue()
            }
            //If child is the only leaf node then delete the parent node too
            if(itemToDelete.parent!.removeChild(itemToDelete.nodeValue!)){
                indexPaths.append(IndexPath(row: indexPath.row - 1, section: indexPath.section))
            }
                
            self.tableView.deleteRows(at: indexPaths, with: .automatic)
            //self.tableView.reloadData()
            self.tableView.endUpdates()

        }
    }
    
    //Don't allow categories to be deleted with swipe
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        //The header text is nil unless using the check out screen, if which case you can't delete a user's checkin
        if let _ = headerText{
            return false    //If headerText is set then this is not the users own list so don't edit
        }else{
            let treeRet = self.placeNodeTreeRoot.children![indexPath.section].returnNodeAtIndex(indexPath.row)
            if let treeNode = treeRet{
                if(treeNode.depth == 3){
                    return true //Can only delete leaves
                }else{
                    return false
                }
            }else{  //Default can't delete
                return false
            }
        }
    }
    
    func confirmDelete(_ checkInItem: PlaceNodeTree, index: IndexPath) {
        let alert = UIAlertController(title: "Delete Check In", message: "Are you sure you want to permanently delete \(checkInItem)?", preferredStyle: .actionSheet)
        
        let DeleteAction = UIAlertAction(title: "Delete", style: .destructive, handler:{action in
//            let refToDelete = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.defaultUser)/\(checkInItem.nodeValue!)")
            let refToDelete = FIRDatabase.database().reference().child("checked/\(self.defaultUser)/\(checkInItem.nodeValue!)")
            self.tableView.beginUpdates()
            //Remove deleted item from Firebase,the tree and then table
            if(checkInItem.sibling != nil)
            {
                refToDelete.child(byAppendingPath: "city").child(byAppendingPath: (checkInItem.parent)!.parent!.nodeValue!)
            }else{
                refToDelete.removeValue()
            }
            checkInItem.parent!.removeChild(checkInItem.nodeValue!)
            self.tableView.deleteRows(at: [index], with: .automatic)
            print("deleted")
            //self.tableView.reloadData()
            self.tableView.endUpdates()
        })
        let CancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleDeleteTableItem(_ alertAction: UIAlertAction!) -> Void
    {
//        let refToDelete = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)/\("insert index path item")")
        let refToDelete = FIRDatabase.database().reference().child("checked/\(self.currUser)/\("insert index Path item")")
        tableView.beginUpdates()
        
        print("deleted")
        tableView.endUpdates()
    }
    
    func cancelDeleteTableItem(_ alertAction: UIAlertAction!) {
        print("cancelled")
        
    }
    
//    Collection view functions
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return catButtonList.count
    }

    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "roundButt"
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! RoundButtCollectionViewCell
//        Outlet no longer used and label created in code
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
//        cell.myLabel.text = catButtonList[indexPath.item]
//        cell.myLabel.sizeToFit()

        //Create label here since autolayout only worked after scroll
        let catLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 86, height: 25))
        catLabel.center = CGPoint(x: 50, y: 50)
        catLabel.textAlignment = NSTextAlignment.center
        catLabel.text = catButtonList[indexPath.item]
        //Adjust font size to fit larger words, and truncate at end
        catLabel.adjustsFontSizeToFitWidth = true
        catLabel.minimumScaleFactor = 0.6
        catLabel.lineBreakMode = .byTruncatingTail

        catLabel.textColor = UIColor.white
        cell.contentView.addSubview(catLabel)
        //set cell properties
        cell.backgroundColor = UIColor.clear
        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.borderWidth = 2
        cell.layer.cornerRadius = 0.5 * cell.bounds.size.width
        
        if(selectedCollection.contains(indexPath.item)){
            selectCell(cell, indexPath: indexPath)
        }
        
        return cell
    }

    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath){
            selectCell(cell, indexPath: indexPath)
        }
        //Keep track of selected items. Items are deselected when scrolled out of view
        selectedCollection.append(indexPath.item)
        selectedFilters.append(catButtonList[indexPath.item])
//        print("Coll \(selectedCollection)")
        
        //filter tree to all categories not matching the selected category
        placeNodeTreeRoot.displayNodeFilter(selectedFilters)
        self.tableView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        if let imageViews = cell?.contentView.subviews{
            for case let image as UIImageView in imageViews{
                image.removeFromSuperview()
            }
        }
        cell?.backgroundColor = UIColor.clear
        //Remove selected item from list Keeping track of selected items' index path
        if let index = selectedCollection.index(of: indexPath.item){
            selectedCollection.remove(at: index)
        }
        //Remove selected item from list Keeping track of selected items' nodeValue string
        if let index = selectedFilters.index(of: catButtonList[indexPath.item]){
            selectedFilters.remove(at: index)
        }
        
        //filter tree to all categories not matching the selected category
        placeNodeTreeRoot.displayNodeFilter(selectedFilters)
        self.tableView.reloadData()
    }
    
    // change background color when user touches cell
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
       let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 1.0)
    }

    // change background color back when user releases touch
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.clear
    }
    
    func selectCell(_ cell: UICollectionViewCell, indexPath: IndexPath)
    {
        let checkImage = UIImage(named: "Check Symbol")
        let checkImageView = UIImageView(image: checkImage)
        
        //center check image at point 50,75
        checkImageView.frame = CGRect(x: 45, y: 70, width: 15, height: 15)
        //add check image
        cell.contentView.addSubview(checkImageView)
        cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
    }
}

