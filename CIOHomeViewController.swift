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
        if (FBSDKAccessToken.currentAccessToken() == nil)
        {
            performSegueWithIdentifier("LoginScreen", sender: nil)
        }
    }
    
    
    @IBAction func LogoutButton(sender: UIButton) {
        //code to force logout
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        performSegueWithIdentifier("LoginScreen", sender: nil)
    }
  /*  @IBAction func InHomeButton(sender: UIButton) {
        print("Home: \(sender)")
    }*/

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
