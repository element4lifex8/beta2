//
//  PlaceDeetsTableViewCell.swift
//  Pods
//
//  Created by Jason Johnston on 2/2/17.
//
//

import UIKit

class PlaceDeetsTableViewCell: UITableViewCell {

    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var deetsLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
