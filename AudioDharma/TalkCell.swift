//
//  TalkCell.swift
//  AudioDharma
//
//  Created by Christopher on 7/29/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class TalkCell: UITableViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var speakerPhoto: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var noteImage: UIImageView! 
    @IBOutlet weak var favoriteImage: UIImageView!
    
    // MARK: Properties
    var isUserSelected: Bool! = false

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
   
    
}
