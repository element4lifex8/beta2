//
//  CheckedOutListViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 12/6/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import Firebase

class CheckedOutListViewController: UITableViewController {

    
    var placesArr = [String]()
    var arrSize = Int()
    var ref: Firebase!
    var userRef: Firebase!
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
        print("view did load entered")
        userRef = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
        // Retrieve new posts as they are added to your database
        userRef.observeEventType(.Value, withBlock: { snapshot in
            
            self.placesArr.removeAll()  //start over since we will store the entire array again
            for child in snapshot.children {
                
                //true if child key in the snapshot is not nil, then unwrap and store in array
                if let childKey = child.key{
                    self.placesArr.append(childKey!)
                }
                
                //how to print values of a child in the returned snapshot if key name is known
                //let childSnapshot = snapshot.childSnapshotForPath(child.key)
                //let someValue = childSnapshot.value["someKey"] as? String
                /*{
                 print("\(child.value as String)")
                 self.placesArr.append(child.value)
                 }*/
            }
            self.arrSize = Int(snapshot.childrenCount)
            print(self.placesArr)
            //self.textBoxOnTable.text = "\(self.placesArr[0])"
            //how to print a child value if key name is known
            //if(!snapshot.value != NSNull)
            //print(snapshot.value.objectForKey("city"))
            //print(snapshot.value.objectForKey("category")!)
            
            self.tableView.reloadData() ////releoad table view once a new item is added to the database
            })
        
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
    
    //return the number of rows per section in the table
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrSize
        //return childCount()
    }

    //configures and provides a cell to display for a given row
    //gets called once for each cell that can be displayed on the current screen
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        print("Configuring Test Cell")
        // Configure the cell...
        let cellIdentifier = "testCell"
        //asks the table view for a cell with my cellidentifier which is the name of my custom cell class
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! TestTableViewCell   //downcast to my cell class type
        cell.tableCellValue.text=self.placesArr[indexPath.row]
        print("index row \(indexPath.row)")
        return cell
    }

}
