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
import FirebaseDatabase
import FirebaseAuth

class FBloginViewController: UIViewController, FBSDKLoginButtonDelegate {
    var unwindPerformed = false
    let currUserDefaultKey = "FBloginVC.currUser"
    fileprivate let sharedFbUser = UserDefaults.standard
    
    
    @IBAction func FacebookLoginButton(_ sender: UIButton) {
        let facebookLogin = FBSDKLoginManager()
        var existingUser = false
        var newUser: [String : String] = ["displayName" : "", "email" : "", "friends" : "true"]
        
        facebookLogin.logIn(withReadPermissions: ["public_profile", "email"], from: self, handler:{(facebookResult, facebookError) -> Void in
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
            } else if (facebookResult?.isCancelled)! {
                print("Facebook login was cancelled.")
            } else {
                
                //Show activity monitor while waiting
                let loadingView: UIView = UIView()
                
                loadingView.frame = CGRect(x: 0,y: 0,width: 80,height: 80)
                loadingView.center = self.view.center
                loadingView.backgroundColor = UIColor(red: 0x44/255, green: 0x44/255, blue: 0x44/255, alpha: 0.7)
                loadingView.clipsToBounds = true
                loadingView.layer.cornerRadius = 10
                //Start activity indicator while making google request
                let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50,  height: 50)) as UIActivityIndicatorView
                activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2,y: loadingView.frame.size.height / 2);
                activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
                activityIndicator.hidesWhenStopped = true
                
                loadingView.addSubview(activityIndicator)
                self.view.addSubview(loadingView)
                activityIndicator.startAnimating()
                
                let credential = FIRFacebookAuthProvider.credential(withAccessToken:  FBSDKAccessToken.current().tokenString)
                
                let authRef = FIRAuth.auth()
                //use current access token from logged in user to pass to firebase's login auth func
              
                authRef!.signIn(with: credential) { (user, error) in
                    if error != nil
                    {
                        print("Login failed \(error)")
                    }
                    else
                    {
                        //<<If not using provider data then "facebook" is appended prior to uid
//                        if let userId = user?.uid{
//                            //user credential now has the string "facebook:" inserted before the facebook id
//                            guard let beginIdx = userId.characters.index(of: ":") else{
//                                print("Malformed facebook user id string: \(userId)")
//                                return
//                            }
//                          
//                            self.currUser = userId.substring(from: userId.index(after: beginIdx)) as NSString
//                            print("Logged in \(self.currUser)")
//                        }else{
//                            print("Facebook user id not provided, login unsuccessful")
//                        }
                        //Check to see if user is new and has not been added to the user's list in Firebase
                        
                        
                        /*TO update one field only:
                         let emailPath = "\(self.currUser)/email"
                         let email = (authData.providerData["email"] as? NSString)!
                         usersRef.updateChildValues([emailPath:email])*/
                        // Create a child path with a key set to the uid underneath the "users" node
                        // This creates a URiL path like the following:
                        //  - https://<YOUR-FIREBASE-APP>.firebaseio.com/users/<uid>
                        
                        //Provider data is an optional array, unwrap the optional then iterate over the 1 expected array entry to gather uid, displayName, and email parameters
                        if let providerData = user?.providerData {
                            //The entry will contain the following items: providerID (facebook.com), userId($uid), displayName (from facebook), photoURL(also from FB), email
                            for entry in providerData{  //Expect only 1 entry
                                self.currUser = entry.uid as NSString
                                newUser = ["displayName1": (entry.displayName)!,
                                               "email": (entry.email)!, "friends" : "true"]
                            }
                            
                        }
                        self.isCurrentUser() {(isUser: Bool) in
                            existingUser = isUser
                            if(!existingUser){
                                let ref = FIRDatabase.database().reference(withPath:"users")
                                //Append user id as root of node and newUser dict nested beneath
                                ref.child(self.currUser as String).setValue(newUser)
                            }
                        }
                        
                        // If you ask for multiple permissions at once, you
                        // should check if specific permissions missing
                        if (facebookResult?.grantedPermissions.contains("email"))!
                        {
                            // Do work
                        }
                        
                        activityIndicator.stopAnimating()
                        loadingView.removeFromSuperview()
//                        self.performSegue(withIdentifier: "profileSteps", sender: nil)
                    }
                }
            }
        })

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
    
    //ViewDidAppear will be called after returning from the FBSDKContainerVC where the user logins in 
     override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Don't segue to profile steps if performing an unwind
        if (FBSDKAccessToken.current() != nil && !unwindPerformed){
           self.performSegue(withIdentifier: "profileSteps", sender: nil)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        //check for an existing token at load.
        if (FBSDKAccessToken.current() == nil)
        {
//            print("Not logged in..")
            //Add facebook login button to center of view
//            let loginView : FBSDKLoginButton = FBSDKLoginButton()
//            self.view.addSubview(loginView)
//            loginView.center = self.view.center
//            loginView.readPermissions = ["public_profile", "email", "user_friends"]
//            loginView.delegate = self
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
    
    
    //<<Unused function that would add the default facebook login icon>>
    // Facebook Delegate Methods
    //func used to know if the user did login correctly and if they did you can grab their information.
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!){
        var existingUser = false
        let ref = FIRDatabase.database().reference()
        let facebookLogin = FBSDKLoginManager()
        
//        if ((error) != nil)
//        {
//            print("Error occured during FB login: \(error)")
//        }
//        else if result.isCancelled
//        {
//            print("User canceled login, this needs to be handled")
//        }
//        else
//        {
            //Old Firebase code
            //            let ref = Firebase(url: "https://check-inout.firebaseio.com")
            //              let accessToken = FBSDKAccessToken.current().tokenString
            //FIRAuth.auth()!.signIn(withOAuthProvider: "facebook", token: accessToken, withCompletionBlock: { error, authData in
        facebookLogin.logIn(withReadPermissions: ["public_profile", "email"], from: self, handler:
        {(facebookResult, facebookError) -> Void in
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
            } else if (facebookResult?.isCancelled)! {
                print("Facebook login was cancelled.")
            } else {
                
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                let authRef = FIRAuth.auth()
                //use current access token from logged in user to pass to firebase's login auth func

                authRef!.signIn(with: credential) { (user, error) in
                    if error != nil
                    {
                        print("Login failed \(error)")
                    }
                    else
                    {
                        //save user's id to NSUser defaults
                        self.currUser = user!.uid as NSString
                        print("Logged in  \(self.currUser)")
                        //Check to see if user is new and has not been added to the user's list in Firebase
                        

                         /*TO update one field only:
                        let emailPath = "\(self.currUser)/email"
                        let email = (authData.providerData["email"] as? NSString)!
                        usersRef.updateChildValues([emailPath:email])*/
                        // Create a child path with a key set to the uid underneath the "users" node
                        // This creates a URiL path like the following:
                        //  - https://<YOUR-FIREBASE-APP>.firebaseio.com/users/<uid>
                            
                        self.isCurrentUser() {(isUser: Bool) in
                            existingUser = isUser
                            if(!existingUser){
                                let newUser = ["displayName1": (user?.displayName)!,
                                               "email": (user?.email)!, "friends:" : "true"]
                                ref.child(byAppendingPath: "users").child(byAppendingPath: self.currUser as String).setValue(newUser)
                            }
                        }
                        
                        // If you ask for multiple permissions at once, you
                        // should check if specific permissions missing
//                        if result.grantedPermissions.contains("email")
//                        {
//                            // Do work
//                        }
                        self.performSegue(withIdentifier: "profileSteps", sender: nil)
                    }
                }
            }
        })
    
        
        
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
    
    /* to do : just make a reference to the user's facebook id and try to get data from that ref in firebase, if it fails then isUser returns with a value of false*/
    func isCurrentUser(_ completionClosure: @escaping (_ isUser:  Bool) -> Void) {
//        let ref = Firebase(url: "https://check-inout.firebaseio.com")
        //"as" without !? can only be used when the compiler knows the cast will always work, like from NSString to string
        let userRef = FIRDatabase.database().reference(withPath: "users").child(self.currUser as String)
        var user = false
        
        userRef.observeSingleEvent(of: .value, with: { snapshot in
            
            
            //Previously I would loop over all users to compare if the curr user existed

            let rootNode = snapshot as FIRDataSnapshot
            //force downcast only works if root node has children, otherwise value will only be a string
            
            //If we have no children then its most certain that the current user doesn't exist
            if let nodeDict = rootNode.value as? NSDictionary{
                user = true
                //No longer need to check for user's string in firebase, we can be certain that the user either doesn't exist or its current entry is malformed if the above downcast fails
//                //Loop over each check in Place and parse its attributes
//                for (key, _ ) in nodeDict{
//                //Compare current logged in user to all users stored in the database (child.key is the user id #)
//                
//                    //?is childkey a string?
//                    if(key as! NSString == self.currUser){
//                        user = true
//                    }
//                }
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
    
    // Unwind seque always bypassed and return to CIO Home
    @IBAction func unwindToStartFbLogin(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        //Check if unwind segue was performed so that viewDidLoad can guard against seguing to profile steps on an unwind
        unwindPerformed = true
        return false
    }
    
}
