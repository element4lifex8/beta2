//
//  OnboardDetailsViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 8/12/17.
//  Copyright © 2017 anuJ. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class OnboardDetailsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var firstNameTextBox: UITextField!
    @IBOutlet var lastNameTextBox: UITextField!
    @IBOutlet var emailTextBox: UITextField!
    @IBOutlet var passwordTextBox: UITextField!
    @IBOutlet var usernameTextBox: UITextField!
   
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var stackView: UIStackView!
    
//    let authRef = FIRAuth.auth()
    //Create queue if async calls is used for missing email alert
    let myGroup = DispatchGroup()
    
    //Keep track of the currently active text field
    var activeTextField: UITextField? = nil
    
    //Calculate the size of the text box I want to move above the keyboard
    var textBoxSize: CGFloat = 0
    //Define the current text box spacing so that is also displayed above keyboard
    var textBoxSpacing: CGFloat = 20.0
    //Calculate the size of the 2 text boxs I want to move above the keyboard
    var emailAndPassSize: CGFloat = 0
    //Calculate the size of the password text box and the submit button I want to move above the keyboard
    var passAndSubmitSize: CGFloat = 0
    //Calculate the size of the stackView holding all of the text boxes
    var stackHeight: CGFloat = 0
    
    //Info from login screen that will be populated here
    var parsedFullName: String?
    var parsedEmail: String?
    var parsedPassword: String?
    var parsedLoginType: Helpers.userType?
    
    //Get a reference to the current frame of the text box in case I need to move it so it appears above the keyboard
    var firstNameFrame: CGRect = CGRect()
    var lastNameFrame: CGRect = CGRect()
    var emailFrame: CGRect = CGRect()
    var passwordFrame: CGRect = CGRect()
    var usernameFrame: CGRect = CGRect()
    
    //Create activity view then pass to helper function that can display or remove
    var loadingView: UIView = UIView()
    var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50,  height: 50)) as UIActivityIndicatorView
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Populate the data in text boxs depending on login type used, if unwrapping fails use email enum which will force the default case and an error since this screen is not for existing email users
        switch(parsedLoginType ?? Helpers.userType.email){
        case(Helpers.userType.new):
            self.emailTextBox.text = self.parsedEmail ?? ""
            self.passwordTextBox.text = self.parsedPassword ?? ""
        //Parse first and last name for
        case(Helpers.userType.facebook):
            //Parse first and last name returned from facebook
            if let fullName = parsedFullName{
                let nameList = fullName.components(separatedBy: " ")
                self.firstNameTextBox.text = nameList.first ?? ""
                self.lastNameTextBox.text = nameList.last ?? ""
            }
            //Don't display password box for facebook users:
            self.passwordTextBox.removeFromSuperview()
            self.emailTextBox.text = self.parsedEmail ?? ""
            
        default:
            Helpers().myPrint(text: "ERROR: Login type not detected, can't populate text fields")
        }


        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        //Set text field delegates so they can dismiss the keyboard
        self.firstNameTextBox.delegate = self
        self.lastNameTextBox.delegate = self
        self.emailTextBox.delegate = self
        self.passwordTextBox.delegate = self
        self.usernameTextBox.delegate = self
        
        //register so that I receive notifications from the keyboard
        registerForKeyboardNotifications()

        //Setup Tap gesture so clicking outside of textbox dismisses keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FBloginViewController.tapDismiss(_:)))
        scrollView.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func signUpButtonPressed(_ sender: UIButton) {
        var errorName = "unknown"
        var errorDesc = ""
        
        //Show activity monitor while waiting
        Helpers().displayActMon(display: true, superView: self.view, loadingView: &self.loadingView, activityIndicator: &self.activityIndicator)
        
        //Disable button so its not pressed while thinking
        sender.isEnabled = false
        
        //Dismiss keyboard if present so that if returning with an error the entire screen will be shown, and not just half, covered by the keyboard
        if let activeField = self.activeTextField{
            activeField.resignFirstResponder()
        }
        
        //Check for missing details depending on the login type
        switch(parsedLoginType ?? Helpers.userType.email){
            //New email login needs first, last name, email, password, username
        case(Helpers.userType.new):
            //Unwrap text boxes and make sure they are not nil
            guard let firstName = self.firstNameTextBox.text, let lastName = self.lastNameTextBox.text, let email = self.emailTextBox.text, let password = self.passwordTextBox.text, let userName = self.usernameTextBox.text else{
//                Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                loginFailMsg(error: "missing")
                sender.isEnabled = true
                return
            }

            //Check if any fields are Empty
            if(firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty || userName.isEmpty){
//                Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                loginFailMsg(error: "missing")
                //Re-enable the login button so they can try again
                sender.isEnabled = true
            }else{
                //Ensure the email has not been modified and be actually linked to an existing account
                Helpers().emailCheck(email: email){(type: Helpers.userType, username: NSString, displayName: NSString) in
                    switch(type){
                    case(.facebook):
//                        Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                        //notify user to login with FB
                        self.loginFailMsg(error: "facebookExists")
                        sender.isEnabled = true
                    case(.email):
//                        Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                        //Current email is an existing user and needs to go back and log in
                        self.loginFailMsg(error: "emailExists")
                        sender.isEnabled = true
                    case(.new):
                        //New user, continue on

                        //Check if the username previously exists or if the user can create it
                        self.usernameValid(name: userName) {(valid: Bool) in
                            //Stop displaying activity indicator
                            Helpers().displayActMon(display: false, superView: self.view, loadingView: &self.loadingView, activityIndicator: &self.activityIndicator)
                            //Continue if Username unique, no special chars,  and > 3 chars long
                            if(valid){
                                //All fields look good, try to create new user
                                Helpers().firAuth?.createUser(withEmail: email, password: password) { (user, error) in
                                    if(error != nil){
                                        if let errorNS = error as NSError?{ //Cast to NSError so I can retrieve components
                                            let errorDict = errorNS.userInfo as NSDictionary   //User info dictionary provided by firebase with additional error info
                                            if let errorStr = errorDict[FIRAuthErrorNameKey] as? String{
                                                //error object provided a specific error name
                                                errorName = errorStr
                                            }
                                            Helpers().myPrint(text: "Error found with new user: \(errorName)")
                                            switch(errorName){  //"#define for "error_name"
                                            case("ERROR_INVALID_EMAIL"):
                                                errorDesc = "emailForm"
                                                break
                                            case("ERROR_WEAK_PASSWORD"):
                                                errorDesc = "weak_password"
                                                break
                                            case("ERROR_EMAIL_ALREADY_IN_USE"):
                                                errorDesc = "email_in_use"
                                                break
                                            default:
                                                break
                                            }
                                            self.loginFailMsg(error: errorDesc)
                                        }else{  //Casting to NS error failed
                                            errorDesc = "A General Error Occured with the email login"
                                            self.loginFailMsg(error: errorDesc)
                                        }

                                        //Re-enable the login button so they can try again
                                        sender.isEnabled = true
                                    }else{  //No Error, create user in database
                                        //Store user ID in NSUserDefaults
                                        Helpers().currUser = user?.uid as! NSString
                                        //Store user's name in UserDefaults
                                        Helpers().currDisplayName = "\(firstName) \(lastName)" as NSString
                                        Helpers().currUserName = userName as NSString
                                        //Once login type is successful store the method used in NSUserDefaults
                                        Helpers().loginType = self.parsedLoginType!.rawValue
                                        //Lowercase the email address to make searching standard
                                        let newUser = ["displayName1": "\(firstName) \(lastName)",
                                                       "email": email.lowercased(), "username": userName, "friends" : "true", "type" : "email"]
                                        let ref = FIRDatabase.database().reference(withPath:"users")
                                        //Append user id as root of node and newUser dict nested beneath
                                        ref.child(Helpers().currUser as String).setValue(newUser)
                                        
                                        //Succesfully finished this screen, now get user Info and username at loginInfo screen
                                        self.performSegue(withIdentifier: "startOnboarding", sender: nil)
                                    }
                                }//End of if that checks bool returned by closure
                            }else{  //If username not valid re-enable login button to retry
                                sender.isEnabled = true
                            }
                        }//End username valid completion
                    }   //End switch
                }   //End check email closure
            }   //End else of empty text fields
                
            

        //New facebook login needs first, last name, email is optional, username
        case(Helpers.userType.facebook):
            
            //Re-enable login button in case login falls through
            sender.isEnabled = true
            
            //unwrap the required fields
            guard let firstName = self.firstNameTextBox.text, let lastName = self.lastNameTextBox.text, let email = self.emailTextBox.text, let userName = self.usernameTextBox.text else{
                loginFailMsg(error: "missing")
                //Stop displaying activity indicator
//                Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                return
            }

            //Check if required fields are Empty
            if(firstName.isEmpty || lastName.isEmpty || email.isEmpty || userName.isEmpty){
                loginFailMsg(error: "missing")
                //Stop displaying activity indicator
//                Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
            }else{
                
                //Check if the username previously exists or if the user can create it
                self.usernameValid(name: userName) {(valid: Bool) in
                    //Stop displaying activity monitor, no more async calls
                    Helpers().displayActMon(display: false, superView: self.view, loadingView: &self.loadingView, activityIndicator: &self.activityIndicator)
                    
                    //Continue if Username is unique, lowercase email for standard searching
                    if(valid){
                        let newUser = ["displayName1": "\(firstName) \(lastName)",
                            "email": email.lowercased() , "username": userName, "friends" : "true", "type" : "facebook", "facebookid": "\(Helpers().FBUserId)" ]
                        
                        let ref = FIRDatabase.database().reference(withPath:"users")
                        //Append user id as root of node and newUser dict nested beneath
                        ref.child(Helpers().currUser as String).setValue(newUser)
                        
                        //Once login type is successful store the method used in NSUserDefaults as NSInt since I can't save custom data types (or even swift data types
                        Helpers().loginType = self.parsedLoginType!.rawValue
                        
                        //Store display Name, and username to NS User defaults (UID was already stored in FBLogin VC
                        Helpers().currDisplayName = "\(firstName) \(lastName)" as NSString
                        Helpers().currUserName = userName as NSString
                        
                        //Succesfully finished this screen, now get user Info and username at loginInfo screen
                        self.performSegue(withIdentifier: "startOnboarding", sender: nil)
                    }
                }
            }
            
            break
        //If an existing user or nil return to login screen
        default:
            loginFailMsg(error: "An error occured, please try logging in again.")
            break
        }
        
    }
    
    
    //Present alert when facebook login canceled/failed
    func loginFailMsg(error: String) -> Void{
        var msgTitle = ""
        var msgBody = ""
        var unwind = false  //Unwind to login screen on catastrphic error
        
        //Stop displaying activity indicator so on return from alert no activity monitor is displayed
        
        Helpers().displayActMon(display: false, superView: self.view, loadingView: &self.loadingView, activityIndicator: &self.activityIndicator)
        switch(error){
        case "emailForm":
            msgTitle = "Email Format Invalid"
            msgBody = "An invalid email address was entered. Please check for typos in your email and ensure it is a valid email address."
            break
        case "missing":
            msgTitle = "Missing Login Details"
            msgBody = "Please fill out all fields so we can get to the fun stuff!"
            break
        case "weak_password":
            msgTitle = "Weak Password"
            msgBody = "Please choose a stronger password to create an account. Password must be at least 6 characters."
            break
        case "email_in_use":
            msgTitle = "Missing account"    //Happens with the backend doesn't have the user but the firebase auth already has them
            msgBody = "Your Check In Out account info for this email is outdated. Please contact technical support at jason@checkinoutlists.com or create a new account with a different email address."
            break
        case "username":
            msgTitle = "Username Taken"    //Happens with the backend doesn't have the user but the firebase auth already has them
            msgBody = "The username you entered is already taken, please try another."
            break
        case "username_length":
            msgTitle = "Username Length Error"
            msgBody = "Please create a username that is at least 3 characters."
            break
        case "invalid_chars":
            msgTitle = "Invalid Username characters"
            msgBody = "Sorry, but the following characters are not allowed in usernames: \n . # $ [ ]"
            break
        case "upper_chars":
            msgTitle = "Invalid Username characters"
            msgBody = "Sorry, but upper case letters are not allowed in usernames, please replace these with lower case characters"
            break
        case "emailExists":
            msgTitle = "Existing User"    //Happens when the user changed the email on this screen to an active user's email
            msgBody = "The email address you have entered is for an existing user. Please log in with this email address."
                unwind = true
            break
        case "facebookUser":  //Not current used
            msgTitle = "Existing"    //Happens with the backend doesn't have the user but the firebase auth already has them
            msgBody = "The email address you have entered is for an existing user. Please log in the the FaceBook associated with this email."
                unwind = true
            break
        default:
            msgTitle = "Signup Failed"
            msgBody = error
            unwind = true
            break
        }
        
        let alert = UIAlertController(title: msgTitle, message: msgBody, preferredStyle: .alert)
        var CancelAction: UIAlertAction
        if(unwind == true){    //Use standard action button but unwind to login screen on button press
            CancelAction = UIAlertAction(title: "Ok", style: .cancel, handler: { UIAlertAction in
                self.performSegue(withIdentifier: "unwindToFBLoginId", sender: self)
            })
        }
        else{//Add standard async action button
            //Async call for uialertview will have already left this function, no handling needed
            CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            
        }
        alert.addAction(CancelAction)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    //check if the current username exists in the system and return true if it does
    func usernameValid(name: String, _ completionClosure: @escaping (_ valid:  Bool) -> Void)
    {
        let userRef = FIRDatabase.database().reference(withPath:"users")
        //Keep track of whether the user exists but only return is the userName is valid (doesn't exists and proper format
        var exists: Bool = false
        var valid: Bool = true
        
        //Check if an upper case letter is present in the username string, not allowing this to make searching case insensitive (as in, always lowercase)
       if let _ = name.range(of: "\\.*[A-Z]+\\.*", options: .regularExpression) {
            loginFailMsg(error: "upper_chars")
            valid = false
            completionClosure(valid)
        }
        else if(name.characters.count < 3){    //Check that user name if of valid length
            loginFailMsg(error: "username_length")
            valid = false
            completionClosure(valid)
        }else{
        //Query for an username equal to the one that the user attempts to create
            userRef.queryOrdered(byChild: "username").queryEqual(toValue: name).observeSingleEvent(of: .value, with: { snapshot in
                //snapshot is the user id of the matching username, each username is unique so only 1 entry should be returned but to only return the items beneath the user id I "loop" over the snapshots child, and if no children return false (username is unique)
                for child in snapshot.children{
                    let rootNode = child as! FIRDataSnapshot
                    //If we have no children then its most certain that the current username doesn't exist
                    //Node dict is the items beneath the user id, If downcast fails then username doesn't exist
                    if let nodeDict = rootNode.value as? NSDictionary{
                        //unwrap the username if it exists to double verify
                        if let foundName = nodeDict["username"] as? String{
                            if foundName == name{
                                exists = true
                                valid = false
                            }
                        }
                    }
                }
                //Notify user of non unique username
                if(exists){
                    self.loginFailMsg(error: "username")
                }
                completionClosure(valid)
            })
        }
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
    @objc func keyboardWasShown(notification: NSNotification){
        //Need to calculate keyboard exact size due to Apple suggestions
        self.scrollView.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        
        //Change scroll view content hieght to stop at the bottom of the frame and not display blank space for the content insets
//        self.scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: scrollView.frame.size.height - /*(self.textBoxSize + self.textBoxSpacing)*/ self.stackHeight)
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        //If the frame above the keyboard doesn't contain the active text field bottom point (maxY) then scroll it to visible
        if let activeField = self.activeTextField {
            //Now that the text boxes are in a stack view their frame will be relative to the position of that stack view
            let activeFrameBottom : CGPoint = CGPoint(x: self.stackView.frame.minX + activeField.frame.origin.x,y: self.stackView.frame.minY + activeField.frame.maxY + self.textBoxSpacing)
            //I will add content insets if the selected textbox plus the spacing to the end of the stack view is not shown so the user can easily skip around
            let stackBottom: CGPoint = CGPoint(x: self.stackView.frame.maxX, y: self.stackView.frame.maxY)
            //--below it is not all visibile above the keyboard
            if (!aRect.contains(stackBottom/*activeFrameBottom*/)){
                //Determine the distance from the bottom of to the space below the active text box, then add the remainder of the height covered by the keyboard to the scroll view offset
                let insetHeight = keyboardSize!.height + (keyboardSize!.height - (view.frame.maxY - (self.stackView.frame.minY + activeField.frame.maxY + self.textBoxSpacing)))
                let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, insetHeight, 0.0)
                self.scrollView.contentInset = contentInsets
                self.scrollView.scrollIndicatorInsets = contentInsets
                //Scroll active text field to be aboce keyboard if it and the spaing below it is not seen above the keyboard
                let textSpaceFrame = CGRect(x: activeField.frame.minX, y: activeFrameBottom.y, width: activeField.frame.width, height: activeField.frame.height)
                self.scrollView.scrollRectToVisible(textSpaceFrame, animated: true)
            }
        }
        
    }
    //Sets insets to 0, the defaults
    @objc func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
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

    


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //If unwinding because of login error then don't do any prep, only on login
        if(segue.identifier == "startOnboarding")
        {
            //Pass email and password to Login info screen if new login
            let destinationVC = segue.destination as! ProfileStepsViewController
            //Notify the AddPeopleVC that it is being accessed during onboarding
            destinationVC.isOnboarding = true
            
            //If I'm seguing then i've finished the onboard process, mark as done
            Helpers().onboardCompleteDefault = 1
        }
    }
 

}
