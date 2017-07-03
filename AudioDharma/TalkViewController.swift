//
//  TalkViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/14/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

/*
 
 AVAudioPlayer
 
 AVPlayerController
 
 -(void)sliderValueChanged:(UISlider *)slider
 {
 self.audioPlayer.volume = slider.value / 100.0;
 }
 */

import UIKit
import AVKit
import AVFoundation
import MediaPlayer

//  https://code.tutsplus.com/tutorials/build-an-mp3-player-with-av-foundation--cms-24482
class TalkViewController: UIViewController {
    
    
    static let TopColor = UIColor(red:1.00, green:0.55, blue:0.00, alpha:1.0)
    
    // Mark: Outlets
    @IBOutlet weak var talkTitle: UILabel!
    @IBOutlet weak var trackTime: UILabel!
    @IBOutlet weak var speakerImage: UIImageView!
    //@IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var talkDuration: UILabel!
    
    
    // Mark: Properties
    var talk: TalkData?
    var mp3Player : MP3Player = MP3Player()
    var timer:Timer?
    
    
    // Mark: Actions
    @IBAction func playTalk(_ sender: UIButton) {
        mp3Player.startTalk(talk: talk!)
        startTimer()

    }
    
    @IBAction func pauseTalk(_ sender: UIButton) {
        mp3Player.pause()
        timer?.invalidate()
    }
    
    @IBAction func setVolume(_ sender: UISlider) {
        mp3Player.setVolume(volume: sender.value)
    }
    
    @IBAction func stopTalk(_ sender: Any) {
        mp3Player.stop()
        updateViews()
        timer?.invalidate()
    }
    
    
    // Mark: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotificationCenter()
        setTrackName()
        updateViews()
        
        //let backgroundColor =  UIColor(red:0.24, green:0.24, blue:0.24, alpha:1.0)
        //self.view.backgroundColor = backgroundColor
        
        speakerImage.image = UIImage(named: (talk?.speaker)!) ?? UIImage(named: "defaultPhoto")!
        talkDuration.text = talk?.duration
        talkTitle.text = talk?.title
        print(talk?.title)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    func startTimer(){
        //x = Timer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateViewsWithTimer:"), userInfo: nil, repeats: true)
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: Selector("updateViewsWithTimer"), userInfo: nil, repeats: true)
        
        
    }
    
    func updateViewsWithTimer(){
        updateViews()
    }
    
    func updateViews(){

        trackTime.text = mp3Player.getCurrentTimeAsString()
        let progress = mp3Player.getProgress()
        //progressBar.progress = progress


    }
    
    func setTrackName(){
        /*
        trackName.text = mp3Player?.getCurrentTrackName()
 */
    }
    
    func setupNotificationCenter(){
        let notificationName = Notification.Name("SetTrackNameText")
        NotificationCenter.default.addObserver(self, selector:"setTrackName", name: notificationName, object:nil)
    }
    
   

}

