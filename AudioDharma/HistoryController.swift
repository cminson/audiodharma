//
//  HistoryController.swift
//  AudioDharma
//
//  Created by Christopher on 8/19/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class HistoryController: BaseController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    //
    //MARK: Properties
    var TalkHistory: [TalkHistoryData] = []
    var FilteredTalkHistory:  [TalkHistoryData] = []
    var Content: String = ""
    var SelectedRow: Int = 0
    
    // MARK: Init
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        TheDataModel.CommunityController = self

        TalkHistory = TheDataModel.getTalkHistory(content: Content)
        FilteredTalkHistory = TalkHistory
        
        SearchController.searchResultsUpdater = self
        SearchController.searchBar.delegate = self
        SearchController.delegate = self
        tableView.tableHeaderView = SearchController.searchBar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        TalkHistory = TheDataModel.getTalkHistory(content: Content)
        FilteredTalkHistory = TalkHistory
        
        // restore the search state, if any
        if SearchText.count > 0 {
            SearchController.searchBar.text! = SearchText
        }
        
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        SearchController.isActive = false
    }
    
    
    deinit {
        
        // this view tends to hang around in the parent.  this clears it
        SearchController.view.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    override func reloadModel() {
        
        TalkHistory = TheDataModel.getTalkHistory(content: Content)
        FilteredTalkHistory = TalkHistory
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "DISPLAY_RESUMETALK":
            guard let navController = segue.destination as? UINavigationController, let playTalkController = navController.viewControllers.last as? PlayTalkController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            
            playTalkController.ResumingLastTalk = true
            playTalkController.CurrentTalkTime = ResumeTalkTime
            playTalkController.CurrentTalk = ResumeTalk

            
        case "DISPLAY_TALKPLAYER":
            
            guard let navController = segue.destination as? UINavigationController, let playTalkController = navController.viewControllers.last as? PlayTalkController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            
            playTalkController.CurrentTalkRow = SelectedRow
            
            var talkList: [TalkData] = []
            for talkHistory in FilteredTalkHistory {
                if let talk = TheDataModel.FileNameToTalk[talkHistory.FileName] {
                    talkList.append(talk)
                }
            }
            playTalkController.TalkList = talkList
        case "DISPLAY_NOTE":
            
            guard let navController = segue.destination as? UINavigationController, let controller = navController.viewControllers.last as? NoteController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let talkHistory = FilteredTalkHistory[SelectedRow]
            if let talk = TheDataModel.FileNameToTalk[talkHistory.FileName] {
                
                controller.TalkFileName = talk.FileName
                controller.title = talk.Title
                print("DISPLAYING NOTE DIALOG FOR \(talk.Title) \(talk.FileName)")
            }
            
        case "DISPLAY_HELP_PAGE":
            
            guard let navController = segue.destination as? UINavigationController, let _ = navController.viewControllers.last as? HelpController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
        
        case "DISPLAY_DONATIONS":
            
            guard let _ = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
        case "DISPLAY_SIMILAR_TALKS":
            guard let controller = segue.destination as? TalkController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let talkHistory = FilteredTalkHistory[SelectedRow]
            if let talk = TheDataModel.FileNameToTalk[talkHistory.FileName] {
                
                let contentKey = talk.FileName
                controller.Content = contentKey
                controller.title = "Similar Talks: " + talk.Title
                
                TheDataModel.downloadSimilarityData(talkFileName: contentKey)
                
            }
            
            
        default:
            
            fatalError("Unexpected Segue Identifier; \(segue.identifier ?? "NONE")")
        }
        
        // dismiss any searching - must do this prior to executing the segue
        // NOTE:  must do this on the return, as it will reset filteredSectionTalks and give us the wrong indexing if done earlier
        SearchText = SearchController.searchBar.text!   //  save this off, so as to restore search state upon return
        SearchController.isActive = false
        
    }
    
    @IBAction func unwindNotesEditToTalk(sender: UIStoryboardSegue) {   // called from NotesController
        
        if let controller = sender.source as? NoteController {
            
            if controller.TextHasBeenChanged == true {
                
                controller.TextHasBeenChanged = false   // just to make sure ...
                
                if let talk = TheDataModel.FileNameToTalk[controller.TalkFileName] {
                    let noteText  = controller.noteTextView.text!
                    TheDataModel.addNoteToTalk(noteText: noteText, talkFileName: talk.FileName)
                    
                    tableView.reloadData()
                }
            }
        }
    }
    
    
    // MARK: UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
 
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            
            FilteredTalkHistory = []
            for talkHistory in TalkHistory {
                
                if let talk = TheDataModel.FileNameToTalk[talkHistory.FileName] {
                    
                    let notes = TheDataModel.getNoteForTalk(talkFileName: talk.FileName).lowercased()
                    let searchedData = talk.Title.lowercased() + " " +
                        talk.Speaker.lowercased() + " " + talk.Date + " " + talk.Keys.lowercased() + " " + notes

                    if searchedData.contains(searchText.lowercased()) {
                        
                        FilteredTalkHistory.append(talkHistory)
                        
                    }
                }
            }
        } else {
            FilteredTalkHistory = TalkHistory
        }
        tableView.reloadData()
    }
    
    
    // MARK: - Table Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return FilteredTalkHistory.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("HistoryCell", owner: self, options: nil)?.first as! HistoryCell
        let talkHistory = FilteredTalkHistory[indexPath.row]
        if let talk = TheDataModel.FileNameToTalk[talkHistory.FileName] {
            
            if TheDataModel.isNotatedTalk(talk: talk) == true {
                cell.noteImage.isHidden = false
            }
            else {
                cell.noteImage.isHidden = true
            }
            if TheDataModel.isFavoriteTalk(talk: talk) == true {
                cell.favoriteImage.isHidden = false
            }
            else {
                cell.favoriteImage.isHidden = true
            }

            
            cell.title.textColor = MAIN_FONT_COLOR
            cell.country.textColor = SECONDARY_FONT_COLOR
            cell.city.textColor = SECONDARY_FONT_COLOR
            cell.date.textColor = SECONDARY_FONT_COLOR

            var talkTitle: String
            if TheDataModel.isDownloadInProgress(talk: talk) {
                talkTitle = "DOWNLOADING: " + talk.Title
            } else {
                talkTitle = talk.Title
            }
            if TheDataModel.isCompletedDownloadTalk(talk: talk) {
                cell.title.textColor = BUTTON_DOWNLOAD_COLOR
            }
            //CJM DEV
            if TheDataModel.hasTalkBeenPlayed(talk: talk) {
                talkTitle = "* " + talkTitle
            }
            
            cell.speakerPhoto.image = talk.SpeakerPhoto
            cell.speakerPhoto.contentMode = UIView.ContentMode.scaleAspectFit
            cell.title.text = talkTitle
            cell.date.text = talkHistory.DatePlayed
            
            cell.city.text = talkHistory.CityPlayed
            
            let statePlayed = talkHistory.StatePlayed.trimmingCharacters(in: .whitespacesAndNewlines)
            cell.country.text = statePlayed + " " + talkHistory.CountryPlayed
  
            
        }
        
        return cell
    }
    
    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        
        view.tintColor = SECTION_BACKGROUND
        header.textLabel?.textColor = SECTION_TEXT
        header.textLabel?.textAlignment = NSTextAlignment.center
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedRow = indexPath.row
        performSegue(withIdentifier: "DISPLAY_TALKPLAYER", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        SelectedRow = indexPath.row
        let talkHistory = FilteredTalkHistory[SelectedRow]
        
        guard let talk = TheDataModel.getTalkForName(name: talkHistory.FileName)
        else {
            return nil
        }
        
        let noteTalk = UITableViewRowAction(style: .normal, title: "note") { (action, indexPath) in
            self.performSegue(withIdentifier: "DISPLAY_NOTE", sender: self)
        }
        
        let shareTalk = UITableViewRowAction(style: .normal, title: "share") { (action, indexPath) in
            self.shareTalk(talk: talk)
        }
        
        var favoriteTalk : UITableViewRowAction
        if TheDataModel.isFavoriteTalk(talk: talk) {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "remove\nlike") { (action, indexPath) in
                self.unFavoriteTalk(talk: talk)
            }
        }
        else {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "like") { (action, indexPath) in
                self.favoriteTalk(talk: talk)
            }
        }
        var downloadTalk : UITableViewRowAction
        if TheDataModel.isDownloadTalk(talk: talk) {
            downloadTalk = UITableViewRowAction(style: .normal, title: "remove\ndownload") { (action, indexPath) in
                
  
                let alert = UIAlertController(title: "Delete Downloaded Talk?", message: "Delete talk from local storage", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: self.handlerDeleteDownload))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))
                self.mypresent(alert)
            }
            
        } else {
            downloadTalk = UITableViewRowAction(style: .normal, title: "down\nload") { (action, indexPath) in
                
                if TheDataModel.isInternetAvailable() == false {
                    let alert = UIAlertController(title: "No Internet Connection", message: "Please check your connection.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.mypresent(alert)
                    return
                }
                
                if TheDataModel.DownloadInProgress {
                    let alert = UIAlertController(title: "Another Download In Progress", message: "Only one download can run at at time.\n\nPlease wait until previous download is completed.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.mypresent(alert)
                    return
                }

                let alert = UIAlertController(title: "Download Talk?", message: "Download talk to device storage.\n\nTalk will be listed in your Download Album", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: self.handlerAddDownload))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))
                self.mypresent(alert)
            }
        }
        
        let similarTalks = UITableViewRowAction(style: .normal, title: SIMILAR_MENU_ITEM) { (action, indexPath) in
            self.performSegue(withIdentifier: "DISPLAY_SIMILAR_TALKS", sender: self)
        }
        
        similarTalks.backgroundColor = BUTTON_SIMILAR_COLOR
        noteTalk.backgroundColor = BUTTON_NOTE_COLOR
        shareTalk.backgroundColor = BUTTON_SHARE_COLOR
        favoriteTalk.backgroundColor = BUTTON_FAVORITE_COLOR
        downloadTalk.backgroundColor = BUTTON_DOWNLOAD_COLOR
        
        return [downloadTalk, shareTalk, noteTalk, favoriteTalk, similarTalks]
        
    }
    
    //MARK: Menu Functions
    func handlerAddDownload(alert: UIAlertAction!) {
        
        let talkHistory = FilteredTalkHistory[SelectedRow]
        
        if let talk = TheDataModel.FileNameToTalk[talkHistory.FileName] {
            self.executeDownload(talk: talk)
        }
    }
    
    func handlerDeleteDownload(alert: UIAlertAction!) {
        
        let talkHistory = FilteredTalkHistory[SelectedRow]
        
        if let talk = TheDataModel.getTalkForName(name: talkHistory.FileName) {
          self.deleteDownloadedTalk(talk: talk)
        }
    }

    
}
