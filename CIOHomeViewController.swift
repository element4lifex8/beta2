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

class CIOHomeViewController: UIViewController   {

    
    //Get firebase auth reference, nil if user signed in with FaceBook (Or no signed in at all)
//    let firAuth = FIRAuth.auth()
    //Listener returned on firAuth block
    var handle:FIRAuthStateDidChangeListenerHandle?
    
    var providerId: String?     //Extract the type of auth process that was used
    
    
    //Check if user has logged in and force login if not, modal segues must be performed in viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        //Check if the user needs to be logged up pending new update
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
        if ((FBSDKAccessToken.current() == nil) && (Helpers().firAuth?.currentUser == nil /*&& (self.providerId ?? "") == "password")*/))
        {
            self.performSegue(withIdentifier: "LoginScreen", sender: nil)
        }else if(shouldLogout == 1){//The NSUserDefault shouldLogut is also checked if the user needs to be forced to login again
            //Update logout Default so the user no longer has to logout 
            Helpers().logoutDefault = 0
            LogoutButton(UIButton())
        }
        
        
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    func getFIRLoginState(_ completionClosure: @escaping ( _ loggedIn: Bool) -> Void){
        //get firebase user and see if they are logged in
        var firebaseLoggedIn = false
        self.handle = Helpers().firAuth?.addStateDidChangeListener {auth, user in
            if let user = user{
                print(user.uid)
                firebaseLoggedIn = true
            }else{
                //user is not logged in
                firebaseLoggedIn = false
            }
            completionClosure(firebaseLoggedIn)
        }

    }
    
    @IBAction func LogoutButton(_ sender: UIButton) {
        //code to force logout
        //If current user is an email user I need to log out of Firebase
        if((self.providerId ?? "") == "password"){
            try! Helpers().firAuth!.signOut()
        }else{
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
        }
        performSegue(withIdentifier: "LoginScreen", sender: nil)
    }
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
