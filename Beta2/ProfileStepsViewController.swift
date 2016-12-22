//
//  ProfileStepsViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 1/21/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit


class ProfileStepsViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addTextBoxBorder()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        addLabelBorders()
        // Do any additional setup after loading the view.
    }

    @IBAction func skipProfileSetup(_ sender: UIButton)
    {
        performSegue(withIdentifier: "skipProfileSetup", sender: nil)
    }

    @IBOutlet weak var homeCityTextBox: UIView!
    @IBOutlet weak var addCityTextBox: UITextField!
    
    @IBOutlet weak var step1Label: UILabel!
    @IBOutlet weak var skipLabel: UIButton!
    
    func addTextBoxBorder(){
        //Create underline bar for home city and additional city text boxes
        let px = 1 / UIScreen.main.scale    //determinte 1 pixel size instead of using 1 point
        let homeCityFrame = CGRect(x: homeCityTextBox.frame.minX, y: homeCityTextBox.frame.maxY, width: homeCityTextBox.frame.size.width, height: px)
        let homeCityLine: UIView = UIView(frame: homeCityFrame)
        homeCityLine.backgroundColor = UIColor.black
        let addCityFrame = CGRect(x: addCityTextBox.frame.minX, y: addCityTextBox.frame.maxY, width: homeCityTextBox.frame.size.width, height: px)
        let addCityLine: UIView = UIView(frame: addCityFrame)
        addCityLine.backgroundColor = UIColor.black
        //Add underline to view
        view.addSubview(homeCityLine)
        view.addSubview(addCityLine) 
    }

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
