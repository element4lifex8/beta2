//
//  ProfileStepsViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 1/21/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import CoreData

class ProfileStepsViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addTextBoxBorder()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //Create Proper look for add city button
        self.addCityButton.layer.cornerRadius = 0.5 * self.addCityButton.bounds.size.width
        self.addCityButton.backgroundColor = UIColor.clear
        self.addCityButton.layer.borderWidth = 1.0
        self.addCityButton.layer.borderColor = UIColor.black.cgColor
        
//        addLabelBorders()
        // Do any additional setup after loading the view.
    }

    @IBOutlet weak var homeCityTextBox: UITextField!
    @IBOutlet weak var addCityTextBox: UITextField!
  
     @IBOutlet weak var addCityButton: UIButton!
    @IBAction func addCityPressed(_ sender: UIButton) {
        if let cityText = addCityTextBox.text{
            if(cityText != ""){
                //Add city to core data
                saveCityButton(cityText)
                addCityTextBox.placeholder = "Add more cities..."
                addCityTextBox.text = ""
            }else{
                print("name of city invalid")
            }
        }else{
            print("No city added to text box")
        }
    }
    
    @IBAction func proceedButtonPressed(_ sender: UIButton) {
        if let cityText = homeCityTextBox.text{
            if(cityText != ""){
            print("Home city: \(homeCityTextBox.text)")
            performSegue(withIdentifier: "segueToAddFriends", sender: nil)
            }else{
                print("Please add a home city to proceed. Empty found")
            }
        }else{
            print("Please add a home city to proceed. Nil found")
        }
    }
    
    
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

    
    //save City button to CoreData for persistance
    func saveCityButton(_ city: String)
    {
        //Get Reference to NSManagedObjectContext
        //The managed object context lives as a property of the application delegate
        let appDelegate =
            UIApplication.shared.delegate as! AppDelegate
        //use the object context to set up a new managed object to be "commited" to CoreData
        let managedContext = appDelegate.managedObjectContext
        
        //Get my CoreData Entity and attach it to a managed context object
        let entity =  NSEntityDescription.entity(forEntityName: "CityButton",
                                                 in:managedContext)
        //create a new managed object and insert it into the managed object context
        let cityButtonMgObj = NSManagedObject(entity: entity!,
                                              insertInto: managedContext)
        
        //Using the managed object context set the "name" attribute to the parameter passed to this func
        cityButtonMgObj.setValue(city, forKey: "city")
        
        //save to CoreData, inside do block in case error is thrown
        do {
            try managedContext.save()
            //Insert the managed object that was saved to disk into the array used to populate the table
            //cityButtonCoreData.append(cityButtonMgObj)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        
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
