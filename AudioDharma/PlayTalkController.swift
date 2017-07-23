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
    @IBOutlet weak var talkFastBackward: UIButton!
    @IBOutlet weak var talkFastForward: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var activityTalkLoadingLabel: UILabel!
    @IBOutlet weak var playTalkSeriesButton: UIButton!
    
    // MARK: Properties
    var TalkList : [TalkData]!
    var CurrentTalkRow : Int!
    var OriginalTalkRow : Int!
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

        setTalkStartDisplay()
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    public func setTalkStartDisplay () {
        
        activityIndicatorView.isHidden = true
        activityTalkLoadingLabel.isHidden = true
        talkFastForward.isEnabled = false
        talkFastBackward.isEnabled = false
        
        talkDuration.text = CurrentTalk.duration
        talkTitle.text = CurrentTalk.title
        metaInfo.text = CurrentTalk.speaker + "   " + CurrentTalk.date
        
        talkTime.text = MP3TalkPlayer.getCurrentTimeAsString()
    }
    
    public func playNextTalk() {
        
        print("Play Next Talk")
        MP3TalkPlayer = MP3Player()
        MP3TalkPlayer.Delegate = self
        
        TalkTimer?.invalidate()
        TalkTimer = nil

        CurrentTalkRow = CurrentTalkRow + 1
        if CurrentTalkRow > TalkList.count {
            CurrentTalkRow = 0
        }
        CurrentTalk = TalkList[CurrentTalkRow]
        
        if (CurrentTalkRow == OriginalTalkRow) {
            // we've wrapped around and completed the talk list
            //TBD
            return
        }

        setTalkStartDisplay()
        talkPlayBack.setImage(UIImage(named: "blacksquare"), for: UIControlState.normal)
        
        activityIndicatorView.isHidden = false
        activityTalkLoadingLabel.isHidden = false
        activityIndicatorView.startAnimating()
        
        MP3TalkPlayer.startTalk(talk: CurrentTalk)
        startTalkTimer()
    }

    
  
    // MARK: Actions
   @IBAction func talkFastBackward(_ sender: UIButton) {
        
        self.MP3TalkPlayer.seekFastBackward()
    }

    @IBAction func talkFastForward(_ sender: UIButton) {
        
        self.MP3TalkPlayer.seekFastForward()
    }
    
    @IBAction func toggleTalkPlay(_ sender: Any) {
    
        talkPlayBack.isSelected = false

        if TalkIsPlaying == true {  // pause the talk
            TalkIsPlaying = false
            
            talkPlayBack.setImage(UIImage(named: "tri_right"), for: UIControlState.normal)
            
            TalkTimer?.invalidate()
            TalkTimer = nil
        
            talkFastForward.isEnabled = false
            talkFastBackward.isEnabled = false
            
            MP3TalkPlayer.pause()

            
        } else {    // start or restart (after a previous pause) the talk
            TalkIsPlaying = true
            
            talkPlayBack.setImage(UIImage(named: "blacksquare"), for: UIControlState.normal)
            
            talkFastForward.isEnabled = true
            talkFastBackward.isEnabled = true

            // if talk hasn't begun yet (we're at the start), then show the "loading talks" and busy icon until talk is fully loaded.
            // otherwise (we're not at the start), just un-pause the talk
            let talkTime = MP3TalkPlayer.currentTime()
            if talkTime.value == 0 {
                activityIndicatorView.isHidden = false
                activityTalkLoadingLabel.isHidden = false
                activityIndicatorView.startAnimating()
                
                MP3TalkPlayer.startTalk(talk: CurrentTalk)
                startTalkTimer()
            }
            else {
                MP3TalkPlayer.play()
                startTalkTimer()
            }
        }
    }
    
    @IBAction func stopTalk(_ sender: UIBarButtonItem) {
        
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
            
         } else {
            PlayEntireList = true
            playTalkSeriesButton.setImage(UIImage(named: "blackcheckmark"), for: UIControlState.normal)
        }
    }

    @IBAction func setVolume(_ sender: UISlider) {
        MP3TalkPlayer.setVolume(volume: sender.value)
    }
    
    
    // MARK: Private functions
    private func startTalkTimer(){
        
        if let timer = TalkTimer {
            timer.invalidate()
            TalkTimer = nil
        }
        TalkTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlayTalkController.updateViewsWithTimer), userInfo: nil, repeats: true)
    }
    
    @objc private func updateViewsWithTimer(){
        
        // if talk is  underway, then  stop the busy notifier and activate forward and backward buttons
        if MP3TalkPlayer.getCurrentTimeAsSeconds() > 0 {
            activityIndicatorView.stopAnimating()
            activityIndicatorView.isHidden = true
            activityTalkLoadingLabel.isHidden = true
            
            talkFastForward.isEnabled = true
            talkFastBackward.isEnabled = true

        }
        talkTime.text = MP3TalkPlayer.getCurrentTimeAsString()
    }
    
    // called when we get a notification from mp3Player that the current talk is done
    public func talkHasCompleted () {
        
        Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(PlayTalkController.playNextTalk), userInfo: nil, repeats: false)

        print("TALK COMPLETED!")
    }
    
    

}

