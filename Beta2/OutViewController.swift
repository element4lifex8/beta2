//
//  OutViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 4/20/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import Firebase

class OutViewController: UIViewController {

    var placesArr = [String]()
    var placesStr = String()
    var arrSize = Int()
    var ref: FIRDatabaseReference!
    var userRef: FIRDatabaseReference!
    
    @IBOutlet var fireRef: UITextView!
    
    let currUserDefaultKey = "FBloginVC.currUser"
    fileprivate let sharedFbUser = UserDefaults.standard
    var currUser: NSString {
        get
        {
            return (sharedFbUser.object(forKey: currUserDefaultKey) as? NSString)!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        userRef = Firebase(url:"https://check-inout.firebaseio.com/checked/\(self.currUser)")
        userRef = FIRDatabase.database().reference().child("checked/\(self.currUser)")
        // Retrieve new posts as they are added to your database
        userRef.observe(.value, with: { snapshot in
            
            print("COunt when load \(snapshot.childrenCount)")
            var count = 0
            for child in (snapshot.children) {
                
                //true if child key in the snapshot is not nil, then unwrap and store in array
                if let childKey = (child as AnyObject).key{
                    self.placesArr.append(childKey!)
                    self.placesStr += ("\(self.placesArr[count]) \n" )
                    count=count + 1
                }
                
                //how to print values of a child in the returned snapshot if key name is known
                //let childSnapshot = snapshot.childSnapshotForPath(child.key)
                //let someValue = childSnapshot.value["someKey"] as? String
                /*{
                 print("\(child.value as String)")
                 self.placesArr.append(child.value)
                 }*/
            }
            self.arrSize = Int((snapshot.childrenCount))
            print(self.placesArr)
            self.fireRef.text = self.placesStr
            
            //self.debugText.text = "\(self.placesArr)"
            //self.textBoxOnTable.text = "\(self.placesArr[0])"
            //how to print a child value if key name is known
            //if(!snapshot.value != NSNull)
            //print(snapshot.value.objectForKey("city"))
            //print(snapshot.value.objectForKey("category")!)
            

        })
    }

}
