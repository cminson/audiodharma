//
//  MP3Player.swift
//  AudioDharma
//
//  Created by Christopher on 7/3/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//


import UIKit
import AVFoundation
import CoreMedia

let FAST_SEEK : Int64 = 25

class MP3Player : NSObject {
    
    var player : AVPlayer = AVPlayer()
    var playerItem : AVPlayerItem?
    
    var currentTrackIndex = 0
    var tracks : [String] = [String]()
    
    override init(){
        super.init()
    }
    
    public func startTalk(talk: TalkData){
        
        
        let url : URL = URL(string: talk.URL)!
        print(talk.URL)
        //let url = URL(string: "http://www.ezimba.com/ad/test01.mp3")!
        self.playerItem  = AVPlayerItem(url: url)
        self.player =  AVPlayer(playerItem : self.playerItem)
        self.player.play()
        
        let notificationName = Notification.Name("SetTrackNameText")
        //NotificationCenter.defaultCenter.postNotificationName("SetTrackNameText", object: nil)
        NotificationCenter.default.post(name: notificationName, object: nil)
        
    }
    
    public func play() {
        
        self.player.play()
    }
    
    public func stop() {
        
        self.player.pause()
        player.seek(to: kCMTimeZero)
    }
    
    public func pause() {
        
        self.player.pause()
    }
    
    public func seekFastForward() {
        
        if let ct = self.playerItem?.currentTime(), let dt = player.currentItem?.asset.duration {
            let currentTimeInSeconds = Int64(CMTimeGetSeconds(ct))
            let durationTimeInSeconds = Int64(CMTimeGetSeconds(dt))
            print(durationTimeInSeconds)
            
            if currentTimeInSeconds + FAST_SEEK < durationTimeInSeconds {
                self.player.seek(to: CMTimeMake(currentTimeInSeconds + FAST_SEEK, 1))

            } else {
                self.player.seek(to: CMTimeMake(durationTimeInSeconds, 1))
            }
        }
    }
    
    public func seekFastBackward() {
        
        if let ct = self.playerItem?.currentTime() {
            let currentTimeInSeconds = Int64(CMTimeGetSeconds(ct))
            
            if currentTimeInSeconds - FAST_SEEK > Int64(0) {
                self.player.seek(to: CMTimeMake(currentTimeInSeconds - FAST_SEEK, 1))
                
            } else {
                self.player.seek(to: CMTimeMake(0, 1))
            }
        }
    }
    
    public func currentTime()-> CMTime {
        
        return self.player.currentTime()
    }
    
    public func nextTalk(talkFinishedPlaying:Bool) {
        
    }
    
    public func getCurrentTrackName() -> String {
        //let trackName = tracks[currentTrackIndex].lastPathComponent.stringByDeletingPathExtension
        let trackName = "test"
        return trackName
    }
    
    public func getCurrentTimeAsString() -> String {
     
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
    
    
     public func getProgress()->Float {
        
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
   
    public func setVolume(volume:Float){
        
        player.volume = volume
    }
    
    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool){
        
        if flag == true {
            nextTalk(talkFinishedPlaying: true)
        }
    }
    
}
