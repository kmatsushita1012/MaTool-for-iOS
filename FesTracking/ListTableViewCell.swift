//
//  ListTableViewCell.swift
//  FesTracking
//
//  Created by 松下和也 on 2024/02/10.
//

import UIKit

class ListTableViewCell: UITableViewCell{
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var option: UILabel!
    var options: [String]?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func setCell(labelText :String,options: [String],defaultIndex:Int){
        self.label.text = labelText
        self.options = options
        self.option.text = self.options![defaultIndex]
        
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }    
}
