//
//  BaseController.swift
//  AudioDharma
//
//  Created by Christopher on 11/2/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class BaseController: UITableViewController {
    
    var ResumeTalk : TalkData!
    var ResumeTalkTime : Int = 0

    @IBOutlet var buttonHelp: UIBarButtonItem!
    @IBOutlet var buttonDonate: UIBarButtonItem!
    @IBOutlet var buttonBookmark: UIBarButtonItem!
    
    let SearchController = UISearchController(searchResultsController: nil)
    var SearchText = ""


    override func viewDidLoad() {
        super.viewDidLoad()
        
        SearchController.hidesNavigationBarDuringPresentation = false
        SearchController.dimsBackgroundDuringPresentation = false
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : MAIN_FONT_COLOR]
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.toolbar.barStyle = UIBarStyle.blackOpaque
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([buttonHelp, flexibleItem, buttonBookmark, flexibleItem, buttonDonate], animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func reloadModel() {
    }

    func executeDownload(talk: TalkData) {
        
        let spaceRequired = talk.DurationInSeconds * MP3_BYTES_PER_SECOND
        
        // if (freeSpace < Int64(500000000)) {
        if let freeSpace = TheDataModel.deviceRemainingFreeSpaceInBytes() {
            print("Freespace: ", freeSpace, spaceRequired)
            if (spaceRequired > freeSpace) {
                
                let alert = UIAlertController(title: "Insufficient Space To Download", message: "You don't have enough space in your device to download this talk", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.mypresent(alert)
                return
            }
        }
        
        TheDataModel.setTalkAsDownload(talk: talk)
        TheDataModel.downloadMP3(talk: talk)
    }
    
    func deleteDownloadedTalk(talk: TalkData) {
        
        TheDataModel.unsetTalkAsDownload(talk: talk)
    }
    
    func favoriteTalk(talk: TalkData) {
        
        TheDataModel.setTalkAsFavorite(talk: talk)
        
        DispatchQueue.main.async(execute: {
            self.reloadModel()
            self.tableView.reloadData()
            return
        })
        
        let alert = UIAlertController(title: "Favorite Talk - Added", message: "This talk has been added to your Favorites Album", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        self.mypresent(alert)
    }
    
    func unFavoriteTalk(talk: TalkData) {
        
        TheDataModel.unsetTalkAsFavorite(talk: talk)
        
        //SearchText = SearchController.searchBar.text!
        //SearchController.isActive = false
        print("Unfavorite: ", SearchText)
        
        DispatchQueue.main.async(execute: {
            self.reloadModel()
            self.tableView.reloadData()
            return
        })
        
        let alert = UIAlertController(title: "Favorite Talk - Removed", message: "This talk has been removed from your Favorites Album", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        self.mypresent(alert)
    }
    
    func shareTalk(talk: TalkData) {
        
        // save off search state and then turn off search. otherwise the modal will conflict with it
        SearchText = SearchController.searchBar.text!
        let searchState = SearchController.isActive
        SearchController.isActive = false
        
        let shareText = "\(talk.Title) by \(talk.Speaker) \nShared from the iPhone AudioDharma app"
        let objectsToShare: URL = URL(string: URL_MP3_HOST + talk.URL)!
        
        let sharedObjects:[AnyObject] = [objectsToShare as AnyObject, shareText as AnyObject]
        //let sharedObjects: [AnyObject] = [objectsToShare as AnyObject, bylineText as AnyObject]
        
        let activityViewController = UIActivityViewController(activityItems: sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        // if something was actually shared, report that activity to cloud
        activityViewController.completionWithItemsHandler = {
            (activity, completed, items, error) in
            
            // restore search state
            self.SearchController.isActive = searchState
            self.SearchController.searchBar.text = self.SearchText
            
            // if the share goes through, record it locally and also report this activity to our host service
            if completed == true {
                TheDataModel.addToShareHistory(talk: talk)
                TheDataModel.reportTalkActivity(type: ACTIVITIES.SHARE_TALK, talk: talk)
            }
        }
        mypresent(activityViewController)
        
    }
    
    func mypresent(_ viewControllerToPresent: UIViewController) {
        
        if self.SearchController.isActive {
            self.SearchController.present(viewControllerToPresent, animated: true, completion: nil)
        } else {
            self.present(viewControllerToPresent, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func gotoTalk(_ sender: Any) {
        
        if let talkName = UserDefaults.standard.string(forKey: "TalkName")
        {
            let currentTalkTime = UserDefaults.standard.integer(forKey: "CurrentTalkTime")
            
            if  let currentTalk = TheDataModel.getTalkForName(name: talkName) {
                ResumeTalk = currentTalk
                ResumeTalkTime = currentTalkTime
                print("Goto BookMark: ", talkName, currentTalk)
                performSegue(withIdentifier: "DISPLAY_RESUMETALK", sender: self)
            }
        } else {
            
            let alert = UIAlertController(title: "Go To Your Last Talk", message: "\nYou have not listened to a talk yet. \nTherefore no action was taken.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            self.mypresent(alert)
        }
    }


    
}
