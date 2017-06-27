//
//  FolderData.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log




class FolderData: NSObject {
    
    //MARK: Properties
    var title: String
    var content: String
    var section: String
    
    
    init(title: String, content: String, section: String) {
        self.title = title
        self.content = content
        self.section = section
        
        print("Created folder.  Title: \(title)  Content: \(content)   Section: \(section)")
        
    }
    
}
