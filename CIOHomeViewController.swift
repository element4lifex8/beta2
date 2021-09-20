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
    var handle:AuthStateDidChangeListenerHandle?
    
    var providerId: String?     //Extract the type of auth process that was used
    
    var noteView = UIView()
    
    //Profile information views
    @IBOutlet weak var checkInInfoView: UIView!
    @IBOutlet weak var followingInfoView: UIView!
    @IBOutlet weak var followersInfoView: UIView!
    
    
    //Profile info numbers
    @IBOutlet weak var checkInNumLabel: UILabel!
    @IBOutlet weak var followerNumLabel: UILabel!
    @IBOutlet weak var FollowingNumLabel: UILabel!
    
    
    //Check if user has logged in and force login if not, modal segues must be performed in viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        let currUser = Helpers().currUser
        let friendsRef = Database.database().reference().child("users/\(currUser)/friends")
        var currentlyDisplaying = 0
        
        super.viewDidAppear(animated)
        let onboardingCompleted = Helpers().onboardCompleteDefault
        //Check if the user needs to be logged out pending new update
        let shouldLogout = Helpers().logoutDefault
        let providerData = Helpers().firAuth.currentUser?.providerData
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
        if ((FBSDKAccessToken.current() == nil) && (Helpers().firAuth.currentUser == nil /*&& (self.providerId ?? "") == "password")*/))
        {
            self.performSegue(withIdentifier: "newUserLogin", sender: self)
        }else if(shouldLogout == NSNumber(value: 1) || onboardingCompleted == NSNumber(value: 0) ){//The NSUserDefault shouldLogut is also checked if the user needs to be forced to login again (will force logout if onboarding not completed either
            //Update logout Default so the user no longer has to logout
            Helpers().logoutDefault = 0
//            LogoutButton(UIButton())  Button no longer exists on home screen
            logoutUser()
        }
        
        //Calculate the number of user check-ins, number of followers and followed friends if not already stored in user defaults
        
        //Make sure the User defaults is current and update if not, then re print
        self.FollowingNumLabel.text = "\(Helpers().numFriendsDefault)"
        self.followerNumLabel.text = "\(Helpers().numFollowersDefault)"
        self.checkInNumLabel.text = "\(Helpers().numCheckInDefault)"

        //Check if any of the currently listed defaults are invalid and update
        if(Helpers().numCheckValDefault == NSNumber(value:0)){  //Need to divorce line 160 on MyList VC where this is set, and set in helpers
             Helpers().retrieveCheckInCount(currUser: currUser) {(checkInCount:Int) in
                Helpers().numCheckInDefault = NSNumber(value: checkInCount)
                self.checkInNumLabel.text = "\(checkInCount)"
            }
            //set the current flag on the home screen status counts
            Helpers().numCheckValDefault = 1
        }
        
        if(Helpers().numFriendValDefault == NSNumber(value:0)){
            Helpers().retrieveMyFriends(friendsRef: Database.database().reference().child("users/\(Helpers().currUser as String)/friends")) {(friendStr:[String], friendId:[String]) in
                //Keep track of the number of user's friends in firebase each time they are retrieved
                Helpers().numFriendsDefault = NSNumber(value: friendStr.count)
                self.FollowingNumLabel.text = "\(Helpers().numFriendsDefault)"
            }
            Helpers().numFriendValDefault = 1
        }
        
        if(Helpers().numFollowerValDefault == NSNumber(value:0)){//Need to divorce from line 54 of Followers VC and add to helpers
            FollowersViewController().retrieveFollowersFromFirebase{(finished:Bool, friendCount: Int) in

                //Check if a new follower was found and add notification flag
                if(Helpers().numFollowersDefault.compare(NSNumber(value: friendCount)) == .orderedAscending)
                {
                    //print("disp foll: \(Helpers().displayFollowersNote)")
                    Helpers().displayFollowersNote = 1
                    //print("disp foll: \(Helpers().displayFollowersNote)")
                }
                //Update number of followers in user defaults
                Helpers().numFollowersDefault = NSNumber(value: friendCount)
                //Display the new follower notification on activivation of observer
                if(Helpers().displayFollowersNote == NSNumber(value: 1)){
                    Helpers().displayNewFollNote(display: true, superView:  self.followersInfoView, noteView:  &self.noteView)
                }
                
                //Update home screen
                self.followerNumLabel.text = "\(friendCount)"
            }
            Helpers().numFollowerValDefault = 1
        }

        //For the new follower notification on first display of home screen
//        if(Helpers().displayFollowersNote == NSNumber(value: 1)){
//            if(currentlyDisplaying == 0){
//                Helpers().displayNewFollNote(display: true, superView:  self.followersInfoView, noteView:  &self.noteView)
//                currentlyDisplaying = 1
//            }

        //Remove notifiation of new follower
    if(Helpers().displayFollowersNote == NSNumber(value: 0)){
        if(self.followersInfoView.subviews.contains(noteView)){
            Helpers().displayNewFollNote(display: false, superView:  self.followersInfoView, noteView:  &self.noteView)
        }
    }
       
        //Add gesture recognizer to allowing clicking on following/followers and transition to that screen
        let followingTapGesture = UITapGestureRecognizer(target: self, action: #selector(CIOHomeViewController.tapFollowingView(_:)))
        
        //Make sure gesture recognizer is added after the view frame has been created otherwise the event won't be triggered since it won't have a frame to receieve the touch
        self.followingInfoView.addGestureRecognizer(followingTapGesture)
        
        let followerTapGesture = UITapGestureRecognizer(target: self, action: #selector(CIOHomeViewController.tapFollowerView(_:)))
        
        //Make sure gesture recognizer is added after the view frame has been created otherwise the event won't be triggered since it won't have a frame to receieve the touch
        self.followersInfoView.addGestureRecognizer(followerTapGesture)
        
        let checkInTapGesture = UITapGestureRecognizer(target: self, action: #selector(CIOHomeViewController.tapCheckInView(_:)))
        
        //Make sure gesture recognizer is added after the view frame has been created otherwise the event won't be triggered since it won't have a frame to receieve the touch
        self.checkInInfoView.addGestureRecognizer(checkInTapGesture)
        
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"FBSDKAccessTokenDidChangeNotification"),
            object:nil, queue:OperationQueue.main, using: { notification in
                
            if ((notification.userInfo?[FBSDKAccessTokenDidChangeUserID] ?? NSNumber(booleanLiteral: false)) as! NSNumber == NSNumber(booleanLiteral: true)) {
                // Update facebook user id in backend when user id changed
                let ref = Database.database().reference(withPath:"users")
                ref.child(Helpers().currUser as String).updateChildValues(["facebookid" : "\(Helpers().FBUserId)"])
                }
            })
    
    }
    
    func getFIRLoginState(_ completionClosure: @escaping ( _ loggedIn: Bool) -> Void){
        //get firebase user and see if they are logged in
        var firebaseLoggedIn = false
        self.handle = Helpers().firAuth.addStateDidChangeListener {auth, user in
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
    
    @objc func tapCheckInView(_ sender: UITapGestureRecognizer)
    {
        self.performSegue(withIdentifier: "segueToCheckIns", sender: self)
    }
    
    @objc func tapFollowerView(_ sender: UITapGestureRecognizer)
    {
        self.performSegue(withIdentifier: "segueToFollowers", sender: self)
    }
    
    @objc func tapFollowingView(_ sender: UITapGestureRecognizer)
    {
        self.performSegue(withIdentifier: "segueToFriends", sender: self)
    }
    
    //Logout button no longer exists, code moved to logoutFunc
    func logoutUser(){
//        If current user is an email user I need to log out of Firebase
        if((self.providerId ?? "") == "password"){
            try! Helpers().firAuth.signOut()
        }else{
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
            try! Helpers().firAuth.signOut()
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

    // Unwind seque from my CheckOutVC
    @IBAction func unwindFromFollowers(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    // Unwind seque from my CheckOutMapView
    @IBAction func unwindFromMapCheckOut(_ sender: UIStoryboardSegue) {
        // empty
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Check if transitioning to check out screen and if doing so from add friends button
        if(segue.identifier == "segueToFriends")
        {
            let destinationVC = segue.destination as! CheckOutContainedViewController
            destinationVC.callerWantsToShowPeople = true
        }
        //Check if transitioning to check out Map screen and if doing so from add slider button
        else if(segue.identifier == "segueToCOMap"){
                let destinationVC = segue.destination as! MapVC
                destinationVC.callerWantsCheckOut = true
        }
    }
    
    //Set status bar text color
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
}
