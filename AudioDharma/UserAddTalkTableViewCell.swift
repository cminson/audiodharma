//
//  UserAddTalkTableViewCell.swift
//  AudioDharma
//
//  Created by Christopher on 6/28/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class UserAddTalkTableViewCell: UITableViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var speakerPhoto: UIImageView!
    @IBOutlet weak var userSelected: UIImageView!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var duration: UILabel!

    
    // MARK: Properties
    var isUserSelected: Bool! = false

    
    override func awakeFromNib() {
        super.awakeFromNib()
     }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

     }
    
    
}
