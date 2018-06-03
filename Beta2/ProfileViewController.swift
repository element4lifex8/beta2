//
//  ProfileViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 10/21/17.
//  Copyright © 2017 anuJ. All rights reserved.
//

import UIKit
import CoreData
import FirebaseDatabase
import FBSDKLoginKit

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var menuView: UIView!
    
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var customUserNameLabel: UILabel!
    
    @IBOutlet var peopleButton: UIButton!
    @IBOutlet var homeCityButton: UIButton!
    @IBOutlet var cityButton: UIButton!
    @IBOutlet var addFriendButton: UIButton!
    @IBOutlet var settingsButton: UIButton!
    
    //Activity monitor and view background
    var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView()
    var loadingView: UIView = UIView()
    
    var progMenuView: UIView = UIView()
    let menuWidth: CGFloat = 187.0
    //Table view holds items in list
    var tableView: UITableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Create round border on the buttons depending on the auto layout width they are given
        peopleButton.layer.cornerRadius = 0.5 * peopleButton.frame.width
        homeCityButton.layer.cornerRadius = 0.5 * homeCityButton.frame.width
        cityButton.layer.cornerRadius = 0.5 * cityButton.frame.width
        
        //title edge insets added in storyboard so shrink button titles if needed
        peopleButton.titleLabel?.adjustsFontSizeToFitWidth = true
        homeCityButton.titleLabel?.adjustsFontSizeToFitWidth = true
        cityButton.titleLabel?.adjustsFontSizeToFitWidth = true
        homeCityButton.titleLabel!.minimumScaleFactor = 0.6
        homeCityButton.titleLabel!.lineBreakMode = .byTruncatingTail
        
        //Until the buttons are used diable touch selection
        peopleButton.isUserInteractionEnabled = false
        cityButton.isUserInteractionEnabled = false
        
        //Populate the text on the city, home city, and num friends icons
        var cityDict = retrieveCoreCities()
        
        if let homeCity = cityDict["homeCity"]{
//            self.homeCityButton.titleLabel?.text = homeCity
            self.homeCityButton.setTitle(homeCity, for: .normal)
        }
        if let cityCount = cityDict["city"]{
//            self.cityButton.titleLabel?.text = cityCount
            self.cityButton.setTitle(cityCount, for: .normal)
        }
        //Set display name from User Defaults
        self.userNameLabel.text = Helpers().currDisplayName as String
        //Set user name from User defaults
        self.customUserNameLabel.text = Helpers().currUserName as String
        
        //Add shadow to button
        let shadowX: CGFloat = 5.0, shadowY:CGFloat = 5.0
        self.addFriendButton.layer.shadowOpacity = 0.5
        self.addFriendButton.layer.shadowOffset = CGSize(width: shadowX, height: shadowY)
        //Radius of 1 only adds shadow to bottom and right
        self.addFriendButton.layer.shadowRadius = 1
        self.addFriendButton.layer.shadowColor = UIColor.black.cgColor
        //Set image attached to add friend button
        let friendImage = UIImage(named: "addFriendIcon")
        self.addFriendButton.setImage(friendImage, for: .normal)
        self.addFriendButton.tintColor = .none
        //Move add friends icon to far left of the button, right now i'll leave it in default location
        //        self.addFriendButton.imageEdgeInsets = UIEdgeInsetsMake(2, 0, 0, 53)

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Add touchdown event to add people button so I can adjust the background color when highlighted
        //Function to highlight when touches begin
        self.addFriendButton.addTarget(self, action: #selector(ProfileViewController.friendButtBeginTouch(_:)), for: .touchDown)
        //Functions to unhighlight when touches finished
        self.addFriendButton.addTarget(self, action: #selector(ProfileViewController.friendButtTouchCancel(_:)), for: .touchDragExit)
        self.addFriendButton.addTarget(self, action: #selector(ProfileViewController.friendButtTouchCancel(_:)), for: .touchDragOutside)
        self.addFriendButton.addTarget(self, action: #selector(ProfileViewController.friendButtTouchCancel(_:)), for: .touchUpOutside)
         self.addFriendButton.addTarget(self, action: #selector(ProfileViewController.friendButtTouchCancel(_:)), for: .touchUpInside)
        self.addFriendButton.addTarget(self, action: #selector(ProfileViewController.friendButtTouchCancel(_:)), for: .touchCancel)
        
        //Perform backend access and configure activity monitor in viewDidAppear so frame sizes are known
        
        //Display the number of friends retrieved from firebase for the curr user
        let friendsRef = FIRDatabase.database().reference().child("users/\(Helpers().currUser)/friends")
        displayActivityMonitor()
        Helpers().retrieveMyFriends(friendsRef: friendsRef) {(friendStr:[String], friendId:[String]) in
            self.clearActivityMonitor()  //Clear activity monitor before displaying friend count in button
            //            self.peopleButton.titleLabel?.text = String(friendStr.count)
            self.peopleButton.setTitle(String(friendStr.count), for: .normal)
            let _ = friendId.count
        }
        
        createMenuView()
        
        //Connect tableview delegate
        self.tableView.dataSource=self
        self.tableView.delegate=self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
    }
    
    //Retrieve the number of cities and the name of the home cities in a dictionary
    func retrieveCoreCities() -> [String : String]{
        //Create default return missing home city and no regular cities
        var returnCity = ["homeCity" : "Pick One", "city" : "0"]
        var cityCount = 0
        
        var cityButtonCoreData = [NSManagedObject]()
        //Get Reference to NSManagedObjectContext
        //The managed object context lives as a property of the application delegate
        let appDelegate =
            UIApplication.shared.delegate as! AppDelegate
        //use the object context to set up a new managed object to be "commited" to CoreData
        let managedContext = appDelegate.managedObjectContext
        
        //Setting a fetch request’s entity property, or alternatively initializing it with init(entityName:), fetches all objects of a particular entity
        //Fetch request could also be used to grab objects meeting certain criteria
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CityButton")
        
        do {
            /*Typically this seems to put the home city first and alpabet sort the remaining cities afterward. Lower case cities always come after an uppercase cities though*/
            let sortHomeDescriptor = NSSortDescriptor(key: "homeCity", ascending: false)
            let sortCityDescriptor = NSSortDescriptor(key: "city", ascending: true)
            let sortDescriptors = [sortHomeDescriptor, sortCityDescriptor]
            fetchRequest.sortDescriptors = sortDescriptors
            //fetchRequests asks for city button entity, try catch syntax used to handle errors
            let cityButtonEntity =
                try managedContext.fetch(fetchRequest)
            cityButtonCoreData = cityButtonEntity as! [NSManagedObject]
            
            //iterate over all attributes in City button entity
            for i in 0 ..< cityButtonCoreData.count{
                let cityButtonAttr = cityButtonCoreData[i]
                
                if let cityNameStr = cityButtonAttr.value(forKey: "homeCity") as? String{
                    //Strip State from city
                    if let rangeOfSpace = cityNameStr.range(of: ",") {
                        //Convert the range returned by the comma to an index and return the string from the space to end of dispay name
                        returnCity["homeCity"] = cityNameStr.substring(to: rangeOfSpace.lowerBound)
                    }else{//If no state/secondary locality is listed (because no ",State Name" was found
                        returnCity["homeCity"] = cityNameStr
                    }

                //Make sure I can unwrap the non home city entires and that they are actual city entries
                }else if let cityNameStr = cityButtonAttr.value(forKey: "city") as? String{
                     cityCount += 1
                }
            }
        
        }catch let error as NSError {
            Helpers().myPrint(text: "Could not fetch home city: \(error), \(error.userInfo)")
        }
        
        returnCity["city"] = String(cityCount)
        
        return returnCity
        
    }
    
    //Display an activity monitor inside the # friends button while retrieving and counting the # friends in the backend
    func displayActivityMonitor(){
        //Create container view then loading for activity indicator to prevent background from overshadowing white color
        
        //Create fame that fits inside the peopleButton
        let frameSquare: CGFloat = self.peopleButton.frame.width * (2/3)
        //Find x,y centerpoint inside people button then set frame origin to be at the top left corner of where frame will begin
        let frameX = (self.peopleButton.frame.minX + (self.peopleButton.frame.width / 2))
        let frameY = (self.peopleButton.frame.minY + (self.peopleButton.frame.height / 2))
        self.loadingView.frame = CGRect(x: frameX - (frameSquare / 2) ,y: frameY - (frameSquare / 2),width: frameSquare, height: frameSquare)
        //        self.loadingView.center = view.center
        //Different shaded color than back ground
        self.loadingView.backgroundColor = UIColor(red: 0x74/255, green: 0x74/255, blue: 0x74/255, alpha: 0.7)
        self.loadingView.clipsToBounds = true
        self.loadingView.layer.cornerRadius = 10
        
        //Create Activity indicator
        self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: frameSquare , height: frameSquare)) as UIActivityIndicatorView
        self.activityIndicator.center = CGPoint(x: frameSquare / 2,y: frameSquare / 2);
        //        activityIndicator.backgroundColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 0.3)
//        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.white
        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        self.activityIndicator.hidesWhenStopped = true
        
        self.loadingView.addSubview(activityIndicator)
        view.addSubview(loadingView)
        self.activityIndicator.startAnimating()
    }
    
    func clearActivityMonitor(){
        self.activityIndicator.stopAnimating()
        self.loadingView.removeFromSuperview()
    }

    func createMenuView(){
        //Label height is 60 and y offset is 20 to display below menu bar
        let labelHeight: CGFloat = 60.0
        let labelOffset: CGFloat = 20.0
        let borderWidth: CGFloat = 2
        self.progMenuView = UIView(frame: CGRect(x: self.view.frame.maxX, y: self.view.frame.minY, width: self.menuWidth, height: self.view.frame.height))
        self.progMenuView.backgroundColor = .white
        self.progMenuView.layer.borderWidth = borderWidth
        self.progMenuView.layer.borderColor = UIColor.black.cgColor
        
        //Create settings label at top of menu but start beneath menu bar
        let labelView = UIView(frame: CGRect(x: 0, y: labelOffset, width: self.progMenuView.frame.width, height: labelHeight))
        labelView.layer.borderWidth = borderWidth
        labelView.layer.borderColor = UIColor.black.cgColor
//        let settingsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.progMenuView.frame.width, height: labelHeight))
        
        let settingsLabel = UILabel()
        settingsLabel.font = UIFont(name: "Avenir-Light", size: 24)
        settingsLabel.text = "Settings"
        settingsLabel.sizeToFit()
        //labelview.center wasn't centering so manually created center point
        let myPoint = CGPoint(x: labelView.frame.width / 2, y: labelView.frame.height / 2)
        settingsLabel.center = myPoint
        //Add view heirarchy
        labelView.addSubview(settingsLabel)
        self.progMenuView.addSubview(labelView)
        
        //Calculate Table view to sit beneath label and extend to bottom of screen
        tableView = UITableView(frame: CGRect(x: 0, y: labelOffset + labelHeight + borderWidth, width: self.progMenuView.frame.width, height: self.progMenuView.frame.height - (labelHeight + borderWidth)))
        //Remove seperator lines
        self.tableView.separatorStyle = .none
        //Stop table view from bouncing since cells will not fill the screen
        self.tableView.alwaysBounceVertical = false
        self.progMenuView.addSubview(tableView)
//        tableView.reloadData()
        
    }
    @IBAction func requestMenu(_ sender: UIButton) {
        animateMenu(dismiss: false)
        self.settingsButton.isEnabled = false   //Disable settings button so it can't be double pressed
        
    }
    
    func animateMenu(dismiss: Bool){
        //When dismissing I increase X to push the view off the screen
        let xOffset = dismiss ? self.progMenuView.frame.origin.x + self.menuWidth : self.progMenuView.frame.origin.x - self.menuWidth
        //If displaying menu first add to super view
        if(!dismiss){
            self.view.addSubview(self.progMenuView)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            self.progMenuView.frame.origin.x = xOffset
        },completion: {finished in
            //Remove from superview if dismissing
            if(dismiss){
                self.progMenuView.removeFromSuperview()
                self.settingsButton.isEnabled = true   //re-enable settings button 
            }
        })

    }

    //Detect when user taps outside the menu view and dismiss the menu if it is present
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesBegan(touches, with: event)
        
        if let touch: UITouch = touches.first{
            if (touch.view == self.view){
                //dismiss menu if present
                if(self.view.bounds.contains(self.progMenuView.frame.origin)){
                    animateMenu(dismiss: true)
                }
            }
        }
    }

    
    //Functions for highlighting add friend button
    //Change button background when touch down event occurs
    @IBAction func friendButtBeginTouch(_ sender: UIButton) {
        if(!sender.isSelected){
            sender.backgroundColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 1.0)
        }
    }
//    //Even with these cancel funcs I am at times able to achieve the modified background color from the above function that is not cleared when a long touch is canceled
    @IBAction func friendButtTouchCancel(_ sender: UIButton) {
        if(!sender.isSelected){
            sender.backgroundColor = UIColor(red: 0x44/255, green: 0x44/255, blue: 0x44/255, alpha: 1.0)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //5 defined settings options
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch(indexPath.row){
        case 0 :
            cell.textLabel?.text = "Share the app"
        case 1 :
            cell.textLabel?.text = "Frequent Questions"
        case 2 :
            cell.textLabel?.text = "Privacy Policy"
        case 3 :
            cell.textLabel?.text = "Terms of Use"
        case 4 :
            cell.textLabel?.text = "Logout"
        default:
            cell.textLabel?.text = "Settings stuff"
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Deselect selected row after the selection is made
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch(indexPath.row){
        //Implement sharing of the app
        case 0 :
            //dismiss the menu 
            animateMenu(dismiss: true)
            // text to share
            let text = "Tired of endless reviews and recommendations online? \(Helpers().currDisplayName) would like to welcome you to Check In Out. Download the app using the following link"
            let appStoreurl = URL(string: "https://itunes.apple.com/us/app/check-in-out-lists/id1234791039?ls=1&mt=8")
            // set up activity view controller
            let itemsToShare = [ text, appStoreurl] as [Any]
            //UIActivityVC : you tell it what kind of data you want to share, and it figures out how best to share it
            let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
            //Set Subject line for email
            activityViewController.setValue("Join the Check In Out Community", forKey: "Subject")
//            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            
            // exclude some activity types from the list (optional)
            activityViewController.excludedActivityTypes = [ UIActivityType.airDrop]
            
            // present the view controller
            self.present(activityViewController, animated: true, completion: nil)
        case 1 :
            performSegue(withIdentifier: "segueToFAQ", sender: self)
        case 2 :
            performSegue(withIdentifier: "segueToPrivacy", sender: self)
        case 3 :
            performSegue(withIdentifier: "segueToTC", sender: self)
        //code to force logout
        case 4 :
            //If current user is an email user I need to log out of Firebase
            if(Helpers().loginType == Helpers.userType.email.rawValue){
                try! Helpers().firAuth!.signOut()
            }else{
                let loginManager = FBSDKLoginManager()
                loginManager.logOut()
            }
            performSegue(withIdentifier: "LoginScreen", sender: self)
        default:
            Helpers().myPrint(text: "Invalid cell in settings table")
        }
        
    }

    // Unwind seque from my ProdileStepsVC
    @IBAction func unwindFromAddPlaces(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromAddFriends(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    // Unwind seque from my FAQs
    @IBAction func unwindFromFAQs(_ sender: UIStoryboardSegue) {
        // empty
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Dismiss the settings view if it is present when leaving screen
        if(self.view.bounds.contains(self.progMenuView.frame.origin)){
            animateMenu(dismiss: true)
        }
    }


}
