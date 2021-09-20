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
    
    //If transition to this screen wants to force showing people, update this var
    //Info from login screen that will be populated here
    var callerWantsToShowPeople: Bool?
    
    //Keeps track of with button on the tab bar is selected
    //If calling VC specifies to show people then do so, otherwise false
    var showPeopleView:Bool = false
    //Keep track of whether I am controlling the button manually or if its controlled from the GUI
    var manualTabControl = false
    var myFriends:[String] = []
    var myFriendIds: [NSString] = []    //list of Facebook Id's with matching index to myFriends array
    var friendCities:[String] = []
    var friendsRef: DatabaseReference!
    var cityRef: DatabaseReference!
    //Handle to the reference observer that needs to be removed when popping the VC from the stack
    var friendHandler, cityHandler: DatabaseHandle?

//    let refChecked = Firebase(url:"https://check-inout.firebaseio.com/checked/")
    let refChecked = Database.database().reference().child("checked")
    let currUserDefaultKey = "FBloginVC.currUser"
    //Retrieve curr user from User Defaults
    var currUser = Helpers().currUser

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //If calling VC specifies to show people then do so, otherwise false
        showPeopleView = (callerWantsToShowPeople ?? false) || showPeopleView
        //Show people view when tab bar button is selected
        if (showPeopleView)
        {
            cityPeopleTabButton.isSelected = true
            self.manualTabControl = true
            setTabBarBackground(cityPeopleTabButton)
        }
        
    }
//        //Create container view then loading for activity indicator to prevent background from overshadowing white color
//        let loadingView: UIView = UIView()
//        
//        loadingView.frame = CGRect(x: 0,y: 0,width: 80,height: 80)
//        loadingView.center = view.center
//        loadingView.backgroundColor = UIColor(red: 0x44/255, green: 0x44/255, blue: 0x44/255, alpha: 0.7)
//        loadingView.clipsToBounds = true
//        loadingView.layer.cornerRadius = 10
//        
//        //Start activity indicator while making Firebase request
//        let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50, height: 50)) as UIActivityIndicatorView
//        activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2,y: loadingView.frame.size.height / 2);
//        //        activityIndicator.backgroundColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 0.3)
//        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
//        activityIndicator.hidesWhenStopped = true
//        
//        
//        //Don't request data again if I already have data in my arrays
//        //Also we won't show the activity monitor unless we are sending request
//        if((self.myFriends.count == 0) && (self.friendCities.count == 0)){
//            //Show activity monitor
//            loadingView.addSubview(activityIndicator)
//            view.addSubview(loadingView)
//            activityIndicator.startAnimating()
//            friendsRef = FIRDatabase.database().reference().child("users/\(self.currUser)/friends")
//            cityRef = FIRDatabase.database().reference().child("checked")
//            retrieveFromFirebase{(finished:Bool)
//                in
//                if(finished){
//                    self.tableView.reloadData()
//                    activityIndicator.stopAnimating()
//                    loadingView.removeFromSuperview()
//                }
//            }
//        }
//        //For the time being the add city button is disabled when showing cities since we don't have an add city button(re-enabled in the tab bar select function)
//        if(!showPeopleView){
//            addButton.isEnabled = false
//            addButton.isHidden = true
//        }
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
        let frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height:  px)
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
        friendsRef = Database.database().reference().child("users/\(self.currUser)/friends")
//         cityRef = Firebase(url:"https://check-inout.firebaseio.com/checked")
        cityRef = Database.database().reference().child("checked")
        retrieveFromFirebase{(finished:Bool)
            in
            if(finished){
                self.tableView.reloadData()
                activityIndicator.stopAnimating()
                loadingView.removeFromSuperview()
            }
        }
        //For the time being the add city button is disabled (re-enabled in the tab bar select function)
        addButton.isEnabled = false
        addButton.isHidden = true
        
        var buttonWatch:Bool = showPeopleView{
            didSet{
               self.tableView.reloadData() 
            }
        }
        
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        if(showPeopleView){
            self.performSegue(withIdentifier: "addPeopleSegue", sender: self)
        }else{
            Helpers().myPrint(text: "add City seque not implementd")
        }
    }
    
    @IBAction func pressTabBar(_ sender: UIButton) {
        //update image for tab bar
        sender.isSelected = sender.state == .highlighted ? true : false
        setTabBarBackground(sender)
    }
    
    func setTabBarBackground(_ sender: UIButton)
    {
        let peopleHighImage = UIImage(named: "peopleButton")
        let addPeopleImage = UIImage(named: "addFriendIcon")
        let addCityImage = UIImage(named: "addCityIcon")
        //Set tab bar background button
        cityPeopleTabButton.setBackgroundImage(peopleHighImage, for: .selected)
        
        //        Default tab is city view, when button is selected people view is shown
        if(sender.isSelected){
            showPeopleView = true
            if(self.manualTabControl)
            {
                sender.isHighlighted = false
                self.manualTabControl = false
            }
            //Set image location and remove background of add button when changing image so that image doesn't stretch
            addButton.setBackgroundImage(nil, for: UIControlState())
            addButton.titleEdgeInsets.top = 8.0
            addButton.titleEdgeInsets.right = 7.0
            addButton.setImage(addPeopleImage, for: UIControlState())
            //Don't display add friend button on old iOS, wasn't working for some reason, check for ios 10 or later
            if #available(iOS 10.0, *) {
                addButton.isEnabled = true
                addButton.isHidden = false
            }
        }else{
            showPeopleView = false
            //            For now the add city button is disabled
            //            addButton.setImage(nil, for: UIControlState())
            //            addButton.setBackgroundImage(addCityImage, for: UIControlState())
            addButton.isHidden = true
            addButton.isEnabled = false
        }
        self.tableView.reloadData()
    }
    //Function retrieves friends and cities and returns when both retrievals are finished
    func retrieveFromFirebase(_ completionClosure: @escaping (_ finished: Bool) -> Void) {
      
        retrieveMyFriends() {(friendStr:[String], friendId:[String]) in
            if(friendStr.count > 0){
                //Keep track of the number of user's friends in firebase each time they are retrieved
                Helpers().numFriendsDefault = NSNumber(value: friendStr.count)
                
                self.myFriends = friendStr
                self.myFriendIds = friendId as [NSString]
                //Combine the Friends names and IDs into a tuple so I can sort by last name
                // use zip to combine the two arrays and sort that based on the first
                //$0.0 refers to the the first value of the first tuple, and $0.1 refers to the first value of the 2nd tupe, so each tuple is a [Friend Name, FriendID] so I'm looking at the first & second item for each iteration and only considering the unAddedFriend name for sorting
                let combinedFriends = zip(self.myFriends, self.myFriendIds).sorted {$0.0.lastName() < $1.0.lastName()}
                //Then extract all of the 1st items in each tuple (Friends names)
                self.myFriends = combinedFriends.map{$0.0}
                //Then extract all of the 2st items in each tuple (unAddedFriends ids)
                self.myFriendIds = combinedFriends.map{$0.1}

                
                //Once I have a list of all friends, get all of their cities using their facebook id
                self.cityHandler = Helpers().retrieveFriendCity(cityRef: self.cityRef, friendsList: friendId) {(completedArr:[String]) in
                    self.friendCities = completedArr
                    if(self.friendCities.count > 0){
                        self.friendCities.sort(by: <)
                    }else{
                        self.displayNoDataAlert(missingData: "city")
                    }
                    completionClosure(true)
                }
            }else{  //User has no friends
                self.displayNoDataAlert(missingData: "friends")  //Display notification to the user that they have no friends
                completionClosure(true)
            }
        }
    }
    

    //retrieve a list of all the user's friends
    func retrieveMyFriends(_ completionClosure: @escaping (_ friendStr: [String], _ friendId:[String]) -> Void) {

        //Retrieve a list of the user's current check in list
        self.friendHandler = friendsRef.queryOrdered(byChild: "displayName1").observe(.value, with: { snapshot in
            //Have to define var's here cause new firebase triggers will only trigger the closure and the previous contents of these variables would have been preserved
            var localFriendsArr = [String]()
            var localFriendsId = [String]()
            guard let nsSnapDict = snapshot.value as? NSDictionary else{
                //If snapshot fails just call completion closure with empty arrays
                completionClosure(localFriendsArr, localFriendsId)
                return
            }
//            each entry in nsSnapDict is a [friendID : ["display Name": name]] dict
            //currID = friendsId displayName = [key = "displayName1", value = friend's name]
        for ( currID , displayName ) in nsSnapDict{
                //Cast displayName dict [key = "displayName1", value = friend's name] or quit before storing to name or Id array
                guard let nameDict = displayName as? NSDictionary else{
                    completionClosure(localFriendsArr, localFriendsId)
                    return
                }
                if let fId = currID as? String, let name = nameDict["displayName1"] as? String{
                    localFriendsId.append(fId)  //Append curr friend ID
                    localFriendsArr.append(name)
                }
            }

            completionClosure(localFriendsArr, localFriendsId)
        })
    }
    
    //Functions moved to Helpers() so they were also accessible from Profile screen
    #if false
    //Retrieve a list of all of the cities the user's friends have
    func retrieveFriendCity(friendsList: [String], completionClosure: @escaping (_ completedArr: [String]) -> Void) {
        var localCityArr = [String]()
        var loopCount = 0
        //Loop over all the user's friends to get a list of their cities
        for friendId in friendsList{
            //Query ordered by child will loop each place in the cityRef
              self.cityHandler = cityRef.child(friendId).queryOrdered(byChild: "city").observe( .value, with: { snapshot in
                
                for child in (snapshot.children) {    //each child is either city, cat or place ID
                    let rootNode = child as! FIRDataSnapshot
                    
                    //force downcast only works if root node has children, otherwise value will only be a string
                    //If nodeDict can't be unwrapped then the key value pair is the google place id
                    if let nodeDict = rootNode.value as? NSDictionary{
                        if let city = nodeDict["city"] as? NSDictionary {
                            //value of city key is a dictionary of [ cityName : "true" ]
                            for (key, _ ) in city{
                                if(!localCityArr.contains(key as! String)){
                                    localCityArr.append(key as! String)
                                }
                            }
                        }
                    }else{  //Enters this block when a place ID is found
//                            print("got a place ID for \(rootNode.value)")
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
#endif
    
    func displayNoDataAlert(missingData: String){
        //FOr this function to be called there are no friends, or the friends have no check ins
        var msg = "", title = ""
        if(missingData == "friends"){
            title = "Invite Friends"
            msg = "Invite some of your Facebook friends to use Check In Out so you can find places to Check Out"
        }else{  //The user's friends have no check ins
            title = "Friends without benefits"
            msg = "None of your friends have checked in anywhere. Encoruage them to Check In so that you can Check Out!"
        }
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(CancelAction)
        self.present(alert, animated: true, completion: nil)
        
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
            return self.friendCities.count
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
        cell.tableCellValue.font = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.light)
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
        }else if(segue.identifier == "unwindFromCheckOut"){   //Remove observers when popping VC
            if let friendHandle = self.friendHandler {
                self.friendsRef.removeObserver(withHandle: friendHandle)
            }
            if let cityHandle = self.cityHandler{
                self.cityRef.removeObserver(withHandle: cityHandle)
            }
        }
        
    }
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromMyList(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromAddFriends(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    
    /*override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue? {
        let segueLeft:SegueFromLeft = SegueFromLeft(identifier: identifier, source: fromViewController, destination: toViewController)
    
        return segueLeft
            SegueFromLeft(identifier: identifier, source: fromViewController, destination: toViewController)
    }*/
    
    //Set status bar to same color as background
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
}
