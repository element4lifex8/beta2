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

class ProfileViewController: UIViewController {

    @IBOutlet var userNameLabel: UILabel!
    
    @IBOutlet var peopleButton: UIButton!
    @IBOutlet var homeCityButton: UIButton!
    @IBOutlet var cityButton: UIButton!
    @IBOutlet var addFriendButton: UIButton!
    
    //Activity monitor and view background
    var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView()
    var loadingView: UIView = UIView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.userNameLabel.text = Helpers().currUsername as String

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
        homeCityButton.isUserInteractionEnabled = false
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
        self.userNameLabel.text = Helpers().currUsername as String

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
        
    }
    
    //Retrieve the number of cities and the name of the home cities in a dictionary
    func retrieveCoreCities() -> [String : String]{
        //Create default return missing home city and no regular cities
        var returnCity = ["homeCity" : "No Home City", "city" : "0"]
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
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromAddFriends(_ sender: UIStoryboardSegue) {
        // empty
    }



}
