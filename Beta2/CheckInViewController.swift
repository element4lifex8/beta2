//
//  CheckInViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 11/15/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import Firebase
import CoreData

class CheckInViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate {
    
//    Class properties and instances
    
    @IBOutlet var checkInView: CheckInView!
    var dictArr = [[String:String]]()
    var placesDict = [String : String]()
    var cityButtonList: [String] = ["+"]
    var catButtonList = ["Bar", "Breakfast", "Brewery", "Brunch", "Beaches", "Coffee Shops", "Night Club", "Desert", "Dinner", "Food Trucks", "Hikes", "Lunch", "Museums", "Parks", "Site Seeing", "Winery"]
    var cityButtonCoreData = [NSManagedObject]()
    var placesArr = [String]()
    var arrSize = Int()
    var ref: Firebase!
    var userRef: Firebase!
    var checkObj = placeNode()
    let restNameDefaultKey = "CheckInView.restName"
    var isEnteringCity = false
    var isEnteringCategory = false
    
    private let sharedRestName = NSUserDefaults.standardUserDefaults()
    
    var restNameHistory: [String] {
        get
        {
            return sharedRestName.objectForKey(restNameDefaultKey) as? [String] ?? []
        }
        set
        {
            sharedRestName.setObject(newValue, forKey: restNameDefaultKey)
        }
    }
    
    var cityScrollView : UIScrollView!
    //container view goes inside the scroll view and holds the buttons
    var cityScrollContainerView : UIView!
    
    var catScrollView: UIScrollView!
    var catScrollContainerView: UIView!
    
    let currUserDefaultKey = "FBloginVC.currUser"
    private let sharedFbUser = NSUserDefaults.standardUserDefaults()
    
    //NSUser defaults stores user i
    var currUser: NSString {
        get
        {
            return (sharedFbUser.objectForKey(currUserDefaultKey) as? NSString)!
        }
    }
    
//  Layout views in view controller
    
    //Since the bounds of the view controller's view is not ready in viewDidLoad, anything that will be calculated based off the view's bounds directly or indirectly must not be put in viewDidLoad (so we put it in did layout subviews
    override func viewDidLoad() {
        super.viewDidLoad()

        //Auto Capitalize words in text box field
        self.CheckInRestField.autocapitalizationType = .Words
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
        checkInView.userInteractionEnabled = true
     }
    
    //Since the bounds of the view controller's view is not ready in viewDidLoad, I like to do frame setting in viewDidLayoutSubviews
    override func viewDidLayoutSubviews() {
        //Locate origin of city scroll view at superview x origin - 3/4 of scroll view height
        let scrollViewHeight:CGFloat = 120
        let cityScrollViewY = (view.frame.size.height / 2) - (scrollViewHeight / 1.25)
        let catScrollViewY = cityScrollViewY + scrollViewHeight
        
        super.viewDidLayoutSubviews()

        //create frame on screen of scroll view that is 250px from top of screen and the width of the screen and a height of 120px
        cityScrollView.frame = CGRectMake(0, cityScrollViewY, view.frame.size.width, scrollViewHeight)
        //we are basing the container view's frame on the scroll view's content size
        cityScrollContainerView.frame = CGRectMake(0, 0, cityScrollView.contentSize.width, cityScrollView.contentSize.height)

        
        //setup category scroll frame
        catScrollView.frame = CGRectMake(0, catScrollViewY, view.frame.size.width, 120)
        
        catScrollContainerView.frame = CGRectMake(0, 0, catScrollView.contentSize.width, catScrollView.contentSize.height)
    }
   
    /**
     * Called when 'return' key pressed. return NO to ignore.
     */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if (textField.placeholder != nil){  //If no user information is in the textBox then clear place holder
            textField.placeholder = nil
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if(textField.text == ""){   //Restore placeholder text if no user input was received
            if(isEnteringCity){
                textField.placeholder = "Enter new city button name"
            }else{
                textField.placeholder = "Enter Name..."
            }
        }
    }
    func textFieldShouldClear(textField: UITextField) -> Bool {
        if(textField.text?.isEmpty ?? true){        //Only clear current textField if no user input previously received
            return true
        }
        else{    //If text field is not empty then don't clear
            return false
        }
    }
    
    //Detect when user taps outside of scroll views and remove any delete city buttons if they are present
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        super.touchesBegan(touches, withEvent: event)
        
        if let touch: UITouch = touches.first{
            if (touch.view == checkInView){
                //dismiss keyboard if present
                CheckInRestField.resignFirstResponder()
                for case let btn as DeleteCityUIButton in cityScrollContainerView.subviews{
                    btn.removeFromSuperview()
                }
                //Remove any background from the city button that was added by the touchdown event
                for case let btn as UIButton in cityScrollContainerView.subviews{
                    if(!btn.selected){
                        btn.backgroundColor = UIColor.clearColor()
                    }
                }
            }
        }
    }
    
    @IBOutlet weak var CheckInRestField: UITextField!
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromMyList(sender: UIStoryboardSegue) {
        // empty
    }
    
//    Collect data from text box and determine if it is for adding new city or to save check in to firebase
    
    //Action triggered when submit button is pressed
    @IBAction func SaveRestField(sender: UIButton) {
        //Create a new button
        if(isEnteringCity)
        {
            let addButtonText = CheckInRestField.text!
            let cityDefaultText = "Enter new city button name"
            let catDefaultText = "Enter new category button name"
            if(addButtonText == cityDefaultText || addButtonText == catDefaultText || addButtonText.isEmpty)
            {
                CheckInRestField.placeholder = "Enter Name..."
                CheckInRestField.text = ""
                isEnteringCity = false
                isEnteringCategory = false
            }
            else if(isEnteringCity)
            {
                //let newCityLoc = cityButtonList.count - 1
                //cityButtonList.insert(addButtonText, atIndex: newCityLoc)
                saveCityButton(addButtonText)
                CheckInRestField.text = ""
                CheckInRestField.placeholder = "Enter Name..."
                isEnteringCity = false
                createCityButtons()
            }
            else if(isEnteringCategory)
            {
                let newCatLoc = catButtonList.count - 1
                catButtonList.insert(addButtonText, atIndex: newCatLoc)
                CheckInRestField.text = ""
                CheckInRestField.placeholder = "Enter Name..."
                isEnteringCategory = false
                createCategoryButtons()
            }
        }
            //Save a city Check in entry
        else
        {
            let restNameText = CheckInRestField.text!
            let dictArrLength = dictArr.count
            if(!restNameText.isEmpty && restNameText != "Enter Name...")
            {
                self.checkObj.place = restNameText
                // Create a reference to a Firebase location
                let refChecked = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
                let refCheckedPlaces = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
                // Write establishment name to user's collection
                refChecked.updateChildValues([restNameText:true])
                // Write establishment name to places collection
                refCheckedPlaces.updateChildValues([restNameText:true])
                //let userRef = refChecked.childByAppendingPath(restNameText)
                
                //update "user places" to contain the establishment and its categories
                for i in 0 ..< dictArr.count    //array of [cat/city: catName/cityName] 
                {
                    for (key,value) in dictArr[i]   //key: city or category
                    {
                        //Store categories and cities in user list
                        refChecked.childByAppendingPath(restNameText).childByAppendingPath(key).updateChildValues([value:"true"])
                        //Store categories and city info in master list
                        refCheckedPlaces.childByAppendingPath(restNameText).childByAppendingPath(key).updateChildValues([value:"true"])
                    }
                }
                //Save to NSUser defaults
                restNameHistory += [restNameText]
                dictArr.removeAll()     //Remove elements so the following check in doesn't overwrite the previous
                self.checkObj = placeNode()  //reinitalize place node for next check in
                //Resotre check in screen to defaults
                CheckInRestField.text = nil
                for view in catScrollContainerView.subviews as [UIView] {
                    if let btn = view as? UIButton {
                        btn.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0, 0, 0) //prevent text from shift when removing check image
                        btn.selected = false
                        if(btn.backgroundColor != UIColor.clearColor()){
                            btn.backgroundColor = UIColor.clearColor()
                        }
                    }
                }
                for view in cityScrollContainerView.subviews as [UIView] {
                    if let btn = view as? UIButton {
                        btn.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0, 0, 0) //prevent text from shift when removing check image
                        btn.selected = false
                        if(btn.backgroundColor != UIColor.clearColor()){
                            btn.backgroundColor = UIColor.clearColor()
                        }
                    }
                }
                //notifyUser()
            }
        }
    }
    
//    Select attributes for check in
    
    @IBAction func categorySelect(sender: UIButton) {
        sender.highlighted = true
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
                if(!dictArr.contains({element in return (element == categoryDict)}))
                {
                    dictArr.append(categoryDict)
                }
            }else{   //Button is being deselected
                if let idxToDelete = dictArr.indexOf({element in return (element == categoryDict)}){
                    dictArr.removeAtIndex(idxToDelete)
                }
            }
        }
    }
    
    
    @IBAction func citySelect(sender: UIButton) {
        
        if(sender.currentTitle! == "+")
        {
            //Clear the touchdown background color
            sender.backgroundColor = UIColor.clearColor()
            CheckInRestField.placeholder = "Enter new city button name"
            isEnteringCity = true
        }
        else
        {
            let cityDict = ["city" : sender.currentTitle!]   //var cityDict = ["city" : "true"]
            if(makeButtonSelected(sender))
            {
                checkObj.addCity(sender.currentTitle!)
                //Prevent from being able to add the same city twice to the dictArr
                if(!dictArr.contains({element in return (element == cityDict)}))
                {
                    dictArr.append(cityDict)
                }
            }
            else{   //Button is being deselected
                if let idxToDelete = dictArr.indexOf({element in return (element == cityDict)}){
                        dictArr.removeAtIndex(idxToDelete)
                    }
            }
            
        }
    }
    
    //Change button background when touch down event occurs
    @IBAction func cityCatButtBeginTouch(sender: UIButton) {
        if(!sender.selected){
            sender.backgroundColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 1.0)
        }
    }
    
    @IBAction func cityCatButtTouchCancel(sender: UIButton) {
        if(!sender.selected){
            sender.backgroundColor = UIColor.clearColor()
        }
    }
    
    @IBAction func citCatButtEndTouch(sender: UIButton) {
        if(!sender.selected){
            sender.backgroundColor = UIColor.clearColor()
        }
    }
    
    
//    Manage and create new buttons
    
    func makeButtonSelected(button: UIButton) -> Bool {
        let checkImage = UIImage(named: "Check Symbol")
        button.setImage(checkImage, forState: .Selected)
        let imageSize: CGSize = checkImage!.size
        
        //User can select and deslect buttons
        //Sender.state = [.Normal, .Highlighted], append or delete .Selected
        button.selected = button.state == .Highlighted ? true : false
        
        //Format location of check mark to be placed beneath button title
        if(button.selected){
            if let titleLabel = button.titleLabel {
                let spacing: CGFloat = button.frame.size.height / 3 //put check mark in botton 3rd of button
                //Shift title left (using negative value for left param) by the width of the image so text stays centered
                button.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width, 0, 0.0)
                let labelString = NSString(string: titleLabel.text!)
                let titleSize = labelString.sizeWithAttributes([NSFontAttributeName: titleLabel.font])
                //Shift image down by adding top edge inset of the size of the title + desired space
                //Shift image right by subtracting right inset by the width of the title
                button.imageEdgeInsets = UIEdgeInsetsMake(titleSize.height + spacing, 0.0, 0.0, -titleSize.width)
                let edgeOffset = abs(titleSize.height - imageSize.height) / 2.0;
                button.contentEdgeInsets = UIEdgeInsetsMake(edgeOffset, 0.0, edgeOffset, 0.0)
                button.backgroundColor = UIColor(white: 1, alpha: 0.5)

            }
        }
        else{
            button.backgroundColor = UIColor.clearColor()
            button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0, 0, 0) //prevent text from shift when removing check image
        }
        return button.selected
    }
    
    //save City button to CoreData for persistance
    func saveCityButton(city: String)
    {
        //Get Reference to NSManagedObjectContext
        //The managed object context lives as a property of the application delegate
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        //use the object context to set up a new managed object to be "commited" to CoreData
        let managedContext = appDelegate.managedObjectContext
        
        //Get my CoreData Entity and attach it to a managed context object
        let entity =  NSEntityDescription.entityForName("CityButton",
                                                        inManagedObjectContext:managedContext)
        //create a new managed object and insert it into the managed object context
        let cityButtonMgObj = NSManagedObject(entity: entity!,
                                            insertIntoManagedObjectContext: managedContext)
        
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
    
    //Retrieve from CoreData
    func retrieveCityButtons() -> [NSManagedObject]
    {
        //pull up the application delegate and grab a reference to its managed object context
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //Setting a fetch request’s entity property, or alternatively initializing it with init(entityName:), fetches all objects of a particular entity
        //Fetch request could also be used to grab objects meeting certain criteria
        let fetchRequest = NSFetchRequest(entityName: "CityButton")
        
        //executeFetchRequest() returns an array of managed objects that meets the criteria specified by the fetch request
        do {
            //Sort fetch requests ascending
            let sortDescriptor = NSSortDescriptor(key: "city", ascending: true)
            let sortDescriptors = [sortDescriptor]
            fetchRequest.sortDescriptors = sortDescriptors
            //fetchRequests asks for city button entity, try catch syntax used to handle errors
            let cityButtonEntity =
                try managedContext.executeFetchRequest(fetchRequest)
            cityButtonCoreData = cityButtonEntity as! [NSManagedObject]
            //iterate over all attributes in City button entity
            for i in 0 ..< cityButtonCoreData.count{
                let cityButtonAttr = cityButtonCoreData[i]
                //optional chain anyObject to string and store in cityButtonArray
                if let cityNameStr = cityButtonAttr.valueForKey("city") as? String
                {
                    //add city name to cityButtonlist if the city doesn't already exists
                    if(!cityButtonList.contains({element in return (element == cityNameStr)}))
                    {
                        //Insert new element before the final plus sign in the list
                        cityButtonList.insert(cityNameStr, atIndex: i)
                    }
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
        let buttonSpacing = 25
        let buttonRad = 100
        //Update city button array to be current with all cities in CoreData Entity CityButton
        retrieveCityButtons()
        
        /*sort list of city buttons before printing
        //Move + sign to end of sort
        cityButtonList.sortInPlace({(s1:String, s2:String) -> Bool in
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
        cityScrollView.contentSize = CGSizeMake(CGFloat((cityButtonList.count * buttonRad) + ((cityButtonList.count  + 1) * buttonSpacing)), 120) //Length of scroll view is the number of 100px buttons plus the number of 25px spacing plus an extra space for the final button, 120 high
        
        //Add container view to scroll view
        cityScrollView.addSubview(cityScrollContainerView)
        
        //add scroll view to super view
        view.addSubview(cityScrollView)
        
        //Add button to scroll view's container view
        for (index,cityText) in cityButtonList.enumerate(){
            let button = UIButton(frame: CGRect(x: (index * buttonRad) + ((index+1)*buttonSpacing), y: 0, width: buttonRad, height: buttonRad))   // X, Y, width, height
            button.layer.cornerRadius = 0.5 * button.bounds.size.width
            button.backgroundColor = UIColor.clearColor()
            button.layer.borderWidth = 2.0
            button.layer.borderColor = UIColor.whiteColor().CGColor
            button.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
            button.titleLabel!.adjustsFontSizeToFitWidth = true;
            button.titleLabel!.minimumScaleFactor = 0.8;
            button.titleLabel!.lineBreakMode = .ByTruncatingTail
            button.setTitle(cityText, forState: .Normal)
            //add target actions for button tap
            button.addTarget(self, action: #selector(CheckInViewController.citySelect(_:)), forControlEvents: .TouchUpInside)
            //Functions to highlight and unhighlight when touches begin
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtBeginTouch(_:)), forControlEvents: .TouchDown)
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtTouchCancel(_:)), forControlEvents: .TouchDragExit)
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
        //remove all previously existing buttons from view to re-draw
        for view in catScrollContainerView.subviews as [UIView] {
            if let btn = view as? UIButton {
                btn.removeFromSuperview()
            }
        }
        catScrollView.contentSize = CGSizeMake(CGFloat((catButtonList.count * 100) + ((catButtonList.count  + 1) * 25)), 120)
        //Add container view to scroll view
        catScrollView.addSubview(catScrollContainerView)
        //add scroll view to super view
        view.addSubview(catScrollView)
        //view.setNeedsLayout()
        //Add button to scroll view's container view
        
        for (index,catText) in catButtonList.enumerate(){
            let button = UIButton(frame: CGRect(x: (index * 100) + ((index+1)*25), y: 0, width: 100, height: 100))   // X, Y, width, height
            button.layer.cornerRadius = 0.5 * button.bounds.size.width
            button.backgroundColor = UIColor.clearColor()
            button.layer.borderWidth = 2.0
            button.layer.borderColor = UIColor.whiteColor().CGColor
            button.titleLabel!.adjustsFontSizeToFitWidth = true;
            button.titleLabel!.minimumScaleFactor = 0.8;
            button.setTitle(catText, forState: .Normal)
            button.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
            button.addTarget(self, action: #selector(CheckInViewController.categorySelect(_:)), forControlEvents: .TouchUpInside)
            //Functions to highlight and unhighlight when touches begin
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtBeginTouch(_:)), forControlEvents: .TouchDown)
            button.addTarget(self, action: #selector(CheckInViewController.cityCatButtTouchCancel(_:)), forControlEvents: .TouchDragExit)
            catScrollContainerView.addSubview(button)
            //button.setNeedsLayout()
        }

    }
    
    func displayCityDeleteButton(sender: UILongPressGestureRecognizer)
    {
        let buttonSpacing = 25
        let buttonRad = 100
        let tapLocation = sender.locationInView(self.cityScrollView)

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
                button.setTitle("X", forState: .Normal)
                button.titleLabel?.font = UIFont.systemFontOfSize(CGFloat(buttonRad / 4), weight: UIFontWeightBold)
                button.setTitleColor(UIColor.blackColor(), forState: .Normal)
                button.addTarget(self, action: #selector(CheckInViewController.deleteCity(_:)), forControlEvents: .TouchUpInside)
                cityScrollContainerView.addSubview(button)
            }
        }
    }
    
    //Used in conjunction with the added gesture on the scroll view's area not containing buttons
    func clearCityDeleteButton(sender: UITapGestureRecognizer)
    {
        for case let btn as DeleteCityUIButton in cityScrollContainerView.subviews{
            btn.removeFromSuperview()
        }
        //For the actual city buttons remove any background color they received from the touch down event
        for case let btn as UIButton in cityScrollContainerView.subviews{
            if(!btn.selected){
                btn.backgroundColor = UIColor.clearColor()
            }
        }
    }
    
    func deleteCity(sender: DeleteCityUIButton){
        let buttonEnum = sender.buttonEnum
        sender.removeFromSuperview()
        let coreData = retrieveCityButtons()  //store list of city attributes from cityButton entity
//        Remove City from Core Data
        //The managed object context lives as a property of the application delegate
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        //use the object context to set up a new managed object to be "commited" to CoreData
        let managedContext = appDelegate.managedObjectContext
        //sorted city attributes can be selected by the button Enum
        managedContext.deleteObject(coreData[buttonEnum] as NSManagedObject)
        do {
            try managedContext.save()   //Updated core data with the deleted attribute
        }catch _ {
        }
        cityButtonList.removeAtIndex(buttonEnum)
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