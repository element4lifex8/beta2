//
//  HeaderTableViewCell.swift
//  Beta2
//
//  Created by Jason Johnston on 5/25/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit

class HeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var tableCellValue: UILabel!
    
    @IBOutlet weak var headerView: UIView!
    
    func addSeperator(tableViewWidth: CGFloat, needsTop: Bool){
        //Add table view top seperator
        let px = 1 / UIScreen.mainScreen().scale    //determinte 1 pixel size instead of using 1 point
        let frame = CGRectMake(0, 0, tableViewWidth, px)
        let topLine: UIView = UIView(frame: frame)
        let bottomframe = CGRectMake(0, headerView.frame.size.height-px, tableViewWidth, px)
        let bottomLine: UIView = UIView(frame: bottomframe)
        //only the first cell needs the top line
        if(needsTop){
            self.headerView.addSubview(topLine)
        }
        self.headerView.addSubview(bottomLine)
        topLine.backgroundColor = UIColor.whiteColor()
        bottomLine.backgroundColor = UIColor.whiteColor()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
