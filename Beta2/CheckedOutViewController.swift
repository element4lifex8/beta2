//
//  CheckedOutViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 6/12/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit

class CheckedOutViewController: UIViewController {
    
    func buttonAction(sender: UIButton!) {
        print("Button tapped")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frame = CGRect(x: 125, y: 200, width: 100, height: 100)
        let blueSquare = UIView(frame: frame)
        blueSquare.backgroundColor = UIColor.blueColor()
        
        view.addSubview(blueSquare)
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 80))   // X, Y, width, height
        button.backgroundColor = .greenColor()
        button.setTitle("Test Button", forState: .Normal)
        button.addTarget(self, action: #selector(buttonAction), forControlEvents: .TouchUpInside)
        
        blueSquare.addSubview(button)
    }
}
