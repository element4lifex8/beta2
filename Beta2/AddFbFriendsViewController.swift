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

class AddFbFriendsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITabBarDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    //Tab bar container view used to add top/bottom seperator
    @IBOutlet var tabBarContainerView: UIView!
    @IBOutlet var tabBar: UITabBar!
    
    @IBOutlet var headerView: UIImageView!  //Get reference to header view so I can add gester recognizer to dismiss keyboard

    @IBOutlet var dummyTextBox: UITextField!    //Used only to become first responder and show keyboard
    //items created for accessory input view
    var accCodeView = UIView()
    var accTextField = UITextField()
    //Keep track of the last tab selected so it can be relected after the share icon is selected
    var lastTabSelected: UITabBarItem?
    var availableTabSelected = false //Keep track of the tab bar thats selected to determine what to display in tableView
    //Keep track of the currently active text field
    var activeTextField: UITextField? = nil
    //View to cover table when keyboard with accessory input view appears
    var tableCover = UIView()
    var selectedFBfriends = [FbookUserInfo]()
    var facebookAuthFriends = [String](), facebookAuthIds = [String]()
    var facebookTaggableFriends = [String](), facebooktaggableIds = [String]()
    var numUnAddedFriends = 0   //number of friends who are displayed on the available tab so I can notify the user if none are available
    var unAddedFriends = [String]()   //Compile a list of auth users that are not friends followed in the app
    var foundUserId : String?    //keep record of an email user that was found so he can be distinguished in the list
    var unAddedFriendId = [String]()   //Match the friends that haven't yet been added to their Id
    var facebookFriendMaster = [String]()
    var myFriends:[String] = []
    var myFriendIds: [String] = []    //list of Facebook Id's with matching index to myFriends array
    var selectedAccessButt: [Int] = []     //List of users who are selected to add as friends
    var selectedIds: [String] = []     //List of users id's who are selected to add as friends
    var friendsRef: FIRDatabaseReference!
    var friendHandler: FIRDatabaseHandle?
    //Dispatch group used to sync firebase and facebook api call
    var myGroup = DispatchGroup()
    let currUserDefaultKey = "FBloginVC.currUser"
   
    var currUser = Helpers().currUser
    //Store the current user's login type
    //Instead of creating a pure enum i'll just get the NSInteger version so I don't have to unwrap it
    //var loginType: Helpers.userType = Helpers.userType(rawValue: Helpers().loginType)!
    var loginType = Helpers().loginType
    
    //Keyboard tracking hack, pass variable on whether I am dismissing keyboard for tab button press or other metthod
    var changeTab = false



//    @IBAction func skipProfileSetup(_ sender: UIButton)
//    {
//        performSegue(withIdentifier: "segueToHome", sender: nil)
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //register so that I receive notifications from the keyboard
        registerForKeyboardNotifications()
        
        //Instatiate table cover that will cover the table when the keyboard appears
        self.tableCover = UIView(frame: CGRect(origin: self.tableView.frame.origin, size: self.tableView.frame.size))
        self.tableCover.backgroundColor = .white
        self.tableCover.alpha = 0.75
        //Setup Tap gesture so clicking outside of textbox dismisses keyboard
        let tableGesture = UITapGestureRecognizer(target: self, action: #selector(AddFbFriendsViewController.tapTableCover(_:)))
        //Make sure gesture recognizer is added after the view frame has been created otherwise the event won't be triggered since it won't have a frame to receieve the touch
        self.tableCover.addGestureRecognizer(tableGesture)
        //        self.tableCover.isHidden = true
        //        self.view.addSubview(tableCover)
        
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
        
        //Dummy text box that becomes first responder when search item in tab bar selected
        self.dummyTextBox.delegate = self
        self.accTextField.delegate = self
        
        let accViewHeight = 150
        let accTextHeight = 25
        //Ignore auto layout contraints from storyboard for codeView
        self.accCodeView.translatesAutoresizingMaskIntoConstraints = false
        self.accCodeView = UIView(frame: CGRect(x: 0, y: 0, width: Int(self.view.frame.width), height: accViewHeight))
        self.accCodeView.backgroundColor = .white
        self.accCodeView.layer.borderWidth = 2
        self.accCodeView.layer.borderColor = UIColor.black.cgColor
        
        //Create label and text field to appear in input accessory view
        self.accTextField = UITextField(frame: CGRect(x: 0, y: (accViewHeight / 2) - (accTextHeight / 2) , width: Int(self.view.frame.width), height: accTextHeight))
        self.accTextField.borderStyle = .none
        self.accTextField.textAlignment = .center
        self.accTextField.font = UIFont(name: "Avenir-Light", size: 18)
        self.accTextField.returnKeyType = .search
        //Don't capitalize the user's input of username's and emails
        self.accTextField.autocapitalizationType = .none
        self.accTextField.spellCheckingType = .no
        //Disabling preditive text cause the keyboard to glitch on dismiss and show an overlapped predictive text view and the accessory input view would have to be reactivity and then re-dismissed to properly dismiss the keyboard
        //self.accTextField.autocorrectionType = .no //Disable spell checking
        self.accTextField.keyboardType = .emailAddress  //make it easier to search for email addresses by setting the email keyboard type
        
        //Fake out a delegate since its not getting called for the accessory text box on return button press, adding this target will trigger the event and for some reason will cause the dummyTextField editing did end to get called too which will dismiss the keyboard (cascadging events somehow)
        self.accTextField.addTarget(self, action: #selector(AddPeopleViewCntroller.accessoryEditEnd(_:)), for: .editingDidEndOnExit )
        //Add text box to accessory view
        accCodeView.addSubview(self.accTextField)
        //add to VC for delegate and hide
        //        self.view.addSubview(self.accTextField)
        //        self.accTextField.isHidden = true
        let accLabel = UILabel(frame: CGRect(x: 0, y: 0, width: Int(self.view.frame.width - 30), height: accTextHeight))
        accLabel.text = "Enter your friend's email/username:"
        //Add labelto accessory view
        accCodeView.addSubview(accLabel)
        //Create auto layout constraints for labal
        let topConstraint = NSLayoutConstraint(item: accLabel, attribute: .top, relatedBy: .equal, toItem: accCodeView, attribute: .top, multiplier: 1.0, constant: 31)
        accCodeView.addConstraint(topConstraint)
        
        let centerConstraint = NSLayoutConstraint(item: accLabel, attribute: .centerX, relatedBy: .equal, toItem: accCodeView, attribute: .centerX, multiplier: 1.0, constant: 0)
        accCodeView.addConstraint(centerConstraint)
        
        accLabel.translatesAutoresizingMaskIntoConstraints = false
        
        //Set input accessory view for keyboard that appears when dummyTextBox is active
        self.dummyTextBox.inputAccessoryView = self.accCodeView
        
        //Manage keyboard notifications and dismissal with tap gesture
        
        //Setup Tap gesture so clicking outside of textbox dismisses keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(AddFbFriendsViewController.tapDismiss(_:)))
        //        self.tableCover.isUserInteractionEnabled =
        //        self.tableCover.addGestureRecognizer(tapGesture)
        //Parent view will steal the header view's tap's if I don't bring it to front before adding gesture recognizer
//        self.view.bringSubview(toFront: self.headerView)
        self.headerView.isUserInteractionEnabled = true
        self.headerView.addGestureRecognizer(tapGesture)
        
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
                self.tabBar.items?[i].image = UIImage(named: "Search Icon Light")
                self.tabBar.items?[i].selectedImage = UIImage(named: "Search Icon")
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
            //Only gather and print facebook friends if the user is a facebook user
            if(self.loginType == Helpers.userType.facebook.rawValue){
                self.myGroup.enter()
                self.sortFacebookFriends(){(finished: Bool) in
                    if(finished){   //only "finished" if I was capable of retrieving friends
                        self.facebookTaggableFriends.sort(by: {$0.lastName() < $1.lastName()})
                    }
                    self.myGroup.leave()
                }
            }else{  //Notify the user to search for friend
                self.loginFailMsg(error: "search")
            }
            
            //Get list of the user's current friends so they can't add them again
            self.myGroup.enter()
            self.friendHandler = Helpers().retrieveMyFriends(friendsRef: self.friendsRef) {(friendStr:[String], friendId:[String]) in
                self.myFriends = friendStr
                self.myFriendIds = friendId
                self.myGroup.leave()
                
            }
        }
        
        //Fire async call once facebook api, and firebase calls have finish
        myGroup.notify(queue: DispatchQueue.main) {
            //Only parse available friends if a facebook user
            if(self.loginType == Helpers.userType.facebook.rawValue){
                //Count the number of auth friends that aren't friends of the current user
                //map will check if each element in the facebookAuthFriends is contained in the myFriends array and only return 1 if the facebookAuthFriend is not already a friend
                var authFriendMap = self.facebookAuthFriends.map{return self.myFriends.contains($0) ? 0 : 1}
                //SInce the facebookAuthIds maps directly to facebookAuthFriends, use the indices from the map array indicating the unAdded friends to create an unadded friend id array
                //Useing the enumerated() I create a tuple array of index and friend id that are unAdded
                var authIdEnumTup = self.facebookAuthIds.enumerated().filter({index, value in authFriendMap[index] == 1})
                //Retrieve just the unadded friend ID's from the tuple above (index = $0, values = $1)
                self.unAddedFriendId = authIdEnumTup.map({$1})
                //reduce Initial value of 0 then add all unAdded friends for a total count of what to display
                self.numUnAddedFriends = authFriendMap.reduce(0, +)
                //create sub array of auth users that I haven't started following in the app
                //Remove from the sub array of unAddedFriends if the user is already in Firebase as my friend
                self.unAddedFriends = self.facebookAuthFriends.filter({!self.myFriends.contains($0)})
                
                //Check if no friends are going to appear in the Available screen and notify the user why that is
                if(self.numUnAddedFriends == 0){
                    self.displayNoFriendsAlert()
                }
                    
                //Combine the unaddedFriends name and Id arrays so they can be sorted and still match up
                self.sortUnaddedFriends()
            }
            
            activityIndicator.stopAnimating()
            loadingView.removeFromSuperview()
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

        checkFriendPermiss(){(permission: Bool?) in
            if(permission ?? false){    //Only check backend and facebook for friends if permissions allow, otherwise to-do check for email only friends
                self.retrieveAuthFacebookFriends() {(displayName: [String], taggableId: [String]) in
                    self.facebookAuthFriends = displayName
                    self.facebookAuthIds = taggableId
                    finishedAuth = true
                    //Call completion closure only when all friends have been retrieved
                    if(finishedAuth && finishedUnauth){
                        completionClosure(true)
                    }
                }
                
                self.retrieveUnauthFacebookFriends() {(displayName: [String], unAuthId: [String]) in
                    self.facebookTaggableFriends = displayName
                    self.facebooktaggableIds = unAuthId
                    finishedUnauth = true
                    //Call completion closure only when all friends have been retrieved
                    if(finishedAuth && finishedUnauth){
                        completionClosure(true)
                    }
                }
            }else{  //friend permission revoked of completion closure returned nil because it failed to obtain friend permissions with FB graph API request
                completionClosure(false)
            }
        }
    }
    
    //Check if facebook friend permission was added and request if it wasn't
    //Returns nil if failed to retrieve friends permissions
    func checkFriendPermiss(_ completionClosure: @escaping (_ frendsAllowed: Bool?) -> Void) {
        //Check permissions to see if I can request friends
        let request = FBSDKGraphRequest(graphPath:"/me/permissions", parameters: ["fields" : "permission, status"]);
        let permissGroup = DispatchGroup()
        var permission:Bool? = nil   //Find out if the user allowed friend permission
        permissGroup.enter()
        request?.start(completionHandler: { (connection, result, error) -> Void in
            if(error != nil){
                Helpers().myPrint(text: "error retrieving permissions")
            }else{
                //Casting to NSDictionary produces Key: data, value: [NSDictionary[permission: name, status: granted/declined]] (value is NSArray of NSDictionary)
                if let resultdict = result as? NSDictionary{
                    //create NSArray of NSDictionaries
                    if let dataVal : NSArray = resultdict.object(forKey: "data") as? NSArray{
                        //Search Facebook permission array for friend permission
                        for i in 0..<dataVal.count{
                            if let valueDict : NSDictionary = dataVal[i] as? NSDictionary{
                                //Check if friend permission is granted or denied
                                if (valueDict["permission"] as? String == Optional("user_friends")){
                                    permission = (valueDict["status"] as? String == Optional("granted")) ? true : false
                                }
                            }
                        }
                    }
                }
            }
            //Ensure completion closure is reached even if the async call or its subsequent casting has errors
//            print("Friends permission: \(permission)")
//            completionClosure(permission)
            permissGroup.leave()
        })
        
        //Once Dispatch group confirms async call is finished
        permissGroup.notify(queue: .main){
            //Look up friends if permission is availabe
            if(permission ?? false){
                completionClosure(permission)
            }else{  //Notify user that friend persmission isn't available
                let alert = UIAlertController(title: "Access to friends list.", message: "Would you like to allow Check In Out to access your Facebook friends so you can see their Check Ins?", preferredStyle: .alert)
                //Exit function if user clicks no and no friends will be printed
                let CancelAction = UIAlertAction(title: "No", style: .cancel, handler: { UIAlertAction in
//                    completionClosure(false)
                    self.performSegue(withIdentifier: "unwindFromFbLoginIdentifier", sender: self)
                })
                //Async call to create button would complete function, so I return after presenting, and if the user wishes I will issue a facebook prompt
                let ConfirmAction = UIAlertAction(title: "Yes", style: .default, handler: { UIAlertAction in
                    //Request facebook authenication for friends list
                    let facebookLogin = FBSDKLoginManager()
                    facebookLogin.logIn(withReadPermissions: ["user_friends"], from: self, handler:{(facebookResult, facebookError) -> Void in
                        if facebookError != nil {
                            Helpers().myPrint(text: "Unable to access friends \(facebookError)")
                            self.loginFailMsg(error: "fail")         //Notify user that login failed
                            completionClosure(false)
                        } else if (facebookResult?.isCancelled)! {
                            Helpers().myPrint(text: "Facebook login was cancelled.")
                            self.loginFailMsg(error: "cancel")         //Notify user that login was canceled
                            completionClosure(false)
                        } else {
                            if !(facebookResult?.grantedPermissions.contains("user_friends") ?? false)
                            {
                                Helpers().myPrint(text: "Facebook friends access denied!")
                                completionClosure(false)
                            }else{
                                Helpers().myPrint(text: "Facebook friends accessed!")
                                completionClosure(true)
                            }
                        }
                    })  //End FB login

                })
                alert.addAction(ConfirmAction)
                alert.addAction(CancelAction)
                //Remove activity monitor so alertview can be presented
                self.present(alert, animated: true, completion: nil)
                

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
            if (error == nil){
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
            else{   //Most likely occured because facebook permissions are denied
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
            if(error != nil){
                Helpers().myPrint(text: "friends not auth")
            }else{
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
#if UNUSED_FUNC
    //Function moved to Helpers()
    //retrieve a list of all the user's friends currently stored in firebase
    func retrieveMyFriends(_ completionClosure: @escaping (_ friendStr: [String], _ friendId:[String]) -> Void) {
        var localFriendsArr = [String]()
        var localFriendsId = [String]()
        //Retrieve a list of the user's current check in list
        friendsRef.queryOrdered(byChild: "displayName1").observeSingleEvent(of: .value, with: { snapshot in
            for child in (snapshot.children) {    //each child should be a root node named by the users friend ID
                let rootNode = child as! FIRDataSnapshot
                let nodeDict = rootNode.value as! NSDictionary
                for ( _ , value ) in nodeDict{
                    localFriendsArr.append((value as? String ?? "Friend Unavailable")!)
//            if let currFriend = snapshot.value as? NSDictionary{
//                localFriendsArr.append((currFriend["displayName1"] as? String ?? "Default Name")!)
//                localFriendsId.append((snapshot.key))
//            }
                }
            }
            completionClosure(localFriendsArr, localFriendsId)
        })
    }
#endif
    
    //check if the current username or email exists in the system and return true if it does
    func findUser(input: String, _ completionClosure: @escaping (_ exists:  Bool) -> Void)
    {
        
        let userRef = FIRDatabase.database().reference(withPath:"users")
        var nameExists = false
        var childString = ""    //either email or username child is searched
        
        //check if the input is formatted as an email address, otherwise search for user name
        //Match any char up to @, match at least 1 char before and after the "."
        if let _ = input.range(of: ".*@.+\\..+", options: .regularExpression) {
            childString = "email"
        }else{
            childString = "username"
        }
        //Query for an username equal to the one that the user attempts to create
        userRef.queryOrdered(byChild: childString).queryEqual(toValue: input).observeSingleEvent(of: .value, with: { snapshot in
            //snapshot is the user id/email of the matching name, each user is unique so only 1 entry should be returned but to only return the items beneath the user id I "loop" over the snapshots child, and if no children return false (username is unique)
            for child in snapshot.children{
                let rootNode = child as! FIRDataSnapshot
                //If we have no children then its most certain that the current username doesn't exist
                //Node dict is the items beneath the user id
                if let nodeDict = rootNode.value as? NSDictionary{
                    //unwrap the username/email if it exists
                    guard let foundName = nodeDict[childString] as? String else {
                        //unwrap fails if user didn't have a username entry, but the query shouldn't have matched if it didn't have one, so...
                        nameExists = false
                        return
                    }
                    //Compare unwrapped item to the user's search input to double verify the query returned correctly
                    if foundName == input{
                        nameExists = true
                        //Unwrap the name and id of the user to add to the tableview's source (unaddedFriends array) otherwise return user not found
                        guard let displayName = nodeDict["displayName1"] as? String, let id = rootNode.key as? String else{
                            nameExists = false
                            return
                        }
                        //Verify the user hasn't already added or searched for this friend before adding to unAdded frineds
                        if(!self.myFriendIds.contains(id) && !self.unAddedFriendId.contains(id) && (id != self.currUser as String)){
                            self.unAddedFriends.append(displayName)
                            self.unAddedFriendId.append(id)
                            //Sort the updated added friends arrays
                            self.sortUnaddedFriends()
                            self.foundUserId = id   //keep trackof the email user that was found so he can appear selected in the table by default
                        }else{
                            //Notify user they can't add this friend again, but still return true, only thing I will do is reload table
                            self.loginFailMsg(error: "currFriend")
                        }
                        
                        //if for some odd reason the query returned an item that didn't match then return false
                    }else{
                        nameExists = false
                    }
                    
                }else{  //If downcast fails then username doesn't exist
                    nameExists = false
                }
            }
            completionClosure(nameExists)
        })
    }
    
    //Failure to request friend permissions alert
    //Present alert when facebook loging canceled/failed
    func loginFailMsg(error: String) -> Void{
        var msgTitle = ""
        var msgBody = ""
        //Unwind for serious errors
        var unwind = false
        switch(error){
        case "cancel":
            msgTitle = "Facebook Friend Persmission"
            msgBody = "It appears you did not allow Check In Out to access your Friend's list. Facebook friends will not be available until you provide permission."
            break
        case "fail":
            msgTitle = "Facebook Login Failed"
            msgBody = "We're sorry, it looks like access to your Facebook friends failed. Please contact tech support: jason@checkinoutlists.com"
            break
        //Technically not a login failure, but really none of these are, just prompt the user to search for friends since they are not a facebook user
        case "search":
            msgTitle = "Search for friends"
            msgBody = "Use the magnifying glass to search for friends by email or username"
            break
        //Technically not a login failure, but notify user if they search from a non-existing user
        case "nonexisting":
            msgTitle = "User not found"
            msgBody = "That Username or email address does not belong to an existing user."
            break
        //Technically not a login failure, but notify user they've already added this friend
        case "currFriend":
            msgTitle = "Existing Friend"
            msgBody = "You've already added this user as your friend. Please add new friends."
            break
        default:
            msgTitle = "Facebook Access Problem"
            msgBody = "Unfortunately your Facebook request wasn't successful. Please conctact jason@checkinoutlists.com for support."
            break
        }
        let alert = UIAlertController(title: msgTitle, message: msgBody, preferredStyle: .alert)
        var CancelAction: UIAlertAction
        if(unwind == true){
            //Async call for uialertview will have already left this function, no handling needed
            CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: { UIAlertAction in
                self.performSegue(withIdentifier: "unwindFromAddFriends", sender: self)
            })
        }else{
            CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        }
        
        alert.addAction(CancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    //When permissions are allowed but not facebook friends exist
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
    
    //combine the unadded friends names and Ids so they can be sorted together and then seperate back out
    func sortUnaddedFriends(){
        //Combine the unAddedFriends names and IDs into a tuple so I can sort by last name
        // use zip to combine the two arrays and sort that based on the first
        //$0.0 refers to the the first value of the first tuple, and $0.1 refers to the first value of the 2nd tupe, so each tuple is a [unAddedFriend Name, unAddedFriendID] so I'm looking at the first & second item for each iteration and only considering the unAddedFriend name for sorting
        let combinedFriends = zip(self.unAddedFriends, self.unAddedFriendId).sorted {$0.0.lastName() < $1.0.lastName()}
        //Then extract all of the 1st items in each tuple (unAddedFriends names)
        self.unAddedFriends = combinedFriends.map{$0.0}
        //Then extract all of the 2st items in each tuple (unAddedFriends ids)
        self.unAddedFriendId = combinedFriends.map{$0.1}
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
            friendName = self.unAddedFriends[sender.tag]
        }else{
            //Data source for selecting buttons in all tab for facebook users
            if(self.loginType == Helpers.userType.facebook.rawValue){
                friendName = facebookTaggableFriends[sender.tag]
            }else{
                friendName = myFriends[sender.tag]
            }
        }
        var FBfriend: FbookUserInfo
        //check or uncheck selected friends, when the user taps a button with a title, the button moves to the highlighted state
        sender.isSelected = sender.state == .highlighted ? true : false
        //When sender is not enabled then I'm creating a button for the user that was returned from the search (and otherwise this function couldn't have been entered unless called directly
        if(!sender.isEnabled){
            sender.isSelected = true
            sender.isEnabled = true
        }

        if(sender.isSelected){
            //Keep track of accessory buttons that are checked so they are reselected when scrolled back into view
            selectedAccessButt.append(sender.tag)
            //Add authorized friends to add to friends list, and create list of unauth friends to notify about the app.
            //friend index will only exist if friend is an auth user
            if let friendIndex = unAddedFriends.index(of: friendName){
                FBfriend = FbookUserInfo(name: friendName, id: self.unAddedFriendId[friendIndex])
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
            //List all facebook friends in available tab if facebook user, otherwise list all friends I've added
            if(self.loginType == Helpers.userType.facebook.rawValue){
                return facebookTaggableFriends.count
            }else{
                return self.myFriends.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var showAccessoryButt = true  //Track if the user can be added and create accessory button if so
        let checkImage = UIImage(named: "tableAccessoryCheck")
        let cellIdentifier = "friendCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! FriendTableViewCell   //downcast to my cell class type
        var existingFriend = false
        var taggableFriendsItem = ""    //Hold a reference to the taggable friends item at the current index if we are a facebook user, otherwise hold empty string
        //display table data from taggable friends which includes auth and unauth friends
        if(self.availableTabSelected){
            cell.nameLabel.text = "\(self.unAddedFriends[indexPath.row])"
        }else{
            //Data source for the "all" tab is either facebook friends or current friends
            if(self.loginType == Helpers.userType.facebook.rawValue){
                cell.nameLabel.text = "\(facebookTaggableFriends[indexPath.row])"
            }else{
                cell.nameLabel.text = "\(self.myFriends[indexPath.row])"
            }
        }
        
        //Only initialize tagable friends item if using the facebook datasource, otherwise would be indexing into empty array
        if(self.loginType == Helpers.userType.facebook.rawValue){
            taggableFriendsItem = facebookTaggableFriends[indexPath.row]
        }

        cell.nameLabel.textColor = UIColor.black
        cell.nameLabel.font = UIFont(name: "Avenir-Light", size: 18)
        cell.nameLabel.lineBreakMode = .byTruncatingTail
        //Set available tag
        //If displaying all friends need to check the facebookTaggable friends, otherwise we can index directly into facebookAutFriends
        if(self.availableTabSelected)
        {
            cell.isAvailableLabel.text = "Available"
            cell.isAvailableLabel.font = UIFont(name: "Avenir-Light", size: 12)
        }
            //If we're in the all tab and the user is an AuthFriend they could either be "trusted" or "Available"
            //If an email user than all friends in the "All tab" are "trusted"
        else if(facebookAuthFriends.contains(taggableFriendsItem) || (self.loginType == Helpers.userType.email.rawValue)){
            if(self.myFriends.contains(taggableFriendsItem) || self.loginType == Helpers.userType.email.rawValue){    //True if the firebase friends list matches the cell || user is an email type
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
        
        //Preselect any user that has appeared due to searching for friends if any unaddedFriends exists
        if(self.unAddedFriends.indices.contains(indexPath.row)){    //First check if any unadded friends exist
            if (self.unAddedFriendId[indexPath.row] == self.foundUserId){
                //Disable button which will be the indicator to the accessoryButtonTapped function to leave highlighted
                accessoryButton.isEnabled = false
                self.accessoryButtonTapped(accessoryButton)
            }
        }
        
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
            //Force all keyboards to resign
            self.view.endEditing(true)
            //If a tab is selected while the keyboard field is present
            resignResponders()
            /*if let activeField = self.activeTextField {
                activeField.resignFirstResponder()
                restoreViewOnKeyboardDissmiss(changeTab: false)
            }*/

            self.lastTabSelected = self.tabBar.items?[0]
            self.availableTabSelected = false
            self.tableView.reloadData()
            break
        case (self.tabBar.items?[1])!:
            //Force all keyboards to resign
            self.view.endEditing(true)
            resignResponders()
            /*if let activeField = self.activeTextField {
                activeField.resignFirstResponder()
                restoreViewOnKeyboardDissmiss(changeTab: false)
            }*/
            self.lastTabSelected = self.tabBar.items?[1]
            self.availableTabSelected = true
            self.tableView.reloadData()
            break
        case (self.tabBar.items?[2])!:
            //Activate dummy textfield to show keyboard that that has accessory input view attached
                self.dummyTextBox.becomeFirstResponder()
            break
        default:    //3rd item is just the picture and no title
            break
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
    
    //    Keyboard helper functions
    //register to receive keyboard notifications
    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    //*method sets the active text box to the field in the accessory input view of the dummy text box which is the view attached to the keyboard */
    func keyboardWasShown(notification: NSNotification){
        //Need to calculate keyboard exact size due to Apple suggestions
        
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        
        modifyViewOnKeyboard()
        
    }
    
    //Sets insets to 0, the defaults
    func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        //Only trigger nullifying active text field and removing frosted view when keyboard is actually hidden
        restoreViewOnKeyboardDissmiss(changeTab: self.changeTab)
        
    }
    
    /* Delegate is only tracking dummy text box
    //Function used to designate active text field
    func textFieldDidBeginEditing(_ textField: UITextField){
        //Keep track of the currently selected text field
        self.activeTextField = textField
    }
    
    
    //Did end editing gets called when I switch the active text field from the dummy text field to the input accessory view so I can't put any code here since it will be called before I even get to editing the input accessory view
    func textFieldDidEndEditing(_ textField: UITextField){
        self.activeTextField = nil
    }
    */
    /*Ununsed since input accessory text box won't conform to delegate
    //Actions to take when user dismisses keyboard: hide keyboard & autocomplete table, add first row text to text box
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        self.activeTextField?.resignFirstResponder()
        //Deselect search bar tab and select last tab
        if let lastTab = self.lastTabSelected {
            self.tabBar.selectedItem = lastTab
            //If last tab was "avilable" tab then update the availableTabSelected which controls which array to use for the datasource
            self.availableTabSelected = lastTab == self.tabBar.items?[1] ? true : false
        }
        
        return true
    }
    */
    
    //Dismiss keyboard if clicking away from text box
    //Detect when user taps on scroll view
    func tapDismiss(_ sender: UITapGestureRecognizer)
    {
        //Before dissmissing keyboard tell the responder that I want to return to the previously selected tab
        self.changeTab = true
        //keyboard dismissal will notify the keyboard observer to call the keyboardWillBeHidden func to restore the view
        //Force all keyboards to resign
        self.view.endEditing(true)
        resignResponders()
//        self.activeTextField?.resignFirstResponder()
//        restoreViewOnKeyboardDissmiss(changeTab: true)
    }
    
    func tapTableCover(_ sender: UITapGestureRecognizer)
    {
        //Before dissmissing keyboard tell the responder that I want to return to the previously selected tab
        self.changeTab = true
        //keyboard dismissal will notify the keyboard observer to call the keyboardWillBeHidden func to restore the view
        //        self.accTextField.resignFirstResponder()
        //Force all keyboards to resign
        self.view.endEditing(true)
        resignResponders()
//        self.activeTextField?.resignFirstResponder()
//        restoreViewOnKeyboardDissmiss(changeTab: true)
    }
    
    //Only function that indicates that the search button was pressed to latch input accessory view input
    func accessoryEditEnd(_ textField: UITextField)    {
        //Before dissmissing keyboard tell the responder that I want to return to the previously selected tab
        self.changeTab = true
        
        //keyboard dismissal will notify the keyboard observer to call the keyboardWillBeHidden func to restore the view
        //        self.accTextField.resignFirstResponder()
        self.activeTextField?.resignFirstResponder()    //Since I just edited the input accessory textbox to add search string this is the only keyboard that needs to be dismissed
        
        //Do nothing if empty string was entered
        guard let searchString = self.accTextField.text else{
            return
        }
        if(searchString.isEmpty){
            return
        }
        
        //Clear text field now that I have unwrapped the data
        self.accTextField.text = ""
        
        //add activity indicator and search backend
        let loadingView: UIView = UIView()
        
        loadingView.frame = CGRect(x: 0,y: 0,width: 80,height: 80)
        loadingView.center = view.center
        loadingView.backgroundColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 0.7)
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
        
        
        //Lowercase the search string so searching is standard
        findUser(input: searchString.lowercased()){(userExists: Bool) in
            activityIndicator.stopAnimating()
            loadingView.removeFromSuperview()
            if(!userExists){
                //Notify User that search input wasn't found
                self.loginFailMsg(error: "nonexisting")
            }else{ //If user does exist we just reload the tableview with the user we found
                //make sure that we move to the available tab so the user can see the new user
                /*if let lastTab = self.lastTabSelected {
                    if(lastTab != self.tabBar.items?[1]){*/
                self.tabBar.selectedItem = self.tabBar.items?[1]    //Select available tab
                //Keep track of the available tab being selected
                self.availableTabSelected = true
                
                self.tableView.reloadData()
                
            }
        }
        
    }
    
    //Dismiss keyboards for both dummy and accessory text box to ensure keyboard is dismissed
    func resignResponders(){
        self.accTextField.resignFirstResponder()
        self.dummyTextBox.resignFirstResponder()
    }
    
    //Since delegate is not getting called, anything that ends the editing has to call this function
    //Only restore the last tab if the keyboard was not dismissed by directly pressing the tab bar
    func restoreViewOnKeyboardDissmiss(changeTab: Bool){
        //Deselect search bar tab and select last tab
        if(changeTab){
            if let lastTab = self.lastTabSelected {
                self.tabBar.selectedItem = lastTab
                //If last tab was "avilable" tab then update the availableTabSelected which controls which array to use for the datasource
                self.availableTabSelected = lastTab == self.tabBar.items?[1] ? true : false
            }
            self.changeTab = false
        }
        
        //Nullify any reference to an active text field
        self.activeTextField = nil
        
        //Remove view covering tablview
        self.tableCover.removeFromSuperview()
        
        //Restore tableview background color
        //        self.tableView.backgroundColor = .clear
        //        self.tableView.alpha = 1
        //        self.tableCover.isHidden = true
    }
    
    func modifyViewOnKeyboard(){
        
        //change active textbox the one created in the accessory view
        self.accTextField.becomeFirstResponder()
        //Change the active text field when it becomes the first responder
        self.activeTextField = self.accTextField
        
        //Dim the background of the tableview
        //        self.tableView.backgroundColor = .black
        //        self.tableView.alpha = 0.33
        
        //Add view over tableview so its not messed with
        self.view.addSubview(self.tableCover)
        //        self.tableCover.isHidden = false
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Dismiss keyboard if unwinding
        resignResponders()
        /*if let activeField = self.activeTextField {
            activeField.resignFirstResponder()
        }*/
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Remove observers dismissing view
        if let friendHandle = self.friendHandler {
            self.friendsRef.removeObserver(withHandle: friendHandle)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //Stop the keyboard actions from sending notifications
        deregisterFromKeyboardNotifications()
    }

    
}
