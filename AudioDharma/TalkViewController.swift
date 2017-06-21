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

class TalkViewController: UIViewController {
    
    static let TopColor = UIColor(red:1.00, green:0.55, blue:0.00, alpha:1.0)
    
    // Mark: Outlets
    @IBOutlet weak var talkTitle: UILabel!
       
    
    
    var player:AVPlayer?
    var playerItem:AVPlayerItem?
    var playButton:UIButton?
    
    
    //MARK: Properties
    var talk: TalkData?
    
    
    // Mark: Actions
    @IBAction func testAudio1(_ sender: Any) {
        
        print("test audio 1")
        
        
        //initAudioControl2()
        initAudioControl1()

  
        
    }
    
    @IBAction func testJSONLoad(_ sender: Any) {
        
        let jsonLocation = "http://www.ezimba.com/ad/test01.json"
        let requestURL : URL? = URL(string: jsonLocation)
        let urlRequest = URLRequest(url : requestURL!)
        let session = URLSession.shared
        
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("Everyone is fine, file downloaded successfully.")
            }
        
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
        
            do {
                guard let todo = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject] else {
                        print("error trying to convert data to JSON")
                    return
                    }
                
                
                // now we have the todo, let's just print it to prove we can access it
                print("The todo is: " + todo.description)
            
                // the todo object is a dictionary
                // so we just access the title using the "title" key
                // so check for a title and print it if we have one
                guard let todoTitle = todo["title"] as? String else {
                    print("Could not get todo title from JSON")
                    return
                }
                print("The title is: " + todoTitle)
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
        
        task.resume()

    }
    
   
    // MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load")
        
        let backgroundColor =  UIColor(red:0.24, green:0.24, blue:0.24, alpha:1.0)
        self.view.backgroundColor = backgroundColor
        
        talkTitle.text = talk?.title
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Mark: private
    
    private func initAudioControl1() {
        
        //let audioLocation = "https://storage.googleapis.com/audiodharma/2005-01-10_GilFronsdal_FourNobleTruths-1.mp3"
        
        let audioLocation = talk?.talkURL
        let audioURL : URL? = URL(string: audioLocation!)
        let player = AVPlayer(url: audioURL!)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        self.view.layer.addSublayer(playerLayer)
        
        player.play()
    }
    
    
   
    
    
    private func initAudioControl2() {
        
        print("initAudioControl2")
        
        //let audioLocation = "https://storage.googleapis.com/audiodharma/2005-01-10_GilFronsdal_FourNobleTruths-1.mp3"
        
        
        let url = URL(string: "http://audiodharma.org:/teacher/1/talk/7897/venue/IMC/20170616-Gil_Fronsdal-IMC-dpd_equanimity_guided_meditation_2.mp3")
        

         let audioLocation : String! = talk?.talkURL
         print(audioLocation)
         //let url = URL(string: audioLocation)

        
        let playerItem:AVPlayerItem = AVPlayerItem(url: url!)
        player = AVPlayer(playerItem: playerItem)
        
        let playerLayer=AVPlayerLayer(player: player!)
        playerLayer.frame=CGRect(x:0, y:0, width:10, height:50)
        self.view.layer.addSublayer(playerLayer)
        
        playButton = UIButton(type: UIButtonType.system) as UIButton
        let xPostion:CGFloat = 50
        let yPostion:CGFloat = 100
        let buttonWidth:CGFloat = 150
        let buttonHeight:CGFloat = 45
        
        playButton!.frame = CGRect(x:xPostion, y:yPostion, width:buttonWidth, height:buttonHeight)
        playButton!.backgroundColor = UIColor.lightGray
        playButton!.setTitle("Play", for: UIControlState.normal)
        playButton!.tintColor = UIColor.black
        //playButton!.addTarget(self, action: Selector("playButtonTapped:"), for: .touchUpInside)
        playButton!.addTarget(self, action: #selector(TalkViewController.playButtonTapped(_:)), for: .touchUpInside)
        
        self.view.addSubview(playButton!)
        
        // Add playback slider
        
        let playbackSlider = UISlider(frame:CGRect(x:10, y:300, width:300, height:20))
        playbackSlider.minimumValue = 0
        
        
        let duration : CMTime = playerItem.asset.duration
        let seconds : Float64 = CMTimeGetSeconds(duration)
        
        playbackSlider.maximumValue = Float(seconds)
        playbackSlider.isContinuous = true
        playbackSlider.tintColor = UIColor.green
        
        playbackSlider.addTarget(self, action: #selector(TalkViewController.playbackSliderValueChanged(_:)), for: .valueChanged)
        // playbackSlider.addTarget(self, action: "playbackSliderValueChanged:", forControlEvents: .ValueChanged)
        self.view.addSubview(playbackSlider)
        
        // add volume control here
        
        let wrapperView = CGRect(x:10, y:350, width:300, height:20)
        let volumeView = MPVolumeView(frame: wrapperView)
        self.view.addSubview(volumeView)
        
        
        
    }
    
    private func initAudioControl3() {
        
        print("initAudioControl3")
        
        //let audioLocation = "https://storage.googleapis.com/audiodharma/2005-01-10_GilFronsdal_FourNobleTruths-1.mp3"
        //let audioLocation = "http://www.audiodharma.org/teacher/1/talk/7897/venue/IMC/20170616-Gil_Fronsdal-IMC-dpd_equanimity_guided_meditation_2.mp3"
        
        let audioLocation = "http://www.audiodharma.org/teacher/1/talk/7929/venue/IMC/20170619-Gil_Fronsdal-IMC-juneteenth.mp3"
        
        //let audioLocation = "http://www.ezimba.com/ad/20170213-Teah_Strozer-IMC-dependent_co_arising.mp3"
        
        print(audioLocation)
        
        let url = URL(string: audioLocation)
        

        let playerItem:AVPlayerItem = AVPlayerItem(url: url!)
        player = AVPlayer(playerItem: playerItem)
        player!.play()
       
    }

    func playbackSliderValueChanged(_ playbackSlider:UISlider)
    {
        
        let seconds : Int64 = Int64(playbackSlider.value)
        let targetTime:CMTime = CMTimeMake(seconds, 1)
        
        player!.seek(to: targetTime)
        
        if player!.rate == 0
        {
            player?.play()
        }
    }
    
    
    func playButtonTapped(_ sender:UIButton)
    {
        if player?.rate == 0
        {
            player!.play()
            //playButton!.setImage(UIImage(named: "player_control_pause_50px.png"), forState: UIControlState.Normal)
            playButton!.setTitle("Pause", for: UIControlState.normal)
        } else {
            player!.pause()
            //playButton!.setImage(UIImage(named: "player_control_play_50px.png"), forState: UIControlState.Normal)
            playButton!.setTitle("Play", for: UIControlState.normal)
        }
    }
    
    func x()
    {
        
    }


}

