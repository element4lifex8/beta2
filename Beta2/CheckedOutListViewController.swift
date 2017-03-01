//
//  CheckedOutListViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 12/6/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Foundation
//Unused view controller previously attempted to create contained view controller
//View controller container used to simultaneously load checkOutCity and checkOutPeople data
class CheckedOutListViewController: UITableViewController {

    
    var placesArr = [String]()
    var tableData = [String]()
    var placeObj = placeNode()
    var objArr = [placeNode()]
    var namePlaceNodeDict = [String: placeNode]()
    var cityPlaceNodeDict = [String: [placeNode]]()
    var citySortedDict = [String: [String:[String]]]()  //[Detroit: [bar: [this,that]], DC: [bar [those]]]
    var citySortedArr = [String]()  //Sorted list of the cities in an array
    var cityDict = [String: Int]()
    var tableDataArr = [String]()
    var arrSize = Int()
    var ref: FIRDatabaseReference!
    var userRef: FIRDatabaseReference!
    var placesRef: FIRDatabaseReference!
    var headerCount = 0
    
    var currUser = Helpers().currUser

    let restNameDefaultKey = "CheckInView.restName"
    fileprivate let sharedRestName = UserDefaults.standard
    
    var restNameHistory: [String] {
        get
        {
            return sharedRestName.object(forKey: restNameDefaultKey) as? [String] ?? []
        }
        set
        {
            sharedRestName.set(newValue, forKey: restNameDefaultKey)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        tableView.registerClass(TestTableViewCell.self,
//                                forCellReuseIdentifier: "Cell")
//        userRef = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
        userRef = FIRDatabase.database().reference().child("checked/\(self.currUser)")
//        placesRef = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
        placesRef = FIRDatabase.database().reference().child("checked/places")
        //Retrieve List of checked out places in curr user's list
        retrieveUserPlaces() {(completedArr:[String]) in
            self.placesArr = completedArr
            self.placeObj.place = completedArr[0]
            //pass list of all user's places to retrieve place attributes from master list
            self.retrieveAttributesFromMaster(completedArr){ (completeTableDataArr: [String]) in
                //localTableDataArr is concatenated list of all data, currently unused
                self.tableDataArr = completeTableDataArr
                self.sortRetrievedDataByCity()
                self.tableView.reloadData()
            }
        }
        
//            //how to print values of a child in the returned snapshot if key name is known
//            let childSnapshot = snapshot.childSnapshotForPath(child.key)
//            let someValue = childSnapshot.value["someKey"] as? String
//
//            //how to print a child value if key name is known
//            if(!snapshot.value != NSNull)
//            print(snapshot.value.objectForKey("city"))
//            print(snapshot.value.objectForKey("category")!)
        
        
    }
    
    func formatTableData(){
        print(cityDict)
        for (index,entry) in self.placesArr.enumerated()
        {
            tableData.append(entry)
            for (key,value) in cityDict
            {
                if(value == index)
                {
                    tableData.append(key)
                }
            }
            
        }
        self.tableView.reloadData()
    }
    
    
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
    

    //function receives the name of the place to look up its city and place attributes
    func retrievePlaceAttributes(_ place: String, completionClosure: @escaping (_ categoryArr: [String], _ cityArr: [String]) -> Void)
    {
        let currPlacesRef: FIRDatabaseReference!
        var completedAttrArr = [String]()
        var cityArrLoc = [String]()
        var categoryArrLoc = [String]()
//        currPlacesRef = Firebase(url: "https://check-inout.firebaseio.com/checked/places/\(place)")
        currPlacesRef = FIRDatabase.database().reference().child("checked/places\(place)")
        currPlacesRef.observe(.value, with: { childSnapshot in
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
            completionClosure(categoryArrLoc, cityArrLoc)
        })

    }
    
    //Funtion is passed the list of checked in places and retrieves the city and category attributes for each place
    func retrieveAttributesFromMaster(_ retrievedPlaces: [String], completionClosure: @escaping (_ completeTableDataArr: [String]) -> Void)
    {
        var localTableDataArr = [String]()
        var locPlaceNodeArr = [placeNode]()
        var locPlaceNodeObj:placeNode = placeNode()
        for (index,place) in retrievedPlaces.enumerated()
        {
            retrievePlaceAttributes(place, completionClosure: { (categoryArr: [String], cityArr: [String]) in
                locPlaceNodeObj = placeNode()
                locPlaceNodeArr.removeAll()
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
                    completionClosure(localTableDataArr)
                }
            })
        }
    }
    
    //Retrieve list of all checked in places for curr user
    func retrieveUserPlaces(_ completionClosure: @escaping (_ completedArr: [String]) -> Void) {
        var localPlacesArr = [String]()
        //Retrieve a list of the user's current check in list
        userRef.observe(.value, with: { snapshot in
            for child in (snapshot.children) {
                //true if child key in the snapshot is not nil (e.g. attributes about the place exist), then unwrap and store in array
//                if let childKey = (child as AnyObject).key{
//                   localPlacesArr.append(childKey!)
//                }
            }
            completionClosure(localPlacesArr)
        })
    }
    
    //Setup section header attributes
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell") as! HeaderTableViewCell
        cell.tableCellValue.text=self.citySortedArr[section]
        cell.tableCellValue.font = UIFont.boldSystemFont(ofSize: 36)
        return cell
    }
    
    
    //Return number of top level entries in sorted dict e.g.  num cities from [City : [Cat:[Place]]]
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.citySortedArr.count
    }
    
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
                //Since the first entry was a category, need to increment the arr count
                subIndexRow -= placeArr.count + 1
            }
        }
        if(currPlace == ""){currPlace="table parsing failed"}
        return(currPlace,header)
        
        
    }

    
    //return the number of rows per section in the table
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let currCityAttrDict = self.citySortedDict[self.citySortedArr[section]]   //get [Category: [Places]] for current city
        var catNameAndPlaceCount = currCityAttrDict?.count  //store the num categories
        //loop over all places in each category to get the full count
        for (_,placeArr) in currCityAttrDict!{
            catNameAndPlaceCount! += placeArr.count
        }
        return catNameAndPlaceCount!
    }

    //configures and provides a cell to display for a given row
    //gets called once for each cell that can be displayed on the current screen
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let tableValue = getItemWithIndexPath(indexPath)
        var cellIdentifier:String
        //return HeaderTableViewCell if table item is a city
        if(tableValue.isHeader)
        {
            cellIdentifier = "subheaderCell"
            //asks the table view for a cell with my cellidentifier which is the name of my custom cell class
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SubheaderTableViewCell   //downcast to my cell class type
            cell.tableCellValue.text=tableValue.place
            cell.tableCellValue.font = UIFont.systemFont(ofSize: 24, weight: UIFontWeightMedium)
            return cell
        }
        else{
            // Configure the cell if not Header
            cellIdentifier = "dataCell"
            //asks the table view for a cell with my cellidentifier which is the name of my custom cell class
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! TestTableViewCell   //downcast to my cell class type
            cell.tableCellValue.text=tableValue.place
            cell.tableCellValue.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightLight)
            return cell
        }
    }

}
