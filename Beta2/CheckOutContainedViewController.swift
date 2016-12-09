//
//  CheckOutContainedViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 10/9/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import Firebase

class CheckOutContainedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cityPeopleTabButton: UIButton!
    
    //Keeps track of with button on the tab bar is selected
    var showPeopleView:Bool = false 
    var myFriends:[String] = []
    var myFriendIds: [NSString] = []    //list of Facebook Id's with matching index to myFriends array
    var friendCities:[String] = []
    var friendsRef: Firebase!
    var cityRef: Firebase!
    let refChecked = Firebase(url:"https://check-inout.firebaseio.com/checked/")
    let currUserDefaultKey = "FBloginVC.currUser"
    fileprivate let sharedFbUser = UserDefaults.standard
    
    var currUser: NSString {
        get
        {
            return (sharedFbUser.object(forKey: currUserDefaultKey) as? NSString)!
        }
    }

//    overide func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        
//    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource=self
        self.tableView.delegate=self
        //remove left padding from tableview seperators
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        //        tableView.registerClass(TestTableViewCell.self,forCellReuseIdentifier: "dataCell")
        self.tableView.backgroundColor=UIColor.clear
        //Create top cell separator for 1st cell
        let px = 1 / UIScreen.main.scale
        let frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: px)
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
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        if(showPeopleView){
            self.performSegue(withIdentifier: "addPeopleSegue", sender: self)
        }else{
            print("add City seque not implementd")
        }
    }
    
    @IBAction func pressTabBar(_ sender: UIButton) {
        let peopleHighImage = UIImage(named: "peopleButton")
        let addPeopleImage = UIImage(named: "addFriendIcon")
        let addCityImage = UIImage(named: "addCityIcon")
        cityPeopleTabButton.setBackgroundImage(peopleHighImage, for: .selected)
        
        sender.isSelected = sender.state == .highlighted ? true : false
        //        Default tab is city view, when button is selected people view is shown
        if(sender.isSelected){
            showPeopleView = true
            addButton.setBackgroundImage(addPeopleImage, for: UIControlState())
        }else{
            showPeopleView = false
            addButton.setBackgroundImage(addCityImage, for: UIControlState())
        }
        self.tableView.reloadData()
    }
    
    //Function retrieves friends and cities and returns when both retrievals are finished
    func retrieveFromFirebase(_ completionClosure: @escaping (_ finished: Bool) -> Void) {
        var finishedFriends = false, finishedCities = false        
        retrieveMyFriends() {(friendStr:[String], friendId:[String]) in
            self.myFriends = friendStr
            self.myFriendIds = friendId as [NSString]
            finishedFriends = true
            if(finishedFriends && finishedCities){
                completionClosure(true)
            }
        }
        retrieveFriendCity() {(completedArr:[String]) in
            self.friendCities = completedArr
            self.friendCities.sort(by: <)
            finishedCities = true
            if(finishedFriends && finishedCities){
                completionClosure(true)
            }
        }
    }
    
    //retrieve a list of all the user's friends
    func retrieveMyFriends(_ completionClosure: @escaping (_ friendStr: [String], _ friendId:[String]) -> Void) {
        var localFriendsArr = [String]()
        var localFriendsId = [String]()
        //Retrieve a list of the user's current check in list
        friendsRef.queryOrdered(byChild: "displayName1").observe(.childAdded, with: { snapshot in
            //If the city is a single dict pair this snap.value will return the city name
            if let currFriend = snapshot?.value as? NSDictionary {
                localFriendsArr.append((currFriend["displayName1"] as? String ?? "Default Name")!)
                localFriendsId.append((snapshot?.key)!)
            }
            completionClosure(localFriendsArr, localFriendsId)
        })
    }
    
    //Retrieve a list of all of the cities the user's friends have
    func retrieveFriendCity(_ completionClosure: @escaping (_ completedArr: [String]) -> Void) {
        var localCityArr = [String]()
        //Query ordered by child will loop each place in the cityRef
        cityRef.queryOrdered(byChild: "city").observe(.childAdded, with: { snapshot in
            //If the city is a single dict pair this snap.value will return the city name
            let nsSnapDict = snapshot?.value as? NSDictionary     //Swift 3 returns snapshot as Any? instead of ID
            if let city = nsSnapDict?["city"] as? String {
                //Only append city if it doesn't already exist in the local city array
                if(!localCityArr.contains(city)){
                    localCityArr.append(city)
                }
            }else{  //The current city entry has a multi entry list
                for child in (snapshot?.children)! {    //each child is either city or cat
                    let rootNode = child as! FDataSnapshot
                    //force downcast only works if root node has children, otherwise value will only be a string
                    let nodeDict = rootNode.value as! NSDictionary
                    for (key, _ ) in nodeDict{
                         if((child as AnyObject).key == "city"){
                            if(!localCityArr.contains(key as! String)){
                                localCityArr.append(key as! String)
                            }
                        }
                    }
                }
            }
            completionClosure(localCityArr)
        })
    }

    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
    }
    
    //Setup data cell height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(showPeopleView){
            return myFriends.count
        }else{
            return friendCities.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellIdentifier = "dataCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! TestTableViewCell   //downcast to my cell class type
        //display table data from either friends list or city list
        if(showPeopleView){
            cell.tableCellValue.text = "    \(myFriends[indexPath.row])"
        }else{
             cell.tableCellValue.text = "  \(friendCities[indexPath.row])"
        }
        cell.tableCellValue.textColor = UIColor.white
        cell.tableCellValue.font = UIFont.systemFont(ofSize: 24, weight: UIFontWeightLight)
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        // Create an instance of myListVC and pass the variable
        //        let controller = MyListViewController(nibName: "MyListViewController", bundle: nil) as MyListViewController
        //        controller.requestedUser = selectedUserId as NSString
        // Perform seque to my List VC
        self.performSegue(withIdentifier: "myListSegue", sender: self)
    }
    
    //Pass the FriendId of the requested list to view
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if(segue.identifier == "myListSegue"){  //only perform if going to MyListVC
            var nameId: String
            // Create a new variable to store the instance ofPlayerTableViewController
            let destinationVC = segue.destination as! MyListViewController
            if(showPeopleView){
                var userName: String = ""
                nameId = "Friend's List"      //Default should it fail
                if let selectedIdx = self.tableView.indexPathForSelectedRow{
                    userName = myFriends[selectedIdx.row]
                    destinationVC.myFriendIds = [myFriendIds[selectedIdx.row]]
                }
                
                //Determine the First Name of the Facebook username before the space
                if let spaceIdx = userName.characters.index(of: " "){
                    nameId = userName.substring(to: spaceIdx)
                }
            
            }else{
                nameId = "Friend's Cities List"      //Default should it fail
                if let selectedIdx = self.tableView.indexPathForSelectedRow{
                     nameId = friendCities[selectedIdx.row]
                    destinationVC.myFriendIds = myFriendIds
                }
            }
            
            destinationVC.headerText = nameId
            destinationVC.showAllCities = !showPeopleView
            
            //Deselect current row so when returning the last selected user is not still selected
            self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
        }
        print("segue to \(segue.identifier)")
    }
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromMyList(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    /*override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue? {
        let segueLeft:SegueFromLeft = SegueFromLeft(identifier: identifier, source: fromViewController, destination: toViewController)
    
        return segueLeft
//            SegueFromLeft(identifier: identifier, source: fromViewController, destination: toViewController)
    }*/
    
}
