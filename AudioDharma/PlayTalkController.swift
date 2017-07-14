//
//  PlayTalkController.swift
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
class PlayTalkController: UIViewController {
    
    static let TopColor = UIColor(red:1.00, green:0.55, blue:0.00, alpha:1.0)
    
    // MARK: Outlets
    @IBOutlet weak var talkTitle: UILabel!
    @IBOutlet weak var speakerPhoto: UIImageView!
    @IBOutlet weak var talkTime: UILabel!
    @IBOutlet weak var talkDuration: UILabel!
    @IBOutlet weak var talkPlayBackButton: UIButton!
    @IBOutlet weak var metaInfo: UILabel!
    
    @IBAction func TestAction1(_ sender: UIBarButtonItem) {
    }

    // MARK: Properties
    var talk: TalkData!
    var timer:Timer!
    var mp3Player : MP3Player = MP3Player()
    var talkIsPlaying: Bool = false
    
    
    // Mark: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotificationCenter()
        setTrackName()
        updateViews()
        
        //let backgroundColor =  UIColor(red:0.24, green:0.24, blue:0.24, alpha:1.0)
        //self.view.backgroundColor = backgroundColor
        
        speakerPhoto.image = UIImage(named: (talk?.speaker)!) ?? UIImage(named: "defaultPhoto")!
        speakerPhoto.contentMode = UIViewContentMode.scaleAspectFit

        talkDuration.text = talk.duration
        talkTitle.text = talk.title
        metaInfo.text = talk.speaker + "   " + talk.date
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: Actions
    @IBAction func toggleTalkPlay(_ sender: Any) {
    
        if talkIsPlaying == true {
            talkIsPlaying = false
            talkPlayBackButton.setImage(UIImage(named: "audioButtonStart"), for: UIControlState.normal)
            
            self.mp3Player.pause()
            self.updateViews()
            self.timer.invalidate()
        
        } else {
            talkIsPlaying = true
            talkPlayBackButton.setImage(UIImage(named: "audioButtonPause"), for: UIControlState.normal)
            
            let talkTime = mp3Player.currentTime()
            if talkTime.value == 0 {
                mp3Player.startTalk(talk: talk)
                startTimer()
            }
            else {
                mp3Player.play()
                startTimer()
            }
    
        }
    }
    
    @IBAction func stopTalk(_ sender: UIBarButtonItem) {
        
        if talkIsPlaying == true {
            mp3Player.stop()
            updateViews()
            timer?.invalidate()
        }
        dismiss(animated: true, completion: nil)
    }

    @IBAction func setVolume(_ sender: UISlider) {
        mp3Player.setVolume(volume: sender.value)
    }
    
    
    // MARK: Private functions
    private func startTimer(){
        
        //x = Timer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateViewsWithTimer:"), userInfo: nil, repeats: true)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlayTalkController.updateViewsWithTimer), userInfo: nil, repeats: true)
    }
    
    @objc private func updateViewsWithTimer(){
        updateViews()
    }
    
    private func updateViews(){

        talkTime.text = mp3Player.getCurrentTimeAsString()
        /*
        let progress = mp3Player.getProgress()
        progressBar.progress = progress
 */
    }
    
    func setTrackName(){
        /*
        trackName.text = mp3Player?.getCurrentTrackName()
 */
    }
    
    func setupNotificationCenter(){
        let notificationName = Notification.Name("SetTrackNameText")
        NotificationCenter.default.addObserver(self, selector:#selector(PlayTalkController.setTrackName), name: notificationName, object:nil)
    }

   

}

