//
//  SelectUserListTableViewCell.swift
//  AudioDharma
//
//  Created by Christopher on 6/30/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class SelectUserListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var listSwitch: UISwitch!
    
    @IBAction func switchChanged(_ sender: Any) {
        print(listSwitch.isOn)
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
