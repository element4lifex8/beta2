//
//  RoundButtCollectionViewCell.swift
//  Beta2
//
//  Created by Jason Johnston on 8/13/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit

class RoundButtCollectionViewCell: UICollectionViewCell {
//    @IBOutlet weak var myLabel: UILabel!

    override func prepareForReuse() {
        //remove labels
        for case let label as UILabel in contentView.subviews{
            label.removeFromSuperview()
        }
        //remove check image
        for case let image as UIImageView in contentView.subviews{
            image.removeFromSuperview()
        }
    }

}
