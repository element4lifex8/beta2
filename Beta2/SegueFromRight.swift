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
        let src = self.source
        let dst = self.destination
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: src.view.frame.size.width, y: 0)
        
        UIView.animate(withDuration: 0.25,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions(),
                                   animations: {
                                    //Move curr VC to the Left off the screen
                                    src.view.transform = CGAffineTransform(translationX: -src.view.frame.size.width, y: 0)
                                    //Slide dest V from right as Src VC is removed
                                    dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
            },
                                   completion: { finished in
//                                    if let navController = src.navigationController {
//                                        navController.pushViewController(dst, animated: true)
//                                    }
                                    src.present(dst, animated: false, completion: nil)
            }
        )
    }
}
