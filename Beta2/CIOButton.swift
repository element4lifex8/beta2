//
//  CIOButton.swift
//  Beta2
//
//  Created by Jason Johnston on 11/7/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit

@IBDesignable
class CIOButton: UIButton
{

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    private var outerRingShape: CAShapeLayer!
    
    @IBInspectable
    var lineWidth: CGFloat = 2 //optional property observer: { didSet { setNeedsDisplay() }}
    
   override func layoutSubviews()
   {
        super.layoutSubviews()
        createButtonLayers()
        self.backgroundColor = UIColor.blackColor()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    func createButtonLayers()
    {
        if outerRingShape == nil
        {
            outerRingShape = CAShapeLayer()
            outerRingShape.path = UIBezierPath(ovalInRect: frameWithInset()).CGPath
            outerRingShape.bounds = frameWithInset()
            outerRingShape.lineWidth = lineWidth
            outerRingShape.strokeColor = UIColor.blueColor().CGColor
            outerRingShape.fillColor = UIColor.redColor().CGColor
            outerRingShape.position = CGPoint(x: CGRectGetWidth(self.bounds)/2, y: CGRectGetHeight(self.bounds)/2)
            //outerRingShape.position = convertPoint(center, fromView: superview)
            //outerRingShape.opacity = 0.5
            self.layer.addSublayer(outerRingShape)
        }

    }
    
    func createSubView()
    {
    }

    //return rect that is smaller than self.bounds by linewidth/2
    private func frameWithInset() -> CGRect
    {
        return CGRectInset(self.bounds, lineWidth/2, lineWidth/2)
    }

}
