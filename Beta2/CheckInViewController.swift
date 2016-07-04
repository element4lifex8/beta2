//
//  CheckInViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 11/15/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import Firebase

class CheckInViewController: UIViewController, UIScrollViewDelegate {

    var dictArr = [[String:String]]()
    var placesDict = [String : String]()
    var cityButtonList = ["Annapolis", "Ann Arbor", "Detroit", "DC", "+"]
    var catButtonList = ["Brunch", "Dinner", "Park", "+"]
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
    
    
    var currUser: NSString {
        get
        {
            return (sharedFbUser.objectForKey(currUserDefaultKey) as? NSString)!
        }
    }
    
    @IBOutlet weak var CheckInRestField: UITextField!
    
    @IBAction func SaveRestField(sender: UIButton) {
        //Create a new button
        if(isEnteringCity || isEnteringCategory)
        {
            let addButtonText = CheckInRestField.text!
            let cityDefaultText = "Enter new city button name"
            let catDefaultText = "Enter new category button name"
            if(addButtonText == cityDefaultText || addButtonText == catDefaultText)
            {
                CheckInRestField.text = "Check in Here"
                isEnteringCity = false
                isEnteringCategory = false
            }
            else if(isEnteringCity)
            {
                let newCityLoc = cityButtonList.count - 1
                cityButtonList.insert(addButtonText, atIndex: newCityLoc)
                CheckInRestField.text = "Check in Here"
                isEnteringCity = false
                createCityButtons()
            }
            else if(isEnteringCategory)
            {
                let newCatLoc = catButtonList.count - 1
                catButtonList.insert(addButtonText, atIndex: newCatLoc)
                CheckInRestField.text = "Check in Here"
                isEnteringCategory = false
                createCategoryButtons()
            }
        }
        //Save a city Check in entry
        else
        {
            let restNameText = CheckInRestField.text!
            let dictArrLength = dictArr.count
            print("dict arr \(dictArrLength)")
            if(!restNameText.isEmpty && restNameText != "Check in Here")
            {
                self.checkObj.place = restNameText
                print(checkObj)
                // Create a reference to a Firebase location
                let refChecked = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
                let refCheckedPlaces = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
                // Write establishment name to user's collection
                refChecked.updateChildValues([restNameText:true])
                // Write establishment name to places collection
                refCheckedPlaces.updateChildValues([restNameText:true])
                //let userRef = refChecked.childByAppendingPath(restNameText)
                
                //update "user places" to contain the establishment and its categories
                for i in 0 ..< dictArr.count
                {
                    for (key,value) in dictArr[i]
                    {
                        refCheckedPlaces.childByAppendingPath(restNameText).childByAppendingPath(key).updateChildValues([value:"true"])
                    }
                }
                //Save to NSUser defaults
                restNameHistory += [restNameText]
                dictArr.removeAll()     //Remove elements so the following check in doesn't overwrite the previous
                self.checkObj = placeNode()  //reinitalize place node for next check in
                CheckInRestField.text = "Check in Here"
                //notifyUser()
            }
        }
    }
    
    
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
            checkObj.addCategory(sender.currentTitle!)
            
            //if dictArr does not contain the selected category already then add it to the dictArr
            //uses closure for contains func as described here: http://stackoverflow.com/questions/34081580/array-of-any-and-contains
            if(!dictArr.contains({element in return (element == categoryDict)}))
            {
                dictArr.append(categoryDict)
            }
        }
    }
    
    
    @IBAction func citySelect(sender: UIButton) {
        sender.highlighted = true
        if(sender.currentTitle! == "+")
        {
            CheckInRestField.text = "Enter new city button name"
            isEnteringCity = true
        }
        else
        {
            let cityDict = ["city" : sender.currentTitle!]   //var cityDict = ["city" : "true"]
            /*if checkObj.city == nil{
             let tempArr = [sender.currentTitle!]
             checkObj.city = tempArr
             }
             else{checkObj.city!.append(sender.currentTitle!)}*/
            checkObj.addCity(sender.currentTitle!)
            //Prevent from being able to add the same city twice to the dictArr
            if(!dictArr.contains({element in return (element == cityDict)}))
            {
                dictArr.append(cityDict)
            }
        }
    }
    

    //Since the bounds of the view controller's view is not ready in viewDidLoad, anything that will be calculated based off the view's bounds directly or indirectly must not be put in viewDidLoad (so we put it in did layout subviews
    override func viewDidLoad() {
        super.viewDidLoad()

        //setup City scroll view
        cityScrollView = UIScrollView()
        cityScrollView.delegate = self
        //setup Category scroll view
        catScrollView = UIScrollView()
        catScrollView.delegate = self
        //setup container view
        cityScrollContainerView = UIView()
        createCityButtons()
        
        //setup category container view
        catScrollContainerView = UIView()
        createCategoryButtons()
     }
    
    //Since the bounds of the view controller's view is not ready in viewDidLoad, I like to do frame setting in viewDidLayoutSubviews
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //create frame on screen of scroll view that is 250px from top of screen and the width of the screen and a height of 120px
        cityScrollView.frame = CGRectMake(0, 250, view.frame.size.width, 120)
        //we are basing the container view's frame on the scroll view's content size
        cityScrollContainerView.frame = CGRectMake(0, 0, cityScrollView.contentSize.width, cityScrollView.contentSize.height)
        
        //setup category scroll frame
        catScrollView.frame = CGRectMake(0, 368, view.frame.size.width, 120)
        
        catScrollContainerView.frame = CGRectMake(0, 0, catScrollView.contentSize.width, catScrollView.contentSize.height)
    }
    
    func createCityButtons()
    {
        //remove all previously existing buttons from view to re-draw alternate loop to cat buttons
        for case let btn as UIButton in cityScrollContainerView.subviews{
                btn.removeFromSuperview()
        }
        cityScrollView.contentSize = CGSizeMake(CGFloat((cityButtonList.count * 100) + ((cityButtonList.count  + 1) * 25)), 120) //Length of scroll view is the number of 100px buttons plus the number of 25px spacing plus an extra space for the final button
        
        //Add container view to scroll view
        cityScrollView.addSubview(cityScrollContainerView)
        //add scroll view to super view
        view.addSubview(cityScrollView)
        //view.setNeedsDisplay()
        //Add button to scroll view's container view
        for (index,cityText) in cityButtonList.enumerate(){
        let button = UIButton(frame: CGRect(x: (index * 100) + ((index+1)*25), y: 0, width: 100, height: 100))   // X, Y, width, height
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.backgroundColor = UIColor.clearColor()
        button.layer.borderWidth = 2.0
        button.layer.borderColor = UIColor.whiteColor().CGColor
        button.setTitle(cityText, forState: .Normal)
        button.addTarget(self, action: #selector(CheckInViewController.citySelect(_:)), forControlEvents: .TouchUpInside)
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
            button.setTitle(catText, forState: .Normal)
            button.addTarget(self, action: #selector(CheckInViewController.categorySelect(_:)), forControlEvents: .TouchUpInside)
            catScrollContainerView.addSubview(button)
            button.setNeedsLayout()
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
