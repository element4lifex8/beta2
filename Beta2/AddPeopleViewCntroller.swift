//
//  AddPeopleViewCntroller.swift
//  Beta2
//
//  Created by Jason Johnston on 10/29/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit

extension UIImage {
    
    class func imageWithColor(color: UIColor, size: CGSize) -> UIImage {
        //Since we added a 2pt top and bottom divider line, subtract 1pt from each size of highlighted image so they don't overlap as much
        let rect: CGRect = CGRect(x: 0, y: 1, width: size.width, height: size.height - 1)
        //Creates a bitmap-based graphics context
        //Parameters size, opaque, and scale
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
}

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

//Make your View Controller implement the Facebook App Invite Dialog delegate and add in delegate methods to receive completion handlers:
extension AddPeopleViewCntroller: FBSDKAppInviteDialogDelegate{
    
    func appInviteDialog (_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable : Any]!) {
        let resultObject = NSDictionary(dictionary: results)
        
        if let didCancel = resultObject.value(forKey: "completionGesture")
        {
            if (didCancel as AnyObject).caseInsensitiveCompare("Cancel") == ComparisonResult.orderedSame
            {
                Helpers().myPrint(text: "User Canceled invitation dialog")
            }
        }
    }
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {
        Helpers().myPrint(text: "Error tool place in appInviteDialog \(error)")
    }
}



class AddPeopleViewCntroller: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tabBar: UITabBar!     //Tab bar used for sorting
    @IBOutlet var tabBarContainerView: UIView!
    //Keep track of the last tab selected so it can be relected after the share icon is selected
    @IBOutlet var HeaderView: UIView!       //Get reference to header view so I can add gester recognizer to dismiss keyboard
    var lastTabSelected: UITabBarItem?
    @IBOutlet var dummyTextBox: UITextField!    //Used only to become first responder and show keyboard
    @IBOutlet var skipButon: UIButton!  //Skip button only appears when onbaording
    @IBOutlet var pagenationImgView: UIImageView!  //Pagenation only appears when onboarding
    @IBOutlet var headerImageView: UIImageView! //Imageview for header that holds image displayed for onboarding
    @IBOutlet var backButton: UIButton!     //Button only appears when on addFriends VC and not during onboarding
    
    //items created for accessory input view
    var accCodeView = UIView()
    var accTextField = UITextField()
  
    //Class member that can be set when transitioning to this VC during the onboarding process 
    var isOnboarding: Bool = false
    var availableTabSelected = false //Keep track of the tab bar thats selected to determine what to display in tableView
    //Keep track of the currently active text field
    var activeTextField: UITextField? = nil
    //View to cover table when keyboard with accessory input view appears
    var tableCover = UIView()
    
    var selectedFBfriends = [FbookUserInfo]()
    var facebookAuthFriends = [String](), facebookAuthIds = [String]()  //Log of users who use the app and are friends with the user
    var facebookTaggableFriends = [String](), facebooktaggableIds = [String]()  //List of all of the users FB friends
    var numUnAddedFriends = 0   //number of friends who are displayed on the available tab so I can notify the user if none are available
    var unAddedFriends = [String]()   //Compile a list of auth users that are not friends followed in the app
    var unAddedFriendId = [String]()   //Match the friends that haven't yet been added to their Id
    var foundUserId : [String] = [""]    //keep record of an email user that was found so he can be distinguished in the list
    var facebookFriendMaster = [String]()
    var myFriends:[String] = []
    var myFriendIds: [String] = []    //list of Facebook Id's with matching index to myFriends array
    var selectedAccessButt: [Int] = []     //List of users who are selected to add as friends
    var selectedIds: [String] = []     //List of users id's who are selected to add as friends
    var friendsRef: FIRDatabaseReference!
    var friendHandler: FIRDatabaseHandle?
    //Dispatch group used to sync firebase and facebook api call
    var myGroup = DispatchGroup()
    var currUser = Helpers().currUser
    //Store the current user's login typea
    //Instead of creating a pure enum i'll just get the NSInteger version so I don't have to unwrap it
    //var loginType: Helpers.userType = Helpers.userType(rawValue: Helpers().loginType)!
    var loginType = Helpers().loginType
    
    //Keyboard tracking hack, pass variable on whether I am dismissing keyboard for tab button press or other metthod
    var changeTab = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Remove views and buttons that do not appear during onboarding
        if(self.isOnboarding){
            //Hide then remove back button
            self.backButton.isHidden = true
            self.backButton.removeFromSuperview()
        }else{
            //Hide first before removing so the user doesn't see them appear before they are removed
            self.skipButon.isHidden = true
            self.pagenationImgView.isHidden = true
            self.headerImageView.isHidden = true
            self.skipButon.removeFromSuperview()
            self.pagenationImgView.removeFromSuperview()
            self.headerImageView.removeFromSuperview()
        }
    }
    
    //Must add submit button in viewDidAppear so that it is added over top of the tablewview (bringSubview to front in viewDidLoad would not put the view on top of the tableview
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //register so that I receive notifications from the keyboard
        registerForKeyboardNotifications()
        
        //Instatiate table cover that will cover the table when the keyboard appears
        self.tableCover = UIView(frame: CGRect(origin: self.tableView.frame.origin, size: self.tableView.frame.size))
        self.tableCover.backgroundColor = .white
        self.tableCover.alpha = 0.75
        //Setup Tap gesture so clicking outside of textbox dismisses keyboard
        let tableGesture = UITapGestureRecognizer(target: self, action: #selector(AddPeopleViewCntroller.tapTableCover(_:)))
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
        //add target actions for button tap and make sure it isuser selectable
//        subButt.isUserInteractionEnabled = true
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
        
        //Modify auto layout constraints and image for header view during onboarding
        if(self.isOnboarding){
            HeaderView.translatesAutoresizingMaskIntoConstraints = false
            let headerHeight = HeaderView.heightAnchor.constraint(equalToConstant: 170)    //Header height is 170 to match other onboarding heights
            headerHeight.priority = UILayoutPriority(rawValue: 750)
            NSLayoutConstraint.activate([headerHeight])
            
            //Set min distance from bottom of headerView to bottom of screen >= 450 for smaller screens to shrink the header view if neccessary to allow for a large enough table to be displayed
            let headerToBottom = NSLayoutConstraint(item: bottomLayoutGuide, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: HeaderView, attribute: .bottom, multiplier: 1.0, constant: 450)
            view.addConstraint(headerToBottom)
            
        }else{//set header view height to 100
            HeaderView.translatesAutoresizingMaskIntoConstraints = false
            let headerHeight = HeaderView.heightAnchor.constraint(equalToConstant: 100)    //Header height is 170 to match other onboarding heights
            NSLayoutConstraint.activate([headerHeight])

        }

        
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
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "Avenir-Light", size: 24)!, NSAttributedStringKey.foregroundColor : UIColor.white], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "Avenir-Light", size: 24)!, NSAttributedStringKey.foregroundColor : UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)], for: .selected)
        
    }
    
    
    override func viewDidLoad() {
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
        self.accTextField.autocorrectionType = .no //Disable predictive text
        self.accTextField.keyboardType = .emailAddress  //make it easier to search for email addresses by setting the email keyboard type

        //Failed attempt to modify the predictive text bar. For iOS 11 this should modify the passord prediction bar
//        self.accTextField.textContentType = UITextContentType("Name")
//        self.dummyTextBox.textContentType = UITextContentType("")
        //Hide predictive text which is only available starting with iOS 9.0

        
        //        self.accTextField.inputAssistantItem.leadingBarButtonGroups = []
//        self.accTextField.inputAssistantItem.trailingBarButtonGroups = []
//        print(self.accTextField.inputAssistantItem.accessibilityElementCount())
//        item.leadingBarButtonGroups = [];
//        item.trailingBarButtonGroups = [];

        
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
        //Create auto layout constraints for label
        let topConstraint = NSLayoutConstraint(item: accLabel, attribute: .top, relatedBy: .equal, toItem: accCodeView, attribute: .top, multiplier: 1.0, constant: 31)
        accCodeView.addConstraint(topConstraint)
        
        let centerConstraint = NSLayoutConstraint(item: accLabel, attribute: .centerX, relatedBy: .equal, toItem: accCodeView, attribute: .centerX, multiplier: 1.0, constant: 0)
        accCodeView.addConstraint(centerConstraint)
        
        accLabel.translatesAutoresizingMaskIntoConstraints = false
        
        //Set input accessory view for keyboard that appears when dummyTextBox is active
        self.dummyTextBox.inputAccessoryView = self.accCodeView
        //hide Dummy text view so even though its constraints put it off the screen if somehow it appears in display-able area it will be behind everthing and hopefully hidden user can't accidently select it
        self.tabBarContainerView.sendSubview(toBack: dummyTextBox)
        
        //Manage keyboard notifications and dismissal with tap gesture
        
        //Setup Tap gesture so clicking outside of textbox dismisses keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(AddPeopleViewCntroller.tapDismiss(_:)))
//        self.tableCover.isUserInteractionEnabled = 
//        self.tableCover.addGestureRecognizer(tapGesture)
        self.HeaderView.addGestureRecognizer(tapGesture)
        
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
        
        //Create container view then loading for activity indicator to prevent background from overshadowing white color
        let loadingView: UIView = UIView()
        
        loadingView.frame = CGRect(x: 0,y: 0,width: 80,height: 80)
        loadingView.center = view.center
        loadingView.backgroundColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
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
                self.tabBar.items?[i].title = "Current"
                //Default this first item to be selected
                let myItem = self.tabBar.items?[i]
                //Select the first item by default
//                self.tabBar.selectedItem = myItem
                self.availableTabSelected = false   //Show all friends, not just availble Auth Friends
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
        
        
        //Start activity indicator while making Firebase request
        let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50,  height: 50)) as UIActivityIndicatorView
        activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2,y: loadingView.frame.size.height / 2);
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.hidesWhenStopped = true
        
        loadingView.addSubview(activityIndicator)
        view.addSubview(loadingView)
        activityIndicator.startAnimating()
        
//        friendsRef = Firebase(url:"https://check-inout.firebaseio.com/users/\(self.currUser)/friends")
        friendsRef = FIRDatabase.database().reference().child("users/\(self.currUser)/friends")
        
        //Had to create the queue and add the async closure because I was getting EXC_BAD_INSTRUCTION when calling myGroup.leave otherwise
        queue.async(group: myGroup) {
            //Only gather and print facebook friends if the user is a facebook user
            if(self.loginType == Helpers.userType.facebook.rawValue){
                self.myGroup.enter()
                self.sortFacebookFriends(){(finished: Bool) in
                    if(finished){   //only "finished" if I was capable of retrieving friends
                        //I no longer combine facebook id's and user name into a dict so this can be erased
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
                //Sort the friends and their IDs by combining into tuple, sorting by the myFriends string array (the first item in each tuple) then seperate back out into two arrays (same thing is done for unAddedFriends in the closure below)
                self.sortFriendArrays(nameArr: &self.myFriends, idArr: &self.myFriendIds)
                self.myGroup.leave()
            }
        }
        
        //Fire async call once facebook api, and firebase calls have finish
        myGroup.notify(queue: DispatchQueue.main) {
            //Only parse available friends if a facebook user
            if(self.loginType == Helpers.userType.facebook.rawValue){
                //Count the number of auth friends that aren't friends of the current user
                //map will check if each element in the facebookAuthFriends is contained in the myFriends array and only return 1 if the facebookAuthFriend is not already a friend
                var authFriendMap = self.facebookAuthIds.map{return self.myFriendIds.contains($0) ? 0 : 1}
                //SInce the facebookAuthIds maps directly to facebookAuthFriends, use the indices from the map array indicating the unAdded friends to create an unadded friend id array
                //Using the enumerated() I create a tuple array of index and friend id that are unAdded
                var authIdEnumTup = self.facebookAuthIds.enumerated().filter({index, value in authFriendMap[index] == 1})
                //Retrieve just the unadded friend ID's from the tuple above (index = $0, values = $1)
                self.unAddedFriendId = authIdEnumTup.map({$1})
                //Using the indices from authFriend map get the facebook friends names by running through the same filter then map as done above for facebook id's
                self.unAddedFriends  = self.facebookAuthFriends.enumerated().filter({index,value in authFriendMap[index] == 1}).map({$1})
                //reduce Initial value of 0 then add all unAdded friends for a total count of what to display
                self.numUnAddedFriends = authFriendMap.reduce(0, +)
                
                //              Done differently above:  //create sub array of auth users that I haven't started following in the app
//                //Remove from the sub array of unAddedFriends if the user is already in Firebase as my friend
//                self.unAddedFriends = self.facebookAuthFriends.filter({!self.myFriends.contains($0)})
                //Check if no friends are going to appear in the Available screen and notify the user why that is
                
                if(self.numUnAddedFriends == 0){
                    self.displayNoFriendsAlert()
                }
                
                //Combine the unaddedFriends name and Id arrays so they can be sorted and still match up
                self.sortFriendArrays(nameArr: &self.unAddedFriends, idArr: &self.unAddedFriendId)
            }
            
            //Stop display of activity monitor
            activityIndicator.stopAnimating()
            loadingView.removeFromSuperview()
            
            self.tableView.reloadData()
        }
        
    }
    
    func sortFacebookFriends(_ completionClosure: @escaping (_ finished: Bool) -> Void){
        var finishedAuth = false, finishedUnauth = false
        
        checkFriendPermiss(){(permission: Bool?) in
            if(permission ?? false){    //Only check backend and facebook for friends if permissions allow, otherwise to-do check for email only friends
                self.retrieveAuthFacebookFriends() {(displayName: [String], taggableId: [String]) in
                    self.facebookAuthFriends = displayName
                    self.facebookAuthIds = taggableId
                    finishedAuth = true  //No longer using, uneeded
//                    completionClosure(true)
                    //Convert facebook user id to firebase if the user has already updated their profile
                        //Update in facebookAuthIds to firebase Id from facebook id
                    self.equateFacebook2Firebase() {(finished: Bool) in
                        completionClosure(true)
                    }
                }
                //No longer retrieving taggable friends
//                self.retrieveUnauthFacebookFriends() {(displayName: [String], unAuthId: [String]) in
//                    self.facebookTaggableFriends = displayName
//                    self.facebooktaggableIds = unAuthId
//                    finishedUnauth = true
//                    //Call completion closure only when all friends have been retrieved
//                    if(finishedAuth && finishedUnauth){
//                        completionClosure(true)
//                    }
//                }
            }else{  //friend permission revoked or completion closure returned nil because it failed to obtain friend permissions with FB graph API request
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
           //Create cancel action that will unwind to a screen depending on isOnboarding or not
            var CancelAction: UIAlertAction
            //Look up friends if permission is availabe
            if(permission ?? false){
                completionClosure(permission)
            }else{  //Notify user that friend persmission isn't available
                let alert = UIAlertController(title: "Access to friends list.", message: "Would you like to allow Check In Out to access your Facebook friends so you can see their Check Ins?", preferredStyle: .alert)
                //Exit function if user clicks no and no friends will be printed
                //If in onboarding unwind to home screen
                if(self.isOnboarding){
                    CancelAction = UIAlertAction(title: "No", style: .cancel, handler: { UIAlertAction in
                        //                    completionClosure(false)
                        self.performSegue(withIdentifier: "unwindFromFbLoginIdentifier", sender: self)
                    })
                }else{  //otherwise unwind to check out screen
                    CancelAction = UIAlertAction(title: "No", style: .cancel, handler: { UIAlertAction in
                        //                    completionClosure(false)
                        self.performSegue(withIdentifier: "unwindFromAddFriends", sender: self)
                    })
                }
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

    //#Unused Func, facebook only allows taggable friends to be used to tag stories inside my app
    //Retrieve friends who have not authorized CIO
    func retrieveUnauthFacebookFriends(_ completionClosure: @escaping (_ displayName: [String], _ taggableId: [String]) -> Void){
        //Taggable friends just provides a reference list of friends that can be tagged or mentioned in stories published to Facebook
        let unAuthrequest = FBSDKGraphRequest(graphPath:"/me/taggable_friends?limit=5000", parameters: ["fields" : "name"]);
        var unAuthFriends = [String]()
        var unAuthId = [String]()
        unAuthrequest?.start(completionHandler: { (connection, result, error) -> Void in
            if error == nil{
                let resultdict = result as! NSDictionary
                let data : NSArray = resultdict.object(forKey: "data") as! NSArray
//                print("unauth data \(data)")
                for i in 0..<data.count{
                    let valueDict : NSDictionary = data[i] as! NSDictionary
                    let fbFriendName = valueDict.object(forKey: "name") as! String
                    unAuthFriends.append(fbFriendName)
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
            if(error != nil){
                Helpers().myPrint(text: "friends not auth")
            }else{
                //Result is cast to an NSDict consiting of [id: value, name: value] for auth friends
                let resultdict = result as! NSDictionary
                let data : NSArray = resultdict.object(forKey: "data") as! NSArray
                //extract dict entries id & name as string for each authorized friend
                for i in 0..<data.count
                {
                    let valueDict : NSDictionary = data[i] as! NSDictionary
                    if let id = valueDict.object(forKey: "id"){
                        authId.append(id as! String)
                    }
                    if let fbFriendName = valueDict.object(forKey: "name"){
                        authFriends.append(fbFriendName  as! String)
                    }
                }
            }
            completionClosure(authFriends, authId)
        })
    }
    

    //retrieve a list of all the user's friends currently stored in firebase
    func retrieveMyFriends(_ completionClosure: @escaping (_ friendStr: [String], _ friendId:[String]) -> Void) {
        var localFriendsArr = [String]()
        var localFriendsId = [String]()
        //Retrieve a list of the user's current check in list
        self.friendsRef.queryOrdered(byChild: "displayName1").observeSingleEvent(of: .value, with: { snapshot in
                for child in (snapshot.children) {    //each child should be a root node named by the users friend ID
                    let rootNode = child as! FIRDataSnapshot
                    let nodeDict = rootNode.value as! NSDictionary
                    //key = "displayName1", value = friend's name
                    for ( _ , value ) in nodeDict{
                        localFriendsArr.append((value as? String ?? "Friend Unavailable")!)
//                        localFriendsId.append((key as? String ?? "999")!)
//                if let currFriend = child.value as? NSDictionary{
//                    localFriendsArr.append((currFriend["displayName1"] as? String ?? "Default Name")!)
//                    localFriendsId.append((snapshot.key))
                }
            }
            completionClosure(localFriendsArr, localFriendsId)
        })
    }
    
    func equateFacebook2Firebase(_ completionClosure: @escaping (_ finished: Bool ) -> Void){
        let userRef = FIRDatabase.database().reference(withPath:"users")
        
        if(self.facebookAuthIds.count > 0){
            for (index, facebookId) in self.facebookAuthIds.enumerated(){
//            Query equal only works when the first level nested value has a key value pair without data nested in the value
                userRef.queryOrdered(byChild: "facebookid").queryEqual(toValue: facebookId).observeSingleEvent(of: .value, with: { snapshot in
                   //snapshot is the user rootnode and query equal will return no nodes beneath the snapshot if there is no matching id to a "facebookid" key
                    //each user is unique so only 1 entry should be returned but to only return the items beneath the user id I "loop" over the snapshots child, and if no children the user doesn't have an updated account with their FB id stored in the backend
                    for child in (snapshot.children) {    //each child should be a root node named by the users friend ID
                        let rootNode = child as! FIRDataSnapshot
                        //store the user id key of the current node
                        let firebaseId = rootNode.key
                        let nodeDict = rootNode.value as! NSDictionary
                        //check for facebook id key and if present and equals the id in the array then the user has updated their id to Firebase
                        for ( key , value ) in nodeDict{
                            if((key as! String) == "facebookid"){
                                //Confirm the key exists for the current user then overwrite facebook ID with Firebase ID
                                self.facebookAuthIds[index] = firebaseId
                            }
                        }
                    }
                    //once I've looped over all id's then we're done
                    if(index == (self.facebookAuthIds.count - 1)){
                        completionClosure(true)
                    }
                })
            }
        }else{//Directly call completion if no user id's to check
            completionClosure(true)
        }

    }
        
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
        //Query equal only works when the first level nested value has a key value pair without data nested in the value
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
                        //Verify the user hasn't already added or searched for this friend before adding to unAdded frineds ( also make sure the user doesn't try to add themself
                        if(!self.myFriendIds.contains(id) && !self.unAddedFriendId.contains(id) && (id != self.currUser as String)){
                            self.unAddedFriends.append(displayName)
                            self.unAddedFriendId.append(id)
                            //Sort the updated added friends arrays
                            self.sortFriendArrays(nameArr: &self.unAddedFriends, idArr: &self.unAddedFriendId)
                            self.foundUserId.append(id)   //keep track of all email users that are found so they can appear selected in the table by default
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
        //Unused for unwinding
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
            msg = "You have already befriended all of your \"Available\" Facebook friends. Invite more friends to Check In Out and then they will appear here as \"Available\""
        }
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(CancelAction)
        self.present(alert, animated: true, completion: nil)

    }

    //combine the friends names and Ids so they can be sorted together and then seperate back out
    //Use "inout" keyword to pass arrays to the function by reference 
    func sortFriendArrays(nameArr: inout [String], idArr: inout [String]){
        //Combine the Friends names and IDs into a tuple so I can sort by last name
        // use zip to combine the two arrays and sort that based on the first
        //$0.0 refers to the the first value of the first tuple, and $0.1 refers to the first value of the 2nd tupe, so each tuple is a [unAddedFriend Name, unAddedFriendID] so I'm looking at the first & second item for each iteration and only considering the unAddedFriend name for sorting
        let combinedFriends = zip(nameArr, idArr).sorted {$0.0.lastName() < $1.0.lastName()}
        //Then extract all of the 1st items in each tuple (unAddedFriends names)
        nameArr = combinedFriends.map{$0.0}
        //Then extract all of the 2st items in each tuple (unAddedFriends ids)
        idArr = combinedFriends.map{$0.1}
    }
    
    //When a user selects an accessory button (or we preselect for searched users then we store the current location of that user in the table data source to sync the selected accessory view
    func syncAccessoryView(uncheck: Bool, idx: Int){
        //Store the selected friend from the data source
        let friendName = self.unAddedFriends[idx]
        let friendID = self.unAddedFriendId[idx]
        //actions to remove the friend from our tracking system when they are unselected
        if(uncheck){
            //Remove from arrays for indices, staged friends, and searched friends
            if let index = self.selectedAccessButt.index(of: idx){
                self.selectedAccessButt.remove(at: index)
            }
            //wish I understood these closures, came from here: http://stackoverflow.com/questions/34081580/array-of-any-and-contains
            if let fbIndex = self.selectedFBfriends.index(where: {$0.id == friendID} )    {
                    self.selectedFBfriends.remove(at: fbIndex)
            }

            //remove the found user so that he will no longer always be selected when the tableview is reloaded, but rather track with the check in the accessory view
            if let idxMatch = self.foundUserId.index(of: friendID){
                self.foundUserId.remove(at: idxMatch)
            }
   
        }else{
            //Keep track of accessory buttons that are checked so they are reselected when scrolled back into view
            self.selectedAccessButt.append(idx)
            //Add authorized friends to add to friends list, and create list of unauth friends to notify about the app.
            let FBfriend = FbookUserInfo(name: friendName, id: friendID)
            
            //Don't add a name twice to the list of users to be added. This may occur when ensuring that a "searched for" friend is selected
            if(!self.selectedFBfriends.contains(where: {$0.id == FBfriend.id})){
                self.selectedFBfriends.append(FBfriend)
            }
        }
    }

     @IBAction func submitSelected(_ sender: UIButton) {
//         let userChecked = Firebase(url:"https://check-inout.firebaseio.com/users/\(self.currUser)/friends")
        let userChecked = FIRDatabase.database().reference().child("users/\(self.currUser)/friends")
        for friend in self.selectedFBfriends{
            if let name = friend.displayName, let id = friend.id{
                //Add id of curr friend with their display name stored underneath
                let friendInfo = ["displayName1" : name]
                userChecked.child(byAppendingPath: id).setValue(friendInfo)
            }else{
                Helpers().myPrint(text: "No id was found for the following friend: \(friend.displayName ?? "friend name failed too")")
            }
        }
        //Transition to the home screen from onboarding
        if(self.isOnboarding){
            performSegue(withIdentifier: "unwindFromFbLoginIdentifier", sender: self)
        }else{  //otherwise unwind to check out screen
            performSegue(withIdentifier: "unwindFromAddFriends", sender: self)
        }
        
    }
    
    
    @IBAction func accessoryButtonTapped(_ sender: UIButton) {
        
        var friendName: String = "", friendID = ""
        if(self.availableTabSelected){
            friendName = self.unAddedFriends[sender.tag]
            friendID = self.unAddedFriendId[sender.tag]
        }else{
            //In the all tab myFriends is the data source
            friendName = self.myFriends[sender.tag]
            friendID = self.myFriendIds[sender.tag]
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
            //Update Tracking arrays of selected accessory buttons 
            syncAccessoryView(uncheck: false, idx: sender.tag)
            
//            //Keep track of accessory buttons that are checked so they are reselected when scrolled back into view
//            self.selectedAccessButt.append(sender.tag)
//            //Add authorized friends to add to friends list, and create list of unauth friends to notify about the app.
//            FBfriend = FbookUserInfo(name: friendName, id: friendID)
//            
//            //Don't add a name twice to the list of users to be added. This may occur when ensuring that a "searched for" friend is selected
//            if(!self.selectedFBfriends.contains(where: {$0.id == FBfriend.id})){
//                self.selectedFBfriends.append(FBfriend)
//            }
        }else{
            //Keep track of accessory buttons that are unchecked
            syncAccessoryView(uncheck: true, idx: sender.tag)
//            if let index = self.selectedAccessButt.index(of: sender.tag){
//                self.selectedAccessButt.remove(at: index)
//            }
//            //wish I understood these closures, came from here: http://stackoverflow.com/questions/34081580/array-of-any-and-contains
//            if let fbIndex = self.selectedFBfriends.index(where: {$0.id == friendID} )    {
//                    self.selectedFBfriends.remove(at: fbIndex)
//            }
//            
//            //remove the found user so that he will no longer always be selected when the tableview is reloaded, but rather track with the check in the accessory view
//            if let idxMatch = self.foundUserId.index(of: friendID){
//                self.foundUserId.remove(at: idxMatch)
//            }
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
            //Previously I showed all auth users in the available screen, now I won't show those if they're already friends
            //            return self.facebookAuthFriends.count
            return self.unAddedFriends.count

        }else{
            //List all friends I've added in "All Tab"
            return self.myFriends.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var showAccessoryButt = true
        let checkImage = UIImage(named: "tableAccessoryCheck")
        let cellIdentifier = "friendCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! FriendTableViewCell   //downcast to my cell class type
        var existingFriend = false
        var taggableFriendsItem = ""    //Hold a reference to the taggable friends item at the current index if we are a facebook user, otherwise hold empty string
        //display table data from taggable friends which includes auth and unauth friends
        if(self.availableTabSelected){
            cell.nameLabel.text = "\(self.unAddedFriends[indexPath.row])"
        }else{
            //Data source for the "all" tab is  current friends
            cell.nameLabel.text = "\(self.myFriends[indexPath.row])"
        }
        
        //Only initialize tagable friends item if using the facebook datasource, otherwise would be indexing into empty array
//        if(self.loginType == Helpers.userType.facebook.rawValue){
//            taggableFriendsItem = facebookTaggableFriends[indexPath.row]
//        }
        //Check if its possible for the current user to be an existing friend so we can change their isAvailable label in the block below
        //All friends are existing if one appears for email users
       /* if(self.loginType == Helpers.userType.email.rawValue){
            existingFriend = true
        }else{
            //If user is not an email user their All tab data source will be facebookTaggabel friends
            if(facebookAuthFriends.contains(facebookTaggableFriends[indexPath.row])){
                existingFriend = true
            }
        }*/
        
 
        cell.nameLabel.textColor = UIColor.black
        cell.nameLabel.font = UIFont(name: "Avenir-Light", size: 18)
        cell.nameLabel.lineBreakMode = .byTruncatingTail
        //Set available tag
        //If displaying all friends need to check the facebookTaggable friends, otherwise we can index directly into unAddedFriends since We don't display already added friends in available tab, only in the all tab
        if(self.availableTabSelected)
        {
            cell.isAvailableLabel.text = "Available"
            cell.isAvailableLabel.font = UIFont(name: "Avenir-Light", size: 12)
            
        }else{
        //If we're in the all tab and the user is an AuthFriend they can only be "trusted"
            //If an email user than all friends in the "All tab" are "trusted"
            cell.isAvailableLabel.text = "Trusted"
            cell.isAvailableLabel.font = UIFont(name: "Avenir-LightOblique", size: 12)
            showAccessoryButt = false   //Don't allow the user to try to re-add a friend
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
        
        //Preselect any user that was selected before searching or has appeared due to searching for friends if any unaddedFriends exists
        if(self.availableTabSelected && self.unAddedFriends.indices.contains(indexPath.row)){    //First check if any unadded friends exist
            //Then check if I still have this user in my found user array or selected FB friends
            if (self.foundUserId.contains(self.unAddedFriendId[indexPath.row]) || self.selectedFBfriends.contains(where: {$0.id == self.unAddedFriendId[indexPath.row]})){
                //Disable button which will be the indicator to the accessoryButtonTapped function to leave highlighted
//                accessoryButton.isEnabled = false
//                self.accessoryButtonTapped(accessoryButton)
                syncAccessoryView(uncheck: false, idx: indexPath.row)
            }
        }
        
        if(!showAccessoryButt){    //Don't add accessory button if not a check in out user or if the user is already following them
            cell.accessoryView?.isHidden = true
        }
        
        //Reselect accessory button when scrolled back into view
        if(self.availableTabSelected && self.selectedAccessButt.contains(indexPath.item)){
            accessoryButton.isSelected = true
        }
        
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }
    
    //Tab bar delegate for selecting buttons
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        switch(item){
        case (self.tabBar.items?[0])!:
            //If a tab is selected while the keyboard field is present
            //keyboard dismissal will notify the keyboard observer to call the keyboardWillBeHidden func to restore the view
            //Force all keyboards to resign
            self.view.endEditing(true)
            resignResponders()
           /* if let activeField = self.activeTextField {
                activeField.resignFirstResponder()
//                restoreViewOnKeyboardDissmiss(changeTab: false)
            }*/
           self.lastTabSelected = self.tabBar.items?[0]
           self.availableTabSelected = false
           self.tableView.reloadData()
            break;
        case (self.tabBar.items?[1])!:
            //Force all keyboards to resign
            self.view.endEditing(true)
            resignResponders()
         /*   if let activeField = self.activeTextField {
                activeField.resignFirstResponder()
//                restoreViewOnKeyboardDissmiss(changeTab: false)
            }*/
            self.lastTabSelected = self.tabBar.items?[1]
            self.availableTabSelected = true
            self.tableView.reloadData()
            break;
        case (self.tabBar.items?[2])!:
            //Activate dummy textfield to show keyboard that that has accessory input view attached
            //If an active text field is already selected then don't make dummyTextBox first responder again 
            if let activeText = self.activeTextField{   //if non-nil I already have an active text box
                //Do nothing
            }else{
                //I have to disable predictive text before becomming first responder, then later re-enable before dismissing to avoid glitch detailed in my Stack overflow question: https://stackoverflow.com/questions/46858834/ios-keyboard-predictive-text-glitch-when-dismissing
                self.accTextField.autocorrectionType = .no //Disable predictive text
                self.dummyTextBox.becomeFirstResponder()
                self.activeTextField = self.dummyTextBox
            }
//            self.activeTextField = self.dummyTextBox
            break
        default:    //No other tabs should exist
            break;
        }

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
    @objc func keyboardWasShown(notification: NSNotification){
        //Need to calculate keyboard exact size due to Apple suggestions
       
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        //Wait until keyboard was shown to activate accessory view as firstResponder so I don't attempt to show the keyboard twice
        modifyViewOnKeyboard()
        
    }
    
    
    //Sets insets to 0, the defaults
    @objc func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        //Only trigger nullifying active text field and removing frosted view when keyboard is actually hidden 
        restoreViewOnKeyboardDissmiss(changeTab: self.changeTab)
    }
    
    /* Delegate is only tracking dummy text box
    //Function used to designate active text field
    func textFieldDidBeginEditing(_ textField: UITextField){
        //Keep track of the currently selected text field
//         self.activeTextField = textField
    }

    
    //Did end editing gets called when I switch the active text field from the dummy text field to the input accessory view so I can't put any code here since it will be called before I even get to editing the input accessory view
    func textFieldDidEndEditing(_ textField: UITextField){
//        self.activeTextField = nil
    }
*/
    /*Unused since input accessory view won't conform to keyboard delegate
    //Actions to take when user dismisses keyboard: hide keyboard & autocomplete table, add first row text to text box
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
//        self.activeTextField?.resignFirstResponder()
        //keyboard dismissal will notify the keyboard observer to call the keyboardWillBeHidden func to restore the view
        self.accTextField.resignFirstResponder()
        //Deselect search bar tab and select last tab
        if let lastTab = self.lastTabSelected {
            self.tabBar.selectedItem = lastTab
            //If last tab was "avilable" tab then update the availableTabSelected which controls which array to use for the datasource
            self.availableTabSelected = lastTab == self.tabBar.items?[1] ? true : false
        }
        
        return true
    }*/

    //Dismiss keyboard if clicking away from text box
    //Detect when user taps on scroll view
    @objc func tapDismiss(_ sender: UITapGestureRecognizer)
    {
        //Before dissmissing keyboard tell the responder that I want to return to the previously selected tab
        self.changeTab = true
        //keyboard dismissal will notify the keyboard observer to call the keyboardWillBeHidden func to restore the view
        //Force all keyboards to resign
        self.view.endEditing(true)
        resignResponders()
//        self.activeTextField?.resignFirstResponder()
        
       /* if let activeField = self.activeTextField {
            activeField.resignFirstResponder()
        }*/
//        restoreViewOnKeyboardDissmiss(changeTab: true)

    }
    
    @objc func tapTableCover(_ sender: UITapGestureRecognizer)
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
    @objc func accessoryEditEnd(_ textField: UITextField)    {

        //Before dissmissing keyboard tell the responder that I want to return to the previously selected tab
        self.changeTab = true
        
        //keyboard dismissal will notify the keyboard observer to call the keyboardWillBeHidden func to restore the view
//        self.accTextField.resignFirstResponder()
//        self.activeTextField?.resignFirstResponder()    //Since I just edited the input accessory textbox to add search string this is the only keyboard that needs to be dismissed
        resignResponders()
        
        restoreViewOnKeyboardDissmiss(changeTab: true)
       
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
               /* if let lastTab = self.lastTabSelected {
                    if(lastTab != self.tabBar.items?[1]){*/
                self.tabBar.selectedItem = self.tabBar.items?[1]    //Select available tab
                //Keep track of the available tab being selected
                self.availableTabSelected = true
                //When updating available tab with new users removed entries in the selected accessory views array since they may no longer correspond to the same index
                self.selectedAccessButt.removeAll()
                //Any non-searched for friends are removed since I remove the selected access button earlier
//                self.selectedFBfriends.removeAll()
                self.tableView.reloadData()
                
            }
        }
        
    }
    
    //Dismiss keyboards for both dummy and accessory text box to ensure keyboard is dismissed
    func resignResponders(){
        //Only resign responders when an active responder exists since this will swap first responders and change accessory text box settings and then dismiss
        if let activeField = self.activeTextField{
            //Before I can dismiss keyboard I have to re-enable predictive text to avoid keyboard glitch
            //To re-enable predictive text I have have to make another text field first responder
            self.dummyTextBox.becomeFirstResponder()
            self.accTextField.autocorrectionType = .yes
            //Return the accessory text box to first responder so it can then be dissmissed
            self.accTextField.becomeFirstResponder()
            self.activeTextField = self.accTextField
            self.accTextField.resignFirstResponder()
            self.dummyTextBox.resignFirstResponder()
        }
    }
    
    //Since delegate is not getting called, anything that ends the editing has to call this function
    //Only restore the last tab if the keyboard was not dismissed by directly pressing the tab bar
    func restoreViewOnKeyboardDissmiss(changeTab: Bool){
        //Deselect search bar tab and select last tab if a new tab button was not pressed
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
        
        //Restore tableview background color (Used before overlaying tableViewCover)
//        self.tableView.backgroundColor = .clear
//        self.tableView.alpha = 1
//        self.tableCover.isHidden = true
    }
    
    func modifyViewOnKeyboard(){
        
        //change active textbox to the one created in the accessory view here once keyboard already shown so I don't try to show the keyboard a second time
        self.accTextField.becomeFirstResponder()
        //Change the active text field when it becomes the first responder, calling resign first responder will only dismiss the keyboard if the accTextField is the active text field
        self.activeTextField = self.accTextField
        
        //Dim the background of the tableview ((Used before overlaying tableViewCover))
        //        self.tableView.backgroundColor = .black
        //        self.tableView.alpha = 0.33
        
        //Add view over tableview so its not messed with
        self.view.addSubview(self.tableCover)
//        self.tableCover.isHidden = false

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Dismiss keyboard if unwinding
        //keyboard dismissal will notify the keyboard observer to call the keyboardWillBeHidden func to restore the view
//        self.accTextField.resignFirstResponder()
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
