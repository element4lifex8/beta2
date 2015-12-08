//
//  TestTableViewCell.swift
//  Beta2
//
//  Created by Jason Johnston on 12/6/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit

class TestTableViewCell: UITableViewCell {

    
    @IBOutlet weak var tableCellValue: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
