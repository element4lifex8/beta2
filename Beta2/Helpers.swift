//
//  Helpers.swift
//  Beta2
//
//  Created by Jason Johnston on 2/23/17.
//  Copyright © 2017 anuJ. All rights reserved.
//

import UIKit
import Foundation
import FirebaseDatabase
import FirebaseAuth

class Helpers{
    //Reference to User Defaults
    fileprivate let defaultsStandard = UserDefaults.standard
    //NSUserDefault keys refer to FB login controller where they originally presided
    static let currUserDefaultKey = "FBloginVC.currUser"
    static let FBUserIdDefaultKey = "FBloginVC.prevUser"
    static let currDisplayNameKey = "FBloginVC.displayName"
    static let userNameKey = "FBloginVC.userName"
    static let loginTypeDefaultKey = "FBloginVC.loginType"
    static let currAppVerKey = "CIOHomeVC.appVer"   //key for storing curr app version so I can force a log out when not up to date
    static let logoutDefaultKey = "CIOHomeVC.logout"    //Key to check if a logout should be forced for a new version 
    static let onboardCompleteDefaultKey = "OnboardDetailsVC.complete"    //Key to check if the user completed the onboarding username step or if they closed the app and skipped it
    static let numChecksDefaultKey = "CIOHomeVC.numChecked"    //Key to reference the number of user check ins
    static let numFollowersDefaultKey = "CIOHomeVC.numFollowers"    //Key to reference the number of user followers
    static let numFriendsDefaultKey = "CIOHomeVC.numFriends"    //Key to reference the number of user friends
    static let numCheckValDefaultKey = "CIOHomeVC.numChecksValid"    //Key to reference if the number of user check ins is current
    static let numFollowerValDefaultKey = "CIOHomeVC.numFollowerValid"    //Key to reference the number if the number of user followers are current
    static let numFriendValDefaultKey = "CIOHomeVC.numFriendValid"    //Key to reference the number if user friends num is current
    static let followNoteDefaultKey = "FollowersVC.followNote"    //Key for flag to display new follower notification
    
    
    let catButtonList = ["Bar",  "Beaches", "Breakfast", "Brewery", "Brunch", "Bucket List", "Coffee Shop", "Dessert", "Dinner", "Food Truck", "Hikes", "Lodging", "Lunch", "Museums", "Night Club", "Parks", "Sightseeing", "Winery"]
    
    //retrieve the current app user from NSUserDefaults
    var currUser: NSString {
        get{
            if let userId = defaultsStandard.object(forKey: Helpers.currUserDefaultKey) as? NSString{
                return userId
            }else{
                return "0"
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.currUserDefaultKey)
//            defaultsStandard.synchronize()      //Force user default to immediately update, supposedly slow and memory intensive
        }
    }
    
    //Keep track of Facebook user id if neccessary
    var FBUserId: NSString {
        get{
            if let userId = defaultsStandard.object(forKey: Helpers.FBUserIdDefaultKey) as? NSString{
                return userId
            }else{
                return "0"
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.FBUserIdDefaultKey)
            //            defaultsStandard.synchronize()      //Force user default to immediately update, supposedly slow and memory intensive
        }
    }
    
    
    //retrieve the current app user display name from NSUserDefaults
    var currDisplayName: NSString {
        get{
            if let userName = defaultsStandard.object(forKey: Helpers.currDisplayNameKey) as? NSString{
                return userName
            }else{
                return "User"
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.currDisplayNameKey)
        }
    }
    
    //retrieve the current user's username from NSUserDefaults
    var currUserName: NSString {
        get{
            if let userName = defaultsStandard.object(forKey: Helpers.userNameKey) as? NSString{
                return userName
            }else{
                return "username"
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.userNameKey)
        }
    }
    
    //retrieve the current login type from NSUserDefaults as raw integer and when used I'll have to equate that with the rawValue of a userType variable
    var loginType: NSInteger {
        get{
            if let loginType = defaultsStandard.object(forKey: Helpers.loginTypeDefaultKey) as? NSInteger{
                return loginType
            }else{  //By default return a new user if UserDeafaults fails to find a user type
                return userType.new.rawValue
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.loginTypeDefaultKey)
        }
    }
    
    //Store the current app version and compare it to the current version in Info.plist
    var appVer: NSString {
        get{
            if let ver = defaultsStandard.object(forKey: Helpers.currAppVerKey) as? NSString{
                return ver
            }else{
                return "0.0"
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.currAppVerKey)
        }
    }
    
    //Store and readback whether a logout should be forced on the user
    var logoutDefault: NSNumber {
        get{
            if let shouldLogout = defaultsStandard.object(forKey: Helpers.logoutDefaultKey) as? NSNumber{
                return shouldLogout
            }else{  //By default I will logout the user if the key doesn't exist yet
                return 1
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.logoutDefaultKey)
        }
    }
    
    //Store and readback whether a user skipped the onboard details screen by closing the app
    var onboardCompleteDefault: NSNumber {
        get{
            if let onboardComplete = defaultsStandard.object(forKey: Helpers.onboardCompleteDefaultKey) as? NSNumber{
                return onboardComplete
            }else{  //By default I will force the user to complete the onboard details screen if this NSDefault value has not yet been set 
                return 0
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.onboardCompleteDefaultKey)
        }
    }
    
    //Store and readback number of user checkins
    var numCheckInDefault: NSNumber {
        get{
            if let numChecks = defaultsStandard.object(forKey: Helpers.numChecksDefaultKey) as? NSNumber{
                return numChecks
            }else{  //By default no check ins have been counted
                return 0
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.numChecksDefaultKey)
        }
    }
    
    //Store and readback number of user friends
    var numFriendsDefault: NSNumber {
        get{
            if let numFriends = defaultsStandard.object(forKey: Helpers.numFriendsDefaultKey) as? NSNumber{
                return numFriends
            }else{  //By default no friends
                return 0
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.numFriendsDefaultKey)
        }
    }
    
    //Store and readback number of peeps following the user
    var numFollowersDefault: NSNumber {
        get{
            if let numFollowers = defaultsStandard.object(forKey: Helpers.numFollowersDefaultKey) as? NSNumber{
                return numFollowers
            }else{  //By default no followers have been counted
                return 0
            }
        }
        
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.numFollowersDefaultKey)
        }
        
        //        //add property oberver so that when the number is increased add notification that is now a new follower
        //        didSet{
        //            //If the new value that was just set is greater than the new value then a new follower exists
        //            if(numFollowersDefault.compare(oldValue) == .orderedAscending) {
        //                print("AHHHHHHHHH:New follower added")
        //            }
        //        }
    }
    
    //Store and readback if number of user checkins is current
    var numCheckValDefault: NSNumber {
        get{
            if let numCheckVal = defaultsStandard.object(forKey: Helpers.numCheckValDefaultKey) as? NSNumber{
                return numCheckVal
            }else{  //By default no check ins have been counted
                return 0
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.numCheckValDefaultKey)
        }
    }
    
    //Store and readback number of user friends
    var numFriendValDefault: NSNumber {
        get{
            if let numFriendVal = defaultsStandard.object(forKey: Helpers.numFriendValDefaultKey) as? NSNumber{
                return numFriendVal
            }else{  //By default no friends
                return 0
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.numFriendValDefaultKey)
        }
    }
    
    //Store and readback number if number of peeps following the user is current
    var numFollowerValDefault: NSNumber {
        get{
            if let numFollowerVal = defaultsStandard.object(forKey: Helpers.numFollowerValDefaultKey) as? NSNumber{
                return numFollowerVal
            }else{  //By default no followers have been counted
                return 0
            }
        }
        
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.numFollowerValDefaultKey)
        }
        
        //        //add property oberver so that when the number is increased add notification that is now a new follower
        //        didSet{
        //            //If the new value that was just set is greater than the new value then a new follower exists
        //            if(numFollowersDefault.compare(oldValue) == .orderedAscending) {
        //                print("AHHHHHHHHH:New follower added")
        //            }
        //        }
    }
    
    //Flag indicates when on the home screen if the
    var displayFollowersNote: NSNumber {
        get{
            if let displayNote = defaultsStandard.object(forKey: Helpers.followNoteDefaultKey) as? NSNumber{
                return displayNote
            }else{  //By default don't display new follower notification
                return 0
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.followNoteDefaultKey)
        }
        
    }
    
    //Enum for login type to be used in login screen and login info screen
    //User types enum
    enum userType: Int {
        case email
        case facebook
        case new
    }
    
    
//    func registerDefaults(){
//            //Ensure NSUserDefault has a default value for each key the app is started
//        defaultsStandard.register(defaults: [currUserDefaultKey: "0"])
//        defaultsStandard.register(defaults: [currUserNameKey: "User"])
//        defaultsStandard.register(defaults: [loginTypeDefaultKey: userType.new.rawValue])
//    }
    
    func returnCurrUser() -> NSString{
        return currUser
    }
    
    //Get firebase auth reference, nil if user signed in with FaceBook (Or no signed in at all)
    let firAuth = Auth.auth()
    
    
    //Function used to only print to console for debug builds which use the -D DEBUG flag:
    //Set it in the "Swift Compiler - Custom Flags" section, "Other Swift Flags" line. You add the DEBUG symbol with the -D DEBUG entry.
    //(Build Settings -> Swift Compiler - Custom Flags)
    func myPrint(text :  String) -> Void{
        #if DEBUG
            print(text)
        #endif
    }
    
    // function chooses to display or remove notification of a new follower
    //Use inout types to pass by reference from the caller
    func displayNewFollNote(display: Bool, superView: UIView, noteView: inout UIView)
    {
        if(display){
            //Calculate size of text and compare to size of follower view to decide location of notification
            var size: CGSize = CGSize(width: 0, height: 0)
            if let font = UIFont(name: "Avenir Light", size: 24) {
                let fontAttributes = [NSAttributedStringKey.font: font]
                let myText = "\(Helpers().numFollowersDefault)"
                //Size of Text string
                size = (myText as NSString).size(withAttributes: fontAttributes)
            }
            //Calculate
            var noteX = superView.frame.size.width/2 - size.width - 5
            noteX = (noteX < 5) ? 5 : noteX //Guard for too many numbers putting it over the edge
    //        print("Size; \(size), frame: \(superView.frame.size), noteX: \(noteX)")
            
            noteView.frame = CGRect(x: noteX,y: 5,width: 10,height: 10)
            noteView.layer.cornerRadius = 5
            noteView.backgroundColor = UIColor.red
        
            superView.addSubview(noteView)
        }else{//Remove notification from view
            noteView.removeFromSuperview()            
        }
    }
    
    // function chooses to display or remove Activity monitor
    //Use inout types to pass by reference from the caller
    func displayActMon(display: Bool, superView: UIView, loadingView: inout UIView, activityIndicator: inout UIActivityIndicatorView )
    {
        //Instantiate parameters and display act mon
        if(display){
            loadingView = UIView()
            loadingView.frame = CGRect(x: 0,y: 0,width: 80,height: 80)
            loadingView.center = superView.center
            loadingView.backgroundColor = UIColor(red: 0x44/255, green: 0x44/255, blue: 0x44/255, alpha: 0.7)
            loadingView.clipsToBounds = true
            loadingView.layer.cornerRadius = 10
            //Start activity indicator while making google request
            activityIndicator = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50,  height: 50)) as UIActivityIndicatorView
            activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2,y: loadingView.frame.size.height / 2);
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
            activityIndicator.hidesWhenStopped = true
            
            loadingView.addSubview(activityIndicator)
            superView.addSubview(loadingView)
            activityIndicator.startAnimating()
        }else{
            activityIndicator.stopAnimating()
            loadingView.removeFromSuperview()
        }
        
    }
    
    //check if the current email exists in the system and if so what type of user are they
    //Return the user's login type, username, and displayname
    func emailCheck(email: String, _ completionClosure: @escaping (_ type:  Helpers.userType, _ userName: NSString, _ displayName: NSString) -> Void)
    {
        let userRef = Database.database().reference(withPath:"users")
        var returnType : Helpers.userType = Helpers.userType.new
        var returnUser: NSString = ""
        var returnName: NSString = ""
        //Query for an email equal to the one that the user attempts a sign in with (queryEqual is case sensitive so string is lowercased)
        userRef.queryOrdered(byChild: "email").queryEqual(toValue: email.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
            //snapshot is the user id of the matching user, email should be unique so only 1 entry should be returned but to only return the items beneath the user id I "loop" over the snapshots child, and if no children return default returnType of userType.new
            for child in snapshot.children{
                let rootNode = child as! DataSnapshot
                //If we have no children then its most certain that the current user doesn't exist
                //Node dict is the items beneath the user id
                if let nodeDict = rootNode.value as? NSDictionary{
                    //unwrap the login type if it exists
                    if let type = nodeDict["type"] as? String{
                        switch(type){
                        case("email"):
                            returnType = Helpers.userType.email
                            break
                        case("facebook"):
                            returnType = Helpers.userType.facebook
                            break
                        default:
                            returnType = Helpers.userType.new
                            break
                        }
                    }
                    
                    //While we're here grab the user's username and display name so we can store it if needed
                    if let username = nodeDict["username"] as? NSString{
                        returnUser = username
                    }
                    if let displayname = nodeDict["displayName1"] as? NSString{
                        returnName = displayname
                    }
                }else{  //If downcast fails then user doesn't exist
                    returnType = Helpers.userType.new
                }
            }
            completionClosure(returnType, returnUser, returnName)
        })
    }
    
    //retrieve a list of all the user's friends from the database and return the firebase handle created by the query
    func retrieveMyFriends(friendsRef: DatabaseReference, _ completionClosure: @escaping (_ friendStr: [String], _ friendId:[String]) -> Void) -> DatabaseHandle? {
        //FIR database handler for removing reference if I decide to user observe instead of observeSingleEvent
        var friendHandler: DatabaseHandle?
        
        //Retrieve a list of the user's current check in list
        //Stop leaving the observe handle active because changes in the back end were triggering this functin then calling the completion closure at the end which was creashing the app
        /*friendHandler =*/ friendsRef.queryOrdered(byChild: "displayName1").observeSingleEvent(of: .value, with: { snapshot in
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
        //Return handler to calling function so it can unattach when needed
        return friendHandler
    }
    
    //Retrieve a list of all of the cities the user's friends have
    func retrieveFriendCity(cityRef: DatabaseReference, friendsList: [String], _  completionClosure: @escaping (_ completedArr: [String]) -> Void) -> DatabaseHandle? {
        var localCityArr = [String]()
        var loopCount = 0
        //FIR database handler for removing reference if I decide to user observe instead of observeSingleEvent
        var cityHandler: DatabaseHandle?
        
        //Loop over all the user's friends to get a list of their cities
        for friendId in friendsList{
            //Query ordered by child will loop each place in the cityRef
            cityHandler = cityRef.child(friendId).queryOrdered(byChild: "city").observe( .value, with: { snapshot in
                
                for child in (snapshot.children) {    //each child is either city, cat or place ID
                    let rootNode = child as! DataSnapshot
                    
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
        //Return handler to calling function so it can unattach when needed
        return cityHandler
    }


    //retrieve a list of all the user's friends from the database and return the firebase handle created by the query
    func retrieveCheckInCount(currUser: NSString, _ completionClosure: @escaping (_ checkInCount: Int) -> Void) -> Void {
        let currRef = Database.database().reference().child("checked/\(currUser)")
        var checkCount = 0
        
        MyListViewController().retrieveWithRef(currRef){ (placeNodeArr: [placeNode]) in
            
            for _ in placeNodeArr{
                checkCount += 1
            }
            completionClosure(checkCount)
        }
        
    }
    
    func addNewFriend(friendId: NSString, friendName: String) -> Void{
        let userChecked = Database.database().reference().child("users/\(Helpers().currUser)/friends")
        let currInfo = ["displayName1" : Helpers().currDisplayName as String]

        //Add id of curr friend with their display name stored underneath
        let friendInfo = ["displayName1" : friendName]
        //add friend to Curr user's list
        userChecked.child(friendId as String).setValue(friendInfo)
        //Add curr user to their new friend's list
        let friendChecked = Database.database().reference().child("users/\(friendId)/followers")
        
        //add friend to Curr user's list
        friendChecked.child(Helpers().currUser as String).setValue(currInfo)
    }
}

