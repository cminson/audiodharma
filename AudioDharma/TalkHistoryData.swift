//
//  TalkHistoryData.swift
//  AudioDharma
//
//  Created by Christopher on 8/5/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log


class TalkHistoryData: NSObject, NSCoding {
    
    // MARK: Persistance
    struct PropertyKey {
        static let FileName = "FileName"
    }
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("TalkHistoryData")
    
    
    // MARK: Properties
    var FileName: String = ""
    
    
    // MARK: Init
    init(fileName: String) {
        FileName = fileName
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(FileName, forKey: PropertyKey.FileName)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let fileName = aDecoder.decodeObject(forKey: PropertyKey.FileName) as? String else {
            os_log("Unable to decode TalkHistoryData object.", log: OSLog.default, type: .debug)
            return nil
        }
        self.init(fileName: fileName)
    }
}
