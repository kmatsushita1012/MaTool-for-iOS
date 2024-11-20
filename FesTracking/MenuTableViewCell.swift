//
//  MenuTableViewCell.swift
//  FesTracking
//
//  Created by 松下和也 on 2024/02/24.
//

import UIKit

class MenuTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    func setCell(text:String,imageName:String){
        label.text = text
        iconImageView.image = UIImage(systemName: "imageName")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
