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
    
    func addSeperator(_ tableViewWidth: CGFloat, needsTop: Bool){
        //Add table view top seperator
        let px = 1 / UIScreen.main.scale    //determinte 1 pixel size instead of using 1 point
        let frame = CGRect(x: 0, y: 0, width: tableViewWidth, height: px)
        let topLine: UIView = UIView(frame: frame)
        let bottomframe = CGRect(x: 0, y: headerView.frame.size.height-px, width: tableViewWidth, height: px)
        let bottomLine: UIView = UIView(frame: bottomframe)
        //only the first cell needs the top line
        if(needsTop){
            self.headerView.addSubview(topLine)
        }
        self.headerView.addSubview(bottomLine)
        topLine.backgroundColor = UIColor.white
        bottomLine.backgroundColor = UIColor.white
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
