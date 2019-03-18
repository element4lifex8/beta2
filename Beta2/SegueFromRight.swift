//
//  SequeFromLeft.swift
//  Beta2
//
//  Created by Jason Johnston on 10/28/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit

class SegueFromRight: UIStoryboardSegue {
    override func perform()
    {
        let src = self.source.view as UIView?
        let dst = self.destination.view as UIView?
        
        let window = UIApplication.shared.delegate?.window!
        // the Views must be in the Window hierarchy, so insert as a subview the destionation above the source
        window?.insertSubview(dst!, aboveSubview: src!)
        
        //temporarily add the destination VC as a subview for the animation
//        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
//        dst.view.transform = CGAffineTransform(translationX: src.view.frame.size.width, y: 0)

//        src.view.superview?.insertSubview(dst.view, belowSubview: src.view)
//        dst.view.frame.offsetBy(dx: src.view.frame.size.width, dy: 0)
        
        dst?.center = CGPoint(x: (src?.center.x)! + (dst?.center.y)!, y: (src?.center.y)!)
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            dst?.center = CGPoint(x: (src?.center.x)!, y: (src?.center.y)!)
            src?.center = CGPoint(x: (src?.center.x)! / 2, y: (dst?.center.y)!)
            //Move curr VC to the Left off the screen
//            src?.transform = CGAffineTransform(translationX: -(src?.frame.size.width)!, y: 0)
//            //Slide dest V from right as Src VC is removed
//            dst?.transform = CGAffineTransform(translationX: 0, y: 0)
            }, completion: { finished in
//                if let navController = src.navigationController {
//                    navController.pushViewController(dst, animated: true)
//                    }
//                dst.view.removeFromSuperview()
                self.source.present(self.destination, animated: false, completion: nil)
               
            })
    }
}
