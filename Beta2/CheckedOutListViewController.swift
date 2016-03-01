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

    override func viewDidLoad() {
        super.viewDidLoad()
        var ref = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
        // Retrieve new posts as they are added to your database
        ref.observeEventType(.ChildAdded, withBlock: { snapshot in
            print(snapshot.value.objectForKey("city"))
            print(snapshot.value.objectForKey("category")!)
            print(snapshot.childrenCount)
        })

        // Do any additional setup after loading the view.
    }

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
    
    func childCount() -> Int {
        var ref = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
        var count: Int = 0  
        // Retrieve new posts as they are added to your database
        ref.observeEventType(.ChildAdded, withBlock: { snapshot in
            count = Int(snapshot.childrenCount)
        })
        return count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restNameHistory.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        // Configure the cell...
        let cellIdentifier = "testCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! TestTableViewCell
        cell.tableCellValue.text=restNameHistory[indexPath.row]


        return cell
    }

}
