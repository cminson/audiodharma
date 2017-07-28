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

let FAST_SEEK : Int64 = 25  // number of seconds to move for each Seek operation

class MP3Player : NSObject {
    
    // MARK: Properties
    var Delegate: PlayTalkController!
    var Player : AVPlayer = AVPlayer()
    var PlayerItem : AVPlayerItem?
    
    // MARK: Init
    override init(){
        
        super.init()
    }
    
    // MARK: Public
    public func startTalk(talk: TalkData){
        
        //let url = URL(string: "http://www.ezimba.com/ad/test01.mp3")!
        let url : URL = URL(string: talk.URL)!
        PlayerItem  = AVPlayerItem(url: url)
        Player =  AVPlayer(playerItem : PlayerItem)
        Player.allowsExternalPlayback = true
        
        // get notification once talk ends
        NotificationCenter.default.addObserver(self,selector:
                        #selector(self.talkHasCompleted),
                        name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                        object: PlayerItem)
        
        Player.play()
    }
    
    
    
    public func play() {
        
        Player.play()
    }
    
    public func stop() {
        
        Player.pause()
        Player.seek(to: kCMTimeZero)
    }
    
    public func pause() {
        
        Player.pause()
    }
    
    public func talkHasCompleted() {
        
        print("Talk has completed")
        Delegate.talkHasCompleted()     // inform our owner that a talk is done
    }
    
    public func seekToTime(seconds: Int64) {
        
        Player.seek(to: CMTimeMake(seconds, 1))
    }
    
    public func seekFastForward() {
        
        if let ct = PlayerItem?.currentTime(), let dt = Player.currentItem?.asset.duration {
            let currentTimeInSeconds = Int64(CMTimeGetSeconds(ct))
            let durationTimeInSeconds = Int64(CMTimeGetSeconds(dt))
            
            if currentTimeInSeconds + FAST_SEEK < durationTimeInSeconds {
                Player.seek(to: CMTimeMake(currentTimeInSeconds + FAST_SEEK, 1))

            } else {
                Player.seek(to: CMTimeMake(durationTimeInSeconds, 1))
            }
        }
    }
    
    public func seekFastBackward() {
        
        if let ct = PlayerItem?.currentTime() {
            let currentTimeInSeconds = Int64(CMTimeGetSeconds(ct))
            
            if currentTimeInSeconds - FAST_SEEK > Int64(0) {
                Player.seek(to: CMTimeMake(currentTimeInSeconds - FAST_SEEK, 1))
                
            } else {
                Player.seek(to: CMTimeMake(0, 1))
            }
        }
    }
    
    public func currentTime()-> CMTime {
        
        return Player.currentTime()
    }
    
    public func nextTalk(talkFinishedPlaying:Bool) {
        
    }
    
    public func convertSecondsToDisplayString(timeInSeconds: Int) -> String {
        
        let seconds = Int(timeInSeconds) % 60
        let minutes = (Int(timeInSeconds) / 60) % 60
        let hours = (Int(timeInSeconds) / 3600) % 3600


        return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
    }

    
    public func getCurrentTimeInSeconds() -> Int {
        
        var time : Int = 0

        if let ct = PlayerItem?.currentTime()  {
            time = Int(CMTimeGetSeconds(ct))
        }
        return time
    }
    
    public func getDurationInSeconds() -> Int {
        
        var time : Int = 0
        
        if let ct = PlayerItem?.duration {
            time = Int(CMTimeGetSeconds(ct))
            
        }
        return time
    }

    public func getProgress()->Float {
        
        var theCurrentTime = 0.0
        var theCurrentDuration = 0.0
        
        let currentTime = CMTimeGetSeconds(Player.currentTime())
        
        if let ct = Player.currentItem?.asset.duration {
            let duration = CMTimeGetSeconds(ct)
            theCurrentTime = currentTime
            theCurrentDuration = duration
        }
        
        return Float(theCurrentTime / theCurrentDuration)
    }
   
    public func setVolume(volume:Float){
        
        Player.volume = volume
    }
    
}
