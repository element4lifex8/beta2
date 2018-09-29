//
//  CIOHomeViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 11/7/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseAuth
import FirebaseDatabase

class CIOHomeViewController: UIViewController   {

    
    //Get firebase auth reference, nil if user signed in with FaceBook (Or no signed in at all)
//    let firAuth = FIRAuth.auth()
    //Listener returned on firAuth block
    var handle:FIRAuthStateDidChangeListenerHandle?
    
    var providerId: String?     //Extract the type of auth process that was used
    
    //Profile information views
    @IBOutlet weak var checkInInfoView: UIView!
    @IBOutlet weak var followingInfoView: UIView!
    
    //Profile info numbers
    @IBOutlet weak var checkInNumLabel: UILabel!
    @IBOutlet weak var followerNumLabel: UILabel!
    @IBOutlet weak var FollowingNumLabel: UILabel!
    
    
    
    //Check if user has logged in and force login if not, modal segues must be performed in viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        let currUser = Helpers().currUser
        let friendsRef = FIRDatabase.database().reference().child("users/\(currUser)/friends")
        
        super.viewDidAppear(animated)
        let onboardingCompleted = Helpers().onboardCompleteDefault
        //Check if the user needs to be logged out pending new update
        let shouldLogout = Helpers().logoutDefault
        let providerData = Helpers().firAuth?.currentUser?.providerData
        if let pData = providerData{
            //pData[0].uid will give me the facebook uid
            //user.providerID will return either "facebook.com" or "password"
            for user in pData{
                self.providerId = user.providerID
            }
        }
        //I could attach a listener if I wanted and track changes to the logged in state, but I'm just going to check if current user of the FIRAuth is nil
        //        getFIRLoginState(){(loggedIn: Bool) in
        
            //If user is not authenicated through either system then show login screen
            //I have to check that even if the currentUser is not nil I have to make sure that it was an email verified auth user. Only want this to be true if the user is not signed in through facebook and the user is not signed in through firebase (isEmailed verfified is false of nil)
//        if ((FBSDKAccessToken.current() == nil) && (Helpers().firAuth?.currentUser == nil /*&& (self.providerId ?? "") == "password")*/))
//        {
//            self.performSegue(withIdentifier: "newUserLogin", sender: self)
//        }else if(shouldLogout == NSNumber(value: 1) || onboardingCompleted == NSNumber(value: 0) ){//The NSUserDefault shouldLogut is also checked if the user needs to be forced to login again (will force logout if onboarding not completed either
//            //Update logout Default so the user no longer has to logout
//            Helpers().logoutDefault = 0
////            LogoutButton(UIButton())  Button no longer exists on home screen
//            logoutUser()
//        }
        
        //Calculate the number of user check-ins, number of followers and followed friends and display
        //TODO handle handler
        let _ = Helpers().retrieveMyFriends(friendsRef: friendsRef) {(friendStr:[String], friendId:[String]) in
            self.FollowingNumLabel.text = "\(friendStr.count)"
        }
        
        //Add gesture recognizer to allowing clicking on following/followers and transition to that screen
        //Setup Tap gesture so clicking outside of textbox dismisses keyboard
        let followingTapGesture = UITapGestureRecognizer(target: self, action: #selector(CIOHomeViewController.tapFollowingView(_:)))
        //Make sure gesture recognizer is added after the view frame has been created otherwise the event won't be triggered since it won't have a frame to receieve the touch
        self.followingInfoView.addGestureRecognizer(followingTapGesture)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"FBSDKAccessTokenDidChangeNotification"),
            object:nil, queue:OperationQueue.main, using: { notification in
                
            if ((notification.userInfo?[FBSDKAccessTokenDidChangeUserID] ?? NSNumber(booleanLiteral: false)) as! NSNumber == NSNumber(booleanLiteral: true)) {
                // Update facebook user id in backend when user id changed
                let ref = FIRDatabase.database().reference(withPath:"users")
                ref.child(Helpers().currUser as String).updateChildValues(["facebookid" : "\(Helpers().FBUserId)"])
                }
            })
    }
    
    func getFIRLoginState(_ completionClosure: @escaping ( _ loggedIn: Bool) -> Void){
        //get firebase user and see if they are logged in
        var firebaseLoggedIn = false
        self.handle = Helpers().firAuth?.addStateDidChangeListener {auth, user in
            if let user = user{
                Helpers().myPrint(text: user.uid)
                firebaseLoggedIn = true
            }else{
                //user is not logged in
                firebaseLoggedIn = false
            }
            completionClosure(firebaseLoggedIn)
        }

    }
    
    @objc func tapFollowerView(_ sender: UITapGestureRecognizer)
    {
        self.performSegue(withIdentifier: "segueToFollowVC", sender: self)
    }
    
    //Logout button no longer exists, code moved to logoutFunc
    func logoutUser(){
//        If current user is an email user I need to log out of Firebase
        if((self.providerId ?? "") == "password"){
            try! Helpers().firAuth!.signOut()
        }else{
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
            try! Helpers().firAuth!.signOut()
        }
        performSegue(withIdentifier: "newUserLogin", sender: self)
    }
    
//    @IBAction func LogoutButton(_ sender: UIButton) {
//        //code to force logout
//        //If current user is an email user I need to log out of Firebase
//        if((self.providerId ?? "") == "password"){
//            try! Helpers().firAuth!.signOut()
//        }else{
//            let loginManager = FBSDKLoginManager()
//            loginManager.logOut()
//        }
//        performSegue(withIdentifier: "newUserLogin", sender: nil)
//    }
    
    /*
    override func viewWillDisappear(_ animated: Bool) {
     //If i want to add the the FirAuth listener then I can remove it with this call:
        //        FIRAuth.auth()?.removeStateDidChangeListener(handle!)
    }*/
    
    // Unwind seque from my list
    @IBAction func unwindFromMyList(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    // Unwind seque from my Onboard process
    @IBAction func unwindFromFbLogin(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    // Unwind seque from my Check In VC
    @IBAction func unwindFromCheckIn(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    // Unwind seque from my CheckOutVC
    @IBAction func unwindFromCheckOut(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    // Unwind seque from my CheckOutVC
    @IBAction func unwindFromProfile(_ sender: UIStoryboardSegue) {
        // empty
    }

}
