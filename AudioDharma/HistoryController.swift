//
//  HistoryController.swift
//  AudioDharma
//
//  Created by Christopher on 8/19/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class HistoryController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    @IBOutlet var buttonHelp: UIBarButtonItem!
    @IBOutlet var buttonDonate: UIBarButtonItem!

    //
    //MARK: Properties
    var TalkHistory: [TalkHistoryData] = []
    var FilteredTalkHistory:  [TalkHistoryData] = []
    var Content: String = ""
    var SelectedRow: Int = 0
    let SearchController = UISearchController(searchResultsController: nil)
    var SearchText = ""
    
    // MARK: Init
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        TheDataModel.CommunityController = self

        TalkHistory = TheDataModel.getTalkHistory(content: Content)
        FilteredTalkHistory = TalkHistory
        
        SearchController.searchResultsUpdater = self
        SearchController.searchBar.delegate = self
        SearchController.delegate = self
        SearchController.hidesNavigationBarDuringPresentation = false
        SearchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = SearchController.searchBar
        
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.toolbar.barStyle = UIBarStyle.blackOpaque
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        //self.navigationController?.navigationBar.backIndicatorImage = UIImage(named: "icoqm")?.withRenderingMode(.alwaysOriginal)
        //self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "icoqm")?.withRenderingMode(.alwaysOriginal)
        
        self.setToolbarItems([buttonHelp, flexibleItem, buttonDonate], animated: false)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        TalkHistory = TheDataModel.getTalkHistory(content: Content)
        FilteredTalkHistory = TalkHistory
        
        // restore the search state, if any
        if SearchText.characters.count > 0 {
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
    
    func reloadModel() {
        
        TalkHistory = TheDataModel.getTalkHistory(content: Content)
        FilteredTalkHistory = TalkHistory
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
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
            
            guard let navController = segue.destination as? UINavigationController, let controller = navController.viewControllers.last as? HelpController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            // display different help text depending on the kind of content we're showing.
            controller.setHelpPage(helpPage: Content)
        
        case "DISPLAY_DONATIONS":
            
            guard let _ = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
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
                    let searchedData = talk.Title.lowercased() + talk.Speaker.lowercased() + talk.Date
                    
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
                cell.noteImage.image? = (cell.noteImage.image?.withRenderingMode(.alwaysTemplate))!
                cell.noteImage.tintColor = BUTTON_NOTE_COLOR
                
            } else {
                cell.noteImage.tintColor = UIColor.white
            }
            if TheDataModel.isFavoriteTalk(talk: talk) == true {
                cell.favoriteImage.image? = (cell.favoriteImage.image?.withRenderingMode(.alwaysTemplate))!
                cell.favoriteImage.tintColor = BUTTON_FAVORITE_COLOR
                
            } else {
                cell.favoriteImage.tintColor = UIColor.white
            }

            var talkTitle: String
            if TheDataModel.isDownloadInProgress(talk: talk) {
                talkTitle = "DOWNLOADING: " + talk.Title
            } else {
                talkTitle = talk.Title
            }
            if TheDataModel.isCompletedDownloadTalk(talk: talk) {
                cell.title.textColor = BUTTON_DOWNLOAD_COLOR
            }

            cell.speakerPhoto.image = talk.SpeakerPhoto
            cell.speakerPhoto.contentMode = UIViewContentMode.scaleAspectFit
            cell.title.text = talkTitle
            cell.date.text = talkHistory.DatePlayed
            
            cell.city.text = talkHistory.CityPlayed
            cell.country.text = talkHistory.CountryPlayed
            
        }
        
        return cell
    }
    
/*
    override public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 60
    }
 */
    
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
        
        let noteTalk = UITableViewRowAction(style: .normal, title: "Notes") { (action, indexPath) in
            self.viewEditNote()
        }
        
        let shareTalk = UITableViewRowAction(style: .normal, title: "Share") { (action, indexPath) in
            self.shareTalk()
        }
        
        var favoriteTalk : UITableViewRowAction
        if TheDataModel.isFavoriteTalk(talk: talk) {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "Un-Favorite") { (action, indexPath) in
                self.unFavoriteTalk(talk: talk)
            }
        }
        else {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "Favorite") { (action, indexPath) in
                self.favoriteTalk(talk: talk)
            }
        }
        var downloadTalk : UITableViewRowAction
        if TheDataModel.isDownloadTalk(talk: talk) {
            downloadTalk = UITableViewRowAction(style: .normal, title: "Remove") { (action, indexPath) in
                
                let alert = UIAlertController(title: "Delete Downloaded Talk?", message: "Delete talk from local storage", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: self.deleteTalk))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
        } else {
            downloadTalk = UITableViewRowAction(style: .normal, title: "Download") { (action, indexPath) in
                
                let alert = UIAlertController(title: "Download Talk?", message: "Download talk to device storage.\n\nTalk will be listed in your Download Album", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: self.executeDownload))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        noteTalk.backgroundColor = BUTTON_NOTE_COLOR
        shareTalk.backgroundColor = BUTTON_SHARE_COLOR
        favoriteTalk.backgroundColor = BUTTON_FAVORITE_COLOR
        downloadTalk.backgroundColor = BUTTON_DOWNLOAD_COLOR
        
        return [shareTalk, noteTalk, favoriteTalk, downloadTalk]
        
    }
        
    private func viewEditNote() {
        
        performSegue(withIdentifier: "DISPLAY_NOTE", sender: self)
    }
    
    
    //MARK: Menu Functions
    func executeDownload(alert: UIAlertAction!) {
        
        if TheDataModel.isInternetAvailable() == false {
            let alert = UIAlertController(title: "No Internet Connection", message: "Please check your connection.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            return
        }

        
        let talkHistory = FilteredTalkHistory[SelectedRow]

        if let talk = TheDataModel.FileNameToTalk[talkHistory.FileName] {
        
            let spaceRequired = talk.DurationInSeconds * MP3_BYTES_PER_SECOND
        
            // if (freeSpace < Int64(500000000)) {
            if let freeSpace = TheDataModel.deviceRemainingFreeSpaceInBytes() {
                print("Freespace: ", freeSpace, spaceRequired)
                if (spaceRequired > freeSpace) {
                    let alert = UIAlertController(title: "Insufficient Space To Download", message: "You don't have enough space in your device to download this talk", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    return
                }
            }
            
            TheDataModel.setTalkAsDownload(talk: talk)
            TheDataModel.downloadMP3(talk: talk)
        }
        
    }
    
    private func deleteTalk(alert: UIAlertAction!) {
        
        let talkHistory = FilteredTalkHistory[SelectedRow]
        
        guard let talk = TheDataModel.getTalkForName(name: talkHistory.FileName)
        else {
            return 
        }

        TheDataModel.unsetTalkAsDownload(talk: talk)
    }

    
    private func favoriteTalk(talk: TalkData) {
        
        TheDataModel.setTalkAsFavorite(talk: talk)
        
        DispatchQueue.main.async(execute: {
            self.reloadModel()
            self.tableView.reloadData()
            return
        })
        
        let alert = UIAlertController(title: "Favorite Talk - Added", message: "This talk has been added to your Favorites Album", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func unFavoriteTalk(talk: TalkData) {
        
        TheDataModel.unsetTalkAsFavorite(talk: talk)
        
        DispatchQueue.main.async(execute: {
            self.reloadModel()
            self.tableView.reloadData()
            return
        })
        
        let alert = UIAlertController(title: "Favorite Talk - Removed", message: "This talk has been removed from your Favorites Album", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func shareTalk() {
        
        let talkHistory = FilteredTalkHistory[SelectedRow]
        
        // save off search state and then turn off search. otherwise the modal will conflict with it
        SearchText = SearchController.searchBar.text!
        SearchController.isActive = false
        
        if let sharedTalk = TheDataModel.FileNameToTalk[talkHistory.FileName] {
            TheDataModel.shareTalk(sharedTalk: sharedTalk, controller: self)
            
            // restore search state
            SearchController.isActive = true
            SearchController.searchBar.text = SearchText
            
        }
    }
    
}
