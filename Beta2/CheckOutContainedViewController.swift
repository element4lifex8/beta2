//
//  CheckOutContainedViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 10/9/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import Firebase

class CheckOutContainedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, sendContainerDelegate {
    
    @IBOutlet weak var cityButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var showPeopleView:Bool = false
 
    var myFriends:[String] = []
    var myFriendIds: [NSString] = []    //list of Facebook Id's with matching index to myFriends array
    var friendCities:[String] = []
    var friendsRef: Firebase!
    var cityRef: Firebase!
    let refChecked = Firebase(url:"https://check-inout.firebaseio.com/checked/")
    let currUserDefaultKey = "FBloginVC.currUser"
    private let sharedFbUser = NSUserDefaults.standardUserDefaults()
    
    var currUser: NSString {
        get
        {
            return (sharedFbUser.objectForKey(currUserDefaultKey) as? NSString)!
        }
    }

    override func viewDidLoad() {
        //set delegate to container VC to receive button state
//        Get ref to storyboard to be able to instantiate view controller
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let containerVC = storyboard.instantiateViewControllerWithIdentifier("CheckOutViewController") as! CheckedOutViewController
//        let containerVC: CheckedOutViewController = CheckedOutViewController(nibName: "CheckedOutViewController", bundle: nil) as CheckedOutViewController
        containerVC.containerDelegate = self

        
        super.viewDidLoad()
        self.tableView.dataSource=self
        self.tableView.delegate=self
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
         cityRef = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
        retrieveFromFirebase{(finished:Bool)
            in
            if(finished){
                self.tableView.reloadData()
            }
        }
//        var buttonWatch:Bool = showPeopleView{
//            didSet{
//               self.tableView.reloadData() 
//            }
//        }
        
    }
    
    func buttonStateChange(shouldDisplayPeople: Bool){
        print("Called delegate")
        showPeopleView = shouldDisplayPeople
        self.tableView.reloadData()
    }
    
    @IBAction func cityPresed(sender: UIButton) {
        print("Ciry Button")
    }
    //Function retrieves friends and cities and returns when both retrievals are finished
    func retrieveFromFirebase(completionClosure: (finished: Bool) -> Void) {
        var finishedFriends = false, finishedCities = false
        retrieveMyFriends() {(friendStr:[String], friendId:[String]) in
            self.myFriends = friendStr
            self.myFriendIds = friendId
            finishedFriends = true
            if(finishedFriends && finishedCities){
                completionClosure(finished: true)
            }
        }
        retrieveFriendCity() {(completedArr:[String]) in
            self.friendCities = completedArr
            finishedCities = true
            if(finishedFriends && finishedCities){
                completionClosure(finished: true)
            }
        }
    }
    //retrieve a list of all the user's friends
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
    
    //Retrieve a list of all of the cities the user's friends have
    func retrieveFriendCity(completionClosure: (completedArr: [String]) -> Void) {
        var localCityArr = [String]()
        //Query ordered by child will loop each place in the cityRef
        cityRef.queryOrderedByChild("city").observeEventType(.ChildAdded, withBlock: { snapshot in
            //If the city is a single dict pair this snap.value will return the city name
            if let city = snapshot.value["city"] as? String {
                //Only append city if it doesn't already exist in the local city array
                if(!localCityArr.contains(city)){
                    localCityArr.append(city)
                }
            }else{  //The current city entry has a multi entry list
                for child in snapshot.children {    //each child is either city or cat
                    let rootNode = child as! FDataSnapshot
                    //force downcast only works if root node has children, otherwise value will only be a string
                    let nodeDict = rootNode.value as! NSDictionary
                    for (key, _ ) in nodeDict{
                        if(child.key == "city"){
                            if(!localCityArr.contains(key as! String)){
                                localCityArr.append(key as! String)
                            }
                        }
                    }
                }
            }
            completionClosure(completedArr: localCityArr)
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
        if(showPeopleView){
            return myFriends.count
        }else{
            return friendCities.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cellIdentifier = "dataCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! TestTableViewCell   //downcast to my cell class type
        //display table data from either friends list or city list
        if(showPeopleView){
            cell.tableCellValue.text = "    \(myFriends[indexPath.row])"
        }else{
             cell.tableCellValue.text = "  \(friendCities[indexPath.row])"
        }
        cell.tableCellValue.textColor = UIColor.whiteColor()
        cell.tableCellValue.font = UIFont.systemFontOfSize(24, weight: UIFontWeightLight)
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsetsZero
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //        // Create an instance of myListVC and pass the variable
        //        let controller = MyListViewController(nibName: "MyListViewController", bundle: nil) as MyListViewController
        //        controller.requestedUser = selectedUserId as NSString
        // Perform seque to my List VC
        self.performSegueWithIdentifier("myListSegue", sender: self)
    }
    
    //Pass the FriendId of the requested list to view
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if(segue.identifier == "myListSegue"){  //only perform if going to MyListVC
            let userName = myFriends[self.tableView.indexPathForSelectedRow!.row]
            var firstName = "Friend's List"
            
            //Determine the First Name of the Facebook username before the space
            if let spaceIdx = userName.characters.indexOf(" "){
                firstName = userName.substringToIndex(spaceIdx)
            }
            // Create a new variable to store the instance ofPlayerTableViewController
            let destinationVC = segue.destinationViewController as! MyListViewController
            destinationVC.requestedUser = myFriendIds[self.tableView.indexPathForSelectedRow!.row]
            destinationVC.headerText = firstName
            
            //Deselect current row so when returning the last selected user is not still selected
            self.tableView.deselectRowAtIndexPath(self.tableView.indexPathForSelectedRow!, animated: true)
        }
    }
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromMyList(sender: UIStoryboardSegue) {
        // empty
    }
    
}
