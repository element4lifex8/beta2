//
//  CIOHomeViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 11/7/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class CIOHomeViewController: UIViewController   {


    override func viewDidLoad()
    {
        super.viewDidLoad()
        //check for an existing token at load.
        if (FBSDKAccessToken.current() == nil)
        {
            performSegue(withIdentifier: "LoginScreen", sender: nil)
        }
    }
    
    
    @IBAction func LogoutButton(_ sender: UIButton) {
        //code to force logout
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        performSegue(withIdentifier: "LoginScreen", sender: nil)
    }
 
    // Unwind seque from my list
    @IBAction func unwindFromMyList(_ sender: UIStoryboardSegue) {
        // empty
    }
}
