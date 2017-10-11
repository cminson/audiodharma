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
class UserTalkController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    @IBOutlet var buttonHelp: UIBarButtonItem!
    @IBOutlet var buttonDonate: UIBarButtonItem!
    
    // MARK: Properties
    var UserAlbum: UserAlbumData!   // the userAlbum that we are currently viewing
    var FilteredTalks: [TalkData]  = [TalkData] ()  // the talk list for the selectedUserList
    var SelectedRow: Int = 0
    let SearchController = UISearchController(searchResultsController: nil)
    var SearchText = ""

    
    // MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FilteredTalks = TheDataModel.getUserAlbumTalks(userAlbum: UserAlbum)

        self.title = UserAlbum.Title
        
        SearchController.searchResultsUpdater = self
        SearchController.searchBar.delegate = self
        SearchController.delegate = self
        SearchController.hidesNavigationBarDuringPresentation = false
        SearchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = SearchController.searchBar
        
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.toolbar.barStyle = UIBarStyle.blackOpaque
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([buttonHelp, flexibleItem, buttonDonate], animated: false)


        //self.tableView.isEditing = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // restore the search state, if any
        if SearchText.characters.count > 0 {
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
    
    func reloadModel() {
        
        FilteredTalks = TheDataModel.getUserAlbumTalks(userAlbum: UserAlbum)
    }

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier ?? "" {
            
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
                if talk.Title.lowercased().contains(searchText.lowercased()) {
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
        
        cell.title.text = talkTitle
        cell.speakerPhoto.image = talk.SpeakerPhoto
        cell.speakerPhoto.contentMode = UIViewContentMode.scaleAspectFit
        cell.duration.text = talk.DurationDisplay
        cell.date.text = talk.Date
        return cell
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedRow = indexPath.row
        performSegue(withIdentifier: "DISPLAY_TALKPLAYER", sender: self)
    }
 
    #if WANTEDITING
    // REMEMBER: if editing method below is active, then left-swipe Share will not work
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        return false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let movedTalk = SelectedTalks[sourceIndexPath.row]
        SelectedTalks.remove(at: sourceIndexPath.row)
        SelectedTalks.insert(movedTalk, at: destinationIndexPath.row)
        print("\(sourceIndexPath.row) => \(destinationIndexPath.row) \(movedTalk.title)")
        
        
        // unpack the  selected talks into talkFileNames (an array of talk filenames strings)
        var talkFileNames = [String]()
        for talk in SelectedTalks {
            talkFileNames.append(talk.fileName)
        }
        
        // save the resulting array into the userlist and then persist into storage
        TheDataModel.UserLists[SelectedUserListIndex].talkFileNames = talkFileNames
        TheDataModel.saveUserListData()
      }
    #endif
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        SelectedRow = indexPath.row
        let talk = FilteredTalks[SelectedRow]

        let noteTalk = UITableViewRowAction(style: .normal, title: "Note") { (action, indexPath) in
            self.viewEditNote()
        }
        
        let shareTalk = UITableViewRowAction(style: .normal, title: "Share") { (action, indexPath) in
            self.shareTalk()
        }
        
        var favoriteTalk : UITableViewRowAction
        if TheDataModel.isFavoriteTalk(talk: talk) {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "Un-Favorite") { (action, indexPath) in
                self.unFavoriteTalk()
            }
            
        } else {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "Favorite") { (action, indexPath) in
                self.favoriteTalk()
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
                
                if TheDataModel.isInternetAvailable() == false {
                    let alert = UIAlertController(title: "No Internet Connection", message: "Please check your connection.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
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
    
    
    //MARK: Menu Functions
    func executeDownload(alert: UIAlertAction!) {
        
        let talk = FilteredTalks[SelectedRow]

        let spaceRequired = talk.DurationInSeconds * MP3_BYTES_PER_SECOND
        
        // if (freeSpace < Int64(500000000)) {
        if let freeSpace = TheDataModel.deviceRemainingFreeSpaceInBytes() {
            print("Freespace: ", freeSpace, spaceRequired)
            if (spaceRequired > freeSpace) {
                let alert = UIAlertController(title: "Insufficient Space To Download", message: "You don't have enough space in your device to download this talk", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                present(alert, animated: true, completion: nil)
                return
            }
        }
        
        TheDataModel.setTalkAsDownload(talk: talk)
        TheDataModel.downloadMP3(talk: talk)
    }
    
    private func deleteTalk(alert: UIAlertAction!) {
        
        let talk = FilteredTalks[SelectedRow]

        TheDataModel.unsetTalkAsDownload(talk: talk)
    }

    private func favoriteTalk() {
        
        let talk = FilteredTalks[SelectedRow]
        TheDataModel.setTalkAsFavorite(talk: talk)
        
        DispatchQueue.main.async(execute: {
            self.reloadModel()
            self.tableView.reloadData()
            return
        })
        
        let alert = UIAlertController(title: "Talk Favorited", message: "This talk has been added to your Favorites Album", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func unFavoriteTalk() {
        
        let talk = FilteredTalks[SelectedRow]
        TheDataModel.unsetTalkAsFavorite(talk: talk)
        
        
        DispatchQueue.main.async(execute: {
            self.reloadModel()
            self.tableView.reloadData()
            return
        })
        
        let alert = UIAlertController(title: "Talk Un-favorited", message: "This talk has been removed from your Favorites Album", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func viewEditNote() {
        
        performSegue(withIdentifier: "DISPLAY_NOTE", sender: self)
    }
    
    private func shareTalk() {
        
        let sharedTalk = FilteredTalks[SelectedRow]
        TheDataModel.shareTalk(sharedTalk: sharedTalk, controller: self)
    }

}
