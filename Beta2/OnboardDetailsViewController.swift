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
    
    let authRef = FIRAuth.auth()
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

    }
    
    @IBAction func signUpButtonPressed(_ sender: UIButton) {
        var errorName = "unknown"
        var errorDesc = ""
        //Create activity view then pass to helper function that can display or remove
        var loadingView: UIView = UIView()
        var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50,  height: 50)) as UIActivityIndicatorView
        
        //Show activity monitor while waiting
        Helpers().displayActMon(display: true, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
        
        //Disable button so its not pressed while thinking
        sender.isEnabled = false
        
        //Check for missing details depending on the login type
        switch(parsedLoginType ?? Helpers.userType.email){
            //New email login needs first, last name, email, password, username
        case(Helpers.userType.new):
            //Unwrap text boxes and make sure they are not nil
            guard let firstName = self.firstNameTextBox.text, let lastName = self.lastNameTextBox.text, let email = self.emailTextBox.text, let password = self.passwordTextBox.text, let userName = self.usernameTextBox.text else{
                Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                loginFailMsg(error: "missing")
                sender.isEnabled = true
                return
            }

            //Check if any fields are Empty
            if(firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty || userName.isEmpty){
                Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                loginFailMsg(error: "missing")
                //Re-enable the login button so they can try again
                sender.isEnabled = true
            }else{
                //Ensure the email has not been modified and be actually linked to an existing account
                Helpers().emailCheck(email: email){(type: Helpers.userType) in
                    switch(type){
                    case(.facebook):
                        Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                        //notify user to login with FB
                        self.loginFailMsg(error: "facebookExists")
                    case(.email):
                        Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                        //Current email is an existing user and needs to go back and log in
                        self.loginFailMsg(error: "emailExists")
                    case(.new):
                        //New user, continue on
                  
                        //Check if the username previously exists or if the user can create it
                        self.usernameExists(name: userName) {(exists: Bool) in
                            //Username already taken by another user
                            if(exists){
                                self.loginFailMsg(error: "username")
                            }else{
                                //All fields look good, try to create new user
                                self.authRef!.createUser(withEmail: email, password: password) { (user, error) in
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
                                        Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                                        //Re-enable the login button so they can try again
                                        sender.isEnabled = true
                                    }else{  //No Error, create user in database
                                        //Store user ID in NSUserDefaults
                                        Helpers().currUser = user?.uid as! NSString
                                        //Once login type is successful store the method used in NSUserDefaults
                                        Helpers().loginType = self.parsedLoginType!
                                        let newUser = ["displayName1": "\(firstName) \(lastName)",
                                                       "email": email, "username": userName, "friends" : "true", "type" : "email"]
                                        let ref = FIRDatabase.database().reference(withPath:"users")
                                        //Append user id as root of node and newUser dict nested beneath
                                        ref.child(Helpers().currUser as String).setValue(newUser)
                                        //Stop displaying activity indicator
                                        Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                                        //Succesfully finished this screen, now get user Info and username at loginInfo screen
                                        self.performSegue(withIdentifier: "startOnboarding", sender: nil)
                                    }
                                }//End of if that checks bool returned by closure
                            }   //End of else username doesn't exist closure
                        }   //End username exists completion

                    }   //End switch
                }   //End check email closure
            }   //End else of empty text fields
                
            

        //New facebook login needs first, last name, email is optional, username
        case(Helpers.userType.facebook):
            
            //Stop displaying activity monitor, no more async calls
            Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
            //Re-enable login button in case login falls through
            sender.isEnabled = true
            
            //unwrap the required fields
            guard let firstName = self.firstNameTextBox.text, let lastName = self.lastNameTextBox.text, let email = self.emailTextBox.text, let userName = self.usernameTextBox.text else{
                loginFailMsg(error: "missing")
                return
            }

            //Check if required fields are Empty
            if(firstName.isEmpty || lastName.isEmpty || email.isEmpty || userName.isEmpty){
                loginFailMsg(error: "missing")
            }else{
                
                let newUser = ["displayName1": "\(firstName) \(lastName)",
                    "email": email , "username": userName, "friends" : "true", "type" : "facebook"]
                
                let ref = FIRDatabase.database().reference(withPath:"users")
                //Append user id as root of node and newUser dict nested beneath
                ref.child(Helpers().currUser as String).setValue(newUser)

                //Succesfully finished this screen, now get user Info and username at loginInfo screen
                self.performSegue(withIdentifier: "startOnboarding", sender: nil)

            }
            
            break
            //If an existing user of nil return to login screen
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
        case "emailExists":
            msgTitle = "Existing User"    //Happens when the user changed the email on this screen to an active user's email
            msgBody = "The email address you have entered is for an existing user. Please log in with this email address."
                unwind = true
            break
        case "facebookUser":
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
                self.performSegue(withIdentifier: "unwindFromLoginDeets", sender: self)
            })
//            alert.addAction(CancelAction)
        }
        else{//Add standard async action button
            //Async call for uialertview will have already left this function, no handling needed
            CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            
//            alert.addAction(CancelAction)
        }
        alert.addAction(CancelAction)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    //check if the current username exists in the system and return true if it does
    func usernameExists(name: String, _ completionClosure: @escaping (_ exists:  Bool) -> Void)
    {
        let userRef = FIRDatabase.database().reference(withPath:"users")
        var nameExists = false
        //Query for an username equal to the one that the user attempts to create
        userRef.queryOrdered(byChild: "username").queryEqual(toValue: name).observeSingleEvent(of: .value, with: { snapshot in
            //snapshot is the user id of the matching username, each username is unique so only 1 entry should be returned but to only return the items beneath the user id I "loop" over the snapshots child, and if no children return false (username is unique)
            for child in snapshot.children{
                let rootNode = child as! FIRDataSnapshot
                //If we have no children then its most certain that the current username doesn't exist
                //Node dict is the items beneath the user id
                if let nodeDict = rootNode.value as? NSDictionary{
                    //unwrap the username if it exists to double verify
                    if let foundName = nodeDict["username"] as? String{
                        if foundName == name{
                            nameExists = true
                        }else{
                            nameExists = false
                        }
                    }else{  //unwrap fails if user didn't have a username entry, but the query shouldn't have matched if it didn't have one, so...
                        nameExists = false
                    }
                }else{  //If downcast fails then username doesn't exist
                    nameExists = false
                }
            }
            completionClosure(nameExists)
        })
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
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        
        //Change scroll view content hieght to stop at the bottom of the frame and not display blank space for the content insets
//        self.scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: scrollView.frame.size.height - /*(self.textBoxSize + self.textBoxSpacing)*/ self.stackHeight)
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        //If the frame above the keyboard doesn't contain the active text field bottom point (maxY) then scroll it to visible
        if let activeField = self.activeTextField {
            //Now that the text boxes are in a stack view their frame will be relative to the position of that stack view
            let activeFrameBottom : CGPoint = CGPoint(x: self.stackView.frame.minX + activeField.frame.origin.x,y: self.stackView.frame.minY + activeField.frame.maxY + self.textBoxSpacing)
            //I will add content insets if the selected textbox plus the spacing below it is not all visibile above the keyboard
            if (!aRect.contains(activeFrameBottom)){
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
    func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
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
    //Detect when user taps outside of scroll vie
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesBegan(touches, with: event)
        
        if let touch: UITouch = touches.first{
            //dismiss keyboard if present
            self.activeTextField?.resignFirstResponder()
            //            self.emailField.resignFirstResponder()
            //            self.passwordField.resignFirstResponder()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        self.activeTextField = nil
    }
    
    //Actions to take when user dismisses keyboard: hide keyboard & autocomplete table, add first row text to text box
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
