//
//  SequeFromLeft.swift
//  Beta2
//
//  Created by Jason Johnston on 10/28/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
//Class used as unwind segue by dismissing the viewcontroller
class SegueFromLeft: UIStoryboardSegue {
    override func perform()
    {
        let src = self.source
        let dst = self.destination
        
//        dst.viewWillDisappear(true)
//        src.viewWillAppear(true)
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
//        src.view.superview?.insertSubview(dst.view, belowSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: -src.view.frame.size.width, y: 0)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            //Move curr VC to the right off the screen
            src.view.transform = CGAffineTransform(translationX: src.view.frame.size.width, y: 0)
            //Slide dest VC from left as the src is removed
            dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
        }, completion: { finished in
            dst.view.removeFromSuperview()
            src.dismiss(animated: false , completion: nil)
//            src.viewDidDisappear(true)
//            dst.viewDidAppear(true)
            })
        }
    }
