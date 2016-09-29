//
//  CheckOutPeopleViewController.swift
//  Pods
//
//  Created by Jason Johnston on 9/25/16.
//
//

import UIKit
import Firebase
import Foundation

class CheckOutPeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var friendsRef: Firebase!
    let currUserDefaultKey = "FBloginVC.currUser"
    private let sharedFbUser = NSUserDefaults.standardUserDefaults()
    
    
    var currUser: NSString {
        get
        {
            return (sharedFbUser.objectForKey(currUserDefaultKey) as? NSString)!
        }
    }
    
    var myFriends:[String] = []
    var peopleArr = ["Jimmy", "John", "Jackie", "Jeremy", "Jack", "Jill", "bob", "Lil"]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource=self;
        self.tableView.delegate=self;
        //remove left padding from tableview seperators
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
//        tableView.registerClass(TestTableViewCell.self,forCellReuseIdentifier: "dataCell")
        self.tableView.backgroundColor=UIColor.clearColor()
        
        friendsRef = Firebase(url:"https://check-inout.firebaseio.com/users/\(self.currUser)/friends")
        
        retrieveMyFriends() {(completedArr:[String]) in
            self.myFriends = completedArr
            self.tableView.reloadData()
        }
    }
    
    func retrieveMyFriends(completionClosure: (completedArr: [String]) -> Void) {
        var localPlacesArr = [String]()
        //Retrieve a list of the user's current check in list
        friendsRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            for child in snapshot.children {
                //true if child key in the snapshot is not nil (e.g. attributes about the place exist), then unwrap and store in array
                if let childKey = child.key{
                    localPlacesArr.append(childKey)
                }
            }
            completionClosure(completedArr: localPlacesArr)
        })
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = .clearColor()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myFriends.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cellIdentifier = "dataCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! TestTableViewCell   //downcast to my cell class type
        cell.tableCellValue.text = "    \(myFriends[indexPath.row])"
        cell.tableCellValue.textColor = UIColor.whiteColor()
        cell.tableCellValue.font = UIFont.systemFontOfSize(24, weight: UIFontWeightLight)
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsetsZero
        return cell
    }
}
