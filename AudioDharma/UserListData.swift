//
//  UserFolderData.swift
//  AudioDharma
//
//  Created by Christopher on 6/27/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log




class UserListData: NSObject {
    
    //MARK: Properties
    var title: String

    
    
    init(title: String) {
        self.title = title

        
        print("Created User folder.  Title: \(title) ")
        
    }
    
}
