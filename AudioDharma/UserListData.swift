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
    
    //MARK: Properties
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("UserListData")
    
    struct PropertyKey {
        static let title = "title"
    }
    
    var title: String = ""
    var talkFileNames:  [String] = [String] ()
    //var talks: [TalkData] = [TalkData] ()
    
    init(title: String) {
        self.title = title
        
        print("Created User folder.  Title: \(title) ")
        
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: PropertyKey.title)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        // The name is required. If we cannot decode a name string, the initializer should fail.
        guard let title = aDecoder.decodeObject(forKey: PropertyKey.title) as? String else {
            os_log("Unable to decode the name for a USListData object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        // Must call designated initializer.
        self.init(title: title)
        
    }
    
    
    
    
}
