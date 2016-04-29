//
//  CheckInView.swift
//  Beta2
//
//  Created by Jason Johnston on 11/15/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import Firebase

class CheckInView: UIView {

    @IBOutlet weak var CheckInRestField: UITextField!
    
    var dictArr = [[String:String]]()
    var placesDict = [String : String]()
    
    var placesArr = [String]()
    var arrSize = Int()
    var ref: Firebase!
    var userRef: Firebase!
    
    let restNameDefaultKey = "CheckInView.restName"
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
    
    let currUserDefaultKey = "FBloginVC.currUser"
    private let sharedFbUser = NSUserDefaults.standardUserDefaults()
    
    var currUser: NSString {
        get
        {
            return (sharedFbUser.objectForKey(currUserDefaultKey) as? NSString)!
        }
    }
    
    
    @IBAction func categorySelect(sender: UIButton) {
         let categoryDict = ["category" : sender.currentTitle!]
        //if dictArr does not contain the selected category already then add it to the dictArr
        //uses closure for contains func as described here: http://stackoverflow.com/questions/34081580/array-of-any-and-contains
        if(!dictArr.contains({element in return (element == categoryDict)}))
        {
            dictArr.append(categoryDict)
        }
    }
    
    //var cityDict = ["city" : "true"]
    @IBAction func citySelect(sender: UIButton) {
        let cityDict = ["city" : sender.currentTitle!]
        //Prevent from being able to add the same city twice to the dictArr
        if(!dictArr.contains({element in return (element == cityDict)}))
        {
            dictArr.append(cityDict)
        }
    }
    
    @IBAction func SaveRestField(sender: UIButton) {
        let restNameText = CheckInRestField.text!
        let dictArrLength = dictArr.count
        print("dict arr \(dictArrLength)")
        if(!restNameText.isEmpty && restNameText != "Check in Here")
        {
            print("saving to firebase")
                // Create a reference to a Firebase location
            let refChecked = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
            let refCheckedPlaces = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
            var refCheckedPlaceCat : Firebase
            // Write establishment name to user's collection
            refChecked.updateChildValues([restNameText:true])
            // Write establishment name to places collection
            refCheckedPlaces.updateChildValues([restNameText:true])
            //let userRef = refChecked.childByAppendingPath(restNameText)
            var keys = [String]()
            var overwriteFlag = false   //overwrite flag is set true the second time a key appears
            //update "user places" to contain the establishment and its categories
            for i in 0 ..< dictArr.count
            {
                for (key,value) in dictArr[i]
                {
//                    if keys.contains(key)  //Store children of existing entry
//                    {
//                        if(overwriteFlag)  //flag is set when a new key is added to keys arrayp k
//                        {
//                            for j in (0 ... (i>0 ? i-1:1)).reverse() //don't overwrite first child entry when expanding child entries
//                            {
//                                //check if previous vlaue for matching key is nil
//                                if let prevEntry = dictArr[j][key]
//                                {
//                                    RefCheckedPlaces.childByAppendingPath(restNameText).childByAppendingPath(key).updateChildValues([prevEntry:"true"])
//                                        break
//                                }
//                            }
//                            overwriteFlag = false
//                        }
                        refCheckedPlaces.childByAppendingPath(restNameText).childByAppendingPath(key).updateChildValues([value:"true"])
//                    }
//                    else    //Create new child under the establishment's name
//                    {
//                        keys.append(key)
//                        overwriteFlag=true
//                        refCheckedPlaces.childByAppendingPath(restNameText).updateChildValues([key:value])
//                    }
                }
            }
            //Save to NSUser defaults
            restNameHistory += [restNameText]
            dictArr.removeAll()     //Remove elements so the following check in doesn't overwrite the previous
            CheckInRestField.text = "Check in Here"
            //notifyUser()
        }
        
    }
    
    func notifyUser()
    {
        let alertController = UIAlertController(title: "Check In Out", message:
            "Saved!", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
        
        //self.presentViewController(alertController, animated: true, completion: nil)
    }

    func createPlaceDict(entered : String) -> Dictionary<String,String>
    {
        var enteredArr = entered.componentsSeparatedByString(",")
        return ["name": enteredArr[0]]
    }
    
    func createDescDict(entered : String) -> Dictionary<String,String>
    {
        var enteredArr = entered.componentsSeparatedByString(",")
        return ["name": enteredArr[0],"city":enteredArr[1],"category":enteredArr[2]]
    }
    
    @IBOutlet weak var previewRestText: UITextView!
        {
        didSet{
            previewRestText.text = "\(restNameHistory)"
        }
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
