//
//  CheckInView.swift
//  Beta2
//
//  Created by Jason Johnston on 11/15/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import Firebase


//CA Layer extension used to allow runtime property to be set on the text box's view for borderUIColor  

extension CALayer {
    var borderUIColor: UIColor {
        set {
            self.borderColor = newValue.cgColor
        }
        
        get {
            return UIColor(cgColor: self.borderColor!)
        }
    }
}
class CheckInView: UIView {
    

//    @IBOutlet weak var CheckInRestField: UITextField!
//    
//    var dictArr = [[String:String]]()
//    var placesDict = [String : String]()
//    
//    var placesArr = [String]()
//    var arrSize = Int()
//    var ref: Firebase!
//    var userRef: Firebase!
//    var checkObj = placeNode()
//    let restNameDefaultKey = "CheckInView.restName"
//    private let sharedRestName = NSUserDefaults.standardUserDefaults()
//    
//    var restNameHistory: [String] {
//        get
//        {
//            return sharedRestName.objectForKey(restNameDefaultKey) as? [String] ?? []
//        }
//        set
//        {
//            sharedRestName.setObject(newValue, forKey: restNameDefaultKey)
//        }
//    }
//    
//    let currUserDefaultKey = "FBloginVC.currUser"
//    private let sharedFbUser = NSUserDefaults.standardUserDefaults()
//    
//    var currUser: NSString {
//        get
//        {
//            return (sharedFbUser.objectForKey(currUserDefaultKey) as? NSString)!
//        }
//    }
//    
//    func addBlue() {
//    let frame = CGRect(x: 125, y: 200, width: 100, height: 100)
//    let blueSquare = UIView(frame: frame)
//    blueSquare.backgroundColor = UIColor.blueColor()
//    
//    }
//    
//    @IBAction func categorySelect(sender: UIButton) {
//         let categoryDict = ["category" : sender.currentTitle!]
//        //checkObj.category? = sender.currentTitle!
//         /*if checkObj.category == nil{
//            let currArr = [sender.currentTitle!]
//            checkObj.category =  currArr
//        }
//        else{checkObj.category!.append(sender.currentTitle!)}*/
//        checkObj.addCategory(sender.currentTitle!)
//        
//        //if dictArr does not contain the selected category already then add it to the dictArr
//        //uses closure for contains func as described here: http://stackoverflow.com/questions/34081580/array-of-any-and-contains
//        if(!dictArr.contains({element in return (element == categoryDict)}))
//        {
//            dictArr.append(categoryDict)
//        }
//    }
//    
//    //var cityDict = ["city" : "true"]
//    @IBAction func citySelect(sender: UIButton) {
//        let cityDict = ["city" : sender.currentTitle!]
//        /*if checkObj.city == nil{
//            let tempArr = [sender.currentTitle!]
//            checkObj.city = tempArr
//        }
//        else{checkObj.city!.append(sender.currentTitle!)}*/
//        checkObj.addCity(sender.currentTitle!)
//        //Prevent from being able to add the same city twice to the dictArr
//        if(!dictArr.contains({element in return (element == cityDict)}))
//        {
//            dictArr.append(cityDict)
//        }
//    }
//    
//    @IBAction func SaveRestField(sender: UIButton) {
//        let restNameText = CheckInRestField.text!
//        let dictArrLength = dictArr.count
//        print("dict arr \(dictArrLength)")
//        if(!restNameText.isEmpty && restNameText != "Check in Here")
//        {
//            self.checkObj.place = restNameText
//            print(checkObj)
//            // Create a reference to a Firebase location
//            let refChecked = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
//            let refCheckedPlaces = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
//            // Write establishment name to user's collection
//            refChecked.updateChildValues([restNameText:true])
//            // Write establishment name to places collection
//            refCheckedPlaces.updateChildValues([restNameText:true])
//            //let userRef = refChecked.childByAppendingPath(restNameText)
//
//            //update "user places" to contain the establishment and its categories
//            for i in 0 ..< dictArr.count
//            {
//                for (key,value) in dictArr[i]
//                {
//                        refCheckedPlaces.childByAppendingPath(restNameText).childByAppendingPath(key).updateChildValues([value:"true"])
//                }
//            }
//            //Save to NSUser defaults
//            restNameHistory += [restNameText]
//            dictArr.removeAll()     //Remove elements so the following check in doesn't overwrite the previous
//            self.checkObj = placeNode()  //reinitalize place node for next check in
//            CheckInRestField.text = "Check in Here"
//            //notifyUser()
//        }
//        
//    }
//    
//    func notifyUser()
//    {
//        let alertController = UIAlertController(title: "Check In Out", message:
//            "Saved!", preferredStyle: UIAlertControllerStyle.Alert)
//        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
//        
//        //self.presentViewController(alertController, animated: true, completion: nil)
//    }
//
//    func createPlaceDict(entered : String) -> Dictionary<String,String>
//    {
//        var enteredArr = entered.componentsSeparatedByString(",")
//        return ["name": enteredArr[0]]
//    }
//    
//    func createDescDict(entered : String) -> Dictionary<String,String>
//    {
//        var enteredArr = entered.componentsSeparatedByString(",")
//        return ["name": enteredArr[0],"city":enteredArr[1],"category":enteredArr[2]]
//    }
//    
//    @IBOutlet weak var previewRestText: UITextView!
//        {
//        didSet{
//            previewRestText.text = "\(restNameHistory)"
//        }
//    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
