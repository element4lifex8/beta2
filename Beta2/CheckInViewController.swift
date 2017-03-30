//
//  CheckInViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 11/15/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAnalytics
import CoreData
import CoreLocation
import GooglePlaces

class CheckInViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
//    Class properties and instances
    
    @IBOutlet var checkInView: CheckInView!
    var dictArr = [[String:String]]()
    var placesDict = [String : String]()
    var cityButtonList: [String] = ["+"]
    var catButtonList = ["Bar", "Breakfast", "Brewery", "Brunch", "Beaches", "Coffee Shop", "Dessert", "Dinner", "Food Truck", "Hikes", "Lunch", "Museums", "Night Club", "Parks", "Site Seeing", "Winery"]
    var placesArr = [String]()
    var arrSize = Int()
    var checkObj = placeNode()  //Appears that this model is filled out, but its actually the dict array contents that are written to the backen
    let restNameDefaultKey = "CheckInView.restName"
    var isEnteringCity = false
    var isEnteringCategory = false
    var autoCompleteArray = [String]()  //Table data containing string from google prediction array
    var googlePrediction = [GMSAutocompletePrediction]()    //Array containing all data returned for each google autocomplete entry
    var autoCompleteTableView: UITableView?
    let autoCompleteFrameMaxHeight = 120
    let autoCompleteCellHeight = 33
    let googleImageView = UIImageView(image: UIImage(named: "poweredByGoogle")) //Google attribution image view
    var tableContainerView: UIView?     //Container view for autocomplete table so border and rounded edges can be achieved
    //Google places client
    var placesClient: GMSPlacesClient!
    //Location manager for detecting user's location
    var locationManager: CLLocationManager? = nil
    //Activity monitor and view background
    var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView()
    var loadingView: UIView = UIView()
    
    //Hack to reiterate through check in process after we notify the user they checked in without autocomplete
    var customCheckIn = false
    
    fileprivate let sharedUserHome = UserDefaults.standard
    let sharedHomeDefaultKey = "ProfileStepsVC.homeAdded"
    
    //Return optional whether the user has added a home, will be nil if they've always skipped the onboarding
    var homeAdded: NSNumber? {
        get
        {
            return sharedUserHome.object(forKey: sharedHomeDefaultKey) as? NSNumber
        }
        set
        {
            sharedUserHome.set(newValue, forKey: sharedHomeDefaultKey)
        }
    }
    
    fileprivate let sharedRestName = UserDefaults.standard
    
    //Unused nsUserDefaults for storing restaurancts
    var restNameHistory: [String] {
        get
        {
            return sharedRestName.object(forKey: restNameDefaultKey) as? [String] ?? []
        }
        set
        {
            sharedRestName.set(newValue, forKey: restNameDefaultKey)
        }
    }
    
    var cityScrollView : UIScrollView!
    //container view goes inside the scroll view and holds the buttons
    var cityScrollContainerView : UIView!
    
    var catScrollView: UIScrollView!
    var catScrollContainerView: UIView!
    
    
    //NSUser defaults stores user and a helper class is user to return this value
    var currUser = Helpers().returnCurrUser()
    
    override func viewDidAppear(_ animated: Bool) {
        //Create autocomplete table view in View did appear because constraints to resize text box had not yet been added during viewDidLoad
        let autoCompleteFrame = CGRect(x: CheckInRestField.frame.minX, y: CheckInRestField.frame.maxY, width: CheckInRestField.frame.size.width, height: CGFloat(self.autoCompleteFrameMaxHeight))
        autoCompleteTableView = UITableView(frame: autoCompleteFrame, style: UITableViewStyle.plain)
        autoCompleteTableView?.delegate = self;
        autoCompleteTableView?.dataSource = self;
        autoCompleteTableView?.isHidden = true;
        autoCompleteTableView?.isScrollEnabled = true;
        autoCompleteTableView?.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        autoCompleteTableView?.layer.cornerRadius = 15
        view.addSubview(autoCompleteTableView!)
        //remove left padding from tableview seperators
//        autoCompleteTableView?.layoutMargins = UIEdgeInsets.zero
//        autoCompleteTableView?.separatorInset = UIEdgeInsets.zero
        
        //add top separator line to footer
        let px = 1 / UIScreen.main.scale

        //create image view for google attribute in the center of the footer view
        let googleFrame = CGRect(x: (autoCompleteFrame.width - googleImageView.frame.width) / 2, y: 5, width: googleImageView.frame.width, height: googleImageView.frame.height + px + 5)
        let googs = UIImageView(frame: googleFrame)
        googs.addSubview(googleImageView)
        //create footer view and add image view with 10 pt above and below
        let tableFooterFrame = CGRect(x: 0, y: 0, width: autoCompleteFrame.width, height: googleImageView.frame.height + px + 10)
        let tableFooterView = UIView(frame: tableFooterFrame)
        tableFooterView.addSubview(googs)
        
        //Create cell separator at bottom of last cell, above google attribution in footer
        let frame = CGRect(x: 0, y: 0, width: (self.autoCompleteTableView?.frame.size.width)!, height:  px)
        let line: UIView = UIView(frame: frame)
        tableFooterView.addSubview(line)
        line.backgroundColor = self.autoCompleteTableView?.separatorColor
        
        //Set autocomplete footer view with google attribution this way so that footer doesn't float
        autoCompleteTableView?.tableFooterView = tableFooterView
        
        //remove left padding from tableview seperators
        autoCompleteTableView?.layoutMargins = UIEdgeInsets.zero
        autoCompleteTableView?.separatorInset = UIEdgeInsets.zero
    
    }
    
//  Layout views in view controller
    
    //Since the bounds of the view controller's view is not ready in viewDidLoad, anything that will be calculated based off the view's bounds directly or indirectly must not be put in viewDidLoad (so we put it in did layout subviews
    override func viewDidLoad() {
        super.viewDidLoad()
        self.CheckInRestField.delegate = self
        //Auto Capitalize words in text box field
        self.CheckInRestField.autocapitalizationType = .words
        //Add target to check in rest field that detects when a change occurs
        self.CheckInRestField.addTarget(self, action: #selector(CheckInViewController.googleAutoComplete(_:)),
                  for: UIControlEvents.editingChanged)
        //If a user leaves the text box but then returns I want the text to remain
        self.CheckInRestField.clearsOnBeginEditing = false
        //setup City scroll view
        cityScrollView = UIScrollView()
        cityScrollView.delegate = self
        cityScrollView.showsHorizontalScrollIndicator = false
        //setup Category scroll view
        catScrollView = UIScrollView()
        catScrollView.delegate = self
        catScrollView.showsHorizontalScrollIndicator = false
        //setup container view
        cityScrollContainerView = UIView()
        //add a tap action to the scroll view that will remove any present delete city buttons
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CheckInViewController.clearCityDeleteButton(_:)))
        cityScrollView.addGestureRecognizer(tapGesture)
        createCityButtons()
        
        //setup category container view
        catScrollContainerView = UIView()
        createCategoryButtons()
        //Enable touch interaction with background view so that delete buttons can be cleared when user touces screen
        checkInView.isUserInteractionEnabled = true
       
        
        //gooogle Places setup
        placesClient = GMSPlacesClient.shared()
        //Initialize CL Location manager so a users current location can be determined
        self.locationManager = CLLocationManager()
        
        if CLLocationManager.authorizationStatus() == .notDetermined{
            self.locationManager?.requestWhenInUseAuthorization()
        }
        
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 200
        locationManager?.delegate = self
        //Don't start updating if user hasn't granted permission so they are not prompted
        if (CLLocationManager.locationServicesEnabled()){
            startUpdatingLocation()
        }
        
     }
    
    //Since the bounds of the view controller's view is not ready in viewDidLoad, I like to do frame setting in viewDidLayoutSubviews
    override func viewDidLayoutSubviews() {
        //Locate origin of city scroll view at superview x origin - 3/4 of scroll view height
        let scrollViewHeight:CGFloat = 120
        let cityScrollViewY = (view.frame.size.height / 2) - (scrollViewHeight / 1.25)
        let catScrollViewY = cityScrollViewY + scrollViewHeight
        
        super.viewDidLayoutSubviews()

        //create frame on screen of scroll view that is 250px from top of screen and the width of the screen and a height of 120px
        cityScrollView.frame = CGRect(x: 0, y: cityScrollViewY, width: view.frame.size.width, height: scrollViewHeight)
        //we are basing the container view's frame on the scroll view's content size
        cityScrollContainerView.frame = CGRect(x: 0, y: 0, width: cityScrollView.contentSize.width, height: cityScrollView.contentSize.height)

        
        //setup category scroll frame
        catScrollView.frame = CGRect(x: 0, y: catScrollViewY, width: view.frame.size.width, height: 120)
        
        catScrollContainerView.frame = CGRect(x: 0, y: 0, width: catScrollView.contentSize.width, height: catScrollView.contentSize.height)
    }
   
    /**
     * Called when 'return' key pressed. return NO to ignore.
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (textField.placeholder != nil){  //If no user information is in the textBox then clear place holder
            textField.placeholder = nil
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if(textField.text == ""){   //Restore placeholder text if no user input was received
            if(isEnteringCity){
                textField.placeholder = "Enter new city button name"
            }else{
                textField.placeholder = "Enter Name..."
            }
        }
        autoCompleteTableView?.isHidden = true
    }
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        //If user is entering a city then a clear button appears in the text field to cancel city input
        if(isEnteringCity && !(textField.text?.isEmpty)!){  //Don't remove from city mode when clearing placeholder text
            CheckInRestField.clearButtonMode = .never
            isEnteringCity = false
            textField.placeholder = "Enter Name..."
            return true
        }
        
        if(textField.text?.isEmpty ?? true){        //Only clear current textField if no user input previously received
            return true
        }
        else{    //If text field is not empty then don't clear
            return false
        }
    }
    
    //Confirm to CL location delegate
    func startUpdatingLocation() {
        self.locationManager?.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        self.locationManager?.stopUpdatingLocation()
    }
    
    //Detect when user taps outside of scroll views and remove any delete city buttons if they are present
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesBegan(touches, with: event)
        
        if let touch: UITouch = touches.first{
            if (touch.view == checkInView){
                //dismiss keyboard if present
                CheckInRestField.resignFirstResponder()
                for case let btn as DeleteCityUIButton in cityScrollContainerView.subviews{
                    btn.removeFromSuperview()
                }
                //Remove any background from the city button that was added by the touchdown event
                for case let btn as UIButton in cityScrollContainerView.subviews{
                    if(!btn.isSelected){
                        btn.backgroundColor = UIColor.clear
                    }
                }
            }
        }
    }
    
    //TableView delegate functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return googlePrediction.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(autoCompleteCellHeight)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = googlePrediction[indexPath.row].attributedFullText.string
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.minimumScaleFactor = 0.6
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsets.zero

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        CheckInRestField.text = googlePrediction[indexPath.row].attributedPrimaryText.string
        //Store placeId object to be stored in firebase with the check in
        checkObj.placeId = googlePrediction[indexPath.row].placeID
        autoCompleteTableView?.isHidden = true
        //dismiss keyboard if present
        CheckInRestField.resignFirstResponder()
    }
    

    @IBOutlet weak var CheckInRestField: UITextField!
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromMyList(_ sender: UIStoryboardSegue) {
        print("Unwind list")
        // empty
    }
    
    
    //Get outlet to list icon so I can determine when to end the check animation that occurs after check in
    @IBOutlet weak var myListIcon: UIButton!
    
//    Collect data from text box and determine if it is for adding new city or to save check in to firebase
    
    //Action triggered when submit button is pressed
    @IBAction func SaveRestField(_ sender: UIButton) {
        //Create a new button
        if(isEnteringCity)
        {
            let addButtonText = CheckInRestField.text!
            let cityDefaultText = "Enter new city button name"
//            let catDefaultText = "Enter new category button name"
            if(addButtonText == cityDefaultText || addButtonText.isEmpty || addButtonText == "+")
            {
                let alert = UIAlertController(title: "Invalid City", message: "You attempted to create a city button but did not provide a city name.", preferredStyle: .alert)
                let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(CancelAction)
                self.present(alert, animated: true, completion: nil)
                CheckInRestField.placeholder = "Enter Name..."
                CheckInRestField.text = ""
                isEnteringCity = false
                isEnteringCategory = false
            }
            else
            {
                if(self.checkObj.placeId != nil)
                {
                    saveCityButton(addButtonText)
                    CheckInRestField.text = ""
                    CheckInRestField.placeholder = "Enter Name..."
                    isEnteringCity = false
                    //Remove clear button after city is checked in
                    CheckInRestField.clearButtonMode = .never
                    createCityButtons()
                }else{
                    let alert = UIAlertController(title: "Google is your friend", message: "You entered \(addButtonText) manually, instead please use our reccomended cities from the list. Try editing your current city until you find a viable match from the list", preferredStyle: .alert)
                    let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(CancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
            //No Longer supporting user supported categories
//            else if(isEnteringCategory)
//            {
//                let newCatLoc = catButtonList.count - 1
//                catButtonList.insert(addButtonText, at: newCatLoc)
//                CheckInRestField.text = ""
//                CheckInRestField.placeholder = "Enter Name..."
//                isEnteringCategory = false
//                createCategoryButtons()
//            }
        }
        //Save an establishment Check in entry
        else
        {
            var restNameText = CheckInRestField.text!
            //Remove any trailing spaces from restNameText
            restNameText = restNameText.trimmingCharacters(in: .whitespaces)
            let dictArrLength = dictArr.count
            if(!restNameText.isEmpty && restNameText != "Enter Name...")
            {
                //Start activity monitor since check process now has to make async request
                displayActivityMonitor()
                //Firebase Keys must be non-empty and cannot contain '.' '#' '$' '[' or ']'
                if let index = restNameText.characters.index(of: ".") {
                    restNameText.remove(at: index)
                }
                if let index = restNameText.characters.index(of: "#") {
                    restNameText.remove(at: index)
                }
                if let index = restNameText.characters.index(of: "$") {
                    restNameText.remove(at: index)
                }
                if let index = restNameText.characters.index(of: "[") {
                    restNameText.remove(at: index)
                }
                if let index = restNameText.characters.index(of: "]") {
                    restNameText.remove(at: index)
                }
                
                //Make sure user has added one city and one category, or prompt the user and have them try again
                if(dictArr.contains(where: {($0.keys).contains("city")}) && dictArr.contains(where: {($0.keys).contains("category")})){      
                
                    self.checkObj.place = restNameText
                    // Create a reference to a Firebase location
    //                let refChecked = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
                    let refChecked = FIRDatabase.database().reference().child("checked/\(self.currUser)")
    //                let refCheckedPlaces = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
                    let refCheckedPlaces = FIRDatabase.database().reference().child("checked/places")
                    // Write establishment name to user's collection

                    //Don't create new Place in the refCheckedPlaces ref ("Places" category) if another user has already created this place
                    //Check if the user had entered this place before and stop them from doing it again
                    findPlaceInFirebase(placeName: restNameText, userRef: refChecked, placesRef: refCheckedPlaces){ (userDoubleEntry: Bool, placeExistsMaster: Bool) in
                        
                        //Add place to user's list if its not a repeat check in
                        if(!userDoubleEntry){
                            
                            //Store place Name and place ID with the check in if the user used google's autocomplete
                            if(self.checkObj.placeId != nil)
                            {
                                refChecked.updateChildValues([restNameText:true])
                                refChecked.child(restNameText).updateChildValues(["placeId":self.checkObj.placeId!])
                            }else if(self.customCheckIn == false){  //Have the user confirm that they want to check in without using auto complete
                                let alert = UIAlertController(title: "Is this a custom Check In?", message: "You didn't use Google's auto complete for this check in. Are you sure this place exists and that you want to check it in under this name?", preferredStyle: .alert)
                                //Exit function if user clicks now and allow them to reconfigure the check in
                                let CancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
                                //Async call to create button would complete function, so I return after presenting, and if the user wishes I will reiterate through the function
                                let ConfirmAction = UIAlertAction(title: "Yes", style: .default, handler: { UIAlertAction in
                                    //Skip this part on the next iteration so add the place name now
                                    refChecked.updateChildValues([restNameText:true])
                                    self.customCheckIn = true
                                    self.SaveRestField(UIButton(type: .custom))
                                })
                                alert.addAction(ConfirmAction)
                                alert.addAction(CancelAction)
                                //Remove activity monitor so alertview can be presented
                                self.present(alert, animated: true, completion: {
                                    self.clearActivityMonitor()
                                })
                                return
                            }
                            
                        }else{  //Notify the user and skip the process if they have previously checked in here
                            let alert = UIAlertController(title: "Reapeated Check In Out", message: "You must really like this place, you've already added \(restNameText) to your List. Please add a new place to Check In Out!", preferredStyle: .alert)
                            //Exit function if user clicks now and allow them to reconfigure the check in
                            let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: {
                                UIAlertAction in
                                self.cleanScreen()
                            })
                            alert.addAction(CancelAction)
                            //Remove activity monitor so alertview can be presented
                            self.clearActivityMonitor()
                            self.present(alert, animated: true, completion:{
                                //Before returning I don't want the user to retain the current place ID and then change the name to something not matching this place ID so I will clear it
                                self.checkObj.placeId = nil
                                self.clearActivityMonitor()
                            })
                          return
                        }
                        
                        if(!placeExistsMaster){
                        // Write establishment name to places collection
                            refCheckedPlaces.updateChildValues([restNameText:true])
                            //Store place ID with the check in if the user used google's autocomplete
                            if(self.checkObj.placeId != nil)
                            {
                                 refCheckedPlaces.child( restNameText).updateChildValues(["placeId":self.checkObj.placeId!])
                            }
                        }
                        //Add user id to the checked in place in the master list
                        refCheckedPlaces.child(restNameText).child("users").updateChildValues([self.currUser:"true"])
                        
                        
                        //update user's and master list with the city & categories chosen by this user
                        for i in 0 ..< self.dictArr.count    //array of [cat/city: catName/cityName]
                        {
                            for (key,value) in self.dictArr[i]   //key: city or category
                            {
                                //Store categories and cities in user list
                                refChecked.child(restNameText).child(key).updateChildValues([value:"true"])
                                //Store categories and city info in master list
                                refCheckedPlaces.child( restNameText).child(byAppendingPath: key).updateChildValues([value:"true"])
                            }
                        }
                        //Save to NSUser defaults
        //                restNameHistory += [restNameText]
                        
                       //Return check in screen to defaults and clear objects created for the previous check in
                        self.cleanScreen()
                        //Turn off activity monitor
                        self.clearActivityMonitor()
                        //perform check animation signaling check in complete
                        self.animateCheckComplete()
                        
                       
                    }//Finish closure after checking whether the place had already been added to the back end
                }else{//End of if checking for a city and a catagory being selected
                    let alert = UIAlertController(title: "Give us more details!", message: "Make sure to select a city and category for \(restNameText)", preferredStyle: .alert)
                    //Exit function if user clicks now and allow them to reconfigure the check in
                    let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(CancelAction)
                    self.present(alert, animated: true, completion: {
                        self.clearActivityMonitor()
                    })
                }
            }else{//If user hits submit with empty check in display alert
                let alert = UIAlertController(title: "Empty Check In", message: "You attempted to add a Check In but did not provide a name.", preferredStyle: .alert)
                let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(CancelAction)
                self.present(alert, animated: true, completion: {
                    self.clearActivityMonitor()
                })
            }
        }
    }
    
    //Remove button check marks and clear any arrays/objects referencing the previous check in
    func cleanScreen() {
        self.dictArr.removeAll()     //Remove elements so the following check in doesn't overwrite the previous
        self.checkObj = placeNode()  //reinitalize place node for next check in
        
        //Restore check in screen to defaults
        self.CheckInRestField.text = nil
        for view in self.catScrollContainerView.subviews as [UIView] {
            if let btn = view as? UIButton {
                btn.titleEdgeInsets = UIEdgeInsetsMake(0.0, 5, 0, 5) //prevent text from shift when removing check image
                btn.isSelected = false
                if(btn.backgroundColor != UIColor.clear){
                    btn.backgroundColor = UIColor.clear
                }
            }
        }
        for view in self.cityScrollContainerView.subviews as [UIView] {
            if let btn = view as? UIButton {
                btn.titleEdgeInsets = UIEdgeInsetsMake(0.0, 5, 0, 5) //prevent text from shift when removing check image
                btn.isSelected = false
                if(btn.backgroundColor != UIColor.clear){
                    btn.backgroundColor = UIColor.clear
                }
            }
        }
        self.CheckInRestField.placeholder = "Enter Name..."
        //Clear any delete icons the user may have left on the screen by calling the same function that would be called if they tapped outside the buttons
        clearCityDeleteButton(UITapGestureRecognizer())
    }
    
//    Select attributes for check in
    
    @IBAction func categorySelect(_ sender: UIButton) {
        sender.isHighlighted = true
        if(sender.currentTitle! == "+")
        {
            CheckInRestField.text = "Enter new category button name"
            isEnteringCategory = true
        }
        else
        {
            let categoryDict = ["category" : sender.currentTitle!]
            if(makeButtonSelected(sender)){
                checkObj.addCategory(sender.currentTitle!)
                //if dictArr does not contain the selected category already then add it to the dictArr
                //uses closure for contains func as described here: http://stackoverflow.com/questions/34081580/array-of-any-and-contains
                if(!dictArr.contains(where: {element in return (element == categoryDict)}))
                {
                    dictArr.append(categoryDict)
                }
            }else{   //Button is being deselected
                if let idxToDelete = dictArr.index(where: {element in return (element == categoryDict)}){
                    dictArr.remove(at: idxToDelete)
                }
            }
        }
    }
    
    
    @IBAction func citySelect(_ sender: UIButton) {
        
        if(sender.currentTitle! == "+")
        {
            //Clear the touchdown background color
            sender.backgroundColor = UIColor.clear
            CheckInRestField.placeholder = "Enter new city button name"
            CheckInRestField.text = ""
            //Add clear button to text field that will be used as a cancel city entry, change color
            CheckInRestField.clearButtonMode = .whileEditing
            if let clearButton = CheckInRestField.value(forKey: "_clearButton") as? UIButton{
                // Create a template copy of the original button image
                let templateImage =  clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
                // Set the template image copy as the button image
                clearButton.setImage(templateImage, for: .normal)
                // Finally, set the image color
                clearButton.tintColor = .white

            }
//            if let searchTextField = CheckInRestField.searchBar.valueForKey("_searchField") as? UITextField, let clearButton = searchTextField.valueForKey("_clearButton") as? UIButton {
//                // Create a template copy of the original button image
//                let templateImage =  clearButton.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate)
//                // Set the template image copy as the button image
//                clearButton.setImage(templateImage, forState: .Normal)
//                // Finally, set the image color
//                clearButton.tintColor = .redColor()
//            }
            //Remove auto complete if the user was previously typing an entry and decided to add city
            autoCompleteTableView?.isHidden = true
            isEnteringCity = true
        }
        else
        {
            let cityDict = ["city" : sender.currentTitle!]   //var cityDict = ["city" : "true"]
            if(makeButtonSelected(sender))
            {
                checkObj.addCity(sender.currentTitle!)
                //Prevent from being able to add the same city twice to the dictArr
                if(!dictArr.contains(where: {element in return (element == cityDict)}))
                {
                    dictArr.append(cityDict)
                }
            }
            else{   //Button is being deselected
                if let idxToDelete = dictArr.index(where: {element in return (element == cityDict)}){
                        dictArr.remove(at: idxToDelete)
                    }
            }
            
        }
    }
    
    //Change button background when touch down event occurs
    @IBAction func cityCatButtBeginTouch(_ sender: UIButton) {
        if(!sender.isSelected){
            sender.backgroundColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 1.0)
        }
    }
    //Even with these cancel funcs I am at times able to achieve the modified background color from the above function that is not cleared when a long touch is canceled
    @IBAction func cityCatButtTouchCancel(_ sender: UIButton) {
        if(!sender.isSelected){
            sender.backgroundColor = UIColor.clear
        }
    }
    
    @IBAction func citCatButtEndTouch(_ sender: UIButton) {
        if(!sender.isSelected){
            sender.backgroundColor = UIColor.clear
        }
    }
   
    //Function was used to display google's guess at the likely location
    @IBAction func printLikelyLocation(_ sender: UIButton) {
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }

//            Notes about the likelihood values:
//            
//            The likelihood provides a relative probability of the place being the best match within the list of returned places for a single request. You can't compare likelihoods across different requests.
//            The value of the likelihood will be between 0 and 1.0.
//            The sum of the likelihoods in a returned array of GMSPlaceLikelihood objects is always less than or equal to 1.0. Note that the sum isn't necessarily 1.0.
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    print("name label: \(place.name)")
                    print("address label: \(place.formattedAddress?.components(separatedBy: ", ").joined(separator: "\n"))")
                }
            }
        })
    }
    
    func findPlaceInFirebase(placeName : String, userRef: FIRDatabaseReference, placesRef: FIRDatabaseReference, _ completionClosure: @escaping (_ userDoubleEntry: Bool, _ placeExistsMaster: Bool) -> Void) {
        //create dispatch group to wait for both entries to complete before calling completion closure
        let myGroup = DispatchGroup()
        
        //These values will be set to true if the placeName is found in fireBase
        var userHasChecked = false
        var placesHasChecked = false
        
        myGroup.enter()
        //Check if the user has checked this in before, if this closure is not entered then no entry was found
        userRef.child( placeName).observeSingleEvent(of: .value, with: { snapshot in
            //If the place exists I will be able to unwrap the snapshot of its contents as an NSDictionary
            if let placeFound = snapshot.value as? NSDictionary{
                userHasChecked = true
            }
            myGroup.leave()
        })
        
        myGroup.enter()
        //Check if another user has checked in here before and the place resides in the master restaurant
        placesRef.child(byAppendingPath: placeName).observeSingleEvent(of: .value, with: { snapshot in
            if let placeFound = snapshot.value as? NSDictionary{
                placesHasChecked = true
            }
            myGroup.leave()
        })
        
        myGroup.notify(queue: .main){
            completionClosure(userHasChecked, placesHasChecked)
        }
        
    }
    
    func googleAutoComplete(_ textField: UITextField) {
        if let checkInString = CheckInRestField.text{
            //Anytime the user changes the text field make sure they aren't changing a previously selected establishment, so clear the place id
            checkObj.placeId = nil
            //Start querying google database with at minimum 3 chars
            if(checkInString.characters.count >= 3 && (checkInString.characters.count % 2 != 0)){
                placeAutocomplete(queryText: checkInString)
            }else if (checkInString.characters.count < 3){
                autoCompleteTableView?.isHidden = true
            }
        }
    }
    
    func placeAutocomplete(queryText: String) {
        let filter = GMSAutocompleteFilter()
        if(isEnteringCity){
            filter.type = .city
        }else{
            filter.type = .establishment
        }
        placesClient.autocompleteQuery(queryText, bounds: coordinateBounds(), filter: filter, callback: {(results, error) -> Void in
            if let error = error {
                print("Autocomplete error \(error)")
                return
            }
            //Remove previous entries in autocomplete arrays
            //AUtoCompleteArray is table data, and maps 1 to 1 to the complete data set contained in googlePrediction array
            self.autoCompleteArray.removeAll()
            self.googlePrediction.removeAll()
            if let results = results {
                for result in results {
//                    result.attributedPrimaryText.string contains the name of the spot
//                    result.attributedSecondaryText.string contains the address to the spot
                    self.googlePrediction.append(result)
                    self.autoCompleteArray.append(result.attributedFullText.string)
                }
            }
            //Determine if the number of entries in the array of table data will exceed the default table frame size of 120pt (~3 tables entries). Shrink table if less than 3 table entries expected
            let newTableSize = (self.autoCompleteArray.count * self.autoCompleteCellHeight) + Int(self.googleImageView.frame.height + 10)
            var tableFrame = self.autoCompleteTableView?.frame;
            
            if(newTableSize < self.autoCompleteFrameMaxHeight){
                tableFrame?.size.height = CGFloat(newTableSize);
                self.autoCompleteTableView?.frame = tableFrame!;
                self.autoCompleteTableView?.setNeedsDisplay()
            }else if(Int((tableFrame?.height)!) < self.autoCompleteFrameMaxHeight){  //If table was previously shrunk then resize to max table size
                tableFrame?.size.height = CGFloat(self.autoCompleteFrameMaxHeight);
                self.autoCompleteTableView?.frame = tableFrame!;
                self.autoCompleteTableView?.setNeedsDisplay()
            }
            
            //Hide auto complete table view if no autocomplete entries exist
            if(self.autoCompleteArray.count == 0){
                self.autoCompleteTableView?.isHidden = true
            }else{
                self.autoCompleteTableView?.isHidden = false
                self.view.bringSubview(toFront: self.autoCompleteTableView!)
            }
            self.autoCompleteTableView?.reloadData()
        })
    }
    
    func coordinateBounds() -> GMSCoordinateBounds{
        var coordBounds: GMSCoordinateBounds?
        var coordinates: CLLocationCoordinate2D?
        //Only grab the user coordinates if their location services are enabled so we don't prompt them every time to enable them 
        if(CLLocationManager.locationServicesEnabled()){
            coordinates = locationManager?.location?.coordinate//CLLocationCoordinate2D(latitude: 37.788204, longitude: -122.411937)
        }else{
            coordinates = nil
        }
        if let center = coordinates{
            let northEast = CLLocationCoordinate2D(latitude: center.latitude + 0.001, longitude: center.longitude + 0.001)
            let southWest = CLLocationCoordinate2D(latitude: center.latitude - 0.001, longitude: center.longitude - 0.001)
            coordBounds = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        }else{  //If user has location services turned off then return coordinates of 0,0 to do a default search
            let coordNone = CLLocationCoordinate2D(latitude: CLLocationDegrees(0), longitude: CLLocationDegrees(0))
            coordBounds = GMSCoordinateBounds(coordinate: coordNone , coordinate: coordNone)
        }
        return coordBounds!
    }
    
    //Display an activity monitor while the user waits for the check in process
    func displayActivityMonitor(){
        //Create container view then loading for activity indicator to prevent background from overshadowing white color
        let frameWidth: CGFloat = 170.0, frameHeight: CGFloat = 30.0
        //center x, and place under text field for y
        let frameX = (view.frame.size.width - frameWidth) / 2
        let frameY = self.CheckInRestField.frame.maxY + 7.5
        self.loadingView.frame = CGRect(x: frameX ,y: frameY,width: frameWidth,height: frameHeight)
//        self.loadingView.center = view.center
        //Different shaded color than back ground
        self.loadingView.backgroundColor = UIColor(red: 0x74/255, green: 0x74/255, blue: 0x74/255, alpha: 0.7)
        self.loadingView.clipsToBounds = true
        self.loadingView.layer.cornerRadius = 10
        
        //Create label to add to view
        let loadingLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 140, height: 30))
        loadingLabel.text = "Check me out!"
        loadingLabel.font = UIFont(name: "Avenir-Heavy", size: 18)
        loadingLabel.textColor = .white
        loadingLabel.textAlignment = .center
        loadingView.addSubview(loadingLabel)
        
        //Create Activity indicator
        self.activityIndicator = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 20, height: 20)) as UIActivityIndicatorView
        self.activityIndicator.center = CGPoint(x: loadingView.frame.size.width - 20,y: loadingView.frame.size.height / 2);
        //        activityIndicator.backgroundColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 0.3)
        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.white
        self.activityIndicator.hidesWhenStopped = true
        
        self.loadingView.addSubview(activityIndicator)
        view.addSubview(loadingView)
        self.activityIndicator.startAnimating()
    }
    
    func clearActivityMonitor(){
        self.activityIndicator.stopAnimating()
        self.loadingView.removeFromSuperview()
    }

//    Manage and create new buttons
    
    func makeButtonSelected(_ button: UIButton) -> Bool {
        let checkImage = UIImage(named: "Check Symbol")
        button.setImage(checkImage, for: .selected)
        let imageSize: CGSize = checkImage!.size
        
        //User can select and deslect buttons
        //Sender.state = [.Normal, .Highlighted], append or delete .Selected
        button.isSelected = button.state == .highlighted ? true : false
        
        //Format location of check mark to be placed beneath button title
        if(button.isSelected){
            if let titleLabel = button.titleLabel {
                let spacing: CGFloat = button.frame.size.height / 3 //put check mark in botton 3rd of button
                //Shift title left (using negative value for left param) by the width of the image so text stays centered
                //Preserve previous title edge insets by adding 5 to left and right
                button.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width + 5, 0, 5)
                let labelString = NSString(string: titleLabel.text!)
                let titleSize = labelString.size(attributes: [NSFontAttributeName: titleLabel.font])
                //Shift image down by adding top edge inset of the size of the title + desired space
                //Shift image right by subtracting right inset by the width of the title
                button.imageEdgeInsets = UIEdgeInsetsMake(titleSize.height + spacing, 0.0, 0.0, -titleSize.width)
                let edgeOffset = abs(titleSize.height - imageSize.height) / 2.0;
                button.contentEdgeInsets = UIEdgeInsetsMake(edgeOffset, 0.0, edgeOffset, 0.0)
                button.backgroundColor = UIColor(white: 1, alpha: 0.5)

            }
        }
        else{
            button.backgroundColor = UIColor.clear
            button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 5, 0, 5) //prevent text from shift when removing check image, preserve original inset of 5 from button creation
        }
        return button.isSelected
    }
    
    //save City button to CoreData for persistance
    func saveCityButton(_ city: String)
    {
        if(self.cityButtonList.contains(city)){
            let alert = UIAlertController(title: "City Button Previously Exists", message: "Can't create button for \"\(city)\" because it already exists", preferredStyle: .alert)
            let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(CancelAction)
            self.present(alert, animated: true, completion: nil)
        }else{   //Save city to core data
            //Get Reference to NSManagedObjectContext
            //The managed object context lives as a property of the application delegate
            let appDelegate =
                UIApplication.shared.delegate as! AppDelegate
            //use the object context to set up a new managed object to be "commited" to CoreData
            let managedContext = appDelegate.managedObjectContext
            
            //Get my CoreData Entity and attach it to a managed context object
            let entity =  NSEntityDescription.entity(forEntityName: "CityButton",
                                                            in:managedContext)
            //create a new managed object and insert it into the managed object context
            let cityButtonMgObj = NSManagedObject(entity: entity!,
                                                insertInto: managedContext)
            
            //Using the managed object context set the "name" attribute to the parameter passed to this func
            cityButtonMgObj.setValue(city, forKey: "city")
            
            //save to CoreData, inside do block in case error is thrown
            do {
                try managedContext.save()
                //Insert the managed object that was saved to disk into the array used to populate the table
                //cityButtonCoreData.append(cityButtonMgObj)
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
    }
    
    //Retrieve from CoreData
    func retrieveCityButtons() -> [NSManagedObject]
    {
        var cityButtonCoreData = [NSManagedObject]()
        //pull up the application delegate and grab a reference to its managed object context
        let appDelegate =
            UIApplication.shared.delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //Setting a fetch request’s entity property, or alternatively initializing it with init(entityName:), fetches all objects of a particular entity
        //Fetch request could also be used to grab objects meeting certain criteria
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CityButton")
        
        do {
            var cityCount = 0   //Keep track of the city button indices
           
            /*Typically this seems to put the home city first and alpabet sort the remaining cities afterward. Lower case cities always come after an uppercase cities though*/
            let sortHomeDescriptor = NSSortDescriptor(key: "homeCity", ascending: false)
            let sortCityDescriptor = NSSortDescriptor(key: "city", ascending: true)
            let sortDescriptors = [sortHomeDescriptor, sortCityDescriptor]
            fetchRequest.sortDescriptors = sortDescriptors
            //fetchRequests asks for city button entity, try catch syntax used to handle errors
            let cityButtonEntity =
                try managedContext.fetch(fetchRequest)
            cityButtonCoreData = cityButtonEntity as! [NSManagedObject]
            
            //iterate over all attributes in City button entity
            for i in 0 ..< cityButtonCoreData.count{
                let cityButtonAttr = cityButtonCoreData[i]
                //optional chain anyObject to string and store in cityButtonArray
                if let cityNameStr = cityButtonAttr.value(forKey: "city") as? String
                {
                    //add city name to cityButtonlist if the city doesn't already exists
                    //this is how the array will be traversed to add a new city that was added by checking each city and incrementing even if a new city wasn't inserted into the array
                    //This will fail if the same city exists multiple times in User defaults because the search will allocate two entried in the array for it but only 1 will be filled
                        //If only 1 city is duplicated you will all cities following this city appear after the plus sign since the index will be incremented 1 ahead of where it should be
                    if(!cityButtonList.contains(where: {element in return (element == cityNameStr)}))
                    {
                        //Insert new element before the final plus sign in the list
                        self.cityButtonList.insert(cityNameStr, at: cityCount)
                    }
                    cityCount += 1
                    
                }else if let cityHome = cityButtonAttr.value(forKey: "homeCity") as? String {
                    //Insert home city at beginning of list if it doesn't already reside there
                    if(!cityButtonList.contains(where: {element in return (element == cityHome)})){
                        self.cityButtonList.insert(cityHome, at: cityCount)
                    }
                    cityCount += 1
                }
            }
        
        }
        catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        return cityButtonCoreData
    }

//    func sortListWithPlus(str1: string, str2: String)

    func createCityButtons()
    {
        let buttonSpacing = 13
        let buttonRad = 100
        //Update city button array to be current with all cities in CoreData Entity CityButton
        retrieveCityButtons()
        
        /*sort list of city buttons before printing
        //Move + sign to end of sort
        cityButtonList.sorted(by: {(s1:String, s2:String) -> Bool in
            if(s1 == "+" || s2 == "+"){
                return s1 > s2
            }
            else{
                return s1 < s2
            }
        })*/
        //remove all previously existing buttons from view to re-draw alternate loop to cat buttons
        for case let btn as UIButton in cityScrollContainerView.subviews{
                btn.removeFromSuperview()
        }
        cityScrollView.contentSize = CGSize(width: CGFloat((cityButtonList.count * buttonRad) + ((cityButtonList.count  + 1) * buttonSpacing)), height: 120) //Length of scroll view is the number of 100px buttons plus the number of 25px spacing plus an extra space for the final button, 120 high
        
        //Add container view to scroll view
        cityScrollView.addSubview(cityScrollContainerView)
        
        //add scroll view to super view
        view.addSubview(cityScrollView)
        
        //Add button to scroll view's container view
        for (index,cityText) in cityButtonList.enumerated(){
            let button = UIButton(frame: CGRect(x: (index * buttonRad) + ((index+1)*buttonSpacing), y: 10, width: buttonRad, height: buttonRad))   // X, Y, width, height
            button.layer.cornerRadius = 0.5 * button.bounds.size.width
            button.backgroundColor = UIColor.clear
            button.layer.borderWidth = 2.0
            button.layer.borderColor = UIColor.white.cgColor
            button.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
            button.titleLabel!.adjustsFontSizeToFitWidth = true
            button.titleLabel!.minimumScaleFactor = 0.6
            button.titleLabel!.lineBreakMode = .byTruncatingTail
            button.setTitle(cityText, for: UIControlState())
            //add target actions for button tap
            button.addTarget(self, action: #selector(CheckInViewController.citySelect(_:)), for: .touchUpInside)
            //Functions to highlight and unhighlight when touches begin
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtBeginTouch(_:)), for: .touchDown)
            //outside notices as soon as the finger leaves the button, exiting is anywhere outside
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtTouchCancel(_:)), for: .touchDragExit)
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtTouchCancel(_:)), for: .touchDragOutside)
            //Trying to capture all events that could be caused by the scroll view
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtTouchCancel(_:)), for: .touchUpOutside)
            //Touch cancel is caused by an event triggered by the system, this clears the button color when delete buttons are created
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtTouchCancel(_:)), for: .touchCancel)
            
            //add target actions for long press on button, but don't add to "+" button
            if(index != (cityButtonList.count - 1)){
                let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(CheckInViewController.displayCityDeleteButton(_:)))
                button.addGestureRecognizer(longGesture)
            }
            cityScrollContainerView.addSubview(button)
        }
    }
    
    func createCategoryButtons()
    {
        let buttonSpacing = 13
        //remove all previously existing buttons from view to re-draw
        for view in catScrollContainerView.subviews as [UIView] {
            if let btn = view as? UIButton {
                btn.removeFromSuperview()
            }
        }
        catScrollView.contentSize = CGSize(width: CGFloat((catButtonList.count * 100) + ((catButtonList.count  + 1) * buttonSpacing)), height: 120)
        //Add container view to scroll view
        catScrollView.addSubview(catScrollContainerView)
        //add scroll view to super view
        view.addSubview(catScrollView)
        //view.setNeedsLayout()
        //Add button to scroll view's container view
        
        for (index,catText) in catButtonList.enumerated(){
            let button = UIButton(frame: CGRect(x: (index * 100) + ((index+1) * buttonSpacing), y: 10, width: 100, height: 100))   // X, Y, width, height
            button.layer.cornerRadius = 0.5 * button.bounds.size.width
            button.backgroundColor = UIColor.clear
            button.layer.borderWidth = 2.0
            button.layer.borderColor = UIColor.white.cgColor
            button.titleLabel!.adjustsFontSizeToFitWidth = true;
            button.titleLabel!.minimumScaleFactor = 0.7;
            button.setTitle(catText, for: UIControlState())
            button.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
            button.addTarget(self, action: #selector(CheckInViewController.categorySelect(_:)), for: .touchUpInside)
            //Functions to highlight and unhighlight when touches begin
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtBeginTouch(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtTouchCancel(_:)), for: .touchDragExit)
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtTouchCancel(_:)), for: .touchDragOutside)
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtTouchCancel(_:)), for: .touchUpOutside)
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtTouchCancel(_:)), for: .touchCancel)
            catScrollContainerView.addSubview(button)
            //button.setNeedsLayout()
        }

    }
    
    func displayCityDeleteButton(_ sender: UILongPressGestureRecognizer)
    {
        let buttonSpacing = 13
        let buttonRad = 100
        let tapLocation = sender.location(in: self.cityScrollView)

        //Determine associated button receiving long press by calculating location (Don't allow "+" button to be deleted by iterating to count -1
        for i in 0..<(cityButtonList.count - 1){
            let locBegin = (i * buttonRad) + ((i+1)*buttonSpacing)
            let locEnd = ((i + 1) * buttonRad) + ((i + 2)*buttonSpacing)
            if(Int(tapLocation.x) > locBegin && Int(tapLocation.x) < locEnd){
                //Custom button used to contain the button enum so that the delete function has a reference to the City
                let button = DeleteCityUIButton(frame: CGRect(x: locBegin, y: 0, width: buttonRad / 3, height: buttonRad / 3))
                button.buttonEnum = i
                button.layer.cornerRadius = 0.5 * button.bounds.size.width
                button.backgroundColor = UIColor(white: 0.75, alpha: 0.9)
                //Chalkboard font has rounded edges that I'm looking for but shifts the title label downwards so I use insets to shift it back upwards
                button.setTitle("x", for: UIControlState())
                button.titleLabel?.font = UIFont(name: "ChalkboardSE-Bold", size: CGFloat(buttonRad / 3))
                button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 11, right: 0)
//                button.titleLabel?.font = UIFont.systemFont(ofSize: CGFloat(buttonRad / 4), weight: UIFontWeightBold)
                button.setTitleColor(UIColor.black, for: UIControlState())
                button.addTarget(self, action: #selector(CheckInViewController.deleteCity(_:)), for: .touchUpInside)
                cityScrollContainerView.addSubview(button)
            }
        }
    }
    
    //Used in conjunction with the added gesture on the scroll view's area not containing buttons
    func clearCityDeleteButton(_ sender: UITapGestureRecognizer)
    {
        for case let btn as DeleteCityUIButton in cityScrollContainerView.subviews{
            btn.removeFromSuperview()
        }
        //For the actual city buttons remove any background color they received from the touch down event
        for case let btn as UIButton in cityScrollContainerView.subviews{
            if(!btn.isSelected){
                btn.backgroundColor = UIColor.clear
            }
        }
    }
    
    func deleteCity(_ sender: DeleteCityUIButton){
        
        let coreData = retrieveCityButtons()  //store list of city attributes from cityButton entity
        //        Remove City from Core Data
        //The managed object context lives as a property of the application delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //use the object context to set up a new managed object to be "commited" to CoreData
        let managedContext = appDelegate.managedObjectContext
        //sorted city attributes can be selected by the button Enum
        let buttonEnum = sender.buttonEnum

        
        //Check if I will have to handle a user attempting to the delete the home city
        //If home city has been added then the user is attempting to delete their home city when buttonEnum is 0
        //If homeAdded is not nil and true then prompt the user that they will delete their home city with this action
        if (buttonEnum == 0 && ((homeAdded as Bool?) ?? false)){
            let alert = UIAlertController(title: "Tired of this town?", message: "Are you sure you want to delete your home city?", preferredStyle: .alert)
            //Exit function if user clicks now and allow them to reconfigure the check in
            let CancelAction = UIAlertAction(title: "No", style: .cancel, handler: {UIAlertAction in
                //Remove any delete city buttons to clean the screen by calling the same function that touches to the scroll view use to clear icons
                self.clearCityDeleteButton(UITapGestureRecognizer())
            })
            //Perform the delete operation in the closure called by the confirm action
            let ConfirmAction = UIAlertAction(title: "Yes", style: .default, handler: { UIAlertAction in
                sender.removeFromSuperview()
                
                managedContext.delete(coreData[buttonEnum] as NSManagedObject)
                do {
                    try managedContext.save()   //Updated core data with the deleted attribute
                    self.cityButtonList.remove(at: buttonEnum)
                    self.createCityButtons() //redraw Buttons
                    //Modify user default to indicate the user no longer has a home city
                    self.homeAdded = false
                }catch _ {
                }

            })
            alert.addAction(ConfirmAction)
            alert.addAction(CancelAction)
            //Remove activity monitor so alertview can be presented
            self.present(alert, animated: true, completion:nil )
        }else{
            sender.removeFromSuperview()
            
            managedContext.delete(coreData[buttonEnum] as NSManagedObject)
            do {
                try managedContext.save()   //Updated core data with the deleted attribute
            }catch _ {
            }
            cityButtonList.remove(at: buttonEnum)
            createCityButtons() //redraw Buttons
        }
        
    }


//    @IBAction func touchUp() {
//            //Create allert
//        let alert = UIAlertController(title: "New Name",
//                                      message: "Add a new name",
//                                      preferredStyle: .Alert)
//        
//        //Create action buttons for the alert
//        let saveAction = UIAlertAction(title: "Save",
//                                       style: .Default,
//                                       handler: { (action:UIAlertAction) -> Void in
//                                        
//                                        let textField = alert.textFields!.first
//                                        self.ref.updateChildValues([textField!.text!:true])
//                                        //self.save2CoreData(textField!.text!)
//                                                })
//        
//        let cancelAction = UIAlertAction(title: "Cancel",
//                                         style: .Default) { (action: UIAlertAction) -> Void in
//        }
//        
//        //Create a text field for the alert
//        alert.addTextFieldWithConfigurationHandler {
//            (textField: UITextField) -> Void in
//        }
//        //Add action buttons to the alert
//        alert.addAction(saveAction)
//        alert.addAction(cancelAction)
//        
//        presentViewController(alert,
//                              animated: true,
//                              completion: nil)
//        
//    }

    func animateCheckComplete() {
        let checkImage = UIImageView(image: UIImage(named: "animationCheck"))
        //Get starting point for check image
        let textFieldCenterX = CheckInRestField.frame.minX + (CheckInRestField.frame.width / 2)
        let textFieldCenterY = CheckInRestField.frame.minY
        //Get final point for check image animate
        //My list icon has title insets 20 from top and 20 from right, split that by half and incorporate into point location to have check end in center or button
        let checkListCenterX = myListIcon.frame.minX + 7
        let checkListCenterY = myListIcon.frame.minY + (myListIcon.frame.height / 2) - 3
        //Create check image view located in the center of the text box
        var checkFrame = CGRect(x: textFieldCenterX, y: textFieldCenterY, width: checkImage.frame.width, height: checkImage.frame.height)
        let checkContainer = UIImageView(frame: checkFrame)
        checkContainer.addSubview(checkImage)
        view.addSubview(checkContainer)
        //Define the mid point that the check will jump to(dependant on size of check mark) before falling to final point at my list icon
        let bounds = checkContainer.bounds
        let midFrame = checkFrame.offsetBy(dx: -bounds.size.height * 2, dy: -(bounds.size.height * 2))
        
        UIView.animateKeyframes(withDuration: 1, delay: 0, options: .calculationModeCubic, animations: {
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.3) {
                checkContainer.frame = midFrame
            }
            checkFrame.origin.x = checkListCenterX
            checkFrame.origin.y = checkListCenterY
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.7) {
                checkContainer.frame = checkFrame
            }
        }, completion: { finished in
            UIView.animate(withDuration: 0.3, animations: {
                checkContainer.alpha = 0.0
            }, completion: { finished in
                    checkContainer.removeFromSuperview()
            })

        })
    }

    func notifyUser()
    {
//        let alert = UIAlertController(title: "Checked In",
//                                      message: "You added a new Check In",
//                                      preferredStyle: .Alert)
//        
//        //Create action buttons for the alert
//        let cancelAction = UIAlertAction(title: "OK",
//                                         style: .Default) { (action: UIAlertAction) -> Void in
//        }
//        
//        //Create a text field for the alert
//        alert.addTextFieldWithConfigurationHandler {
//            (textField: UITextField) -> Void in
//        }
//        //Add action buttons to the alert
//        alert.addAction(cancelAction)
//        
//        presentViewController(alert,
//                              animated: true,
//                              completion: nil)
//        let alertController = UIAlertController(title: "Check In Out", message:
//            "Saved!", preferredStyle: UIAlertControllerStyle.Alert)
//        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
//        
//        self.presentViewController(alertController, animated: true, completion: nil)
    }
    //
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print(segue.destination)
    }
    //
    
    
    

}
