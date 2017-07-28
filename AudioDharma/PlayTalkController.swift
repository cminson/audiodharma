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
    @IBOutlet weak var talkTime: UILabel!
    @IBOutlet weak var talkDuration: UILabel!
    @IBOutlet weak var metaInfo: UILabel!
    @IBOutlet weak var talkPlayBack: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var activityTalkLoadingLabel: UILabel!
    @IBOutlet weak var playTalkSeriesButton: UIButton!
    @IBOutlet weak var talkProgressSlider: UISlider!
    @IBOutlet weak var talkFastBackward: UIButton!
    @IBOutlet weak var talkFastForward: UIButton!
    @IBOutlet weak var MPVolumeParentView: UIView!
    @IBOutlet weak var playPauseBusyContainer: UIView!
    @IBOutlet weak var talkPlayPauseButton: UIBarButtonItem!
    
    
    // MARK: Properties
    var TalkList : [TalkData]!
    var CurrentTalkRow : Int = 0
    var OriginalTalkRow : Int = 0
    var CurrentTalk : TalkData!

    var TalkTimer : Timer?
    var MP3TalkPlayer : MP3Player!
    var TalkIsPlaying: Bool = false
    var PlayEntireList: Bool = false
    

    // Mark: Init
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        MP3TalkPlayer = MP3Player()
        MP3TalkPlayer.Delegate = self
        OriginalTalkRow = CurrentTalkRow
        CurrentTalk = TalkList[CurrentTalkRow]

        resetTalkDisplay()
 
        MPVolumeParentView.backgroundColor = UIColor.clear
        let volumeView = MPVolumeView(frame: MPVolumeParentView.bounds)
        volumeView.showsRouteButton = true
        volumeView.sizeToFit()
        MPVolumeParentView.addSubview(volumeView)
        
        self.title = "1/1"
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

    
    // MARK: Actions
    @IBAction func talkProgressSliderChanged(_ sender: UISlider) {
        
        let fractionTimeCompleted = talkProgressSlider.value
        let durationInSeconds = MP3TalkPlayer.getDurationInSeconds()
        
        let currentTime = Int64(Float(durationInSeconds) * fractionTimeCompleted)
        MP3TalkPlayer.seekToTime(seconds: currentTime)
    }
    
    @IBAction func playOrPauseTalk(_ sender: UIBarButtonItem) {
        talkPlayBack.isSelected = false
        
        if TalkIsPlaying == true {  // pause the talk
            TalkIsPlaying = false
            
            talkPlayBack.setImage(UIImage(named: "tri_right"), for: UIControlState.normal)
            
            TalkTimer?.invalidate()
            TalkTimer = nil
            
            disableScanButtons()
            
            MP3TalkPlayer.pause()
        
            
        } else {    // start or restart (after a previous pause) the talk
            TalkIsPlaying = true
            
            enableActivityIcons()
            
            talkPlayBack.setImage(UIImage(named: "blacksquare"), for: UIControlState.normal)
            
            // if talk hasn't begun yet (we're at the start), then show the "loading talks" and busy icon until talk is fully loaded.
            // otherwise (we're not at the start), just un-pause the talk
            let talkTime = MP3TalkPlayer.currentTime()
            if talkTime.value == 0 {
                MP3TalkPlayer.startTalk(talk: CurrentTalk)
                startTalkTimer()
            }
            else {
                MP3TalkPlayer.play()
                startTalkTimer()
            }
        }
    }
    
    @IBAction func shareTalk(_ sender: UIBarButtonItem) {
        
        self.shareCurrentTalk()
    }

    @IBAction func stopTalk(_ sender: UIBarButtonItem) {
        
        print("StopTalk")
        if TalkIsPlaying == true {
            MP3TalkPlayer.stop()
            //talkTime.text = MP3TalkPlayer.getCurrentTimeAsString()
            TalkTimer?.invalidate()
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func togglePlayTalkSeries(_ sender: UIButton) {
        
        if PlayEntireList == true {
            PlayEntireList = false
            playTalkSeriesButton.setImage(UIImage(named: "checkboxoff"), for: UIControlState.normal)
            self.title = "Playing 1/1"
            
        } else {
            PlayEntireList = true
            playTalkSeriesButton.setImage(UIImage(named: "blackcheckmark"), for: UIControlState.normal)
            self.title = "Playing \(CurrentTalkRow+1)/\(TalkList.count)"

        }
    }
    
    @IBAction func setVolume(_ sender: UISlider) {
        MP3TalkPlayer.setVolume(volume: sender.value)
    }
    
 
    // MARK: Public
    public func resetTalkDisplay () {
        
        disableActivityIcons()
        disableScanButtons()
        
        TalkIsPlaying = false
        talkProgressSlider.value = 0.0
        
        talkTitle.text = CurrentTalk.title
        metaInfo.text = CurrentTalk.speaker + "   " + CurrentTalk.date
        
        talkPlayBack.setImage(UIImage(named: "tri_right"), for: UIControlState.normal)
        
        let time = MP3TalkPlayer.getCurrentTimeInSeconds()
        talkTime.text = MP3TalkPlayer.convertSecondsToDisplayString(timeInSeconds: time)
     }
    
    public func playNextTalk() {
        
        CurrentTalkRow = CurrentTalkRow + 1
        if CurrentTalkRow >= TalkList.count {
            CurrentTalkRow = 0
        }
        CurrentTalk = TalkList[CurrentTalkRow]
        
        if (CurrentTalkRow == OriginalTalkRow) {
            // we've wrapped around and completed the talk list
            // stop the timer
            stopTalkTimer()
            return
        }

        resetTalkDisplay()
        talkPlayBack.setImage(UIImage(named: "blacksquare"), for: UIControlState.normal)
        
        enableActivityIcons()
        MP3TalkPlayer.startTalk(talk: CurrentTalk)
        startTalkTimer()
        
        self.title = "Playing \(CurrentTalkRow)/\(TalkList.count)"
    }

    // called when we get a notification from mp3Player that the current talk is done
    public func talkHasCompleted () {
        
        MP3TalkPlayer = MP3Player()
        MP3TalkPlayer.Delegate = self

        // if option is enabled, play the next talk in the current series
        if PlayEntireList == true {
            Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(PlayTalkController.playNextTalk), userInfo: nil, repeats: false)
        } else {    // otherwise reset the display and keep the current tak
            stopTalkTimer()
            resetTalkDisplay()
        }
    }
    
  
    // MARK: Actions
    @IBAction func talkFastBackwards(_ sender: UIButton) {
        self.MP3TalkPlayer.seekFastBackward()
    }
    
    @IBAction func talkFastForwards(_ sender: UIButton) {
        self.MP3TalkPlayer.seekFastForward()
    }
    
    
    @IBAction func toggleTalkPlay(_ sender: Any) {
    
        talkPlayBack.isSelected = false

        if TalkIsPlaying == true {  // pause the talk
            TalkIsPlaying = false
            
            talkPlayBack.setImage(UIImage(named: "tri_right"), for: UIControlState.normal)
            
            TalkTimer?.invalidate()
            TalkTimer = nil
        
            disableScanButtons()
            
            MP3TalkPlayer.pause()

            
        } else {    // start or restart (after a previous pause) the talk
            TalkIsPlaying = true
            
            enableActivityIcons()

            talkPlayBack.setImage(UIImage(named: "blacksquare"), for: UIControlState.normal)
            
            // if talk hasn't begun yet (we're at the start), then show the "loading talks" and busy icon until talk is fully loaded.
            // otherwise (we're not at the start), just un-pause the talk
            let talkTime = MP3TalkPlayer.currentTime()
            if talkTime.value == 0 {
                MP3TalkPlayer.startTalk(talk: CurrentTalk)
                startTalkTimer()
            }
            else {
                MP3TalkPlayer.play()
                startTalkTimer()
            }
        }
    }
    
    
    // MARK: Private functions
    private func startTalkTimer(){
        
        // stop  previous timer, if any
        stopTalkTimer()
        
        // start a new timer
        TalkTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlayTalkController.updateViewsWithTimer), userInfo: nil, repeats: true)
    }
    
    private func stopTalkTimer(){
        
        if let timer = TalkTimer {
            timer.invalidate()
            TalkTimer = nil
        }
    }
    
    // called every second to update views
    @objc private func updateViewsWithTimer(){
        
        // if talk is  underway, then stop the busy notifier and activate the display (buttons, durations etc)
        if MP3TalkPlayer.getCurrentTimeInSeconds() > 0 {
            disableActivityIcons()
            enableScanButtons()
         
            // show current talk time and actual talk duration (which may be different from the what is claimed in the config)
            let currentTime = MP3TalkPlayer.getCurrentTimeInSeconds()
            let duration = MP3TalkPlayer.getDurationInSeconds()
        
            talkTime.text = MP3TalkPlayer.convertSecondsToDisplayString(timeInSeconds: currentTime)
            talkDuration.text = MP3TalkPlayer.convertSecondsToDisplayString(timeInSeconds: duration)
        

            let fractionTimeCompleted = Float(currentTime) / Float(duration)
            talkProgressSlider.value = fractionTimeCompleted
        }
    }
    
    private func enableActivityIcons() {
        
        talkPlayBack.isHidden = true
        activityIndicatorView.isHidden = false
        activityTalkLoadingLabel.isHidden = false
        activityIndicatorView.startAnimating()
    }
    
    private func disableActivityIcons() {
        
        talkPlayBack.isHidden = false
        activityIndicatorView.isHidden = true
        activityTalkLoadingLabel.isHidden = true
        activityIndicatorView.stopAnimating()
    }
    
    private func enableScanButtons() {
        
        talkFastForward.isEnabled = true
        talkFastBackward.isEnabled = true
        talkProgressSlider.isEnabled = true
    }
    
    private func disableScanButtons() {
        
        talkFastForward.isEnabled = false
        talkFastBackward.isEnabled = false
        talkProgressSlider.isEnabled = false
    }

    private func shareCurrentTalk() {
        
        let sharedTalk = CurrentTalk!
        TheDataModel.shareTalk(sharedTalk: sharedTalk, controller: self)
    }
    
}

