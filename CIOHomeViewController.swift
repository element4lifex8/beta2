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

    //Check if user has logged in and force login if not
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        print("Logout button segue")
    }
 
    // Unwind seque from my list
    @IBAction func unwindFromMyList(_ sender: UIStoryboardSegue) {
        // empty
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
//        print("segue to \(segue.identifier)")
//    }

}
