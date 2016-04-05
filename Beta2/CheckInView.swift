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
    
    var dictArr = [[String:String]]()
    var categoryDict = ["category" : "true"]
      @IBAction func categorySelect(sender: UIButton) {
        categoryDict = ["category" : sender.currentTitle!]
        dictArr.append(categoryDict)
    }
    
    //var cityDict = ["city" : "true"]
    var cityDict = [String: String]()
    @IBAction func citySelect(sender: UIButton) {
        cityDict = ["city" : sender.currentTitle!]
        dictArr.append(cityDict)
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
            
            // Write data to Firebase
            refChecked.updateChildValues([restNameText:true])
            //let userRef = refChecked.childByAppendingPath(restNameText)
            var keys = [String]()
            print ("\(dictArr)")
            for i in 0 ..< dictArr.count
            {
                for (key,value) in dictArr[i]
                {
                    if keys.contains(key)  //Store children of existing entry
                    {
                        refChecked.childByAppendingPath(restNameText).childByAppendingPath(key).updateChildValues([value:"true"])
                    }
                    else    //Create new child under the establishment's name
                    {
                        keys.append(key)
                        refChecked.childByAppendingPath(restNameText).updateChildValues([key:value])
                    }
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
