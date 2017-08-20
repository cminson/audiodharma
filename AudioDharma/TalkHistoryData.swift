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
        static let DatePlayed = "DatePlayed"
        static let TimePlayed = "TimePlayed"
        static let Location = "Location"
    }
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveTalkHistoryURL = DocumentsDirectory.appendingPathComponent("ArchiveTalkHistory")
    static let ArchiveShareHistoryURL = DocumentsDirectory.appendingPathComponent("ArchiveShareHistory")

    
    // MARK: Properties
    var FileName: String = ""
    var DatePlayed: String = ""
    var TimePlayed: String = ""
    var Location: String = ""
  
    
    // MARK: Init
    init(fileName: String, datePlayed: String, timePlayed: String, location: String) {
        FileName = fileName
        DatePlayed = datePlayed
        TimePlayed = timePlayed
        Location = location
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(FileName, forKey: PropertyKey.FileName)
        aCoder.encode(DatePlayed, forKey: PropertyKey.DatePlayed)
        aCoder.encode(TimePlayed, forKey: PropertyKey.TimePlayed)
        aCoder.encode(Location, forKey: PropertyKey.Location)
   }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let fileName = aDecoder.decodeObject(forKey: PropertyKey.FileName) as? String else {
            os_log("Unable to decode TalkHistoryData object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let datePlayed = aDecoder.decodeObject(forKey: PropertyKey.DatePlayed) as? String else {
            os_log("Unable to decode TalkHistoryData object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let timePlayed = aDecoder.decodeObject(forKey: PropertyKey.TimePlayed) as? String else {
            os_log("Unable to decode TalkHistoryData object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let location = aDecoder.decodeObject(forKey: PropertyKey.Location) as? String else {
            os_log("Unable to decode TalkHistoryData object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        
        self.init(fileName: fileName, datePlayed: datePlayed, timePlayed: timePlayed, location: location)
    }
}
