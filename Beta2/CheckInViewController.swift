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
    var catButtonList = ["Bar", "Breakfast", "Brewery", "Brunch", "Beaches", "Coffee Shops", "Night Club", "Dessert", "Dinner", "Food Truck", "Hikes", "Lunch", "Museums", "Parks", "Site Seeing", "Winery"]
    var placesArr = [String]()
    var arrSize = Int()
    var checkObj = placeNode()
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
    
    fileprivate let sharedRestName = UserDefaults.standard
    
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
    
    let currUserDefaultKey = "FBloginVC.currUser"
    fileprivate let sharedFbUser = UserDefaults.standard
    
    //NSUser defaults stores user i
    var currUser: NSString {
        get
        {
            return (sharedFbUser.object(forKey: currUserDefaultKey) as? NSString)!
        }
    }
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
        
        //create image view for the center of the footer view
        let googleFrame = CGRect(x: (autoCompleteFrame.width - googleImageView.frame.width) / 2, y: 0, width: googleImageView.frame.width, height: googleImageView.frame.height)
        let googs = UIImageView(frame: googleFrame)
        googs.addSubview(googleImageView)
        
        //create google attribution for bottom of table
        let tableFooterFrame = CGRect(x: 0, y: 0, width: autoCompleteFrame.width, height: googleImageView.frame.height)
        let tableFooterView = UIView(frame: tableFooterFrame)
        tableFooterView.addSubview(googs)
        
        //Set autocomplete footer view with google attribution this way so that footer doesn't float
        autoCompleteTableView?.tableFooterView = tableFooterView
    }
//  Layout views in view controller
    
    //Since the bounds of the view controller's view is not ready in viewDidLoad, anything that will be calculated based off the view's bounds directly or indirectly must not be put in viewDidLoad (so we put it in did layout subviews
    override func viewDidLoad() {
        super.viewDidLoad()

        //Auto Capitalize words in text box field
        self.CheckInRestField.autocapitalizationType = .words
        //Add target to check in rest field that detects when a change occurs
        self.CheckInRestField.addTarget(self, action: #selector(CheckInViewController.googleAutoComplete(_:)),
                  for: UIControlEvents.editingChanged)
        //setup City scroll view
        cityScrollView = UIScrollView()
        cityScrollView.delegate = self
        //setup Category scroll view
        catScrollView = UIScrollView()
        catScrollView.delegate = self
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
            locationManager?.requestAlwaysAuthorization()
        }
        
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 200
        locationManager?.delegate = self
        startUpdatingLocation()

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
//        if(!isEnteringCity){
            cell.textLabel?.text = googlePrediction[indexPath.row].attributedFullText.string
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            cell.textLabel?.minimumScaleFactor = 0.6
            cell.textLabel?.lineBreakMode = .byTruncatingTail
//        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        CheckInRestField.text = googlePrediction[indexPath.row].attributedPrimaryText.string
        //Store placeId object to be stored in firebase with the check in
        checkObj.placeId = googlePrediction[indexPath.row].placeID
        autoCompleteTableView?.isHidden = true
    }
    

    @IBOutlet weak var CheckInRestField: UITextField!
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromMyList(_ sender: UIStoryboardSegue) {
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
                saveCityButton(addButtonText)
                CheckInRestField.text = ""
                CheckInRestField.placeholder = "Enter Name..."
                isEnteringCity = false
                //Remove clear button after city is checked in
                CheckInRestField.clearButtonMode = .never
                createCityButtons()
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
            //Save a city Check in entry
        else
        {
            var restNameText = CheckInRestField.text!
            //Remove any trailing spaces from restNameText
            restNameText = restNameText.trimmingCharacters(in: .whitespaces)
            let dictArrLength = dictArr.count
            if(!restNameText.isEmpty && restNameText != "Enter Name...")
            {
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
                
                self.checkObj.place = restNameText
                // Create a reference to a Firebase location
//                let refChecked = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
                let refChecked = FIRDatabase.database().reference().child("checked/\(self.currUser)")
//                let refCheckedPlaces = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
                let refCheckedPlaces = FIRDatabase.database().reference().child("checked/places")
                // Write establishment name to user's collection
                refChecked.updateChildValues([restNameText:true])
                // Write establishment name to places collection
                refCheckedPlaces.updateChildValues([restNameText:true])
                //let userRef = refChecked.childByAppendingPath(restNameText)
                //Store place ID with the check in if the user used google's autocomplete
                if(checkObj.placeId != nil)
                {
                    refChecked.child(byAppendingPath: restNameText).updateChildValues(["placeId":checkObj.placeId!])
                }else{
                    print("not a google prediction")
                }
                
                //update "user places" to contain the establishment and its categories
                for i in 0 ..< dictArr.count    //array of [cat/city: catName/cityName] 
                {
                    for (key,value) in dictArr[i]   //key: city or category
                    {
                        //Store categories and cities in user list
                        refChecked.child(byAppendingPath: restNameText).child(byAppendingPath: key).updateChildValues([value:"true"])
                        //Store categories and city info in master list
                        refCheckedPlaces.child(byAppendingPath: restNameText).child(byAppendingPath: key).updateChildValues([value:"true"])
                    }
                }
                //Save to NSUser defaults
//                restNameHistory += [restNameText]
                dictArr.removeAll()     //Remove elements so the following check in doesn't overwrite the previous
                self.checkObj = placeNode()  //reinitalize place node for next check in
                //Resotre check in screen to defaults
                CheckInRestField.text = nil
                for view in catScrollContainerView.subviews as [UIView] {
                    if let btn = view as? UIButton {
                        btn.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0, 0, 0) //prevent text from shift when removing check image
                        btn.isSelected = false
                        if(btn.backgroundColor != UIColor.clear){
                            btn.backgroundColor = UIColor.clear
                        }
                    }
                }
                for view in cityScrollContainerView.subviews as [UIView] {
                    if let btn = view as? UIButton {
                        btn.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0, 0, 0) //prevent text from shift when removing check image
                        btn.isSelected = false
                        if(btn.backgroundColor != UIColor.clear){
                            btn.backgroundColor = UIColor.clear
                        }
                    }
                }
                
                //perform check animation signaling check in complete
                animateCheckComplete()
                
                CheckInRestField.placeholder = "Enter Name..."
            }else{//If user hits submit with empty check in display alert
                let alert = UIAlertController(title: "Empty Check In", message: "You attempted to add a Check In but did not provide a name.", preferredStyle: .alert)
                let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(CancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
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
    
    func googleAutoComplete(_ textField: UITextField) {
        if let checkInString = CheckInRestField.text{
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
            let newTableSize = (self.autoCompleteArray.count * self.autoCompleteCellHeight) + Int(self.googleImageView.frame.height)
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
        let coordinates = locationManager?.location?.coordinate//CLLocationCoordinate2D(latitude: 37.788204, longitude: -122.411937)
        if let center = coordinates{
            let northEast = CLLocationCoordinate2D(latitude: center.latitude + 0.001, longitude: center.longitude + 0.001)
            let southWest = CLLocationCoordinate2D(latitude: center.latitude - 0.001, longitude: center.longitude - 0.001)
            coordBounds = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        }else{  //If user has location services turned off then return coordinates of 0,0 to do a default search
            print("User's location services are likely off")
            let coordNone = CLLocationCoordinate2D(latitude: CLLocationDegrees(0), longitude: CLLocationDegrees(0))
            coordBounds = GMSCoordinateBounds(coordinate: coordNone , coordinate: coordNone)
        }
        return coordBounds!
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
            //Sort fetch requests ascending
            let sortDescriptor = NSSortDescriptor(key: "city", ascending: true)
            let sortDescriptors = [sortDescriptor]
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
                    if(!cityButtonList.contains(where: {element in return (element == cityNameStr)}))
                    {
                        //Insert new element before the final plus sign in the list
                        self.cityButtonList.insert(cityNameStr, at: cityCount)
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
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtTouchCancel(_:)), for: .touchDragExit)
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
                button.setTitle("X", for: UIControlState())
                button.titleLabel?.font = UIFont.systemFont(ofSize: CGFloat(buttonRad / 4), weight: UIFontWeightBold)
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
        let buttonEnum = sender.buttonEnum
        sender.removeFromSuperview()
        let coreData = retrieveCityButtons()  //store list of city attributes from cityButton entity
//        Remove City from Core Data
        //The managed object context lives as a property of the application delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //use the object context to set up a new managed object to be "commited" to CoreData
        let managedContext = appDelegate.managedObjectContext
        //sorted city attributes can be selected by the button Enum
        managedContext.delete(coreData[buttonEnum] as NSManagedObject)
        do {
            try managedContext.save()   //Updated core data with the deleted attribute
        }catch _ {
        }
        cityButtonList.remove(at: buttonEnum)
        createCityButtons() //redraw Buttons
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    

}
