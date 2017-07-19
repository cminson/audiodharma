//
//  FolderTableViewCell.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit


class FolderTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var listImage: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var statTalkCount: UILabel!
    @IBOutlet weak var statTotalTime: UILabel!
    
    // MARK: Init
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
