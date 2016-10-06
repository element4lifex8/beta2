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
    var myFriends:[String] = []
    var myFriendIds: [String] = []    //list of Facebook Id's with matching index to myFriends array
    var friendsRef: Firebase!
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
        self.tableView.dataSource=self;
        self.tableView.delegate=self;
        //remove left padding from tableview seperators
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
//        tableView.registerClass(TestTableViewCell.self,forCellReuseIdentifier: "dataCell")
        self.tableView.backgroundColor=UIColor.clearColor()
        //Create top cell separator for 1st cell
        let px = 1 / UIScreen.mainScreen().scale
        let frame = CGRectMake(0, 0, self.tableView.frame.size.width, px)
        let line: UIView = UIView(frame: frame)
        self.tableView.tableHeaderView = line
        line.backgroundColor = self.tableView.separatorColor
        
        friendsRef = Firebase(url:"https://check-inout.firebaseio.com/users/\(self.currUser)/friends")
        
        retrieveMyFriends() {(friendStr:[String], friendId:[String]) in
            self.myFriends = friendStr
            self.myFriendIds = friendId
            self.tableView.reloadData()
        }
    }
    
    func retrieveMyFriends(completionClosure: (friendStr: [String], friendId:[String]) -> Void) {
        var localFriendsArr = [String]()
        var localFriendsId = [String]()
        //Retrieve a list of the user's current check in list
        friendsRef.queryOrderedByChild("displayName1").observeEventType(.ChildAdded, withBlock: { snapshot in
            //If the city is a single dict pair this snap.value will return the city name
            if let currFriend = snapshot.value["displayName1"] as? String {
                localFriendsArr.append(currFriend)
                localFriendsId.append(snapshot.key)
            }
            completionClosure(friendStr: localFriendsArr, friendId: localFriendsId)
        })
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = .clearColor()
    }
    
    //Setup data cell height
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 50
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var myListViewController: MyListViewController!
        let selectedItem = myFriends[indexPath.row]
        
        print(selectedItem)
        // create var to store the UID to send to myListVC
        let selectedUserId = myFriendIds[indexPath.row]
        
        //Get ref to storyboard to be able to instantiate view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        myListViewController = storyboard.instantiateViewControllerWithIdentifier("MyListVC") as! MyListViewController
        // Create an instance of myListVC and pass the variable
        
        myListViewController.requestedUser = selectedUserId as NSString
        
        // This will perform the segue and pre-load the variable for you to use
        self.performSegueWithIdentifier("myListSegue", sender: self)
    }
}
