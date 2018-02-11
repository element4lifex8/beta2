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
    static let prevUserDefaultKey = "FBloginVC.prevUser"
    static let currDisplayNameKey = "FBloginVC.displayName"
    static let userNameKey = "FBloginVC.userName"
    static let loginTypeDefaultKey = "FBloginVC.loginType"
    static let currAppVerKey = "CIOHomeVC.appVer"   //key for storing curr app version so I can force a log out when not up to date
    static let logoutDefaultKey = "CIOHomeVC.logout"    //Key to check if a logout should be forced for a new version 
    
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
    
    //Keep track of any old FB users if neccessary
    var prevUser: NSString {
        get{
            if let userId = defaultsStandard.object(forKey: Helpers.prevUserDefaultKey) as? NSString{
                return userId
            }else{
                return "0"
            }
        }
        set
        {
            defaultsStandard.set(newValue, forKey: Helpers.prevUserDefaultKey)
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
//            defaultsStandard.synchronize()
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
            //            defaultsStandard.synchronize()
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
//            defaultsStandard.synchronize()
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
    let firAuth = FIRAuth.auth()
    
    
    //Function used to only print to console for debug builds which use the -D DEBUG flag:
    //Set it in the "Swift Compiler - Custom Flags" section, "Other Swift Flags" line. You add the DEBUG symbol with the -D DEBUG entry.
    //(Build Settings -> Swift Compiler - Custom Flags)
    func myPrint(text :  String) -> Void{
        #if DEBUG
            print(text)
        #endif
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
    func emailCheck(email: String, _ completionClosure: @escaping (_ type:  Helpers.userType, _ userName: NSString, _ displayName: NSString) -> Void)
    {
        let userRef = FIRDatabase.database().reference(withPath:"users")
        var returnType : Helpers.userType = Helpers.userType.new
        var returnUser: NSString = ""
        var returnName: NSString = ""
        //Query for an email equal to the one that the user attempts a sign in with (queryEqual is case sensitive so string is lowercased)
        userRef.queryOrdered(byChild: "email").queryEqual(toValue: email.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
            //snapshot is the user id of the matching user, email should be unique so only 1 entry should be returned but to only return the items beneath the user id I "loop" over the snapshots child, and if no children return default returnType of userType.new
            for child in snapshot.children{
                let rootNode = child as! FIRDataSnapshot
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
                    }else{  //if entry doesn't include type then user should be recreated
                        //This in coordination with checking for username forces Beta users to complete this onboard details screen
                        returnType = Helpers.userType.new
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
    func retrieveMyFriends(friendsRef: FIRDatabaseReference, _ completionClosure: @escaping (_ friendStr: [String], _ friendId:[String]) -> Void) -> FIRDatabaseHandle? {
        //FIR database handler for removing reference if I decide to user observe instead of observeSingleEvent
        var friendHandler: FIRDatabaseHandle?
        
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


}
