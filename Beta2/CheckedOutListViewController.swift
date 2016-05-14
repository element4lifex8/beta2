//
//  CheckedOutListViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 12/6/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import Firebase
import Foundation

class CheckedOutListViewController: UITableViewController {

    
    var placesArr = [String]()
    var tableData = [String]()
    var cityDict = [String: Int]()
    var tableDataArr = [String]()
    var arrSize = Int()
    var ref: Firebase!
    var userRef: Firebase!
    var placesRef: Firebase!
    let currUserDefaultKey = "FBloginVC.currUser"
    private let sharedFbUser = NSUserDefaults.standardUserDefaults()


    var currUser: NSString {
        get
        {
            return (sharedFbUser.objectForKey(currUserDefaultKey) as? NSString)!
        }
    }

    let restNameDefaultKey = "CheckInView.restName"
    private let sharedRestName = NSUserDefaults.standardUserDefaults()
    
    var restNameHistory: [String] {
        get
        {
            return sharedRestName.objectForKey(restNameDefaultKey) as? [String] ?? []
        }
        set
        {
            sharedRestName.setObject(newValue, forKey: restNameDefaultKey)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(TestTableViewCell.self,
                                forCellReuseIdentifier: "Cell")
        userRef = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
        placesRef = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
        retrieveTablePlacesData() {(completedArr:[String]) in
            self.placesArr = completedArr
            self.retrieveTableAttributeData(completedArr){ (completeTableDataArr: [String]) in
                self.tableDataArr = completeTableDataArr
                self.tableView.reloadData()
            }
        }
        
        // Retrieve new posts from currUser's list as they are added to your database
//        userRef.observeEventType(.Value, withBlock: { snapshot in
//            
//            self.placesArr.removeAll()  //start over since we will store the entire array again
//            for child in snapshot.children {
//                
//                //true if child key in the snapshot is not nil, then unwrap and store in array
//                if let childKey = child.key{
//                    self.placesArr.append(childKey!)
//                }
//                
//                //how to print values of a child in the returned snapshot if key name is known
//                //let childSnapshot = snapshot.childSnapshotForPath(child.key)
//                //let someValue = childSnapshot.value["someKey"] as? String
//                /*{
//                 print("\(child.value as String)")
//                 self.placesArr.append(child.value)
//                 }*/
//            }
//            self.arrSize = Int(snapshot.childrenCount)
//            print(self.placesArr)
            //self.textBoxOnTable.text = "\(self.placesArr[0])"
            //how to print a child value if key name is known
            //if(!snapshot.value != NSNull)
            //print(snapshot.value.objectForKey("city"))
            //print(snapshot.value.objectForKey("category")!)
            
//            self.tableView.reloadData() ////releoad table view once a new item is added to the database
//            })
        
    }
    
    func formatTableData(){
        print(cityDict)
        for (index,entry) in self.placesArr.enumerate()
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
    
    //function receives the name of the place to look up its city and place attributes
    func retrievePlaceAttributes(place: String, completionClosure: (attributeArr: [String]) -> Void)
    {
        var currPlacesRef: Firebase!
        var completedAttrArr = [String]()
        currPlacesRef = Firebase(url: "https://check-inout.firebaseio.com/checked/places/\(place)")
        currPlacesRef.observeEventType(.Value, withBlock: { childSnapshot in
            //print("place children count \(childSnapshot.childrenCount)")
            if !(childSnapshot.value is NSNull)
            {
                //get category and city key then retreive the attribute's children
                for attribute in childSnapshot.children {
                    //check if multiple children exist beneath currrent node
                    if let singleEntry = childSnapshot.childSnapshotForPath(attribute.key).value as? String{
                        //print(singleEntry)
                        completedAttrArr.append(singleEntry)   //append singld child
                    }
                    else{
                        //loop over each entry in child snapshot and store in array
                        let rootNode = attribute as! FDataSnapshot
                        //                                    print("item val \(item.value)")
                        //force downcast only works if root node has children, otherwise value will only be a string
                        let nodeDict = rootNode.value as! NSDictionary
                        for (key, _ ) in nodeDict{
                            //                                        print("key \(key) value: \(value)")
                            completedAttrArr.append(key as! String)
                        }
                    }
                }
                print("complete att arr \(completedAttrArr)")
            }
            else
            {
                print("attribute \(childSnapshot.key) found but contained no children")
            }
            completionClosure(attributeArr: completedAttrArr)
        })

    }
    
    //Funtion is passed the list of checked in places and retrieves the city and category attributes for each place
    func retrieveTableAttributeData(retrievedPlaces: [String], completionClosure: (completeTableDataArr: [String]) -> Void)
    {
        var localTableDataArr = [String]()
        for (index,place) in retrievedPlaces.enumerate()
        {
            retrievePlaceAttributes(place, completionClosure: { (attributeArr: [String]) in
                localTableDataArr.append(place)
                for attribute in attributeArr{
                    localTableDataArr.append(attribute)
                }
                //call completion closure for viewDidLoad calling function if this closure is called on last array item
                if(index == (retrievedPlaces.count - 1)){
                    print("Table Data \(localTableDataArr)")
                    completionClosure(completeTableDataArr: localTableDataArr)
                }
            })
        }
        
        
//        for place in retrievedPlaces
//        {
//            currPlacesRef = Firebase(url: "https://check-inout.firebaseio.com/checked/places/\(place)")
//            currPlacesRef.observeEventType(.Value, withBlock: { childSnapshot in
//                print("place children count \(childSnapshot.childrenCount)")
//                if !(childSnapshot.value is NSNull)
//                {
//                    //get child and city key then retreive the attribute's children
//                    for attribute in childSnapshot.children {
//                    //check if multiple children exist beneath currrent node
//                        if let singleEntry = childSnapshot.childSnapshotForPath(attribute.key).value as? String{
//                            //print(singleEntry)
//                            self.cityDict[singleEntry]=cityCounter   //append singld child
//                        }
//                        else{
//                            //loop over each entry in child snapshot and store in array
//                            let rootNode = attribute as! FDataSnapshot
//    //                                    print("item val \(item.value)")
//                            //force downcast only works if root node has children, otherwise value will only be a string
//                            let nodeDict = rootNode.value as! NSDictionary
//                            for (key, _ ) in nodeDict{
//    //                                        print("key \(key) value: \(value)")
//                                self.cityDict[key as! String]=cityCounter
//                            }
//                            //broken,can't iterate over anyobject at childSanpForPath
//                            //print("broke\(childSnapshot.childSnapshotForPath(attribute.key).value)")
//    //                                    {
//    //                                        self.placesArr.append(childLeaf.key)
//    //                                    }
//                        }
//                    }
//    //                            print("not ill \(childSnapshot.value.objectForKey("city"))")
//    //                            //get city object if multiple cities are present
//    //                            if let cityObject = childSnapshot.value.objectForKey("city")
//    //                            {
//    //                               if cityObject is AnyObject{
//    //                                    print("ANy object")
//    //                                }
//    //                                //print("City downcast: \(cityString)")
//    //
//    //                            }
//    //                            else{
//    //                                print("no city included")}
//    //
//    //                            //for placesChild in childSnapshot.children {
//    //                            //print("places child:\(placesChild.key)")
//    //                            //let placesChildSnapshot = childSnapshot.childSnapshotForPath("city")
//    //
//    //                            //if only one city is present then I can get the value of the city key
//    //                            let city = childSnapshot.value["city"] as? String
//    //                           print("city of \(childKey) : \(city)")
//                }
//                cityCounter += 1
//                self.formatTableData()
//                //self.tableView.reloadData()
//            })
//        }
    }
    
    func retrieveTablePlacesData(completionClosure: (completedArr: [String]) -> Void) {
        var currPlacesRef: Firebase!
        var cityIndex = String()
        var cityCounter = 0
        var localPlacesArr = [String]()
        //Retrieve a list of the user's current check in list
        userRef.observeEventType(.Value, withBlock: { snapshot in
           // self.placesArr.removeAll()  //start over since we will store the entire array again
            print(snapshot.childrenCount)
            for child in snapshot.children {
                //print(child.key)
                //true if child key in the snapshot is not nil (e.g. attributes about the place exist), then unwrap and store in array
                if let childKey = child.key{
                   localPlacesArr.append(childKey!)
//                    currPlacesRef = Firebase(url: "https://check-inout.firebaseio.com/checked/places/\(childKey)")
//                    currPlacesRef.observeEventType(.Value, withBlock: { childSnapshot in
////                        print("chill \(childSnapshot.childrenCount)")
//                        if !(childSnapshot.value is NSNull)
//                        {
//                            //get child and city key then retreive the attribute's children
//                            for attribute in childSnapshot.children {
//                            //check if multiple children exist beneath currrent node
//                                if let singleEntry = childSnapshot.childSnapshotForPath(attribute.key).value as? String{
//                                    //print(singleEntry)
//                                    self.cityDict[singleEntry]=cityCounter   //append singld child
//                                }
//                                else{
//                                    //loop over each entry in child snapshot and store in array
//                                    let rootNode = attribute as! FDataSnapshot
////                                    print("item val \(item.value)")
//                                    //force downcast only works if root node has children, otherwise value will only be a string
//                                    let nodeDict = rootNode.value as! NSDictionary
//                                    for (key, _ ) in nodeDict{
////                                        print("key \(key) value: \(value)")
//                                        self.cityDict[key as! String]=cityCounter
//                                    }
//                                    //broken,can't iterate over anyobject at childSanpForPath
//                                    //print("broke\(childSnapshot.childSnapshotForPath(attribute.key).value)")
////                                    {
////                                        self.placesArr.append(childLeaf.key)
////                                    }
//                                }
//                            }
////                            print("not ill \(childSnapshot.value.objectForKey("city"))")
////                            //get city object if multiple cities are present
////                            if let cityObject = childSnapshot.value.objectForKey("city")
////                            {
////                               if cityObject is AnyObject{
////                                    print("ANy object")
////                                }
////                                //print("City downcast: \(cityString)")
////                                
////                            }
////                            else{
////                                print("no city included")}
////                            
////                            //for placesChild in childSnapshot.children {
////                            //print("places child:\(placesChild.key)")
////                            //let placesChildSnapshot = childSnapshot.childSnapshotForPath("city")
////                            
////                            //if only one city is present then I can get the value of the city key
////                            let city = childSnapshot.value["city"] as? String
////                           print("city of \(childKey) : \(city)")
//                        }
//                        cityCounter += 1
//                        self.formatTableData()
//                        //self.tableView.reloadData()
//                    })
//
                }
            }
            completionClosure(completedArr: localPlacesArr)
        })
        //Retrieve the details of each checked place and create new entry in dictArr for each city
//        for entry in placesArr{
//            placesRef.childByAppendingPath(entry).observeEventType(.Value, withBlock: { snapshot in
//                for child in snapshot.children {
//                    let childSnapshot = snapshot.childSnapshotForPath(child.key)
//                    let someValue = childSnapshot.value["city"] as? String
//                }
//            })
//        }
    }
    
    
    func childCount() -> Int {
        var count: Int = 0
        userRef = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
        // Retrieve new posts as they are added to your database
        userRef.observeEventType(.Value, withBlock: { snapshot in
            count = Int(snapshot.childrenCount)
            print("count from childCount func \(count)")
            })
        return count
    }
    
    //default to having 1 section per table
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
//    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return "Test"
//        //return self.section\[section\]
//        
//    }
    
    //return the number of rows per section in the table
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableDataArr.count
        //return childCount()
    }

    //configures and provides a cell to display for a given row
    //gets called once for each cell that can be displayed on the current screen
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        //print("Configuring Test Cell")
        // Configure the cell...
        let cellIdentifier = "testCell"
        //asks the table view for a cell with my cellidentifier which is the name of my custom cell class
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! TestTableViewCell   //downcast to my cell class type
        cell.tableCellValue.text=self.tableDataArr[indexPath.row]
        //print("index row \(indexPath.row)")
        return cell
    }

}
