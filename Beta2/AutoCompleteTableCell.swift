//
//  AutoCompleteTableCell.swift
//  Pods
//
//  Created by Jason Johnston on 6/8/17.
//
//

import UIKit

class AutoCompleteTableCell: UITableViewCell {

    
    var primaryLabel: UILabel!
    var secondaryLabel: UILabel!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
//    override init(frame: CGRect, title: String) {
//        super.init(style: UITableViewCellStyle.default, reuseIdentifier: "autoCompleteCell")
    
        //Create attributes for the heading label
//        let primarySize = CGRect(x: 10, y: 5, width: self.frame.width - 30, height: self.frame.height / 2.5)
        primaryLabel = UILabel(frame: CGRect.zero)
        primaryLabel.textColor = .black
        primaryLabel.font = UIFont(name: "Avenir-Light", size: 18)
        primaryLabel.lineBreakMode = .byTruncatingTail
        
        //Create attributes for the secondary address label
//        let secondY = (self.frame.height / 2.5) + 5
//        let secondarySize = CGRect(x: 10, y: secondY, width: self.frame.width - 30, height: self.frame.height / 3)
        secondaryLabel = UILabel(frame: CGRect.zero)
        secondaryLabel.textColor = .black
        secondaryLabel.font = UIFont(name: "Avenir-Light", size: 12)
        secondaryLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(primaryLabel)
        contentView.addSubview(secondaryLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let primarySize = CGRect(x: 10, y: 3, width: self.frame.width - 10, height: self.frame.height / 1.9)
        primaryLabel.frame = primarySize
        let secondY = (self.frame.height / 1.9) + 3
        let secondarySize = CGRect(x: 10.0, y: secondY, width: self.frame.width - 10.0, height: self.frame.height / 2.9)
        secondaryLabel.frame = secondarySize
    }

}
