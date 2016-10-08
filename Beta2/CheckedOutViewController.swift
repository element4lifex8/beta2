//
//  CheckedOutViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 6/12/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit

class CheckedOutViewController: UIViewController {
    
    
//    @IBOutlet weak var contentTabView: UIView!
    @IBOutlet weak var cityPeopleButton: UIButton!
    
    @IBOutlet weak var peopleContainerView: UIView!
    
    @IBOutlet weak var cityContainerView: UIView!
    
//    var checkOutCityViewController: CheckOutCityViewController!
//    var checkOutPeopleViewController: CheckOutPeopleViewController!
//    var viewControllers: [UIViewController] = []
//    var selectedVC: Int = 0 //default is City
    
    @IBAction func pressTabBar(sender: UIButton) {
//        var viewCont: UIViewController
//        var previousVC: UIViewController? = nil
        let peopleHighImage = UIImage(named: "peopleButton")
//        cityPeopleButton.setImage(peopleHighImage, forState: .Selected)
        cityPeopleButton.setBackgroundImage(peopleHighImage, forState: .Selected)
        
        sender.selected = sender.state == .Highlighted ? true : false
       
        //        Default tab is city view, when button is selected people view is shown
        if(sender.selected){
            cityContainerView.alpha = 0
            peopleContainerView.alpha = 1
        }else{
            cityContainerView.alpha = 1
            peopleContainerView.alpha = 0
        }

//        Default tab is city view, when button is selected people view is shown
//        if(sender.selected){
//            if (checkOutCityViewController.isViewLoaded()){
//                previousVC = checkOutCityViewController
//            }
//            viewCont = checkOutPeopleViewController
//        }else{
//            if (checkOutPeopleViewController.isViewLoaded()){
//                previousVC = checkOutPeopleViewController
//            }
//            viewCont = checkOutCityViewController
//        }
//        //Remove previous view controller
//        //  Calling the willMoveToParentViewController method with the value nil gives the child view controller an opportunity to prepare for the change.
//        if let oldVC = previousVC{
//            oldVC.willMoveToParentViewController(nil)
//            oldVC.view.removeFromSuperview()
//            //        The removeFromParentViewController method also calls the child’s didMoveToParentViewController: method, passing that method a value of nil. Setting the parent view controller to nil finalizes the removal of the child’s view from your container.
//            oldVC.removeFromParentViewController()
//        }
//        
//        //Show new view controller
//        //Calls viewWillAppear from the requested view controller, and this method calls the child’s willMoveToParentViewController
//        addChildViewController(viewCont)
//        viewCont.loadView()
//        viewCont.view.frame = contentTabView.bounds
////        viewCont.view.frame = contentTabView.frame
//        contentTabView.addSubview(viewCont.view)
//        //Call view did appear of the requested view controller
//        viewCont.didMoveToParentViewController(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let cityHighImage = UIImage(named: "cityButton")
//        cityPeopleButton.setImage(cityHighImage, forState: .Normal)
        pressTabBar(cityPeopleButton)
        
        //Get ref to storyboard to be able to instantiate view controller
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        checkOutCityViewController = storyboard.instantiateViewControllerWithIdentifier("CheckOutCityViewController") as! CheckOutCityViewController
//        checkOutPeopleViewController = storyboard.instantiateViewControllerWithIdentifier("CheckOutPeopleViewController") as! CheckOutPeopleViewController
//        viewControllers = [checkOutCityViewController, checkOutPeopleViewController]


    }
}
    

