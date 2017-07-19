//
//  UserListTableViewCell.swift
//  AudioDharma
//
//  Created by Christopher on 6/27/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class UserListTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var listImage: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var statTalkCount: UILabel!
    @IBOutlet weak var statTotalTime: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
