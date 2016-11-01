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
        let src = self.sourceViewController
        let dst = self.destinationViewController
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransformMakeTranslation(src.view.frame.size.width, 0)
        
        UIView.animateWithDuration(0.25,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.CurveEaseInOut,
                                   animations: {
                                    //Move curr VC to the Left off the screen
                                    src.view.transform = CGAffineTransformMakeTranslation(-src.view.frame.size.width, 0)
                                    //Slide dest V from right as Src VC is removed
                                    dst.view.transform = CGAffineTransformMakeTranslation(0, 0)
            },
                                   completion: { finished in
//                                    if let navController = src.navigationController {
//                                        navController.pushViewController(dst, animated: true)
//                                    }
                                    src.presentViewController(dst, animated: false, completion: nil)
            }
        )
    }
}
