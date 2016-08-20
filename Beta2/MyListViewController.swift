//
//  MyListViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 8/7/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import Firebase
import Foundation

class MyListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate      {

    var placesArr = [String]()
    var tableData = [String]()
    var placeObj = placeNode()
    var placeNodeTreeRoot = PlaceNodeTree()
    var objArr = [placeNode()]
    var namePlaceNodeDict = [String: placeNode]()
    var cityPlaceNodeDict = [String: [placeNode]]()
    var citySortedDict = [String: [String:[String]]]()  //[Detroit: [bar: [this,that]], DC: [bar [those]]]
    var citySortedArr = [String]()  //Sorted list of the cities in an array
    var cityDict = [String: Int]()
    var tableDataArr = [String]()
    var arrSize = Int()
    var ref: Firebase!
    var userRef: Firebase!
    var placesRef: Firebase!
    var selectedCollection = [Int]()
    var headerCount = 0
    var catButtonList = ["Bar", "Breakfast", "Brunch", "Beaches", "Night Club", "Desert", "Dinner", "Food Trucks", "Hikes", "Lunch", "Museums", "Parks", "Site Seeing"]

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let currUserDefaultKey = "FBloginVC.currUser"
    private let sharedFbUser = NSUserDefaults.standardUserDefaults()
    
    
    var currUser: NSString {
        get
        {
            return (sharedFbUser.objectForKey(currUserDefaultKey) as? NSString)!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //setup tableView delegates
        self.tableView.dataSource=self;
        self.tableView.delegate=self;
        //remove left padding from tableview seperators
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.registerClass(TestTableViewCell.self,forCellReuseIdentifier: "Cell")
        self.tableView.backgroundColor=UIColor.clearColor()
        collectionView?.allowsMultipleSelection = true
        userRef = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
        placesRef = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
        //Retrieve List of checked out places in curr user's list
        retrieveUserPlaces() {(completedArr:[String]) in
            self.placesArr = completedArr

            //pass list of all user's places to retrieve place attributes from master list
            self.retrieveAttributesFromMaster(completedArr){ (placeNodeArr: [placeNode]) in
                self.generateTree(placeNodeArr)
                
                self.sortRetrievedDataByCity()
                self.tableView.reloadData()
            }

        }
    }
    
//Tree generation functions
    func generateTree(nodeArr: [placeNode]){
        //Loop through all place nodes, and iterate over array of categories and cities
        for placeNode in nodeArr{
            //I can have multiple cities for a single placeNode, or city can be nil
            if let cities = placeNode.city{
                for city in cities{
                    if let existingCity = placeNodeTreeRoot.search(city)
                    {
                        addTreeNodeToCity(placeNode, cityNode: existingCity)
                    }else{//Currenty city does not exist
                        let newCityNode = PlaceNodeTree(nodeVal: city)
                        placeNodeTreeRoot.addChild(newCityNode)
                        addTreeNodeToCity(placeNode, cityNode: newCityNode)
                        
                    }
                }
            }
        }
        print(placeNodeTreeRoot)
    }
    
    func addTreeNodeToCity(nodeStruct: placeNode, cityNode: PlaceNodeTree){
        //Add place to existing city for each category
        if let categories = nodeStruct.category{
            for category in categories{
                if let existingCategory = cityNode.search(category){
                    existingCategory.addChild(PlaceNodeTree(nodeVal: nodeStruct.place!))
                }else{//category does not exist
                    let newCategoryNode = PlaceNodeTree(nodeVal: category)
                    cityNode.addChild(newCategoryNode)
                    newCategoryNode.addChild(PlaceNodeTree(nodeVal: nodeStruct.place!))
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
        self.citySortedArr.sortInPlace(<)
        
    }
        
    //function receives the name of the place to look up its city and place attributes
    func retrievePlaceAttributes(place: String, completionClosure: (categoryArr: [String], cityArr: [String]) -> Void)
    {
        let currPlacesRef: Firebase!
        var completedAttrArr = [String]()
        var cityArrLoc = [String]()
        var categoryArrLoc = [String]()
        currPlacesRef = Firebase(url: "https://check-inout.firebaseio.com/checked/places/\(place)")
        currPlacesRef.observeEventType(.Value, withBlock: { childSnapshot in
            if !(childSnapshot.value is NSNull)
            {
                //get category and city key then retreive the attribute's children
                for attribute in childSnapshot.children {
                    //check if multiple children exist beneath currrent node, will return nil if path is not only a key:value
                    if let singleEntry = childSnapshot.childSnapshotForPath(attribute.key).value as? String{
                        if (attribute.key == "city"){
                            cityArrLoc.append(singleEntry)   //append singld child
                        }
                        else if (attribute.key == "category"){
                            categoryArrLoc.append(singleEntry)   //append singld child
                        }
                        else{
                            completedAttrArr.append(singleEntry)   //append singld child
                        }
                    }
                    else{
                        //loop over each entry in child snapshot and store in array
                        let rootNode = attribute as! FDataSnapshot
                        //force downcast only works if root node has children, otherwise value will only be a string
                        let nodeDict = rootNode.value as! NSDictionary
                        for (key, _ ) in nodeDict{
                            if(attribute.key == "city"){
                                cityArrLoc.append(key as! String)
                            }
                            if(attribute.key == "category"){
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
            completionClosure(categoryArr: categoryArrLoc, cityArr: cityArrLoc)
        })
        
    }

    //Funtion is passed the list of checked in places and retrieves the city and category attributes for each place
    func retrieveAttributesFromMaster(retrievedPlaces: [String], completionClosure: (placeNodeArr: [placeNode]) -> Void)
    {
        var localTableDataArr = [String]()
        var locPlaceNodeArr = [placeNode]()
        var locPlaceNodeObj:placeNode = placeNode()
        for (index,place) in retrievedPlaces.enumerate()
        {
            retrievePlaceAttributes(place, completionClosure: { (categoryArr: [String], cityArr: [String]) in
                locPlaceNodeObj = placeNode()
                locPlaceNodeObj.place = place
                localTableDataArr.append(place)
                //store data in the place node
                locPlaceNodeObj.category = categoryArr
                locPlaceNodeObj.city = cityArr
                locPlaceNodeArr.append(locPlaceNodeObj)
                self.namePlaceNodeDict[place] = locPlaceNodeObj
                for attribute in cityArr{
                    localTableDataArr.append(attribute)
                }
                //call completion closure for viewDidLoad calling function if this closure is called on last array item
                if(index == (retrievedPlaces.count - 1)){
                    //localTableDataArr is concatenated list of all data, currently unused
                    completionClosure(placeNodeArr: locPlaceNodeArr)
                }
            })
        }
    }

    //Retrieve list of all checked in places for curr user
    func retrieveUserPlaces(completionClosure: (completedArr: [String]) -> Void) {
        var localPlacesArr = [String]()
        //Retrieve a list of the user's current check in list
        userRef.observeEventType(.Value, withBlock: { snapshot in
            for child in snapshot.children {
                //true if child key in the snapshot is not nil (e.g. attributes about the place exist), then unwrap and store in array
                if let childKey = child.key{
                    localPlacesArr.append(childKey)
                }
            }
            completionClosure(completedArr: localPlacesArr)
        })
    }
        
//  Table view methods

    //Setup section header attributes
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("headerCell") as! HeaderTableViewCell
        //add separator below header
        cell.addSeperator(tableView.frame.size.width)

        cell.tableCellValue.text=placeNodeTreeRoot.children![section].nodeValue
        cell.tableCellValue.font = UIFont(name: "Avenir-HeavyOblique", size: 24)
        cell.tableCellValue.textColor=UIColor.whiteColor()
        //cell.backgroundColor=UIColor.clearColor()
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsetsZero
        return cell
    }
    
    //Setup subheader and data cell attributes
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        let tableValue = getItemWithIndexPath(indexPath)
        //return HeaderTableViewCell if table item is a city
        if(tableValue.isHeader){
            return 33.0
        }else{
            return 50
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = .clearColor()
    }
    
    //Return number of top level entries from the first depth of the tree (Number of cities by default)
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return placeNodeTreeRoot.nodeCountAtDepth(1)
    }
    
//    Unused Function used as a dict lookup for table data
    func getItemWithIndexPath(indexPath: NSIndexPath) -> (place: String,isHeader: Bool)
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
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //Count all of the children for the current section
        return placeNodeTreeRoot.children![section].nodeCountAtDepth(-1)
    }
    
    //configures and provides a cell to display for a given row
    //gets called once for each cell that can be displayed on the current screen
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cellIdentifier:String

        //the root's children are the setion headers, or cities
        //The city becomes the root and is traversed depth first iteratively for the nth item (n=indexPath.row)
        let treeRet = self.placeNodeTreeRoot.children![indexPath.section].returnNodeAtIndex(indexPath.row)
        if let treeNode = treeRet{
            if(treeNode.depth == 2){  //subheader depth
                cellIdentifier = "subheaderCell"
                //asks the table view for a cell with my cellidentifier which is the name of my custom cell class
                let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SubheaderTableViewCell   //downcast to my cell class type
                cell.tableCellValue.text="  \(treeNode.nodeValue!)"
                cell.tableCellValue.font = UIFont(name: "Avenir-Heavy", size: 24)
                cell.tableCellValue.textColor = UIColor.whiteColor()
                //Remove seperator insets
                cell.layoutMargins = UIEdgeInsetsZero
                return cell
            }
            else if(treeNode.depth == 3){
                // Configure the cell if not Header
                cellIdentifier = "dataCell"
                //asks the table view for a cell with my cellidentifier which is the name of my custom cell class
                let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! TestTableViewCell   //downcast to my cell class type
                
                cell.tableCellValue.text = "    \(treeNode.nodeValue!)"
                cell.tableCellValue.font = UIFont(name: "Avenir-Light", size: 24)
                cell.tableCellValue.textColor = UIColor.whiteColor()
                //Remove seperator insets
                cell.layoutMargins = UIEdgeInsetsZero
                return cell
            }
        }

            print("broken")
            cellIdentifier = "subheaderCell"
            //asks the table view for a cell with my cellidentifier which is the name of my custom cell class
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SubheaderTableViewCell   //downcast to my cell class type
            cell.tableCellValue.text="Failed to retrieve cell from tree data structure"

            return cell

    }
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return catButtonList.count
    }

    // make a cell for each cell index path
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "roundButt"
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! RoundButtCollectionViewCell
//        Outlet no longer used and label created in code
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
//        cell.myLabel.text = catButtonList[indexPath.item]
//        cell.myLabel.sizeToFit()

        //Create label here since autolayout only worked after scroll
        let catLabel = UILabel(frame: CGRectMake(0, 0, 86, 25))
        catLabel.center = CGPointMake(50, 50)
        catLabel.textAlignment = NSTextAlignment.Center
        catLabel.text = catButtonList[indexPath.item]

        catLabel.textColor = UIColor.whiteColor()
        cell.contentView.addSubview(catLabel)
        //set cell properties
        cell.backgroundColor = UIColor.clearColor()
        cell.layer.borderColor = UIColor.whiteColor().CGColor
        cell.layer.borderWidth = 2
        cell.layer.cornerRadius = 0.5 * cell.bounds.size.width
        
        if(selectedCollection.contains(indexPath.item)){
            selectCell(cell, indexPath: indexPath)
        }
        
        return cell
    }

    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath){
            selectCell(cell, indexPath: indexPath)
        }
        //Keep track of selected items. Items are deselected when scrolled out of view
        selectedCollection.append(indexPath.item)
        print("Coll \(selectedCollection)")
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        if let imageViews = cell?.contentView.subviews{
            for case let image as UIImageView in imageViews{
                image.removeFromSuperview()
            }
        }
        cell?.backgroundColor = UIColor.clearColor()
        //Keep track of selected items. Items are deselected when scrolled out of view
        if let index = selectedCollection.indexOf(indexPath.item){
            selectedCollection.removeAtIndex(index)
        }
    }
    
    // change background color when user touches cell
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
       let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 1.0)
    }

    // change background color back when user releases touch
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor.clearColor()
    }
    
    func selectCell(cell: UICollectionViewCell, indexPath: NSIndexPath)
    {
        let checkImage = UIImage(named: "Check Symbol")
        let checkImageView = UIImageView(image: checkImage)
        
        //center check image at point 50,75
        checkImageView.frame = CGRectMake(45, 70, 15, 15)
        //add check image
        cell.contentView.addSubview(checkImageView)
        cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
    }
}

