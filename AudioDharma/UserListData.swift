//
//  UserFolderData.swift
//  AudioDharma
//
//  Created by Christopher on 6/27/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log

class UserListData: NSObject, NSCoding {
    
    // MARK: Persistance
    struct PropertyKey {
        static let title = "title"
        static let talkFileNames = "talkFileNames"
    }
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("UserListData")

    
    // MARK: Properties
    var title: String = ""
    var talkFileNames:  [String] = [String] ()
    
    
    // MARK: Init
    init(title: String) {
        self.title = title
        print("Init 1 Created User folder.  Title: \(title) ")
    }

    init(title: String, talkFileNames: [String]) {
        self.title = title
        self.talkFileNames = talkFileNames
        print("Init 2 Created User folder.  Title: \(title) ")
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        
        print("UserFolderData: Encode")
        aCoder.encode(title, forKey: PropertyKey.title)
        aCoder.encode(talkFileNames, forKey: PropertyKey.talkFileNames)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        print("UserFolderData: Decode")
        guard let title = aDecoder.decodeObject(forKey: PropertyKey.title) as? String else {
            os_log("Unable to decode the title for a USListData object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let talkFileNames = aDecoder.decodeObject(forKey: PropertyKey.talkFileNames) as? [String] else {
            os_log("Unable to decode the talkFileNames for a [String] object.", log: OSLog.default, type: .debug)
            return nil
        }
       
        self.init(title: title, talkFileNames: talkFileNames)
        
    }
    
    
    
    
}
