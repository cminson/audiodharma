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
    var VURL: String
    var FileName: String
    var Date: String
    var Speaker: String
    var Section: String
    var DurationDisplay: String
	var PDF: String
    var Keys: String
    
    var DurationInSeconds: Int
    var SpeakerPhoto: UIImage
        
    // MARK: Init
    init(title: String,
         url: String,
         vurl: String,
         fileName: String,
         date: String,
         durationDisplay: String,
         speaker: String,
         section: String,
         durationInSeconds: Int,
         pdf: String,
         keys: String) {
        
        Title = title
        URL = url
        VURL = vurl
        FileName = fileName
        Date = date
        DurationDisplay = durationDisplay
        Speaker = speaker
        Section = section
        DurationInSeconds = durationInSeconds
        PDF = pdf
        Keys = keys
        
        SpeakerPhoto = UIImage(named: Speaker) ?? UIImage(named: "defaultPhoto")!
        
     } 

}
