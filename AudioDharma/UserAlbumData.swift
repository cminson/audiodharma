//
//  UserFolderData.swift
//  AudioDharma
//
//  Created by Christopher on 6/27/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log

class UserAlbumData: NSObject, NSCoding {
    
    // MARK: Persistance
    struct PropertyKey {
        static let Title = "Title"
        static let TalkFileNames = "TalkFileNames"
        static let Image = "Image"
    }
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("UserAlbumData")

    
    // MARK: Properties
    var Title: String = ""
    var TalkFileNames:  [String] = [String] ()
    var Image: UIImage

    
    // MARK: Init
    init(title: String, image: UIImage) {
        Title = title
        Image = image
    }


    init(title: String,  image: UIImage, talkFileNames: [String]) {
        Title = title
        Image = image
        TalkFileNames = talkFileNames
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(Title, forKey: PropertyKey.Title)
        aCoder.encode(Image, forKey: PropertyKey.Image)
        aCoder.encode(TalkFileNames, forKey: PropertyKey.TalkFileNames)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let title = aDecoder.decodeObject(forKey: PropertyKey.Title) as? String else {
            os_log("Unable to decode the title for a USListData object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let image = aDecoder.decodeObject(forKey: PropertyKey.Image) as? UIImage else {
            os_log("Unable to decode the image for a UIImage object.", log: OSLog.default, type: .debug)
            return nil
        }
       
        guard let talkFileNames = aDecoder.decodeObject(forKey: PropertyKey.TalkFileNames) as? [String] else {
            os_log("Unable to decode the talkFileNames for a [String] object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        self.init(title: title, image: image, talkFileNames: talkFileNames)
    }
    
    
    
    
}
