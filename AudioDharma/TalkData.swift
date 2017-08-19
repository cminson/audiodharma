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
    var Speaker: String
    var SpeakerPhoto: UIImage
    var Section: String
    var DurationDisplay: String
    
    var DurationInSeconds: Int
    
    var DatePlayed: String!
    var TimePlayed: String!
    var Location: String!
    
    // MARK: Init
    init(title: String,  url: String, fileName: String, date: String, durationDisplay: String, speaker: String, section: String, durationInSeconds: Int) {
        
        Title = title
        URL = url
        FileName = fileName
        Date = date
        DurationDisplay = durationDisplay
        Speaker = speaker
        SpeakerPhoto = UIImage(named: speaker) ?? UIImage(named: "defaultPhoto")!
        Section = section
        DurationInSeconds = durationInSeconds
        
        DatePlayed = ""
        TimePlayed = ""
        Location = ""
    }

}
