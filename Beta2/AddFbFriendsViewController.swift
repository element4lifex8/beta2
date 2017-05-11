//
//  AddFbFriendsViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 1/23/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit
import FirebaseDatabase



extension String{
    func lastName() -> String{
        var lastName: String = ""
        //Find from end of string the location of the space that prcedes the last name
        if let rangeOfSpace = self.range(of: " ", options: .backwards) {
            //Convert the range returned by the space to an index and return the string from the space to end of dispay name
            lastName = self.substring(from: rangeOfSpace.upperBound)
        }
        return lastName
    }
}

class AddFbFriendsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITabBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    //Tab bar container view used to add top/bottom seperator
    @IBOutlet var tabBarContainerView: UIView!
    @IBOutlet var tabBar: UITabBar!
    
    //Keep track of the last tab selected so it can be relected after the share icon is selected
    var lastTabSelected: UITabBarItem?
      var availableTabSelected = false //Keep track of the tab bar thats selected to determine what to display in tableView
    
    var selectedFBfriends = [FbookUserInfo]()
    var facebookAuthFriends = [String](), facebookAuthIds = [String]()
    var facebookTaggableFriends = [String](), facebooktaggableIds = [String]()
    var numUnAddedFriends = 0   //number of friends who are displayed on the available tab so I can notify the user if none are available
    var unAddedFriends = [String]()   //Compile a list of auth users that are not friends followed in the app
    var facebookFriendMaster = [String]()
    var myFriends:[String] = []
    var myFriendIds: [String] = []    //list of Facebook Id's with matching index to myFriends array
    var selectedAccessButt: [Int] = []     //List of users who are selected to add as friends
    var selectedIds: [String] = []     //List of users id's who are selected to add as friends
    var friendsRef: FIRDatabaseReference!
    //Dispatch group used to sync firebase and facebook api call
    var myGroup = DispatchGroup()
    let currUserDefaultKey = "FBloginVC.currUser"
   
    var currUser = Helpers().currUser


//    @IBAction func skipProfileSetup(_ sender: UIButton)
//    {
//        performSegue(withIdentifier: "segueToHome", sender: nil)
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Add submit button view
        let shadowX: CGFloat = 2.0, shadowY:CGFloat = 1.0
        let buttViewHeight:CGFloat = 50, buttViewWidth:CGFloat = 150
        let buttonView = UIView(frame: CGRect(x: 0, y: 0, width: buttViewWidth, height: buttViewHeight))
        buttonView.backgroundColor = UIColor.clear
        //allow autolayout constrainsts to be set on buttonView
        buttonView.translatesAutoresizingMaskIntoConstraints = false
        
        //Put button view on top of table
        buttonView.layer.zPosition = tableView.layer.zPosition + 1
        view.addSubview(buttonView)
        
        //Create submit button to add to container view
        let buttonWidth:CGFloat = 150, buttonHeight:CGFloat = 50
        let subButt = UIButton(frame: CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight))
        subButt.backgroundColor = UIColor.white
        subButt.layer.borderWidth = 2.0
        subButt.layer.borderColor = UIColor.black.cgColor
        subButt.setTitle("Submit", for: UIControlState())
        subButt.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 36)
        subButt.setTitleColor(UIColor.black, for: UIControlState())
        //add target actions for button tap
        subButt.addTarget(self, action: #selector(AddPeopleViewCntroller.submitSelected(_:)), for: .touchUpInside)
        //Add shadow to button
        subButt.layer.shadowOpacity = 0.7
        subButt.layer.shadowOffset = CGSize(width: shadowX, height: shadowY)
        //Radius of 1 only adds shadow to bottom and right
        subButt.layer.shadowRadius = 1
        subButt.layer.shadowColor = UIColor.black.cgColor
        buttonView.addSubview(subButt)
        
        //Set Button view width/height constraints so it doesn't default to zero at runtime
        let widthConstraint = buttonView.widthAnchor.constraint(equalToConstant: buttViewWidth)
        let heightConstraint = buttonView.heightAnchor.constraint(equalToConstant: buttViewHeight)
        NSLayoutConstraint.activate([widthConstraint, heightConstraint])
        
        //        Screen default to 400x800 so I can only pin to the left and top to create my constraints
        //From top measure to the bottom of the button and subtract 50 from bottom margin and 50 for button height
        let pinBottom = NSLayoutConstraint(item: buttonView, attribute: .top, relatedBy: .equal, toItem: view , attribute: .top, multiplier: 1.0, constant: view.bounds.height - 50 - buttViewHeight)
        //Pin left of button to center of screen minus the button width
        let pinLeft = NSLayoutConstraint(item: buttonView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: (view.bounds.width/2) - (buttViewWidth/2))
        view.addConstraint(pinBottom)
        view.addConstraint(pinLeft)
     
        //        Tab bar configuration
        //Create top and bottom border of tab bar
        //        let px = 1 / UIScreen.main.scale    //determinte 1 pixel size instead of using 1 point
        let barLine = 2.0
        let frame = CGRect(x: 0, y: 0, width: Double(self.tabBar.frame.size.width), height: barLine)
        let topLine: UIView = UIView(frame: frame)
        let bottomframe = CGRect(x: 0, y: Double(self.tabBar.frame.size.height) - barLine, width: Double(tableView.frame.size.width), height: barLine)
        let bottomLine: UIView = UIView(frame: bottomframe)
        topLine.backgroundColor = UIColor.black
        bottomLine.backgroundColor = UIColor.black
        self.tabBarContainerView.addSubview(topLine)
        self.tabBarContainerView.addSubview(bottomLine)
        
        // remove default border at left and right edges of screen
        //Apple has a 2px border between the left and right sides of the tab bar and the tab bar items.
        
        //make the tab bar 4px wider, and then offset it so the border on the left falls just outside of the view, thus the border on the right will also fall outside of the view.
        //        self.tabBar.frame.size.width = self.view.frame.width + 4
        //        self.tabBar.frame.origin.x = -2
        
        let numberOfItems = CGFloat((self.tabBar.items!.count))
        //Subtract the over hang that removes the default borders
        let itemWidth = /*floor*/((self.tabBar.frame.size.width) / numberOfItems)
        let tabBarItemSize = CGSize(width: itemWidth,
                                    height: (self.tabBar.frame.height))
        
        // this is the separator width.  0.5px matches the line at the top of the tab bar
        let separatorWidth: CGFloat = 2
        //Add seperator bars between each tab
        // iterate through the items in the Tab Bar, except the last one
        for i in 0 ... Int(numberOfItems) {
            // make a new separator at the end of each tab bar item
            //Conditional assignment so first shows up full size instead of shifting 1pt left off the screen, the last shifts left by 2 to display entirely on screen, and the rest center between each item
            var xVal: CGFloat
            switch(i){
            case(0):
                xVal = itemWidth * CGFloat(i)
            case (Int(numberOfItems)):
                xVal = itemWidth * CGFloat(i) - CGFloat(separatorWidth)
                break
            default:
                xVal = itemWidth * CGFloat(i) - CGFloat(separatorWidth / 2)
                break
            }
            
            let separator = UIView(frame: CGRect(x: xVal, y: 0, width: CGFloat(separatorWidth), height: self.tabBar.frame.size.height))
            
            // set the color to light gray (default line color for tab bar)
            separator.backgroundColor = UIColor.black
            
            self.tabBar.addSubview(separator)
        }
        //To Do : iphone 5 and 6E has 1pt gap between each of the middle seperators when the middle tab item is selected since the screen is not seperable by 3 (120pt)
        //When a button with end caps is resized, the resizing occurs only in the middle of the button, in the region between the end caps.
        tabBar.selectionIndicatorImage
            = UIImage.imageWithColor(color: .white,
                                     size: tabBarItemSize).resizableImage(withCapInsets: .zero)
    }
    
    //Set tab bar text settings in awakeFromNib otherwise they won't change the font size
    //apperance() is global so this will change every instance of UIBarItem
    override func awakeFromNib() {
        super.awakeFromNib()
        //
        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir-Light", size: 24)!, NSForegroundColorAttributeName : UIColor.white], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir-Light", size: 24)!, NSForegroundColorAttributeName : UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)], for: .selected)
    }


    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.dataSource=self
        self.tableView.delegate=self
        self.tabBar.delegate = self
        //Async queue for synchronization
        let queue = DispatchQueue(label: "com.checkinoutlists.checkinout", attributes: .concurrent, target: .main)
        
        //remove left padding from tableview seperators
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        //        tableView.registerClass(TestTableViewCell.self,forCellReuseIdentifier: "dataCell")
        self.tableView.backgroundColor=UIColor.clear
        //Create top cell separator for 1st cell
        let px = 1 / UIScreen.main.scale
        let frame = CGRect(x: view.frame.width/2, y: view.frame.height/2, width: self.tableView.frame.size.width, height: px)
        let line: UIView = UIView(frame: frame)
        self.tableView.tableHeaderView = line
        line.backgroundColor = self.tableView.separatorColor
        
        //Tab bar customization
        
        //        (AddPeopleViewCntroller as! UIViewController).extendedLayoutIncludesOpaqueBars = true;
        
        //Hide seperator bar between top and bottom views
        //        self.tabBar.setValue(true, forKey: "_hidesShadow")
        //        self.tabBar.shadowImage = UIImage()
        
        
        //        self.tabBar.barTintColor = UIColor(red: 0x40, green: 0x40 /*(64/255)*/, blue: 0x40 	, alpha: 1)
        //        self.tabBar.isTranslucent = false
        //Change selected tint color of tab bar image item image when they are selected (text selection font settings configured in awakeFromNib)
        self.tabBar.tintColor = UIColor(red: (64/255), green: (64/255), blue: (64/255), alpha: 1)
        //Set background image
        //        self.tabBar.backgroundImage = UIImage()
        for i in  0 ..< Int(self.tabBar.items!.count){
            switch(i){
            case 0:
                //Set the title
                self.tabBar.items?[i].title = "All"
                //Default this first item to be selected
                let myItem = self.tabBar.items?[i]
                //Select the first item by default
                //                self.tabBar.selectedItem = myItem
                //                self.availableTabSelected = false   //Show all friends, not just availble Auth Friends
                //                self.lastTabSelected = myItem   //Keep track so it can be reselected after the user selects the share button
                //Center the text by shifting up by 6 pt
                self.tabBar.items?[i].titlePositionAdjustment = UIOffsetMake(0, -6)
                break;
            case 1:
                self.tabBar.items?[i].title = "Available"
                self.tabBar.items?[i].titlePositionAdjustment = UIOffsetMake(0, -6)
                let myItem = self.tabBar.items?[i]
                self.tabBar.selectedItem = myItem
                self.availableTabSelected = true   //Show just availble Auth Friends
                self.lastTabSelected = myItem   //Keep track so it can be reselected after the user selects the share button
                self.availableTabSelected = true
                break;
            case 2:
                //3rd tab item has white default and grey selected image added from storyboard
                //Center Image on 3rd tab bar item, Subtract Insets from bottom as well to preserve image size
                self.tabBar.items?[i].image = UIImage(named: "whiteShareIcon")
                self.tabBar.items?[i].selectedImage = UIImage(named: "shareIcon")
                self.tabBar.items?[i].imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
            default:    //3rd item is just the picture and no title
                break;
            }
            
        }
        //Set share image for last tab bar item
        //        self.shareTabItem.image = UIImage(named: "shareIcon")?.withRenderingMode(.alwaysOriginal)
        //Try to center the share icon
        //Center Image on 3rd tab bar item, Subtract Insets from bottom as well to preserve image size
        //        self.shareTabItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)

        
        //        friendsRef = Firebase(url:"https://check-inout.firebaseio.com/users/\(self.currUser)/friends")
        friendsRef = FIRDatabase.database().reference().child("users/\(self.currUser)/friends")
        
        //Create container view then loading for activity indicator to prevent background from overshadowing white color
        let loadingView: UIView = UIView()
        
        loadingView.frame = CGRect(x: 0,y: 0,width: 80,height: 80)
        loadingView.center = view.center
        loadingView.backgroundColor = UIColor(red: 0x44/255, green: 0x44/255, blue: 0x44/255, alpha: 0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10

        
        //Start activity indicator while making Firebase request
        let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50,  height: 50)) as UIActivityIndicatorView
        activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2,y: loadingView.frame.size.height / 2);
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.hidesWhenStopped = true
        
        loadingView.addSubview(activityIndicator)
        view.addSubview(loadingView)
        activityIndicator.startAnimating()
        
        //Had to create the queue and add the async closure because I was getting EXC_BAD_INSTRUCTION when calling myGroup.leave otherwise
        queue.async(group: myGroup) {
            self.myGroup.enter()
            self.sortFacebookFriends(){(finished: Bool) in
                self.facebookTaggableFriends.sort(by: {$0.lastName() < $1.lastName()})
                self.myGroup.leave()
            }
            
            //Get list of the user's current friends so they can't add them again
            self.myGroup.enter()
            self.retrieveMyFriends() {(friendStr:[String], friendId:[String]) in
                self.myGroup.leave()
                self.myFriends = friendStr
                self.myFriendIds = friendId
                
            }
        }
        
        //Fire async call once facebook api, and firebase calls have finish
        myGroup.notify(queue: DispatchQueue.main) {
            //Count the number of auth friends that aren't friends of the current user
            //map will check if each element in the facebookAuthFriends is contained in the myFriends array and only return 1 if the facebookAuthFriend is not already a friend
            //reduce Initial value of 0 then add all non friends for a total count of what to display
            self.numUnAddedFriends = self.facebookAuthFriends.map{return self.myFriends.contains($0) ? 0 : 1}.reduce(0, +)
            //create sub array of auth users that I haven't started following in the app
            //Remove from the sub array of unAddedFriends if the user is already in Firebase as my friend
            self.unAddedFriends = self.facebookAuthFriends.filter({!self.myFriends.contains($0)})
            activityIndicator.stopAnimating()
            loadingView.removeFromSuperview()
            //Check if no friends are going to appear in the Available screen and notify the user why that is
            if(self.numUnAddedFriends == 0){
                self.displayNoFriendsAlert()
            }
            self.tableView.reloadData()
        }


    }
        //Previously part of viewDidLoad
//        Sample add friends onboarding page to Retrieve auth friends
//        let request = FBSDKGraphRequest(graphPath:"/me/friends", parameters: nil) //["fields" : "email" : "name"]);
//        
//        request?.start( completionHandler: { (connection, result, error) -> Void in
//                if error == nil
//                {
//                    let resultdict = result as! NSDictionary
//                    let data : NSArray = resultdict.object(forKey: "data") as! NSArray
//                    print("data \(data)")
//                    for i in 0..<data.count
//                    {
//                        let valueDict : NSDictionary = data[i] as! NSDictionary
//                        let id = valueDict.object(forKey: "id") as! String
//                        print("the id value is \(id)")
//                        let fbFriendName = valueDict.object(forKey: "name") as! String
//                        print ("name \(fbFriendName)")
//                        self.authList.append(fbFriendName)
//                        self.friendsText.text = "\(self.authList)"
//                    }
//                    //print a facebook default photo of some randomly selected fried from taggable friends
//                    let url = URL(string: "https://scontent.xx.fbcdn.net/hprofile-xtp1/v/t1.0-1/p50x50/12208701_10107495141218734_1003556140154763994_n.jpg?oh=46a32f1783c508f8eb0ff2be33b5c4cb&oe=5700219A")
//                    let imgdata = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check
//                    self.friendImage.contentMode = .scaleAspectFill

                    //self.friendImage.image = UIImage(data: imgdata!)
                    
                    /*udemy example not showing image when using same url var
                let imgdata = NSURLSession.sharedSession().dataTaskWithURL(url!)
                {
                //urldata contains the data that comes back when the urldata is loaded
                (urldata, response, error) -> Void in
                if error != nil
                {
                print (error)
                }
                else
                {
                if let fbImage = UIImage(data: urldata!)
                {
                self.friendImage.image = fbImage
                }
                }
                self.friendImage.contentMode = .ScaleAspectFill
                }*/

//                }
//                else
//                {
//                    print("Error Getting Friends \(error)");
//                }
//        })
        //only print 5 of the non-authorized friends to not overrun the buffer
//        let unAuthrequest = FBSDKGraphRequest(graphPath:"/me/taggable_friends?limit=5", parameters: nil) //["fields" : "email" : "name"]);
//
//        unAuthrequest?.start( completionHandler: { (connection, result, error ) -> Void in
//                if error == nil
//                {
//                    //print friend boken
//                    let resultdict = result as! NSDictionary
//                    let data : NSArray = resultdict.object(forKey: "data") as! NSArray
//                    print("data \(data)")
//                    for i in 0..<data.count
//                    {
//                        let valueDict : NSDictionary = data[i] as! NSDictionary
//                        let fbFriendName = valueDict.object(forKey: "name") as! String
//                        self.unAuthList.append(fbFriendName)
//                        self.unAuthFriends.text = "\(self.unAuthList)"
//                    }
//                }
//                else
//                {
//                    print("Error Getting Friends \(error)");
//                }
//        })


    func sortFacebookFriends(_ completionClosure: @escaping (_ finished: Bool) -> Void){
        var finishedAuth = false, finishedUnauth = false
        retrieveAuthFacebookFriends() {(displayName: [String], taggableId: [String]) in
            self.facebookAuthFriends = displayName
            self.facebookAuthIds = taggableId
            finishedAuth = true
            //Call completion closure only when all friends have been retrieved
            if(finishedAuth && finishedUnauth){
                completionClosure(true)
            }
        }
        
        retrieveUnauthFacebookFriends() {(displayName: [String], unAuthId: [String]) in
            self.facebookTaggableFriends = displayName
            self.facebooktaggableIds = unAuthId
            finishedUnauth = true
            //Call completion closure only when all friends have been retrieved
            if(finishedAuth && finishedUnauth){
                completionClosure(true)
            }
        }
    }
    
    //Retrieve friends who have not authorized CIO
    func retrieveUnauthFacebookFriends(_ completionClosure: @escaping (_ displayName: [String], _ taggableId: [String]) -> Void){
        //Taggable friends just provides a reference list of friends that can be tagged or mentioned in stories published to Facebook
        let unAuthrequest = FBSDKGraphRequest(graphPath:"/me/taggable_friends?limit=5000", parameters: ["fields" : "name"]);
        var unAuthFriends = [String]()
        var unAuthId = [String]()
        var friendFailed = false
        unAuthrequest?.start(completionHandler: { (connection, result, error) -> Void in
            if error == nil{

                let resultdict = result as! NSDictionary
                let data : NSArray = resultdict.object(forKey: "data") as! NSArray
                for i in 0..<data.count{
                    let valueDict : NSDictionary = data[i] as! NSDictionary
                    if let fbFriendName = valueDict.object(forKey: "name") as? String{
                        unAuthFriends.append(fbFriendName)
                    }
                    else{
                        friendFailed = true
                    }
                }
                if(friendFailed){
                    Helpers().myPrint(text: "Error unwrapping at least of the user's FB friends")
                }
            }
            else{
                Helpers().myPrint(text: "Error Getting Friends \(error)");
            }
            
            completionClosure(unAuthFriends, unAuthId)
        })
    }
    
    
    
    func retrieveAuthFacebookFriends(_ completionClosure: @escaping (_ displayName: [String], _ friendId: [String]) -> Void){
        //Create request to retrieve friends who have authorized CIO
        let request = FBSDKGraphRequest(graphPath:"/me/friends", parameters: ["fields" : "id, name"]);
        var authFriends = [String]()
        var authId = [String]()
        
        request?.start(completionHandler: { (connection, result, error) -> Void in
            if error == nil
            {
                //Result is cast to an NSDict consiting of [id: value, name: value] for auth friends
                let resultdict = result as! NSDictionary
                //prints out auth friends
                //print("Friends \(resultdict)")
                let data : NSArray = resultdict.object(forKey: "data") as! NSArray
                //                print("data \(data)")
                //extract dict entries id & name as string for each authorized friend
                for i in 0..<data.count
                {
                    let valueDict : NSDictionary = data[i] as! NSDictionary
                    if let id = valueDict.object(forKey: "id"){
                        authId.append(id as! String)
                        //                        print("the id value is \(id)")
                    }
                    if let fbFriendName = valueDict.object(forKey: "name"){
                        //                    print ("name \(fbFriendName)")
                        authFriends.append(fbFriendName  as! String)
                    }
                }
            }
            completionClosure(authFriends, authId)
        })
    }
    
    //retrieve a list of all the user's friends
    func retrieveMyFriends(_ completionClosure: @escaping (_ friendStr: [String], _ friendId:[String]) -> Void) {
        var localFriendsArr = [String]()
        var localFriendsId = [String]()
        //Retrieve a list of the user's current check in list
        friendsRef.queryOrdered(byChild: "displayName1").observeSingleEvent(of: .value, with: { snapshot in
            for child in (snapshot.children) {    //each child should be a root node named by the users friend ID
                let rootNode = child as! FIRDataSnapshot
                let nodeDict = rootNode.value as! NSDictionary
                for ( _ , value ) in nodeDict{
                    localFriendsArr.append((value as? String ?? "no user")!)
//            if let currFriend = snapshot.value as? NSDictionary{
//                localFriendsArr.append((currFriend["displayName1"] as? String ?? "Default Name")!)
//                localFriendsId.append((snapshot.key))
//            }
                }
            }
            completionClosure(localFriendsArr, localFriendsId)
        })
    }
    
    func displayNoFriendsAlert(){
        //FOr this function to be called there are no friends in the availabe screen, that is because there are no auth users or there are no new user to follow
        var msg = "", title = ""
        if(self.facebookAuthFriends.count == 0){
            title = "Invite Friends"
            msg = "Invite some of your Facebook friends to use Check In Out so that they will appear here as \"Available\" and then you can find places to Check Out"
        }else{  //The user has already added all available friends
            title = "Invite More Friends"
            msg = "You have already befriend all of your \"Available\" Facebook friends. Invite more friends to Check In Out and then they will appear here as \"Available\""
        }
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(CancelAction)
        self.present(alert, animated: true, completion: nil)
        
    }

    @IBAction func submitSelected(_ sender: UIButton) {
        //         let userChecked = Firebase(url:"https://check-inout.firebaseio.com/users/\(self.currUser)/friends")
        var invite = false
        let userChecked = FIRDatabase.database().reference().child("users/\(self.currUser)/friends")
        for friend in selectedFBfriends{
            if(friend.auth)!{
                //Add id of curr friend with their display name stored underneath to firebase
                let friendInfo = ["displayName1" : friend.displayName!]
                userChecked.child(byAppendingPath: friend.id!).setValue(friendInfo)
            }else{
                Helpers().myPrint(text: "send email of Facebook Message to invite \(friend.displayName) to CIO")
//                invite = true
            }
        }
        
    //Triggering default FB sharing screen is failing unwrapping nil for some reason
        if(invite){
            let inviteDialog:FBSDKAppInviteDialog = FBSDKAppInviteDialog()
            if(inviteDialog.canShow()){
                let appLinkUrl:NSURL = NSURL(string: "https://fb.me/1420072051347427")!
                let previewImageUrl:NSURL = NSURL(string: "http://yourwebpage.com/preview-image.png")!
                
                let inviteContent:FBSDKAppInviteContent = FBSDKAppInviteContent()
                inviteContent.appLinkURL = appLinkUrl as URL!
                inviteContent.appInvitePreviewImageURL = previewImageUrl as URL!
                
                inviteDialog.content = inviteContent
                inviteDialog.delegate = self
                inviteDialog.show()
            }
            
        }
        performSegue(withIdentifier: "unwindFromFbLoginIdentifier", sender: self)
    }
    
    
    @IBAction func accessoryButtonTapped(_ sender: UIButton) {
        var friendName: String = ""
        if(self.availableTabSelected){
            friendName = facebookAuthFriends[sender.tag]
        }else{
            friendName = facebookTaggableFriends[sender.tag]
        }
        var FBfriend: FbookUserInfo
        //check or uncheck selected friends
        sender.isSelected = sender.state == .highlighted ? true : false
        if(sender.isSelected){
            //Keep track of accessory buttons that are checked so they are reselected when scrolled back into view
            selectedAccessButt.append(sender.tag)
            //Add authorized friends to add to friends list, and create list of unauth friends to notify about the app.
            //friend index will only exist if friend is an auth user
            if let friendIndex = facebookAuthFriends.index(of: friendName){
                FBfriend = FbookUserInfo(name: friendName, id: facebookAuthIds[friendIndex])
            }else{
                FBfriend = FbookUserInfo(name: friendName)
            }
            selectedFBfriends.append(FBfriend)
        }else{
            //Keep track of accessory buttons that are checked
            if let index = selectedAccessButt.index(of: sender.tag){
                selectedAccessButt.remove(at: index)
            }
            //wish I understood these closures, came from here: http://stackoverflow.com/questions/34081580/array-of-any-and-contains
            if let fbIndex = selectedFBfriends.index(where: {$0.displayName == friendName} )    {
                selectedFBfriends.remove(at: fbIndex)
            }
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
        if(self.availableTabSelected)
        {
            return self.unAddedFriends.count
        }else{
            return facebookTaggableFriends.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var showAccessoryButt = true  //Track if the user can be added and create accessory button if so
        let checkImage = UIImage(named: "tableAccessoryCheck")
        let cellIdentifier = "friendCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! FriendTableViewCell   //downcast to my cell class type
        //display table data from taggable friends which includes auth and unauth friends
        if(self.availableTabSelected){
            cell.nameLabel.text = "\(facebookAuthFriends[indexPath.row])"
        }else{
            cell.nameLabel.text = "\(facebookTaggableFriends[indexPath.row])"
        }
        

        cell.nameLabel.textColor = UIColor.black
        cell.nameLabel.font = UIFont(name: "Avenir-Light", size: 18)
        //Set available tag
        //If displaying all friends need to check the facebookTaggable friends, otherwise we can index directly into facebookAutFriends
        if(self.availableTabSelected || facebookAuthFriends.contains(facebookTaggableFriends[indexPath.row]))
        {
            cell.isAvailableLabel.text = "Available"
            cell.isAvailableLabel.font = UIFont(name: "Avenir-Light", size: 12)
        }
            //If we're in the all tab and the user is an AuthFriend they could either be "trusted" or "Available"
        else if(facebookAuthFriends.contains(facebookTaggableFriends[indexPath.row])){
            if(self.myFriends.contains(facebookTaggableFriends[indexPath.row])){    //True is the firebase friends list matches the cell
                cell.isAvailableLabel.text = "Trusted"
                cell.isAvailableLabel.font = UIFont(name: "Avenir-LightOblique", size: 12)
                showAccessoryButt = false   //Don't allow the user to try to re-add a friend
            }else{
                cell.isAvailableLabel.text = "Available"
                cell.isAvailableLabel.font = UIFont(name: "Avenir-Light", size: 12)
            }
        }
        else{
            cell.isAvailableLabel.text = "Invite to Check-In-Out"
            cell.isAvailableLabel.font = UIFont(name: "Avenir-Light", size: 12)
            showAccessoryButt = false
        }
        cell.isAvailableLabel.textColor = UIColor.black
        
        
        
        //Add custom accessory view for check button
        let accessoryButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        accessoryButton.layer.cornerRadius = 0.5 * accessoryButton.bounds.size.width
        accessoryButton.backgroundColor = UIColor.clear
        accessoryButton.layer.borderWidth = 2.0
        accessoryButton.layer.borderColor = UIColor.black.cgColor
        accessoryButton.setImage(checkImage, for: .selected)
        //        accessoryButton.contentMode = .ScaleAspectFill
        accessoryButton.tag = indexPath.row //store row index of selected button
        accessoryButton.addTarget(self, action: #selector(AddPeopleViewCntroller.accessoryButtonTapped(_:)), for: .touchUpInside)
        
        cell.accessoryView = accessoryButton as UIView
        
        //Reselect accessory button when scrolled back into view
        if(selectedAccessButt.contains(indexPath.item)){
            accessoryButton.isSelected = true
        }
        if(!showAccessoryButt){  //Don't add accessory button from unAuth friends
            cell.accessoryView?.isHidden = true
        }
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }
    
    //Tab bar delegate for selecting buttons
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        switch(item){
        case (self.tabBar.items?[0])!:
            self.lastTabSelected = self.tabBar.items?[0]
            self.availableTabSelected = false
            self.tableView.reloadData()
            break;
        case (self.tabBar.items?[1])!:
            self.lastTabSelected = self.tabBar.items?[1]
            self.availableTabSelected = true
            self.tableView.reloadData()
            break;
        case (self.tabBar.items?[2])!:
            //Notify the user that sharing is not yet available in beta
            let alert = UIAlertController(title: "We're glad you want to Share!", message: "Sharing the Check In Out app is not supported for testing, but once the app is in the app store we'd love for you to share it!", preferredStyle: .alert)
            //Exit function if user clicks now and allow them to reconfigure the check in
            let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: { UIAlertAction in
                if let lastTab = self.lastTabSelected {
                    self.tabBar.selectedItem = lastTab
                }
            })
            alert.addAction(CancelAction)
            self.present(alert, animated: true, completion: nil)
            //Reselect the previous tab when the last tab is selected
            
            break
        default:    //3rd item is just the picture and no title
            break;
        }
        
    }

    

}

//Make your View Controller implement the Facebook App Invite Dialog delegate and add in delegate methods to receive completion handlers:
extension AddFbFriendsViewController: FBSDKAppInviteDialogDelegate{
    
    func appInviteDialog (_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable : Any]!) {
        let resultObject = NSDictionary(dictionary: results)
        
        if let didCancel = resultObject.value(forKey: "completionGesture")
        {
            if (didCancel as AnyObject).caseInsensitiveCompare("Cancel") == ComparisonResult.orderedSame
            {
                Helpers().myPrint(text: "User Canceled invitation dialog")
            } } }
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {
        Helpers().myPrint(text: "Error tool place in appInviteDialog \(error)")
    }
    
}
