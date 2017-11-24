//
//  ProfileStepsViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 1/21/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import CoreData
import GooglePlaces

class ProfileStepsViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    //Scroll view used to slide text box above keyboard
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var addCityLabel: UILabel!
    
    //Items on the page that are remove depedning on whether we are onbooarding
    @IBOutlet var backButton: UIButton!
    @IBOutlet var skipButon: UIButton!
    @IBOutlet var pagenationImage: UIImageView!
    //Class member that can be set when transitioning to this VC during the onboarding process
    var isOnboarding: Bool = false
    var unwindPerformed = false
    //Calculate the size of the text box and label I want to move above the keyboard
    var boxAndLabelSize: CGFloat = 0
    //Calculate the offset between the bottom of the scroll view and superview to account for scrolling the text box to be visible above the keyboard
    var bottomScrollOffset: CGFloat = 0
    
    var autoCompleteArray = [GMSAutocompletePrediction]()  //Table data containing string from google prediction array
    
    var autoCompleteTableView: UITableView?
    let autoCompleteFrameMaxHeight = 87
    let autoCompleteCellHeight = 33
    let googleImageView = UIImageView(image: UIImage(named: "googleNonWhite")) //Google attribution image view
    var tableContainerView: UIView?     //Container view for autocomplete table so border and rounded edges can be achieved
    //Google places client
    var placesClient: GMSPlacesClient!
    var activeTextField: UITextField? = nil
    
    //Use place ID as distinguishing factor that an autocomplete entry was used
    var addCityPlaceId: String?
    var homeCityPlaceId: String?
    
    //Set up NSUserDefaults to save boolean noting that home city exists
    fileprivate let sharedUserHome = UserDefaults.standard
    let sharedHomeDefaultKey = "ProfileStepsVC.homeAdded"
    var homeAdded: NSNumber {
        get
        {
            return (sharedUserHome.object(forKey: sharedHomeDefaultKey) as? NSNumber)!
        }
        set
        {
            sharedUserHome.set(newValue, forKey: sharedHomeDefaultKey)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addTextBoxBorder()
        
        //Remove views and buttons that do not appear during onboarding
        if(self.isOnboarding){
            //Hide then remove back button
            self.backButton.isHidden = true
            self.backButton.removeFromSuperview()
        }else{
            //Hide first before removing so the user doesn't see them appear before they are removed
            self.skipButon.isHidden = true
            self.pagenationImage.isHidden = true
            self.skipButon.removeFromSuperview()
            self.pagenationImage.removeFromSuperview()
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //register so that I receive notifications from the keyboard
        registerForKeyboardNotifications()
        
        self.boxAndLabelSize = addCityTextBox.frame.height + addCityLabel.frame.height
        self.bottomScrollOffset = self.view.frame.maxY - self.scrollView.frame.maxY
        //gooogle Places setup
        placesClient = GMSPlacesClient.shared()
        
        //Create autocomplete table view in View did appear because constraints to resize text box had not yet been added during viewDidLoad
        let autoCompleteFrame = CGRect(x: addCityTextBox.frame.minX, y: addCityTextBox.frame.maxY, width: addCityTextBox.frame.size.width, height: CGFloat(self.autoCompleteFrameMaxHeight))
        autoCompleteTableView = UITableView(frame: autoCompleteFrame, style: UITableViewStyle.plain)
        autoCompleteTableView?.delegate = self;
        autoCompleteTableView?.dataSource = self;
        autoCompleteTableView?.isHidden = true;
        autoCompleteTableView?.isScrollEnabled = true;
        autoCompleteTableView?.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        autoCompleteTableView?.layer.cornerRadius = 15
        autoCompleteTableView?.backgroundColor = UIColor(red: 0x40/0x255, green: 0x40/0x255, blue: 0x40/0x255, alpha: 1.0)
        autoCompleteTableView?.separatorColor = .white
        scrollView.addSubview(autoCompleteTableView!)
        //remove left padding from tableview seperators
        autoCompleteTableView?.layoutMargins = UIEdgeInsets.zero
        autoCompleteTableView?.separatorInset = UIEdgeInsets.zero
        
        //add top separator line to footer
        let px = 1 / UIScreen.main.scale
        //create image view for the center of the footer view
        let googleFrame = CGRect(x: (autoCompleteFrame.width - googleImageView.frame.width) / 2, y: 5, width: googleImageView.frame.width, height: googleImageView.frame.height + px + 5)
        let googs = UIImageView(frame: googleFrame)
        googs.addSubview(googleImageView)
        
        //create google attribution for bottom of table
        let tableFooterFrame = CGRect(x: 0, y: 0, width: autoCompleteFrame.width, height: googleImageView.frame.height + px + 10)
        let tableFooterView = UIView(frame: tableFooterFrame)
        tableFooterView.addSubview(googs)
        
        //Create cell seperator at top of table footer
        let frame = CGRect(x: 0, y: 0, width: (self.autoCompleteTableView?.frame.size.width)!, height: px)
        let line: UIView = UIView(frame: frame)
        tableFooterView.addSubview(line)
        line.backgroundColor = .white

        //Set autocomplete footer view with google attribution this way so that footer doesn't float
        autoCompleteTableView?.tableFooterView = tableFooterView

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set text field delegates so they can dismiss the keyboard
        self.homeCityTextBox.delegate = self
        self.addCityTextBox.delegate = self
        
        //Create Proper look for add city button
        self.addCityButton.layer.cornerRadius = 0.5 * self.addCityButton.bounds.size.width
        self.addCityButton.backgroundColor = UIColor.clear
        self.addCityButton.layer.borderWidth = 1.0
        self.addCityButton.layer.borderColor = UIColor.black.cgColor
        
        //Add target to check in rest field that detects when a change occurs
        self.homeCityTextBox.addTarget(self, action: #selector(ProfileStepsViewController.googleAutoComplete(_:)),
                                        for: UIControlEvents.editingChanged)
        self.addCityTextBox.addTarget(self, action: #selector(ProfileStepsViewController.googleAutoComplete(_:)),
                                       for: UIControlEvents.editingChanged)
        self.addCityTextBox.autocapitalizationType = .words
        self.homeCityTextBox.autocapitalizationType = .words
    }
    

    @IBOutlet weak var homeCityTextBox: UITextField!
    @IBOutlet weak var addCityTextBox: UITextField!
    
  
     @IBOutlet weak var addCityButton: UIButton!
    @IBAction func addCityPressed(_ sender: UIButton) {
        if let cityText = addCityTextBox?.text{
            if(cityText != "" && (addCityPlaceId != nil)){
                //Add city to core data
                saveCityButton(cityText)
                addCityTextBox.placeholder = "Add more cities..."
                addCityTextBox.text = ""
                //Clear place id so the user can't enter an incorrect city on any additional entries
                self.addCityPlaceId = nil
            }else{
                if(cityText == ""){
                    displayAddCityMissing()
                }else if(addCityPlaceId == nil){
                    let alert = UIAlertController(title: "Google is your friend", message: "You entered \(cityText) manually, instead please use our reccomended cities from the list. Try editing your current city until you find a viable match from the list", preferredStyle: .alert)
                    let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(CancelAction)
                    self.present(alert, animated: true, completion: nil)
                }else{ //should never be reached
                    defaultCitySaveError()
                }
            }
        }else{
            displayAddCityMissing()
        }
    }
    
    func displayAddCityMissing(){
        let alert = UIAlertController(title: "Please pick a city", message: "It doesn't look like you entered a city to add...", preferredStyle: .alert)
        let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(CancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func defaultCitySaveError(){
        let alert = UIAlertController(title: "City Save Error", message: "We're sorry, there was an error saving your city. You can add new cities from the Check In Screen once you get there.", preferredStyle: .alert)
        let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(CancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func proceedButtonPressed(_ sender: UIButton) {
        //Check if any text is left on add city line, and if the city was saved to user defaults or if it was rejected
        var didSave = true
        if let cityText = addCityTextBox?.text{
            if(cityText != ""){
                if(addCityPlaceId != nil){
                    //Add city to core data
                    didSave = saveCityButton(cityText)
                }else if(addCityPlaceId == nil){
                    //Don't continue because the add city entry wasn't able to be saved
                    didSave = false
                    let alert = UIAlertController(title: "Google is your friend", message: "You entered your additional city \(cityText) manually, instead please use our reccomended cities from the list. Try editing \(cityText) until you find a viable match from the list", preferredStyle: .alert)
                    let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(CancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        if (didSave){
            //Save home city
            if var cityText = homeCityTextBox?.text{
                if(cityText != "" && (homeCityPlaceId != nil)){
                    //Remove any trailing spaces from restNameText
//                    cityText = cityText.trimmingCharacters(in: .whitespaces)
                    //Function only returns true when user trys to overwrite currently saved home city, so I wont transition here and let alert controller closure handle segue, or wait until submit is hit again
                    let displayAlert = saveHomeCity(cityText)
                    if(!displayAlert){
                        //Choose segue destination whether you need to continue onboard or return to profile VC
                        if(self.isOnboarding){
                            performSegue(withIdentifier: "segueToAddFriends", sender: nil)
                        }else{
                            performSegue(withIdentifier: "unwindFromAddPlaces", sender: nil)
                        }
                    }
                }else{
                    //Notify User why home city can't be saved(either empty or didn't use autocomplete
                    if(cityText == ""){
                        missingHomeAlert()
                    }else if(homeCityPlaceId == nil){
                        let alert = UIAlertController(title: "Google is your friend", message: "You entered your home city \(cityText) manually, instead please use our reccomended cities from the list. Try editing your current home city until you find a viable match from the list", preferredStyle: .alert)
                        let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alert.addAction(CancelAction)
                        self.present(alert, animated: true, completion: nil)
                    }else{  //Should never be reached
                        defaultCitySaveError()
                    }
                }
            }else{
                missingHomeAlert()
            }
        }
    }
    
    func missingHomeAlert(){
        let alert = UIAlertController(title: "Missing Home City", message: "Tell us your home city and we'll make it easier for you to check in around town.", preferredStyle: .alert)
        let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(CancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveHomeCity(_ homeCity: String) -> Bool{
        var addNewHome = true
        var displayAlert = false
        //Get Reference to NSManagedObjectContext
        //The managed object context lives as a property of the application delegate
        let appDelegate =
            UIApplication.shared.delegate as! AppDelegate
        //use the object context to set up a new managed object to be "commited" to CoreData
        let managedContext = appDelegate.managedObjectContext
        
        //Retrieve from CityButton entity only the homeCity attribute
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CityButton")
        
        do {
            let cityButtonEntity =
                try managedContext.fetch(fetchRequest)
            let homeCityCoreData = cityButtonEntity as! [NSManagedObject]
            //Check if the user is changing their home city
            for i in 0 ..< homeCityCoreData.count{
                if let cityNameStr = homeCityCoreData[i].value(forKey: "homeCity") as? String{
                    //mark that home city was previously set
                    addNewHome = false
                    if (cityNameStr != homeCity){
                        displayAlert = true
                        let alert = UIAlertController(title: "Have you Moved?", message: "Are you sure you want to change your home city from \(cityNameStr) to \(homeCity)?", preferredStyle: .alert)
                        //Async call for uialertview will have already left this function, no handling needed
                        let CancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
                        
                        let ConfirmAction = UIAlertAction(title: "Yes", style: .default, handler: { UIAlertAction in
                            //Save the new value in core data
                            
                            homeCityCoreData[i].setValue(homeCity, forKey: "homeCity")
                            
                            do {
                                try homeCityCoreData[i].managedObjectContext?.save()
                                self.homeAdded = true
                            } catch {
                                let saveError = error as NSError
                                let errorString = String(describing: saveError)
                                Helpers().myPrint(text: errorString)
                            }
                            //Choose segue destination whether you need to continue onboard or return to profile VC
                            if(self.isOnboarding){
                                self.performSegue(withIdentifier: "segueToAddFriends", sender: nil)
                            }else{
                                self.performSegue(withIdentifier: "unwindFromAddPlaces", sender: nil)
                            }
                        })
                        alert.addAction(CancelAction)
                        alert.addAction(ConfirmAction)
                        self.modalPresentationStyle = .overCurrentContext
                        self.present(alert, animated: true, completion: nil)
                    }
                }else if let cityNameStr = homeCityCoreData[i].value(forKey: "city") as? String{
                    //Check all other cities to make sure their home city doesn't exist there
                    if( cityNameStr == homeCity){
                        addNewHome = false
                        displayAlert = true
                        let alert = UIAlertController(title: "Home City Exists", message: "You have already added \(cityNameStr) to your city list. Please delete \(cityNameStr) from your city list before adding as your home city.", preferredStyle: .alert)
                        //Async call for uialertview will have already left this function, no handling needed
                        let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    
                        alert.addAction(CancelAction)
                        self.modalPresentationStyle = .overCurrentContext
                        self.present(alert, animated: true, completion: nil)
                    }
                }

            }
            if (addNewHome){//save to coredata since no previous entry existed

                //Get my CoreData Entity and attach it to a managed context object
                let entity =  NSEntityDescription.entity(forEntityName: "CityButton",
                                                         in:managedContext)
                //create a new managed object and insert it into the managed object context
                let cityButtonMgObj = NSManagedObject(entity: entity!,
                                                      insertInto: managedContext)
                
                //Using the managed object context set the "name" attribute to the parameter passed to this func
                cityButtonMgObj.setValue(homeCity, forKey: "homeCity")
                
                //save to CoreData, inside do block in case error is thrown
                do {
                    try managedContext.save()
                    //Save to NSUSerDefaults that the user now has a home city saved
                    homeAdded = true
                } catch let error as NSError  {
                    Helpers().myPrint(text: "Could not save \(error), \(error.userInfo)")
                }

            }
        }catch let error as NSError {
            Helpers().myPrint(text: "Could not fetch \(error), \(error.userInfo)")
        }
        //Notify the submit button to not transition until alert controller is handled
        return displayAlert
   }
    
    func googleAutoComplete(_ textField: UITextField) {

        if let cityString = self.activeTextField?.text{
            //Start querying google database with at minimum 3 chars
            if(cityString.characters.count >= 3 && (cityString.characters.count % 2 != 0)){
                placeAutocomplete(queryText: cityString)
            }else if (cityString.characters.count < 3){
                autoCompleteTableView?.isHidden = true
            }
        }
    }
    
    func placeAutocomplete(queryText: String) {
        let filter = GMSAutocompleteFilter()
            filter.type = .city
        //create global search by using coord bounds of 0,0
        let coordNone = CLLocationCoordinate2D(latitude: CLLocationDegrees(0), longitude: CLLocationDegrees(0))
        let coordBounds = GMSCoordinateBounds(coordinate: coordNone , coordinate: coordNone)
        placesClient.autocompleteQuery(queryText, bounds: coordBounds, filter: filter, callback: {(results, error) -> Void in
            if let error = error {
                Helpers().myPrint(text: "Autocomplete error \(error)")
                return
            }
            //Remove previous entries in autocomplete arrays
            //AUtoCompleteArray is table data, and maps 1 to 1 to the complete data set contained in googlePrediction array
            self.autoCompleteArray.removeAll()
            if let results = results {
                for result in results {
                    self.autoCompleteArray.append(result)
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
                self.autoCompleteTableView?.frame = tableFrame!
                self.autoCompleteTableView?.setNeedsDisplay()
            }
            
            //Hide auto complete table view if no autocomplete entries exist
            if(self.autoCompleteArray.count == 0){
                self.autoCompleteTableView?.isHidden = true
            }else{
                self.autoCompleteTableView?.isHidden = false
                self.scrollView.bringSubview(toFront: self.autoCompleteTableView!)
            }
            self.autoCompleteTableView?.reloadData()
        })
    }
    
    func addTextBoxBorder(){
        //Create underline bar for home city and additional city text boxes
        let px = 1 / UIScreen.main.scale    //determinte 1 pixel size instead of using 1 point
        let homeCityFrame = CGRect(x: homeCityTextBox.frame.minX, y: homeCityTextBox.frame.maxY, width: homeCityTextBox.frame.size.width, height: px)
        let homeCityLine: UIView = UIView(frame: homeCityFrame)
        homeCityLine.backgroundColor = UIColor.black
        let addCityFrame = CGRect(x: addCityTextBox.frame.minX, y: addCityTextBox.frame.maxY, width: homeCityTextBox.frame.size.width, height: px)
        let addCityLine: UIView = UIView(frame: addCityFrame)
        addCityLine.backgroundColor = UIColor.black
        //Add underline to view
        scrollView.addSubview(homeCityLine)
        scrollView.addSubview(addCityLine)
    }

    
    //save City button to CoreData for persistance
    func saveCityButton(_ city: String) -> Bool
    {
        var isHomeCity = false //Make sure user isn't trying to add a city that is their home city
        var shouldSave = true   //Asume we will save the user's city unless we find their user defaults already has that city
        var cityButtonCoreData = [NSManagedObject]()
        //Get Reference to NSManagedObjectContext
        //The managed object context lives as a property of the application delegate
        let appDelegate =
            UIApplication.shared.delegate as! AppDelegate
        //use the object context to set up a new managed object to be "commited" to CoreData
        let managedContext = appDelegate.managedObjectContext
        
        //Create fetch request to retieve data before saving new city
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CityButton")
        
        //Get my CoreData Entity and attach it to a managed context object
        let entity =  NSEntityDescription.entity(forEntityName: "CityButton",
                                                 in:managedContext)
        //create a new managed object and insert it into the managed object context
        let cityButtonMgObj = NSManagedObject(entity: entity!,
                                              insertInto: managedContext)
        
        
        //Check if the city previously existed then save to CoreData, inside do block in case error is thrown
        do {
            //Fetch existing cities and compare to the city being added
            //fetchRequests asks for city button entity, try catch syntax used to handle errors
            let cityButtonEntity =
                try managedContext.fetch(fetchRequest)
            cityButtonCoreData = cityButtonEntity as! [NSManagedObject]
            
            //iterate over all attributes in City button entity
            cityLoop: for i in 0 ..< cityButtonCoreData.count{
                let cityButtonAttr = cityButtonCoreData[i]
                //optional chain anyObject to string and store in cityButtonArray
                if let cityNameStr = cityButtonAttr.value(forKey: "city") as? String
                {
                    //Compare each city to the city the user is attempting to save
                    if(cityNameStr == city){
                        shouldSave = false
                        break cityLoop  //Done checking against user defaults because we found the city
                    }
                }else if let cityNameStr = cityButtonAttr.value(forKey: "homeCity") as? String
                {
                    //Compare each city to the city the user is attempting to save
                    if(cityNameStr == city){
                        shouldSave = false
                        isHomeCity = true
                        break cityLoop  //Done checking against user defaults because we found the city
                    }
                }
            }

            if(shouldSave){
                //Using the managed object context set the "name" attribute to the parameter passed to this func
                cityButtonMgObj.setValue(city, forKey: "city")
                try managedContext.save()
            }else{  //Create notification that this city already exists
                
                let alert = UIAlertController(title: "Duplicate City", message: isHomeCity ? "You have already made \(city) your home city!" : "You have already added \(city), go ahead and add a Check In here!", preferredStyle: .alert)
                let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: { UIAlertAction in
                    self.activeTextField?.text = nil
                    
                })
                alert.addAction(CancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        } catch let error as NSError  {
            Helpers().myPrint(text: "Could not save \(error), \(error.userInfo)")
        }
        return shouldSave
    }
    
    //Unused function, instead using global var activeTextField
    func returnActiveField() -> UITextField?{
        //Determine the active field
        
        if let activeField = self.addCityTextBox{
            return activeField
        }else if let activeField = self.homeCityTextBox{
            return activeField
        }else{//No active field
            return nil
        }

    }
    
    
    //TableView delegate functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autoCompleteArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(autoCompleteCellHeight)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = autoCompleteArray[indexPath.row].attributedFullText.string
        cell.textLabel?.textColor = .white
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.minimumScaleFactor = 0.6
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Grab the city name from primary text and get the state name from secondaryText
        var cityState = autoCompleteArray[indexPath.row].attributedPrimaryText.string
        
        //unwrap secondary text or quit while we're ahead
        guard let secondaryText = autoCompleteArray[indexPath.row].attributedSecondaryText?.string else {
            return
        }
        //Find the first comma in the secondary text, which should fall after the state
        if let rangeOfSpace = secondaryText.range(of: ",") {
            //Convert the range returned by the comma to an index and return the string from the space to end of dispay name
            let stateName = secondaryText.substring(to: rangeOfSpace.lowerBound)
            cityState = cityState + ", " + stateName
        }

        self.activeTextField?.text = cityState
        //Use placeholder text to determine which text box is being edited
        //The place holder text changes after the first city is added to "add more cities"
        if((self.activeTextField?.placeholder == "Pick more cities...") || (self.activeTextField?.placeholder == "Add more cities...")){
            //Store place Id essentially as a flag that autocomplete was used
            self.addCityPlaceId = autoCompleteArray[indexPath.row].placeID
        }else{
            self.homeCityPlaceId = autoCompleteArray[indexPath.row].placeID
        }
        autoCompleteTableView?.isHidden = true
        //dismiss keyboard if present
        self.activeTextField?.resignFirstResponder()
    }

    
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
        //Height of content inserts considers the height of the keyboard from the bottom of the screen, but the scroll view doesn't extend to the bottom of the screen, so subract the bottom Scroll offset
        //move the text box high enough so that the text box and auto complete frame can be shown without contacting the keyboard
        let insetHeight = (keyboardSize!.height - self.bottomScrollOffset) + (self.boxAndLabelSize + CGFloat(self.autoCompleteFrameMaxHeight) )
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, insetHeight, 0.0)
        
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if let activeField = self.activeTextField {
            //check-me: Only checking if keyboard reaches text box, should I be calculating a CGPoint that is high enough for the max table frame too be included in this contains parameter?
            if (!aRect.contains(activeField.frame.origin)){
                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
        
    }
    //Sets insets to 0, the defaults
    func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        //check-me: Should I be subtracting the max table frame height here too?
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -(keyboardSize!.height - self.bottomScrollOffset + self.boxAndLabelSize), 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
        self.scrollView.isScrollEnabled = false
    }
    
    //2 funcs below are used to set and clear activeFields var
    func textFieldDidBeginEditing(_ textField: UITextField){
        self.activeTextField = textField
        let autoCompleteFrame = CGRect(x: textField.frame.minX, y: textField.frame.maxY, width: textField.frame.size.width, height: CGFloat(self.autoCompleteFrameMaxHeight))
        autoCompleteTableView?.frame = autoCompleteFrame
        //Clear any previous entries that may exist in the autocomplete array and hide the table so that an erroneous autocomplete table doesn't pop up
        self.autoCompleteArray.removeAll()
        self.autoCompleteTableView?.isHidden = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        self.activeTextField = nil
    }
    
    
    //Dismiss keyboard if clicking away from text box
    //Detect when user taps outside of scroll vie
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesBegan(touches, with: event)
        
        if let touch: UITouch = touches.first{
            homeCityTextBox.resignFirstResponder()
            addCityTextBox.resignFirstResponder()
        }
    }
    
    //Actions to take when user dismisses keyboard: hide keyboard & autocomplete table, add first row text to text box
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        self.autoCompleteTableView?.isHidden = true
        return true
    }
    
   /* Moved to view did disappear
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //When transitioning to next screen in profile steps deregister keyboard notifications
        //Don't perform when unwinding
        if (!self.unwindPerformed){
            deregisterFromKeyboardNotifications()
        }
    }*/
    
    
    
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        //Check if unwind segue was performed so that prepare for seguing will not deregister keyboard notifications an unwind
        self.unwindPerformed = true
        return false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //Stop the keyboard actions from sending notifications
        deregisterFromKeyboardNotifications()
    }
    
    //Pass email and password to Login info screen if new login
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        //Only notify the destination VC that we're onboarding if the class member exists at the destination
        if(segue.identifier == "segueToAddFriends"){
            let destinationVC = segue.destination as! AddPeopleViewCntroller
            //Notify the AddPeopleVC that it is being accessed during onboarding
            destinationVC.isOnboarding = true
        }
    }

}
