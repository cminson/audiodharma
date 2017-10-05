//
//  PlayTalkController.swift
//  AudioDharma
//
//  Created by Christopher on 6/14/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//


import UIKit
import AVKit
import AVFoundation
import MediaPlayer


class PlayTalkController: UIViewController {
    
    static let TopColor = UIColor(red:1.00, green:0.55, blue:0.00, alpha:1.0)
    
    // MARK: Outlets
    @IBOutlet weak var talkTitle: UILabel!
    @IBOutlet weak var talkDuration: UILabel!
    @IBOutlet weak var metaInfo: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var playTalkSeriesButton: UIButton!
    @IBOutlet weak var talkProgressSlider: UISlider!
    @IBOutlet weak var talkFastBackward: UIButton!
    @IBOutlet weak var talkFastForward: UIButton!
    @IBOutlet weak var playPauseBusyContainer: UIView!
    @IBOutlet weak var talkPlayPauseButton: UIButton!
    @IBOutlet weak var MPVolumeParentView: UIView!

    @IBOutlet var buttonHelp: UIBarButtonItem!
    @IBOutlet var buttonDonate: UIBarButtonItem!
    @IBOutlet var buttonShare: UIBarButtonItem!
    @IBOutlet var buttonFavorite: UIBarButtonItem!
    
    // MARK: Constants
    
    enum TalkStates {                   // all possible states of the talk player
        case INITIAL
        case LOADING
        case PLAYING
        case PAUSED
        case STOPPED
        case FINISHED
        case ALBUMFINISHED
    }
    
    // MARK: Properties
    var TalkPlayerStatus: TalkStates = TalkStates.INITIAL
    var CurrentTalkRow : Int = 0
    var OriginalTalkRow : Int = 0
    var PlayEntireAlbum: Bool = false
    var HaveReportedTalk: Bool = false
    
    var TalkList : [TalkData]!
    var CurrentTalk : TalkData!
    var TalkTimer : Timer?
    var MP3TalkPlayer : MP3Player!

    
    // Mark: Init
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        MP3TalkPlayer = MP3Player()
        MP3TalkPlayer.Delegate = self
        OriginalTalkRow = CurrentTalkRow
        CurrentTalk = TalkList[CurrentTalkRow]

        resetTalkDisplay()
 
        MPVolumeParentView.backgroundColor = UIColor.clear
        //MPVolumeParentView.backgroundColor = UIColor.green

        let volumeView = MPVolumeView(frame: MPVolumeParentView.bounds)
        volumeView.showsRouteButton = true
        
        let iconBlack = UIImage(named: "routebuttonblack")
        let iconGreen = UIImage(named: "routebuttongreen")
        
        volumeView.setRouteButtonImage(iconBlack, for: UIControlState.normal)
        volumeView.setRouteButtonImage(iconBlack, for: UIControlState.disabled)
        volumeView.setRouteButtonImage(iconGreen, for: UIControlState.highlighted)
        volumeView.setRouteButtonImage(iconGreen, for: UIControlState.selected)
        
        //volumeView.backgroundColor = UIColor.gray
        //volumeView.sizeToFit()
        
        let point = CGPoint(x: MPVolumeParentView.frame.size.width  / 2,y : (MPVolumeParentView.frame.size.height / 2) + 5)
        volumeView.center = point
        MPVolumeParentView.addSubview(volumeView)
        
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.toolbar.barStyle = UIBarStyle.blackOpaque
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([buttonHelp, flexibleItem, buttonFavorite, flexibleItem, buttonShare, flexibleItem, buttonDonate], animated: false)

    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "DISPLAY_HELP_PAGE":
            guard let navController = segue.destination as? UINavigationController, let controller = navController.viewControllers.last as? HelpController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            // display different help text depending on the kind of content we're showing.
            controller.setHelpPage(helpPage: KEY_PLAY_TALK)
            
        case "DISPLAY_DONATIONS":
            guard let _ = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier ?? "NONE")")
        }
    }

    
    // MARK: Actions
    @IBAction func toggleFavorite(_ sender: UIBarButtonItem) {
        
        TheDataModel.toggleTalkAsFavorite(talk: CurrentTalk, controller: self)

    }
    
    @IBAction func talkProgressSliderChanged(_ sender: UISlider) {
        
        let fractionTimeCompleted = talkProgressSlider.value
        let durationInSeconds = MP3TalkPlayer.getDurationInSeconds()
        
        let currentTime = Int64(Float(durationInSeconds) * fractionTimeCompleted)
        MP3TalkPlayer.seekToTime(seconds: currentTime)
    }
    
    @IBAction func talkFastBackwards(_ sender: UIButton) {
        MP3TalkPlayer.seekFastBackward()
    }
    
    @IBAction func talkFastForwards(_ sender: UIButton) {
        MP3TalkPlayer.seekFastForward()
        
        if MP3TalkPlayer.getCurrentTimeInSeconds() >= MP3TalkPlayer.getDurationInSeconds() {
            talkHasCompleted()
        }
    }
    
    @IBAction func togglePlayTalkSeries(_ sender: UIButton) {
        
        // this toggles whether we play just the current talk vs current talk + all talks in its album
        if PlayEntireAlbum == true {
            PlayEntireAlbum = false
            playTalkSeriesButton.setImage(UIImage(named: "checkboxoff"), for: UIControlState.normal)
            
        } else {
            PlayEntireAlbum = true
            playTalkSeriesButton.setImage(UIImage(named: "blackcheckmark"), for: UIControlState.normal)
        }
    }
    
    @IBAction func stopTalk(_ sender: UIBarButtonItem) {
        
        TalkPlayerStatus = .STOPPED

        stopTalks()
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func shareTalk(_ sender: UIBarButtonItem) {
        
        let sharedTalk = CurrentTalk!
        TheDataModel.shareTalk(sharedTalk: sharedTalk, controller: self)

    }
    

    @IBAction func playOrPauseTalk(_ sender: UIButton) {
        
        talkPlayPauseButton.isSelected = false
        
        switch TalkPlayerStatus {
        case .INITIAL, .STOPPED, .FINISHED, .ALBUMFINISHED:
 
            startTalk()
        case .PAUSED:
            restartTalk()
        case .PLAYING:
            pauseTalk()
        default:
            fatalError("Unknown TalkPlayerStatus")
        }
    }
    
    // MARK: Functions
    func startTalk() {
        
        if TheDataModel.isInternetAvailable() == true
        {
            HaveReportedTalk = false
            TalkPlayerStatus = .LOADING
        
            talkPlayPauseButton.setImage(UIImage(named: "blacksquare"), for: UIControlState.normal)
            enableActivityIcons()
            
            MP3TalkPlayer.startTalk(talk: CurrentTalk)
            startTalkTimer()
        
            updateTitleDisplay()
        
        } else {
            let alert = UIAlertController(title: "Can Not Connect to AudioDharma Talks Server", message: "Please check your internet connection or try again in a few minutes", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    func restartTalk() {
        
        TalkPlayerStatus = .LOADING
        
        talkPlayPauseButton.setImage(UIImage(named: "blacksquare"), for: UIControlState.normal)
        enableActivityIcons()
        
        MP3TalkPlayer.play()
        startTalkTimer()
        
        updateTitleDisplay()
    }

    func pauseTalk() {
        
        TalkPlayerStatus = .PAUSED
        
        talkPlayPauseButton.setImage(UIImage(named: "tri_right"), for: UIControlState.normal)
        disableScanButtons()
        
        stopTalkTimer()
        MP3TalkPlayer.pause()
        
        updateTitleDisplay()
    }
    
    func stopTalks() {
        
        HaveReportedTalk = false

        MP3TalkPlayer.stop()
        stopTalkTimer()
        
        updateTitleDisplay()
    }
    
    func resetTalkDisplay () {
        
        stopTalkTimer()
        
        disableActivityIcons()
        disableScanButtons()
        
        HaveReportedTalk = false
        talkProgressSlider.value = 0.0

        talkTitle.text = CurrentTalk.Title
        metaInfo.text = CurrentTalk.Speaker + "   " + CurrentTalk.Date
        
        talkPlayPauseButton.setImage(UIImage(named: "tri_right"), for: UIControlState.normal)
        
        updateTitleDisplay()
     }
    
    @objc func playNextTalk() {
        
        CurrentTalkRow = CurrentTalkRow + 1
        if CurrentTalkRow >= TalkList.count {
            CurrentTalkRow = 0
        }
        CurrentTalk = TalkList[CurrentTalkRow]
        
        if (CurrentTalkRow == OriginalTalkRow) {
            
            // we've wrapped around and completed the talk list
            // stop the talk
            TalkPlayerStatus = .ALBUMFINISHED
            stopTalks()
            return
        }

        resetTalkDisplay()
        startTalk()
    }

    // called when we get a notification from mp3Player that the current talk is done
    func talkHasCompleted () {
        
        TalkPlayerStatus = .FINISHED
        
        MP3TalkPlayer.stop()
        resetTalkDisplay()

        // if option is enabled, play the next talk in the current series
        if PlayEntireAlbum == true {
            
            // create a new MP3 player.  just to ensure state is fully cleared
            MP3TalkPlayer = MP3Player()
            MP3TalkPlayer.Delegate = self

            // and then play next talk in SECONDS_TO_NEXT_TALK seconds
            Timer.scheduledTimer(timeInterval: SECONDS_TO_NEXT_TALK, target: self, selector: #selector(PlayTalkController.playNextTalk), userInfo: nil, repeats: false)
        }
        updateTitleDisplay()
    }
    
    func updateTitleDisplay() {
        
        let currentTalkIndex = CurrentTalkRow + 1
        
        switch TalkPlayerStatus {
            
        case .LOADING:
            if PlayEntireAlbum == true {
                
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                let formattedTalkIndex = numberFormatter.string(from: NSNumber(value: currentTalkIndex)) ?? ""
                let formattedTalkCount = numberFormatter.string(from: NSNumber(value: TalkList.count)) ?? ""

                self.title = "Loading Talk \(formattedTalkIndex)/\(formattedTalkCount)"
            }
            else {
                self.title = "Loading Talk"
            }
        case .PLAYING:
            let currentTime = MP3TalkPlayer.getCurrentTimeInSeconds()
            let displayTime = MP3TalkPlayer.convertSecondsToDisplayString(timeInSeconds: currentTime)
            
            if PlayEntireAlbum == true {
                
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                let formattedTalkIndex = numberFormatter.string(from: NSNumber(value: currentTalkIndex)) ?? ""
                let formattedTalkCount = numberFormatter.string(from: NSNumber(value: TalkList.count)) ?? ""
                
                self.title = "Playing \(formattedTalkIndex)/\(formattedTalkCount)  \(displayTime)"
            }
            else {
                
                self.title = "Playing   \(displayTime)"
            }
        case .PAUSED:
            let currentTime = MP3TalkPlayer.getCurrentTimeInSeconds()
            let displayTime = MP3TalkPlayer.convertSecondsToDisplayString(timeInSeconds: currentTime)
            
            if PlayEntireAlbum == true {
                
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                let formattedTalkIndex = numberFormatter.string(from: NSNumber(value: currentTalkIndex)) ?? ""
                let formattedTalkCount = numberFormatter.string(from: NSNumber(value: TalkList.count)) ?? ""
              
                self.title = "Paused \(formattedTalkIndex)/\(formattedTalkCount)  \(displayTime)"
            }
            else {
                self.title = "Paused \(displayTime)"
            }
        case .STOPPED:
            self.title = "Stopped"
        case .FINISHED:
            self.title = "Talk Finished"
        case .ALBUMFINISHED:
            self.title = "Album Finished"
        default:
            self.title = ""
        }
    }

    func startTalkTimer() {
        
        // stop  previous timer, if any
        stopTalkTimer()
        
        // start a new timer.  this calls a method to update the views once each second
        TalkTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlayTalkController.updateViewsWithTimer), userInfo: nil, repeats: true)

    }
    
    func stopTalkTimer(){
        
        if let timer = TalkTimer {
            
            timer.invalidate()
            TalkTimer = nil
        }
    }
    
    // called every second to update views
    @objc func updateViewsWithTimer(){
        
        // if talk is  underway, then stop the busy notifier and activate the display (buttons, durations etc)
        let currentPlayTime = MP3TalkPlayer.getCurrentTimeInSeconds()
        if currentPlayTime > 0 {
            

            TalkPlayerStatus = .PLAYING
            
            disableActivityIcons()
            enableScanButtons()
         
            // show current talk time and actual talk duration 
            // note these may be different from what is stated in the (often inaccurate) config!
            let currentTime = MP3TalkPlayer.getCurrentTimeInSeconds()
            let duration = MP3TalkPlayer.getDurationInSeconds()
        
            talkDuration.text = MP3TalkPlayer.convertSecondsToDisplayString(timeInSeconds: duration)
        
            let fractionTimeCompleted = Float(currentTime) / Float(duration)
            talkProgressSlider.value = fractionTimeCompleted
            
            updateTitleDisplay()
            
            // if play time exceeds reporting threshold, record and report that this talk was played
            if currentPlayTime > REPORT_TALK_THRESHOLD, HaveReportedTalk != true {
                
                HaveReportedTalk = true
                print("Reporting Play")
                TheDataModel.addToTalkHistory(talk: CurrentTalk)
                TheDataModel.reportTalkActivity(type: ACTIVITIES.PLAY_TALK, talk: CurrentTalk)
            }
            
        }
    } 
    private func enableActivityIcons() {
        
        talkPlayPauseButton.isHidden = true
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
    }
    
    private func disableActivityIcons() {
        
        talkPlayPauseButton.isHidden = false
        activityIndicatorView.isHidden = true
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
    
}

