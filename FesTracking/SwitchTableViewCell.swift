//
//  SwitchTableViewCell.swift
//  FesTracking
//
//  Created by 松下和也 on 2024/02/10.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var uiSwitch: UISwitch!
    var returnFunc:((Bool)->Void)?
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func setCell(labelText :String,isOn:Bool, returnFunc:@escaping ((Bool)->Void)){
        self.label.text = labelText
        self.returnFunc = returnFunc
        self.uiSwitch.isOn = isOn
    }
    
    @IBAction func uiSwitch(_ sender: UISwitch) {
        if let returnFunc = self.returnFunc{
            returnFunc(sender.isOn)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
