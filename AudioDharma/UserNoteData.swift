//
//  UserNoteData.swift
//  AudioDharma
//
//  Created by Christopher on 7/30/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log


class UserNoteData: NSObject, NSCoding {
    
    // MARK: Persistance
    struct PropertyKey {
        static let Notes = "Notes"
    }
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("UserNoteData")
    
    
    // MARK: Properties
    var Notes: String = ""
    
    
    // MARK: Init    
    init(notes: String) {
        Notes = notes
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(Notes, forKey: PropertyKey.Notes)
     }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        //print("UserNoteData: Decode")
        guard let notes = aDecoder.decodeObject(forKey: PropertyKey.Notes) as? String else {
            return nil
        }
        
        self.init(notes: notes)
    }
    
}


