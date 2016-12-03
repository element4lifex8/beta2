//
//  ProfileStepsViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 1/21/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit


class ProfileStepsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        addLabelBorders()
        // Do any additional setup after loading the view.
    }

    @IBAction func skipProfileSetup(_ sender: UIButton)
    {
        performSegue(withIdentifier: "skipProfileSetup", sender: nil)
    }

    
    @IBOutlet weak var step1Label: UILabel!
    @IBOutlet weak var skipLabel: UIButton!

    func addLabelBorders()
    {
        step1Label.layer.borderWidth = 1
        step1Label.layer.borderColor = UIColor.black.cgColor
        //skipLabel.layer.masksToBounds = true
        skipLabel.layer.cornerRadius = 8
        skipLabel.layer.borderWidth = 1
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
