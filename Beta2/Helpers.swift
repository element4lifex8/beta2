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
    
    //Function used to only print to console for debug builds which use the -D DEBUG flag:
    //Set it in the "Swift Compiler - Custom Flags" section, "Other Swift Flags" line. You add the DEBUG symbol with the -D DEBUG entry.
    //(Build Settings -> Swift Compiler - Custom Flags)
    func myPrint(text :  String) -> Void{
        #if DEBUG
            print(text)
        #endif
    }
}
