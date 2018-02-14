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

class FBloginViewController: UIViewController, UITextFieldDelegate{
    var unwindPerformed = false
//    let currUserDefaultKey = "FBloginVC.currUser"
//    fileprivate let sharedFbUser = UserDefaults.standard
    let authRef = FIRAuth.auth()

    var userEmail: String?
    var userPassword: String?
    var userFullName: String?
    var betaUser: Bool?     //Force facebook beta users to transition to login details for release 1.1.3
    
    @IBOutlet var scrollView: UIScrollView!
    var activeTextField: UITextField? = nil
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    //Get reference to button for size
    @IBOutlet var loginButtOut: UIButton!
    
    var loginType: Helpers.userType?    //Keep track of what type of login the user has performed
    
    //Calculate the size of the text box I want to move above the keyboard
    var textBoxSize: CGFloat = 0
    //Define the current text box spacing so that is also displayed above keyboard
    var textBoxSpacing: CGFloat = 20.0
    //Calculate the size of the 2 text boxs I want to move above the keyboard
    var emailAndPassSize: CGFloat = 0
    //Calculate the size of the password text box and the submit button I want to move above the keyboard
    var passAndSubmitSize: CGFloat = 0
    
    
//    var currUser: NSString {
//        get
//        {
//            return (sharedFbUser.object(forKey: currUserDefaultKey) as? NSString)!
//        }
//        set
//        {
//            sharedFbUser.set(newValue, forKey: currUserDefaultKey)
//        }
//    }
    
    @IBAction func FacebookLoginButton(_ sender: UIButton) {
        //Moved instantiation to present activity monitor before calling facebook manager to check login capabilities
//        let facebookLogin = FBSDKLoginManager()

        var loginFinished = false    //keep track of whether the user has previously logged in, will use this to determine if I can automatically segue to the next screen
        var existingUser = false    //Keep track of whether this is a new user so we know to get additional info
        var shouldUpdate = false    //Will check if the user is a Beta user who is currently using the facebook id and needs to update to firebase id
        
        //variables for saving FB info to firebase
        var emailFB = "", nameFB = "", friendsFB = "true"
        
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
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logIn(withReadPermissions: ["public_profile", "user_friends", "email"], from: self, handler:{(facebookResult, facebookError) -> Void in
            if facebookError != nil {
                Helpers().myPrint(text: "Facebook login failed. Error \(facebookError)")
                self.loginFailMsg(error: "fail")         //Notify user that login failed
                activityIndicator.stopAnimating()
                loadingView.removeFromSuperview()
            } else if (facebookResult?.isCancelled)! {
                Helpers().myPrint(text: "Facebook login was cancelled.")
                self.loginFailMsg(error: "cancel")         //Notify user that login was canceled
                activityIndicator.stopAnimating()
                loadingView.removeFromSuperview()
            } else {    
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                
                //use current access token from logged in user to pass to firebase's login auth func
              
                Helpers().firAuth?.signIn(with: credential) { (user, error) in
                    if error != nil
                    {
                        Helpers().myPrint(text: "Login failed \(error)")
                        self.loginFailMsg(error: "auth")         //Notify user that login failed
                        activityIndicator.stopAnimating()
                        loadingView.removeFromSuperview()
                    }
                    else
                    {
                        
                        // Check if any of the permissions are missing and notify accordingly
                        // Write revoked to firebase for later handling if grantedPermissions returns false or nil
                        if !(facebookResult?.grantedPermissions.contains("email") ?? false)
                        {
                            emailFB = "revoked"
                        }
                        if !(facebookResult?.grantedPermissions.contains("user_friends") ?? false)
                        {
                            friendsFB = "revoked"
                        }
                        if let authUser = self.authRef?.currentUser{
                           
                            Helpers().currUser = authUser.uid as NSString
                            //facebook doesn't provide an email if the user logged in with phone number
                            if let email = authUser.email{
                                self.userEmail = email
                            }
                            //The display name is not provided if a user revoked public_profile permissions
                            if let nameWrap = authUser.displayName {
                                self.userFullName = nameWrap
                            }

                            Helpers().myPrint(text: "\(authUser.uid)")
                            Helpers().myPrint(text: "\(authUser.email)")//If email is empty then user logged in with phone #
                            Helpers().myPrint(text: "\(authUser.displayName)")
                        }
                        
                        //Check to see if user is new and has not been added to the user's list in Firebase
                        
                        //Previously used Facebook's explicitly returned object to get user info, now using Firebase object per above code, but for supporting legacy beta users get the facebook id too
                        //Provider data is an optional array, unwrap the optional then iterate over the 1 expected array entry to gather uid, displayName, and email parameters
                        if let providerData = user?.providerData {
//                            //The entry will contain the following items: providerID (facebook.com), userId($uid), displayName (from facebook), photoURL(also from FB), email
                            for entry in providerData{  //Expect only 1 entry
                                Helpers().prevUser = entry.uid as NSString
                                Helpers().myPrint(text: "\(Helpers().prevUser)")
//                                //sometimes facebook doesn't provide an email
//                                if let emailWrap = entry.email {
//                                    emailFB = emailWrap
//                                    self.userEmail = emailWrap
//                                }
//                                //The display name is not provided if a user revoked public_profile permissions
//                                if let nameWrap = entry.displayName {
//                                    nameFB = nameWrap
//                                    self.userFullName = nameWrap
//                                }
                            }
                        }
                        
                
                        
                        self.isCurrentUser() {(isUser: Bool, requiresUpdate: Bool) in
                            existingUser = isUser
                            shouldUpdate = requiresUpdate
                      
                            activityIndicator.stopAnimating()
                            loadingView.removeFromSuperview()

                            //Keep track of current logintype, it is stored in user defaults for new users in the onboard info VC
                            self.loginType = Helpers.userType.facebook
                            //Transition to loginInfo screen for new user or skip onboarding for existing user
                            //For beta I check if their back end details are current and if not I set betaUser = true and transition to onboard details
                            if(existingUser  && !(self.betaUser ?? false)){
                                //If the user is not having to create a username make sure I save their login type to NS Defaults with this VC
                                Helpers().loginType = self.loginType!.rawValue
                                  //The user has the old facebook id and I need to update the backend with the firebase id, and then transition to home screen
                                if(shouldUpdate){
                                    //Use completion closure to stop return from function until async calls finish
                                    self.updateUserId() {(_: Bool) in
                                        self.performSegue(withIdentifier: "unwindLogin4CurrUser", sender: nil)
                                    }
                                }else{
                                    self.performSegue(withIdentifier: "unwindLogin4CurrUser", sender: nil)
                                }
                            }else{
                                //If old beta user I still want to update ID but then also transition to retrieve new user name
                                if(shouldUpdate){
                                    //Use completion closure to stop return from function until async calls finish
                                    self.updateUserId() {(_: Bool) in
                                        self.performSegue(withIdentifier: "loginInfo", sender: nil)
                                    }
                                }else{
                                    self.performSegue(withIdentifier: "loginInfo", sender: nil)
                                }
                            }
                        }
                    }
                }
            }
        })

    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        var loadingView: UIView = UIView()
        var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50,  height: 50)) as UIActivityIndicatorView
        var errorName = "unknown"
        var errorDesc = ""
        //Show activity monitor while waiting
        Helpers().displayActMon(display: true, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
        
        //Disable the login button from being double pressed:
        loginButtOut.isEnabled = false
        
        //Hide keyboard
        self.activeTextField?.resignFirstResponder()
        
        //Unwrap text boxes
        guard let email = self.emailField.text, let password = self.passwordField.text else{
            Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
            loginFailMsg(error: "missing")
            return
        }
        
        //Empty email or password
        if(email.isEmpty || password.isEmpty){
            Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
            loginFailMsg(error: "missing")
            //Re-enable the login button so they can try again
            loginButtOut.isEnabled = true
        }else{
        
            //Check if user is new or needs to be created
            Helpers().emailCheck(email: email){(type: Helpers.userType, username: NSString, displayName: NSString) in
                switch(type){
                case(.facebook):
                    //notify user to login with FB
                    self.loginFailMsg(error: "facebook")
                    Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                    //Re-enable the login button so they can try again
                    self.loginButtOut.isEnabled = true
                    break
                case(.email):
                    //Attempt Login with email
                    Helpers().firAuth!.signIn(withEmail: email, password: password) { (user, error) in
                        
                        if(error != nil){
                            if let errorNS = error as NSError?{ //Cast to NSError so I can retrieve components
                                let errorDict = errorNS.userInfo as NSDictionary   //User info dictionary provided by firebase with additional error info
                                if let errorStr = errorDict[FIRAuthErrorNameKey] as? String{
                                    //error object provided a specific error name
                                    errorName = errorStr
                                }
                                switch(errorName){  //"define for "error_name"
                                case("ERROR_INVALID_EMAIL"):
                                    errorDesc = "emailForm"
                                    break
                                case("ERROR_USER_NOT_FOUND"):
                                    errorDesc="noUser"
                                    break
                                case("ERROR_WRONG_PASSWORD"):
                                    errorDesc="password"
                                    self.passwordField.text = nil
                                    break
                                default:
                                    Helpers().myPrint(text: "Firebase error unknown, review NSUnderlyingErrorKey for more info")
                                    //Use firebase error info to notify the user
                                    if let localDesc = errorDict["NSLocalizedDescription"] as? String{
                                        errorDesc = localDesc
                                    }else{
                                        errorDesc = "A General Error Occured with the email login"
                                    }
                                    break
                                }
                                self.loginFailMsg(error: errorDesc)
                                //Re-enable the login button so they can try again
                                self.loginButtOut.isEnabled = true
                            }else{  //Casting to NS error failed
                                errorDesc = "A General Error Occured with the email login"
                                self.loginFailMsg(error: errorDesc)
                            }
                            Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                            //Re-enable the login button so they can try again
                            self.loginButtOut.isEnabled = true
                        }else{  //No error found, login existing user complete
                            self.loginType = Helpers.userType.email
                            //Update login type to user defaults since i'm logging in, new users update this item in NSDefaults in the Onboard details VC
                            Helpers().loginType = self.loginType!.rawValue
                            Helpers().currUser = user?.uid as! NSString
                            Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                        
                            //Also need to update the username & display name in User defaults in case this is a new install or a different user from the last login
                            Helpers().currUserName = username
                            Helpers().currDisplayName = displayName
                            
                            //Succesfully finished this screen, existing user so skip onboarding
                            self.performSegue(withIdentifier: "unwindLogin4CurrUser", sender: nil)
                        }
                    }
                    break
                case(.new):
                    //Now that we have an additional login details screen the new user sign with Firebase is moved to the onBoardDetailsViewController
                    //Disable activity monitor
                    Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                    
                    //Quick and dirty check of email format
                    //Match any char up to @, match at least 1 char before and after the "."
                    if let _ = email.range(of: ".*@.+\\..+", options: .regularExpression) {
                        //make sure password is at least 6 characters
                        if(password.characters.count >= 6){
                            self.userEmail = email
                            self.userPassword = password
                            //Keep track of login type:
                            self.loginType = Helpers.userType.new
                            //Succesfully finished this screen, now get user Info and username at loginInfo screen
                            self.performSegue(withIdentifier: "loginInfo", sender: nil)
                        }else{
                            self.loginFailMsg(error: "weak_password")
                            self.loginButtOut.isEnabled = true
                        }
                    }else{
                        self.loginFailMsg(error: "emailForm")
                        self.loginButtOut.isEnabled = true
                    }
                    break
                }   //end switch
                
            }   //end completion email check closure
        }
    }
    
    //ViewDidAppear will be called after returning from the FBSDKContainerVC where the user logins in 
     override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.emailAndPassSize =  passwordField.frame.height + emailField.frame.height
        self.passAndSubmitSize = passwordField.frame.height + loginButtOut.frame.height
        self.textBoxSize = passwordField.frame.height + self.textBoxSpacing
        //Don't segue to profile steps if performing an unwind
//        if (FBSDKAccessToken.current() != nil && !unwindPerformed){
//           self.performSegue(withIdentifier: "profileSteps", sender: nil)
//        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        //Set text field delegates so they can dismiss the keyboard
        self.emailField.delegate = self
        self.passwordField.delegate = self

        //register so that I receive notifications from the keyboard
        registerForKeyboardNotifications()
        
        //Setup Tap gesture so clicking outside of textbox dismisses keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FBloginViewController.tapDismiss(_:)))
        scrollView.addGestureRecognizer(tapGesture)
        
        //check for an existing token at load.
        if (FBSDKAccessToken.current() == nil)
        {
            Helpers().myPrint(text: "Not logged in..")
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
            Helpers().myPrint(text: "Token existed when it shouldn't have..")
            /*print( FBSDKAccessToken.currentAccessToken().tokenString!)
            let request = FBSDKGraphRequest(graphPath:"/me/friends", parameters: nil) //["fields" : "email" : "name"]);
        
            request.startWithCompletionHandler
            {
                (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error == nil
                {
                    //print friend token
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
    
    //Send email to user to reset password
    @IBAction func forgotPassword(_ sender: Any) {
        var errorDesc = "A General Error Occured with the email login"
        guard let email = self.emailField.text else{
            loginFailMsg(error: "missing_email")
            return
        }
        Helpers().firAuth!.sendPasswordReset(withEmail: email) { error in
            if(error != nil){
                if let errorNS = error as NSError?{ //Cast to NSError so I can retrieve components
                    let errorDict = errorNS.userInfo as NSDictionary   //User info dictionary provided by firebase with additional error info
                    Helpers().myPrint(text: "Firebase error unknown, review NSUnderlyingErrorKey for more info")
                    //Use firebase error info to notify the user
                    if let localDesc = errorDict["NSLocalizedDescription"] as? String{
                        errorDesc = localDesc
                    }
                }
                self.loginFailMsg(error: errorDesc)
            }else{
                self.loginFailMsg(error: "forgot_password")
            }
        }
    }
    
    
    //Present alert when facebook login canceled/failed
    func loginFailMsg(error: String) -> Void{
        var msgTitle = ""
        var msgBody = ""
        
        switch(error){
        case "cancel":
            msgTitle = "Facebook Login Canceled"
            msgBody = "Whoops, you canceled the Facebook login before it was completed. Please try again."
            break
        case "fail":
            msgTitle = "Facebook Login Failed"
            msgBody = "We're sorry, it looks like your Facebook login failed. Please try again or contact tech support: jason@checkinoutlists.com"
            break
        case "auth":
            msgTitle = "Facebook account not recognized"
            msgBody = "It appears that this Facebook account is not recognized by Check In Out. Please contact tech support: jason@checkinoutlists.com"
            break
        case "emailForm":
            msgTitle = "Email Format Invalid"
            msgBody = "An invalid email address was entered. Please check for typos in your email and ensure it is a valid email address."
            break
        case "missing":
            msgTitle = "Missing Login Details"
            msgBody = "Please provide an email and a password to proceed"
            break
        case "missing_email":
            msgTitle = "Reset password for email"
            msgBody = "Please provide the email for the account that needs a password reset."
            break
        case "password":
            msgTitle = "Incorrect Password"
            msgBody = "Password for this email addess is incorrect. Please try again."
            break
        case "weak_password":
            msgTitle = "Weak Password"
            msgBody = "Please choose a stronger password to create an account. Password must be at least 6 characters."
            break
        case "facebook":
            msgTitle = "Email linked to Facebook Account"
            msgBody = "This email is linked to a Facebook account, please log in using Facebook."
            break
        //Occurs when the user is in the back end but they are not signed up under Firebase Auth
        case "noUser":
            msgTitle = "Unauthenicated Account "
            msgBody = "Your Check In Out account info for this email is outdated. Please contact technical support at jason@checkinoutlists.com or create a new account with a different email address."
            break
        case "email_in_use":
            msgTitle = "Email Address Taken"    //Happens with the backend doesn't have the user but the firebase auth already has them
            msgBody = "Your Check In Out account info for this email is outdated. Please contact technical support at jason@checkinoutlists.com or create a new account with a different email address."
            break
        case "forgot_password":
            msgTitle = "Forgotten Password"
            msgBody = "Email sent to reset password."
            break
        default:
            msgTitle = "Login Failed"
            msgBody = error
            break
        }
        let alert = UIAlertController(title: msgTitle, message: msgBody, preferredStyle: .alert)
        //Async call for uialertview will have already left this function, no handling needed
        let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        
        alert.addAction(CancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    //Check if the current user is a facebook user
    //As of build 1.1.6 started migrating Facebook id of users over to firebase id
    func isCurrentUser(_ completionClosure: @escaping (_ isUser:  Bool, _ requiresUpdate: Bool) -> Void) {
        //Dispatch group used to sync firebase and facebook api call
        var myGroup = DispatchGroup()
        //Async queue for synchronization
        let queue = DispatchQueue(label: "com.checkinoutlists.checkinout.isCurrentUser", attributes: .concurrent, target: .main)
        
        //"as" without !? can only be used when the compiler knows the cast will always work, like from NSString to string
        let prevUserRef = FIRDatabase.database().reference(withPath: "users").child(Helpers().prevUser as String)
         let userRef = FIRDatabase.database().reference(withPath: "users").child(Helpers().currUser as String)
        var user = false, shouldUpdate = false
        
        //Create async group so I don't call completion closure til both calls are done
        queue.async(group: myGroup) {
            myGroup.enter()
            userRef.observeSingleEvent(of: .value, with: { snapshot in
                
                
                //Previously I would loop over all users to compare if the curr user existed

                let rootNode = snapshot as FIRDataSnapshot
                //force downcast only works if root node has children, otherwise value will only be a string
                
                //If we have no children then its most certain that the current user doesn't exist
                if let nodeDict = rootNode.value as? NSDictionary{
                    user = true
                    //Check for beta users without current username
                    //In here i also store the user's display name and username in NS USer defaults if exists
                    self.checkForUsername(nodeDict: nodeDict)
                    
                }
                myGroup.leave()
            })
            
            myGroup.enter()
            prevUserRef.observeSingleEvent(of: .value, with: { snapshot in
                
                let rootNode = snapshot as FIRDataSnapshot
                //force downcast only works if root node has children, otherwise value will only be a string
                
                //If we have no children then its most certain that the user didn't exist under the facebook id
                if let nodeDict = rootNode.value as? NSDictionary{
                    shouldUpdate = true //found the user under the old id
                    //it is a current user and so I need to store their user name if it exists
                    user = true
                    //Check for beta users without current username
                    //In here i also store the user's display name and username in NS USer defaults if exists
                    self.checkForUsername(nodeDict: nodeDict)
                    
                }
                myGroup.leave()
            })

            
            //Fire async call once facebook api, and firebase calls have finish
            myGroup.notify(queue: DispatchQueue.main) {
                completionClosure(user, shouldUpdate)
            }
        }
        
    }
    
    //User had old facebook ID and I need to update all instances of this Id to firebase Id
    //Function will block until it is finished to wait before transitioning
    func updateUserId(_ completionClosure: @escaping (_ isFinished:  Bool) -> Void){
        let allUserRef = FIRDatabase.database().reference(withPath: "users")
        let prevUserRef = allUserRef.child(Helpers().prevUser as String)
        let userRef = allUserRef.child(Helpers().currUser as String)
        let placesRef = FIRDatabase.database().reference(withPath: "places")
        let prevCheckedRef = FIRDatabase.database().reference(withPath: "checked").child(Helpers().prevUser as String)
        let checkedRef = FIRDatabase.database().reference(withPath: "checked").child(Helpers().currUser as String)
        //Arrary of all of the ref's that a user's friends have to their old user name
        var friendsRefUpdate = [FIRDatabaseReference]()
        //Array of all the places that need the checked in user updated
        var placesRefUpdate = [FIRDatabaseReference]()
        var prevUserSnap: FIRDataSnapshot = FIRDataSnapshot()
        var prevCheckedSnap: FIRDataSnapshot = FIRDataSnapshot()
        
        
        var myGroup = DispatchGroup()
        
        //Async queue for synchronization
        // We create a new queue to do our work on, since calling wait() on
        // the semaphore will cause it to block the current queue
        //global queues: these are concurrent queues that are shared by the whole system so I won't block the main thread
        let queue = DispatchQueue(label: "com.checkinoutlists.checkinout.updateUserId", attributes: .concurrent, target: .global())
        
        
        //Sempaphore value is the "thread capacity" (the number of concurrent threads (of dispatch queues that can execute smultaneously on the given data 
        //The value is essentially a counter that let the Semaphore know how many threads can use its resource
        //Each time you wait on the semaphore, the dispatch_semaphore_wait function decrements that count variable by 1, if the result is negative it tells the kernel to block your thread
        //semaphore_signal function increments the count variable by 1
//        let semaphore = DispatchSemaphore(value: 0)
        
        //Start displaying activity indicator in main queue, so perform before entering global queue
        let loadingView = UIView()
        loadingView.frame = CGRect(x: 0,y: 0,width: 100,height: 100)
        loadingView.center = self.view.center
        loadingView.backgroundColor = UIColor(red: 0x44/255, green: 0x44/255, blue: 0x44/255, alpha: 0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50,  height: 50)) as UIActivityIndicatorView
        activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2,y: loadingView.frame.size.height / 2);
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.hidesWhenStopped = true
        loadingView.addSubview(activityIndicator)
        //Create label to add to view
        let loadingLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        loadingLabel.text = "Updating App"
        loadingLabel.font = UIFont(name: "Avenir-Heavy", size: 12)
        loadingLabel.textAlignment = .center
        loadingLabel.textColor = .white
        loadingView.addSubview(loadingLabel)
        //Create label for please wait
        let waitLabel = UILabel(frame: CGRect(x: 0, y: (loadingView.frame.size.height - 35 ), width: 100, height: 30))
        waitLabel.text = "Please Wait"
        waitLabel.font = UIFont(name: "Avenir-Heavy", size: 14)
        waitLabel.textAlignment = .center
        waitLabel.textColor = .white
        loadingView.addSubview(waitLabel)
        
        self.view.addSubview(loadingView)
        activityIndicator.startAnimating()
        
        //Start activity monitor and update block until completed by signaling semaphore
//        DispatchQueue.main.async {
        queue.async{
            
            //Retrieve the user's entire user data from checked and user refs
            myGroup.enter()
            prevUserRef.observeSingleEvent(of: .value, with: {
                snapshot in
                prevUserSnap = snapshot
                myGroup.leave()
            })

            myGroup.enter()
            prevCheckedRef.observeSingleEvent(of: .value, with: {
                snapshot in
                prevCheckedSnap = snapshot
                myGroup.leave()
            })
            
            //Retrieve all the user's friends that have a reference to their old user id
            myGroup.enter()
            allUserRef.queryOrdered(byChild: "friends").observeSingleEvent(of: .value, with: { snapshot in
                //One of the hits will be the user's own profile, the rest will be their friends with references to their user id
                for child in (snapshot.children) {    //each child should be a user's friend's id root node so I have to drill down to their friends
                    let rootNode = child as! FIRDataSnapshot
                    let nodeDict = rootNode.value as! NSDictionary
                    let friendUserId = rootNode.key as String
                
                    //Store the ref to the friends section of the curr user to be updated if that user is a friend
                    //Find the friends list under the each users data and compare them to the current user's previous ID
                    if let nodeDict = rootNode.value as? NSDictionary{
                        //Loop over all of the retrieved user's friends
                        for (key, value ) in nodeDict{
                            if(key as! NSString == "friends"){
                                if let friendDict = value as? NSDictionary{
                                    //loop over all the friends of this user
                                    for friend in friendDict.allKeys{
                                        //add the user's reference to update
                                        if (friend as! NSString == Helpers().prevUser){
                                            friendsRefUpdate.append(allUserRef.child("\(friendUserId)/friends"))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                myGroup.leave()
            })
            
            //Retrieve all the check ins from the "places" branch and create ref to the user's check ins
            myGroup.enter()
            //currently retrieving all of the places items and not just filtered by prev user
            placesRef.queryOrdered(byChild: "users").observeSingleEvent(of: .value, with: { snapshot in
                //Children will be place check in, i need to update the user id under "users" key
                for child in (snapshot.children) {
                    let rootNode = child as! FIRDataSnapshot
                    let placeName = rootNode.key as String
                    //Store the ref to the users section of the place to be updated
                    //Check all the users of the current checkin
                    if let nodeDict = rootNode.value as? NSDictionary{
                        //Loop over all of attributes of places
                        for (key, value ) in nodeDict{
                            //Get the dictionary underneath user node
                            if (key as! NSString == "users"){
                                if let userDict = value as? NSDictionary{
                                    for (userKey, _ ) in userDict {
                                        if (userKey as! NSString == Helpers().prevUser){
                                           placesRefUpdate.append(placesRef.child("\(placeName)/users"))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                myGroup.leave()
            })
            
            myGroup.notify(queue: DispatchQueue.main) {
                //write new entry and remove old entry
                prevUserRef.removeValue()
                prevCheckedRef.removeValue()
                userRef.setValue(prevUserSnap.value)
                checkedRef.setValue(prevCheckedSnap.value)
                
                //Update all the user's friends who have references to their old user id
                let name = Helpers().currDisplayName
                print("Curr name \(name)")
                let friendInfo = ["displayName1" : name]
                //Remove the current user's prev user id from the ref to their friends list
                for ref in friendsRefUpdate{
                    ref.child("\(Helpers().currUser)").setValue(friendInfo)
                    ref.child("\(Helpers().prevUser)").removeValue()
                }
                
                //add user's new id to the places check ins and remove their old ID
                for ref in placesRefUpdate{
                    ref.updateChildValues(["\(Helpers().currUser)" : "true"])
                    ref.child("\(Helpers().prevUser)").removeValue()
                }
                //Call completion closure to leave function with async calls
                completionClosure(true)
            }
        
        }

    }
    
    
    //For beta testers that haven't created a user name I want them to transition to this screen
    //Also need to store username for user in user defaults
    func checkForUsername(nodeDict: NSDictionary){
        if let userName = nodeDict["username"] as? NSString{
            //was able to unwrap username, betaUser is current
            self.betaUser = false
            //Update core data with the user's name in case logging in and username previously didn't exist in Coredata
            Helpers().currUserName = userName
        }else{
                //Beta user missing backend details
                self.betaUser = true
        }
        //While I'm in here check for the display name too
        if let displayName = nodeDict["displayName1"] as? NSString{
            Helpers().currDisplayName = displayName
        }
            
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!)
    {
        Helpers().myPrint(text: "User Logged Out")
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
    
    //*method gets the keyboard size from the info dictionary of the notification and adjusts the bottom content inset of the scroll view by the height of the keyboard. It also sets the scrollIndicatorInsets property of the scroll view to the same value so that the scrolling indicator won’t be hidden by the keyboard. */
    func keyboardWasShown(notification: NSNotification){
        //Need to calculate keyboard exact size due to Apple suggestions
        self.scrollView.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        //Height of content inserts considers the height of the keyboard from the bottom of the screen
        //move the text box high enough so that the text box and auto complete frame can be shown without contacting the keyboard
        let insetHeight = keyboardSize!.height + self.textBoxSize + self.textBoxSpacing
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, insetHeight, 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        //Change scroll view content hieght to stop at the bottom of the frame and not display blank space for the content insets
        self.scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: scrollView.frame.size.height - (self.textBoxSize + self.textBoxSpacing))
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        //If the frame above the keyboard doesn't contain the active text field origin then scroll it to visible
        if let activeField = self.activeTextField {
            if (!aRect.contains(activeField.frame.origin)){
                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
        
    }
    //Sets insets to 0, the defaults
    func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        //check-me: Should I be subtracting the max table frame height here too?
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -(keyboardSize!.height - self.textBoxSize - self.textBoxSpacing), 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
        self.scrollView.isScrollEnabled = false
    }
    
    //Function used to designate active text field
    func textFieldDidBeginEditing(_ textField: UITextField){
        self.activeTextField = textField
        if(textField.placeholder! == "Email"){
            textField.keyboardType = .emailAddress
        }
    }
    
    
    //Dismiss keyboard if clicking away from text box
    //Detect when user taps on scroll view
    func tapDismiss(_ sender: UITapGestureRecognizer)
    {
        self.activeTextField?.resignFirstResponder()
    }

    func textFieldDidEndEditing(_ textField: UITextField){
        self.activeTextField = nil
    }

    //Actions to take when user dismisses keyboard: hide keyboard & autocomplete table, add first row text to text box
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
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
        //Check if unwind segue was performed so that viewDidLoad can guard against seguing to profile steps on an unwind unless I am unwinding from the Onboard details screen due to error
        if(fromViewController.title == "Onboard info"){ //Name of View Controller scene is listed in the storyboard
            return true
        }else{
            return false
        }
        self.unwindPerformed = true
    }
    
    //Pass email and password to Login info screen if new login
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if(segue.identifier == "loginInfo"){  //only perform a new user needs to provide additional info
            let destinationVC = segue.destination as! OnboardDetailsViewController
            //If user type is nil then force .facebook enum which will use default case
            switch (self.loginType ?? .facebook) {
            //A new user signed up by email, send their info to the login details screen
            case(.new):
                destinationVC.parsedEmail = self.userEmail
                destinationVC.parsedPassword = self.userPassword
                destinationVC.parsedLoginType = self.loginType
            //At this case we should have a new facebook user
            case(.facebook):
                destinationVC.parsedFullName = self.userFullName
                destinationVC.parsedEmail = self.userEmail
                destinationVC.parsedLoginType = self.loginType
                destinationVC.parsedBetaUser = self.betaUser    //Track whether this is an existing facebook beta users
            default:
                Helpers().myPrint(text: "ERROR: Login type not set or An existing user should not be entering login info screen")
            }
        }
    }
    
}
