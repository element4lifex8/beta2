//
//  Helpers.swift
//  Beta2
//
//  Created by Jason Johnston on 2/23/17.
//  Copyright © 2017 anuJ. All rights reserved.
//

import Foundation

class Helpers{
    let currUserDefaultKey = "FBloginVC.currUser"
    fileprivate let sharedFbUser = UserDefaults.standard
    
    //retrieve the current app user from NSUserDefaults
    var currUser: NSString {
        get{
            return (sharedFbUser.object(forKey: currUserDefaultKey) as? NSString)!
        }
    }
    
    func returnCurrUser() -> NSString{
        return currUser
    }
}
