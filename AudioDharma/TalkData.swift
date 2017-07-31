//
//  TalkData.swift
//  AudioDharma
//
//  Created by Christopher on 6/14/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit


class TalkData: NSObject {
    
    // MARK: Properties
    var Title: String
    var URL: String
    var FileName: String
    var Date: String
    var Duration: String
    var Speaker: String
    var SpeakerPhoto: UIImage
    var Section: String
    var Time: Int
    var HasNotes: Bool
    
    // MARK: Init
    init(title: String,  url: String, fileName: String, date: String, duration: String, speaker: String, section: String, time: Int, hasNotes: Bool) {
        Title = title
        URL = url
        FileName = fileName
        Date = date
        Duration = duration
        Speaker = speaker
        SpeakerPhoto = UIImage(named: speaker) ?? UIImage(named: "defaultPhoto")!
        Section = section
        Time = time
        HasNotes = hasNotes
    }

}
