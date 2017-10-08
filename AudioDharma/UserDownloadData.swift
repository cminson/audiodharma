//
//  UserDownloadData.swift
//  AudioDharma
//
//  Created by Christopher on 10/8/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log


class UserDownloadData: NSObject, NSCoding {
    
    // MARK: Persistance
    struct PropertyKey {
        static let FileName = "FileName"
        static let DownloadCompleted = "DownloadCompleted"
    }
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("UserDownloadData")
    
    
    // MARK: Properties
    var FileName: String = ""
    var DownloadCompleted: Bool = false
    
    
    // MARK: Init
    init(fileName: String, downloadCompleted: Bool) {
        
        FileName = fileName
        DownloadCompleted = downloadCompleted
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(FileName, forKey: PropertyKey.FileName)
        aCoder.encode(DownloadCompleted, forKey: PropertyKey.DownloadCompleted)

    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let fileName = aDecoder.decodeObject(forKey: PropertyKey.FileName) as? String else {
            return nil
        }
        guard let downloadCompleted = aDecoder.decodeObject(forKey: PropertyKey.DownloadCompleted) as? Bool else {
            return nil
        }

        self.init(fileName: fileName, downloadCompleted: downloadCompleted)
    }
    
}
