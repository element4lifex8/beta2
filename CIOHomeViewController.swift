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

    //Check if user has logged in and force login if not, modal segues must be performed in viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (FBSDKAccessToken.current() == nil)
        {
            self.performSegue(withIdentifier: "LoginScreen", sender: nil)
        }
        
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
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
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromFbLogin(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromCheckIn(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    // Unwind seque from my CheckOutVC
    @IBAction func unwindFromCheckOut(_ sender: UIStoryboardSegue) {
        // empty
    }

}
