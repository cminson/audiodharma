//
//  TalkPlayer.swift
//  AudioDharma
//
//  Created by Christopher on 7/3/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//


import UIKit
import AVFoundation

class TalkPlayer: NSObject, AVAudioPlayerDelegate {
    
    var player : AVPlayer?
    var playerItem : AVPlayerItem?

    var currentTrackIndex = 0
    var tracks : [String] = [String]()
    
    override init(){
        super.init()
    }
    
    func startTalk(talk: TalkData){
        
        let audioLocation = talk.talkURL
        let audioURL : URL? = URL(string: audioLocation)
        let player = AVPlayer(url: audioURL!)
            
        //let playerLayer = AVPlayerLayer(player: player)
        //playerLayer.frame = self.view.bounds
        //self.view.layer.addSublayer(playerLayer)
            
        player.play()

        
        let notificationName = Notification.Name("SetTrackNameText")
        //NotificationCenter.defaultCenter.postNotificationName("SetTrackNameText", object: nil)
        NotificationCenter.default.post(name: notificationName, object: nil)
        
    }
    
    func play() {
        
    }
    
    func stop(){
    }
    
    func pause(){
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
    
    
    // Access Current Time
    //NSTimeInterval aCurrentTime = CMTimeGetSeconds(anAudioStreamer.currentTime);
    
    // Access Duration
    //NSTimeInterval aDuration = CMTimeGetSeconds(anAudioStreamer.currentItem.asset.duration);
    /*
    func getCurrentTimeAsString() -> String {
       
        var seconds = 0
        var minutes = 0
        if let time = player?.currentTime {
            seconds = Int(time) % 60
            minutes = (Int(time) / 60) % 60
        }
        return String(format: "%0.2d:%0.2d",minutes,seconds)
    }
 
    func getProgress()->Float{
        var theCurrentTime = 0.0
        var theCurrentDuration = 0.0
        if let currentTime = player?.currentTime, let duration = player?.currentItem.asset.duration {
            theCurrentTime = currentTime
            theCurrentDuration = duration
        }
        return Float(theCurrentTime / theCurrentDuration)
    }
 */

    
    func setVolume(volume:Float){
        player?.volume = volume
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool){
        if flag == true {
            nextTalk(talkFinishedPlaying: true)
        }
    }
    
}
