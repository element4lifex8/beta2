//
//  FaqViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 12/4/17.
//  Copyright © 2017 anuJ. All rights reserved.
//

import UIKit

class FaqViewController: UIViewController {

    @IBOutlet var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()

        //Because the iphone 6s with ios 11 was adding some intial scroll offset to the text view I had to create this entire class just to force the offset to zero
        self.textView.scrollRangeToVisible(NSMakeRange(0, 0))
    }

}
