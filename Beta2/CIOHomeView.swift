//
//  CIOHomeView.swift
//  Beta2
//
//  Created by Jason Johnston on 11/7/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit

//CA Layer extension used to allow runtime property to be set on the text box's view for borderUIColor

extension CALayer {
    var buttBorUIColor: UIColor {
        set {
            self.borderColor = newValue.cgColor
        }
        
        get {
            return UIColor(cgColor: self.borderColor!)
        }
    }
}

class CIOHomeView: UIView {

    //@IBOutlet weak var CheckText: UILabel!
    
    // Only override drawRect: if you perform custom drawing.
    /*An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        
    }*/
        /*
        let checkOutButtonCircle = UIBezierPath(arcCenter: centerPt(), radius: CGFloat(bounds.size.width/2), startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
        checkOutButtonCircle.stroke()
        //CheckText.font = UIFont( name: "AmericanTypewriter-bold", size: 48)!
    }

    func centerPt () ->CGPoint {
        //center must be converted from super class view controller
        let buttonCenter = convertPoint(center , fromView: superview)
        return buttonCenter

    }*/




}
