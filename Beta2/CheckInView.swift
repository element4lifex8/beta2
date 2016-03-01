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
    
    @IBAction func SaveRestField(sender: UIButton) {
        let restNameText = CheckInRestField.text!
        if(!restNameText.isEmpty)
        {
            print("saving to firebase")
            let userCheckedPath = "checked/\(self.currUser)"
            // Create a reference to a Firebase location
            let refChecked = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
            var enteredArr = restNameText.componentsSeparatedByString(",")
            // Write data to Firebase
            refChecked.updateChildValues([enteredArr[0]:true])
            refChecked.childByAppendingPath(enteredArr[0]).updateChildValues(["city":enteredArr[1],"category":enteredArr[2]])
            restNameHistory += [restNameText]
        }
        
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
