//
//  AlbumData.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log



class AlbumData: NSObject {
    
    //MARK: Properties
    var Title: String
    var Content: String
    var Section: String
    var Image: String
    var Date: String
    
    
    init(title: String, content: String, section: String, image: String, date: String) {
        
        Title = title
        Content = content
        Section = section
        Image = image
        Date = date
    }
    
}
