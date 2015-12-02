//
//  testButt.swift
//  Beta2
//
//  Created by Jason Johnston on 11/7/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
@IBDesignable
class testButt: UIButton {

    // Only override drawRect: if you perform custom drawing.
    /* An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        let rect = UIBezierPath(rect: CGRect(origin: CGPoint(x:50,y:50), size: CGSize(width: 100, height: 100)))
        rect.stroke()
    }*/

    override func layoutSubviews()
    {
        let rect = UIBezierPath(rect: CGRect(origin: CGPoint(x:50,y:50), size: CGSize(width: 100, height: 100)))
        rect.stroke()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let rect = UIBezierPath(rect: CGRect(origin: CGPoint(x:50,y:50), size: CGSize(width: 100, height: 100)))
        rect.stroke()
    }

}
