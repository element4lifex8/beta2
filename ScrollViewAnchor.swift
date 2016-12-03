//
//  ScrollViewAnchor.swift
//  Beta2
//
//  Created by Jason Johnston on 8/28/16.
//  Copyright © 2016 anuJ. All rights reserved.
//
import UIKit

class ScrollViewAnchor: UIScrollView {
    
    class MyView: UIView {
        override init (frame : CGRect) {
            super.init(frame : frame)
            let myView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            myView.backgroundColor = UIColor.red
//            myView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(myView)
            //myView.centerYAnchor.constraintEqualToAnchor(superview!.centerYAnchor).active = true

        }
        
        convenience init () {
            self.init(frame:CGRect.zero)
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("This class does not support NSCoding")
        }
        
        func addBehavior (){
            print("Add all the behavior here")
        }
    }
    
    
 
    
    
    

//    lazy var sv: UIScrollView = {
//        let object = UIScrollView()
//        
//        object.backgroundColor = UIColor.whiteColor()
//        object.translatesAutoresizingMaskIntoConstraints = false
//        return object
//    }()
//
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        self.addSubview(self.sv)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        let vc = nextResponder() as? UIViewController
//        let mainSreenWidth = UIScreen.mainScreen().bounds.size.width
//        let mainScreenHeight = UIScreen.mainScreen().bounds.size.height
//        
//        NSLayoutConstraint.activateConstraints([
//            self.sv.topAnchor.constraintEqualToAnchor(vc?.topLayoutGuide.bottomAn     chor),
//            self.sv.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor),
//            self.sv.bottomAnchor.constraintEqualToAnchor(vc?.bottomLayoutGuide.topAnchor),
//            self.sv.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor)
//            ])
//    }
}
