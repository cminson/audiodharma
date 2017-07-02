//
//  Talk.swift
//  AudioDharma
//
//  Created by Christopher on 6/14/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log


// comment
/*
 MPVolumeView
 http://swiftdeveloperblog.com/code-examples/add-playback-slider-to-avplayer-example-in-swift/
 
 */

class TalkData: NSObject {
    
    //MARK: Properties
    var title: String
    var talkURL: String
    var date: String
    var duration: String
    var speaker: String
    var speakerPhoto: UIImage
    var section: String
    var time: Int

    
    init(title: String,  talkURL: String, date: String, duration: String, speaker: String, section: String, time: Int) {
        self.title = title
        self.talkURL = talkURL
        self.date = date
        self.duration = duration
        self.speaker = speaker
        self.speakerPhoto = UIImage(named: speaker) ?? UIImage(named: "defaultPhoto")!
        self.section = section
        self.time = time

    }

}
