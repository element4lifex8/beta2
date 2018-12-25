//
//  T&CviewController.swift
//  
//
//  Created by Jason Johnston on 7/13/18.
//

import UIKit

class T_CviewController: UIViewController {

    @IBOutlet var textView: UITextView!
    
    //Class member that can be set when transitioning to this VC during the onboarding process
    var isOnboarding: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //         self.textView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0,y: 0), size: CGSize(width: 1, height: 1)), animated: false)
        //Because the iphone 6s with ios 11 was adding some intial scroll offset to the text view I had to create this entire class just to force the offset to zero
        self.textView.scrollRangeToVisible(NSMakeRange(0, 0))
    }
    
    //Have to do manual unwind since unwind wasn't working from storyboard
    @IBAction func PressBackButton(_ sender: UIButton) {
        //If we're coming from onboarding then dismiss, otherwise unwind
        if(isOnboarding)
        {
            dismiss(animated: true, completion: nil)
        }else{
            self.performSegue(withIdentifier: "UnwindTerms2Profile", sender: self)
        }
    }
}
