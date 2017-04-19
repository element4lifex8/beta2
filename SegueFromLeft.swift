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
        let src = self.source.view as UIView!
        let dst = self.destination.view as UIView!
        
        let window = UIApplication.shared.delegate?.window!
        // the Views must be in the Window hierarchy, so insert as a subview the destionation above the source
        window?.insertSubview(dst!, aboveSubview: src!)
        
//        dst.viewWillDisappear(true)
//        src.viewWillAppear(true)
//        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
//        src.view.superview?.insertSubview(dst.view, belowSubview: src.view)
//        dst.view.transform = CGAffineTransform(translationX: -src.view.frame.size.width, y: 0)
        dst?.center = CGPoint(x: (src?.center.x)! - (dst?.center.y)!, y: (src?.center.y)!)

        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            dst?.center = CGPoint(x: (src?.center.x)!, y: (src?.center.y)!)
            src?.center = CGPoint(x: 2 * (src?.center.x)!, y: (dst?.center.y)!)
            //Move curr VC to the right off the screen
//            src.view.transform = CGAffineTransform(translationX: src.view.frame.size.width, y: 0)
            //Slide dest VC from left as the src is removed
//            dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
        }, completion: { finished in
//            dst.view.removeFromSuperview()
            self.source.dismiss(animated: false , completion: nil)
//            src.viewDidDisappear(true)
//            dst.viewDidAppear(true)
            })
        }
    }
