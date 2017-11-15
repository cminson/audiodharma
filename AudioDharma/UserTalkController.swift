//
//
//  UserTalkController.swift
//  AudioDharma
//
//  Created by Christopher on 6/15/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

//
// Displays the talks that a user has stored in their User Album
//
class UserTalkController: BaseController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
   
    // MARK: Properties
    var UserAlbum: UserAlbumData!   // the userAlbum that we are currently viewing
    var FilteredTalks: [TalkData]  = [TalkData] ()  // the talk list for the selectedUserList
    var SelectedRow: Int = 0
    
    // MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FilteredTalks = TheDataModel.getUserAlbumTalks(userAlbum: UserAlbum)

        self.title = UserAlbum.Title
        
        SearchController.searchResultsUpdater = self
        SearchController.searchBar.delegate = self
        SearchController.delegate = self
        tableView.tableHeaderView = SearchController.searchBar

        TheDataModel.UserTalkController = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // restore the search state, if any
        if SearchText.count > 0 {
            SearchController.searchBar.text! = SearchText
        }
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
        
        FilteredTalks = TheDataModel.getUserAlbumTalks(userAlbum: UserAlbum)
    }

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier ?? "" {
            
        case "DISPLAY_RESUMETALK":
            
            guard let navController = segue.destination as? UINavigationController, let playTalkController = navController.viewControllers.last as? PlayTalkController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            
            playTalkController.ResumingLastTalk = true
            playTalkController.CurrentTalkTime = ResumeTalkTime
            playTalkController.CurrentTalk = ResumeTalk

            
        case "DISPLAY_EDITUSERTALKS":  // edit the talks within this User List
            
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let controller = navController.viewControllers.last as? UserTalksEditController
            controller?.SelectedTalks =  FilteredTalks
            
        case "DISPLAY_TALKPLAYER":   // play the selected talk in the MP3
            
            guard let navController = segue.destination as? UINavigationController, let controller = navController.viewControllers.last as? PlayTalkController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }

            controller.TalkList = FilteredTalks
            controller.CurrentTalkRow = SelectedRow
            
        case "DISPLAY_NOTE":
            guard let navController = segue.destination as? UINavigationController, let controller = navController.viewControllers.last as? NoteController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            
            //print(self.selectedSection, self.selectedRow)
            let talk = FilteredTalks[SelectedRow]
            controller.TalkFileName = talk.FileName
            controller.title = talk.Title

        case "DISPLAY_HELP_PAGE":
            guard let navController = segue.destination as? UINavigationController, let controller = navController.viewControllers.last as? HelpController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            controller.setHelpPage(helpPage: KEY_USER_TALKS)
            
        case "DISPLAY_DONATIONS":
            guard let _ = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }


        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier!)")
        }
        
        // dismiss any searching - must do this prior to executing the segue
        // NOTE:  must do this on the return, as it will reset filteredSectionTalks and give us the wrong indexing if done earlier
        SearchText = SearchController.searchBar.text!   //  save this off, so as to restore search state upon return
        SearchController.isActive = false
     }
    
    @IBAction func unwindTalkEditToUserTalks(sender: UIStoryboardSegue) {  // called from UserTalkEditViewController
        
        //
        // gather the talks selected in Add Talks and store them off
        //
        if let controller = sender.source as? UserTalksEditController {
            
            FilteredTalks = controller.SelectedTalks
            TheDataModel.saveUserAlbumTalks(userAlbum: UserAlbum, talks: FilteredTalks)
            
            tableView.reloadData()
        }
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
            
            FilteredTalks = []
            for talk in TheDataModel.getUserAlbumTalks(userAlbum: UserAlbum) {
                
                let notes = TheDataModel.getNoteForTalk(talkFileName: talk.FileName).lowercased()

                let searchedData = talk.Title.lowercased() + " " +
                    talk.Speaker.lowercased() + " " + talk.Date + " " + talk.Keys.lowercased() + " " + notes

                if searchedData.contains(searchText.lowercased()) {
                    FilteredTalks.append(talk)
                }
            }
        } else {
            
            FilteredTalks = TheDataModel.getUserAlbumTalks(userAlbum: UserAlbum)
        }

        tableView.reloadData()
    }

    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return FilteredTalks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("TalkCell", owner: self, options: nil)?.first as! TalkCell
        let talk = FilteredTalks[indexPath.row]

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

        
        var talkTitle: String
        if TheDataModel.isDownloadInProgress(talk: talk) {
            talkTitle = "DOWNLOADING: " + talk.Title
        } else {
            talkTitle = talk.Title
        }
        if TheDataModel.isCompletedDownloadTalk(talk: talk) {
            cell.title.textColor = BUTTON_DOWNLOAD_COLOR
        }
        
        cell.title.text = talkTitle
        cell.speakerPhoto.image = talk.SpeakerPhoto
        cell.speakerPhoto.contentMode = UIViewContentMode.scaleAspectFit
        cell.duration.text = talk.DurationDisplay
        cell.date.text = talk.Date
        
        cell.duration.textColor = SECONDARY_FONT_COLOR
        cell.date.textColor = SECONDARY_FONT_COLOR
        
        return cell
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedRow = indexPath.row
        performSegue(withIdentifier: "DISPLAY_TALKPLAYER", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        SelectedRow = indexPath.row
        let talk = FilteredTalks[SelectedRow]

        let noteTalk = UITableViewRowAction(style: .normal, title: "note") { (action, indexPath) in
            self.viewEditNote()
        }
        
        let shareTalk = UITableViewRowAction(style: .normal, title: "share") { (action, indexPath) in
            self.shareTalk(talk: talk)
        }
        
        var favoriteTalk : UITableViewRowAction
        if TheDataModel.isFavoriteTalk(talk: talk) {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "remove\nfavorite") { (action, indexPath) in
                self.unFavoriteTalk(talk: talk)
            }
            
        } else {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "favorite") { (action, indexPath) in
                self.favoriteTalk(talk: talk)
            }
        }
        
        var downloadTalk : UITableViewRowAction
        if TheDataModel.isDownloadTalk(talk: talk) {
            downloadTalk = UITableViewRowAction(style: .normal, title: "remove\ndownload") { (action, indexPath) in
                
                let alert = UIAlertController(title: "Delete Downloaded Talk?", message: "Delete talk from local storage", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: self.handlerDeleteDownload))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
                self.mypresent(alert)
            }
            
        } else {
            downloadTalk = UITableViewRowAction(style: .normal, title: "download") { (action, indexPath) in
                
                if TheDataModel.isInternetAvailable() == false {
                    let alert = UIAlertController(title: "No Internet Connection", message: "Please check your connection.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.mypresent(alert)
                    return
                }
                
                if TheDataModel.DownloadInProgress {
                    let alert = UIAlertController(title: "Another Download In Progress", message: "Only one download can run at at time.\n\nPlease wait until previous download is completed.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.mypresent(alert)
                    return
                }

                let alert = UIAlertController(title: "Download Talk?", message: "Download talk to device storage.\n\nTalk will be listed in your Download Album", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: self.handlerAddDownload))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
                self.mypresent(alert)
            }
        }
        
        
        noteTalk.backgroundColor = BUTTON_NOTE_COLOR
        shareTalk.backgroundColor = BUTTON_SHARE_COLOR
        favoriteTalk.backgroundColor = BUTTON_FAVORITE_COLOR
        downloadTalk.backgroundColor = BUTTON_DOWNLOAD_COLOR
        
        return [downloadTalk, shareTalk, noteTalk, favoriteTalk]
    }
    
    
    //MARK: Menu Functions
    func handlerAddDownload(alert: UIAlertAction!) {
        
        let talk = FilteredTalks[SelectedRow]
        self.executeDownload(talk: talk)
    }
    
    func handlerDeleteDownload(alert: UIAlertAction!) {
        
        let talk = FilteredTalks[SelectedRow]
        self.deleteDownloadedTalk(talk: talk)
    }
    
    private func viewEditNote() {
        
        performSegue(withIdentifier: "DISPLAY_NOTE", sender: self)
    }
    
   
    
}


