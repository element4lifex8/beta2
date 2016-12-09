//
//  FBlogin.swift
//  Beta2
//
//  Created by Jason Johnston on 12/19/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class FBloginViewController: UIViewController, FBSDKLoginButtonDelegate {

    let currUserDefaultKey = "FBloginVC.currUser"
    fileprivate let sharedFbUser = UserDefaults.standard
    
    @IBAction func homeButt(_ sender: UIButton) {
        performSegue(withIdentifier: "goHome", sender: nil)
    }
    var currUser: NSString {
        get
        {
            return (sharedFbUser.object(forKey: currUserDefaultKey) as? NSString)!
        }
        set
        {
            sharedFbUser.set(newValue, forKey: currUserDefaultKey)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        print("FB login entered")
        //check for an existing token at load.
        if (FBSDKAccessToken.current() == nil)
        {
            print("Not logged in..")
            //Add facebook login button to center of view
            let loginView : FBSDKLoginButton = FBSDKLoginButton()
            self.view.addSubview(loginView)
            loginView.center = self.view.center
            loginView.readPermissions = ["public_profile", "email", "user_friends"]
            loginView.delegate = self
        }
        //If token exist, user had already logged in, seque to CIO Home
        else
        {
            print("Token existed when it shouldn't have..")
            /*print( FBSDKAccessToken.currentAccessToken().tokenString!)
            let request = FBSDKGraphRequest(graphPath:"/me/friends", parameters: nil) //["fields" : "email" : "name"]);
        
            request.startWithCompletionHandler
            {
                (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error == nil
                {
                    //print friend boken
                    let resultdict = result as! NSDictionary
                    let data : NSArray = resultdict.objectForKey("data") as! NSArray
                    print("data \(data)")
                    for i in 0..<data.count
                    {
                        let valueDict : NSDictionary = data[i] as! NSDictionary
                        let id = valueDict.objectForKey("id") as! String
                        print("the id value is \(id)")
                        let fbFriendName = valueDict.objectForKey("name") as! String
                        print ("name \(fbFriendName)")
                    }
                }
                else
                {
                    print("Error Getting Friends \(error)");
                }
            }
            /*code to force logout
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()*/
            performSegueWithIdentifier("goHome", sender: nil)*/
            
        }

    }
    
    // Facebook Delegate Methods
    //func used to know if the user did login correctly and if they did you can grab their information.
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!){
        var existingUser = false
        
        if ((error) != nil)
        {
            print("Error occured during FB login: \(error)")
        }
        else if result.isCancelled
        {
            print("User canceled login, this needs to be handled")
        }
        else
        {
            let ref = Firebase(url: "https://check-inout.firebaseio.com")
            //use current access token from loggedd in user to pass to firebase's login auth func
            let accessToken = FBSDKAccessToken.current().tokenString
            ref?.auth(withOAuthProvider: "facebook", token: accessToken, withCompletionBlock: { error, authData in
                if error != nil
                {
                    print("Login failed \(error)")
                }
                else
                {
                    self.currUser = (authData?.providerData["id"] as? NSString)!
                    print("Logged in  \(self.currUser)")
                    //Check to see if user is new and has not been added to the user's list in Firebase
                    

                     /*TO update one field only:
                    let emailPath = "\(self.currUser)/email"
                    let email = (authData.providerData["email"] as? NSString)!
                    usersRef.updateChildValues([emailPath:email])*/
                    // Create a child path with a key set to the uid underneath the "users" node
                    // This creates a URL path like the following:
                    //  - https://<YOUR-FIREBASE-APP>.firebaseio.com/users/<uid>
                        
                    self.isCurrentUser() {(user: Bool) in
                        existingUser = user
                        if(!existingUser){
                            let newUser = ["displayName1": (authData?.providerData["displayName"] as? NSString)!,
                                "email": (authData?.providerData["email"] as? NSString)!]
                            ref?.child(byAppendingPath: "users").child(byAppendingPath: self.currUser as String).setValue(newUser)
                        }
                    }
                }
            })
        

            
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
            }
            self.performSegue(withIdentifier: "profileSteps", sender: nil)
        }
        
        
        /*let request = FBSDKGraphRequest(graphPath:"/me/friends", parameters: nil) //["fields" : "email" : "name"]);
        
        request.startWithCompletionHandler
            {
                (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error == nil
                {
                    //print friend boken
                    let resultdict = result as! NSDictionary
                    let data : NSArray = resultdict.objectForKey("data") as! NSArray
                    print("data \(data)")
                    for i in 0..<data.count
                    {
                        let valueDict : NSDictionary = data[i] as! NSDictionary
                        let id = valueDict.objectForKey("id") as! String
                        print("the id value is \(id)")
                        let fbFriendName = valueDict.objectForKey("name") as! String
                        print ("name \(fbFriendName)")
                    }
                }
                else
                {
                    print("Error Getting Friends \(error)");
                }
        }*/
        
    }
    
    func isCurrentUser(_ completionClosure: @escaping (_ isUser:  Bool) -> Void) {
        let ref = Firebase(url: "https://check-inout.firebaseio.com")
        var user = false
        
        ref?.child(byAppendingPath: "users").observeSingleEvent(of: .value, with: { snapshot in
            for child in (snapshot?.children)! {
                //Compare current logged in user to all users stored in the database (child.key is the user id #)
                if let childKey = (child as AnyObject).key{
                    //?is childkey a string?
                    if(childKey == self.currUser as String){
                        user = true
                    }
                }
            }
            completionClosure(user)
        })
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!)
    {
        print("User Logged Out")
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
