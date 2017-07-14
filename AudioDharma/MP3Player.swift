//
//  MP3Player.swift
//  AudioDharma
//
//  Created by Christopher on 7/3/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//


import UIKit
import AVFoundation

class MP3Player : NSObject {
    
    var player : AVPlayer = AVPlayer()
    var playerItem : AVPlayerItem?
    
    var currentTrackIndex = 0
    var tracks : [String] = [String]()
    
    override init(){
        super.init()
    }
    
    func startTalk(talk: TalkData){
        
        
        let url : URL = URL(string: talk.URL)!
        self.playerItem  = AVPlayerItem(url: url)
        self.player =  AVPlayer(playerItem : self.playerItem)
        self.player.play()
        
        
        let notificationName = Notification.Name("SetTrackNameText")
        //NotificationCenter.defaultCenter.postNotificationName("SetTrackNameText", object: nil)
        NotificationCenter.default.post(name: notificationName, object: nil)
        
    }
    
    func play() {
        self.player.play()
    }
    
    func stop(){
        self.player.pause()
        player.seek(to: kCMTimeZero)
  
    }
    
    func pause(){
        self.player.pause()
    }
    
    func currentTime()-> CMTime {
        return self.player.currentTime()
    }
    
    func nextTalk(talkFinishedPlaying:Bool){
        
    }
    
    
    
    func previousTalk(){
    }
    
    func getCurrentTrackName() -> String {
        //let trackName = tracks[currentTrackIndex].lastPathComponent.stringByDeletingPathExtension
        let trackName = "test"
        return trackName
    }
    
   
     func getCurrentTimeAsString() -> String {
     
        var seconds = 0
        var minutes = 0
        
        let ct = self.playerItem?.currentTime()
        if (ct != nil) {
            let time = CMTimeGetSeconds(ct!)
        
            seconds = Int(time) % 60
            minutes = (Int(time) / 60) % 60
        }
        return String(format: "%0.2d:%0.2d",minutes,seconds)
     }
    
    
     func getProgress()->Float {
        
        var theCurrentTime = 0.0
        var theCurrentDuration = 0.0
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        
        let ct = player.currentItem?.asset.duration
        if (ct != nil) {
            let duration = CMTimeGetSeconds(ct!)
            theCurrentTime = currentTime
            theCurrentDuration = duration
            
        }
        return Float(theCurrentTime / theCurrentDuration)
     }
   
    
    
    func setVolume(volume:Float){
        player.volume = volume
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool){
        if flag == true {
            nextTalk(talkFinishedPlaying: true)
        }
    }
    
}
