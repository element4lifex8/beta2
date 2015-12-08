//
//  CheckedView.swift
//  Beta2
//
//  Created by Jason Johnston on 12/1/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit

class CheckedView: UIView {
    let restNameDefaultKey = "CheckInView.restName"
    private let sharedRestName = NSUserDefaults.standardUserDefaults()
    
    var restNameHistory: [String] {
        get
        {
            return sharedRestName.objectForKey(restNameDefaultKey) as? [String] ?? []
        }
        set
        {
            sharedRestName.setObject(newValue, forKey: restNameDefaultKey)
        }
    }
    

    @IBOutlet weak var previewRestText: UITextView!
        {
        didSet{
            previewRestText.text = "\(restNameHistory)"
        }

    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
