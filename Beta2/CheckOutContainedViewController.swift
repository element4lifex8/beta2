//
//  CheckOutContainedViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 10/9/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import FirebaseDatabase

class CheckOutContainedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cityPeopleTabButton: UIButton!
    
    //Keeps track of with button on the tab bar is selected
    var showPeopleView:Bool = false 
    var myFriends:[String] = []
    var myFriendIds: [NSString] = []    //list of Facebook Id's with matching index to myFriends array
    var friendCities:[String] = []
    var friendsRef: FIRDatabaseReference!
    var cityRef: FIRDatabaseReference!
//    let refChecked = Firebase(url:"https://check-inout.firebaseio.com/checked/")
    let refChecked = FIRDatabase.database().reference().child("checked")
    let currUserDefaultKey = "FBloginVC.currUser"
    fileprivate let sharedFbUser = UserDefaults.standard
    
    var currUser: NSString {
        get
        {
            return (sharedFbUser.object(forKey: currUserDefaultKey) as? NSString)!
        }
    }

    

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
        
//        friendsRef = Firebase(url:"https://check-inout.firebaseio.com/users/\(self.currUser)/friends")
        friendsRef = FIRDatabase.database().reference().child("users/\(self.currUser)/friends")
//         cityRef = Firebase(url:"https://check-inout.firebaseio.com/checked")
        cityRef = FIRDatabase.database().reference().child("checked")
        retrieveFromFirebase{(finished:Bool)
            in
            if(finished){
                self.tableView.reloadData()
                activityIndicator.stopAnimating()
                loadingView.removeFromSuperview()
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
            //Set image location and remove background of add button when changing image so that image doesn't stretch
            addButton.setBackgroundImage(nil, for: UIControlState())
            addButton.titleEdgeInsets.top = 8.0
            addButton.titleEdgeInsets.right = 7.0
            addButton.setImage(addPeopleImage, for: UIControlState())
        }else{
            showPeopleView = false
            addButton.setImage(nil, for: UIControlState())
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
            //Once I have a list of all friends, get all of their cities using their facebook id
            self.retrieveFriendCity(friendsList: friendId) {(completedArr:[String]) in
            self.friendCities = completedArr
            self.friendCities.sort(by: <)
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
            if let currFriend = snapshot.value as? NSDictionary {
                if let displayName = currFriend["displayName1"]{
                    localFriendsArr.append(displayName as! String)
                    localFriendsId.append((snapshot.key))
                }
//                localFriendsArr.append((currFriend["displayName1"] as? String ?? "Default Name")!)
//                localFriendsId.append((snapshot?.key)!)
            }
            completionClosure(localFriendsArr, localFriendsId)
        })
    }
    
    //Retrieve a list of all of the cities the user's friends have
    func retrieveFriendCity(friendsList: [String], completionClosure: @escaping (_ completedArr: [String]) -> Void) {
        var localCityArr = [String]()
        var loopCount = 0
        //Loop over all the user's friends to get a list of their cities
        for friendId in friendsList{
            //Query ordered by child will loop each place in the cityRef
            cityRef.child(friendId).queryOrdered(byChild: "city").observe(.childAdded, with: { snapshot in
                //If the city is a single dict pair this snap.value will return the city name
                let nsSnapDict = snapshot.value as? NSDictionary     //Swift 3 returns snapshot as Any? instead of ID
                if let city = nsSnapDict?["city"] as? String {
                    //Only append city if it doesn't already exist in the local city array
                    if(!localCityArr.contains(city)){
                        localCityArr.append(city)
                    }
                }else{  //The current city entry has a multi entry list
                    for child in (snapshot.children) {    //each child is either city, cat or place ID
                        let rootNode = child as! FIRDataSnapshot
                        //force downcast only works if root node has children, otherwise value will only be a string
                        //If nodeDict can't be unwrapped then the key value pair is the google place id
                        if let nodeDict = rootNode.value as? NSDictionary{
                            for (key, _ ) in nodeDict{
                                 if((child as AnyObject).key == "city"){
                                    if(!localCityArr.contains(key as! String)){
                                        localCityArr.append(key as! String)
                                    }
                                }
                            }
                        }else{
                            print("got a place ID for \(rootNode.value)")
                        }
                    }
                }
                loopCount+=1
                //Once all friends have been looped over, call completion closure
                if(loopCount >= friendsList.count){
                    completionClosure(localCityArr)
                }
            })
        }
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
