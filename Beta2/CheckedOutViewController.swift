//
//  CheckedOutViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 6/12/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit

protocol sendContainerDelegate {
    func buttonStateChange(_ shouldDisplayPeople: Bool)
}

class CheckedOutViewController: UIViewController {
    
    
//    @IBOutlet weak var contentTabView: UIView!
    @IBOutlet weak var cityPeopleButton: UIButton!
    
//    @IBOutlet weak var peopleContainerView: UIView!
    
    @IBOutlet weak var checkContainerView: UIView!
    
    //delegate used to send button state to contained VC
    var containerDelegate: sendContainerDelegate?
    
    
    //keep track of which tableview to display
    //default view in city view
    var willDisplayPeople:Bool = false
    
//    var checkOutCityViewController: CheckOutCityViewController!
//    var checkOutPeopleViewController: CheckOutPeopleViewController!
//    var viewControllers: [UIViewController] = []
//    var selectedVC: Int = 0 //default is City
    
    @IBAction func pressTabBar(_ sender: UIButton) {
//        var viewCont: UIViewController
//        var previousVC: UIViewController? = nil
        let peopleHighImage = UIImage(named: "peopleButton")
//        cityPeopleButton.setImage(peopleHighImage, forState: .Selected)
        cityPeopleButton.setBackgroundImage(peopleHighImage, for: .selected)
        
        sender.isSelected = sender.state == .highlighted ? true : false
       
        //        Default tab is city view, when button is selected people view is shown
        if(sender.isSelected){
            willDisplayPeople = true
             containerDelegate?.buttonStateChange(true)
        }else{
            willDisplayPeople = false
            containerDelegate?.buttonStateChange(false)
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
//        pressTabBar(cityPeopleButton)
        let containedVC: CheckOutContainedViewController = CheckOutContainedViewController(nibName: "CheckOutContainedViewController", bundle: nil) as CheckOutContainedViewController
        
//        How to setup container view controllers the right way (didn't work for me) I don't think I was obtaining a proper reference to the VC's from the storyboard
//        containedVC = CheckOutContainedViewController(nibName: "CheckOutContainedViewController", bundle: nil) as CheckOutContainedViewController
        
//        let cityHighImage = UIImage(named: "cityButton")
//        cityPeopleButton.setImage(cityHighImage, forState: .Normal)
        
        //Get ref to storyboard to be able to instantiate view controller
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        checkOutCityViewController = storyboard.instantiateViewControllerWithIdentifier("CheckOutCityViewController") as! CheckOutCityViewController
//        checkOutPeopleViewController = storyboard.instantiateViewControllerWithIdentifier("CheckOutPeopleViewController") as! CheckOutPeopleViewController
//        viewControllers = [checkOutCityViewController, checkOutPeopleViewController]


    }
    
    
}


