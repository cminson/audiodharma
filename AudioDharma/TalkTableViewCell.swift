//
//  TalkTableViewCell.swift
//  AudioDharma
//
//  Created by Christopher on 6/15/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class TalkTableViewCell: UITableViewCell {
   
    
    // MARK: Properties
    @IBOutlet weak var speakerPhoto: UIImageView!
    @IBOutlet weak var title: UILabel!

    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
