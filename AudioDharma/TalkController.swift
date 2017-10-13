//
//  TalkController.swift
//  AudioDharma
//
//  Created by Christopher on 6/15/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import Social

class TalkController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    @IBOutlet var buttonHelp: UIBarButtonItem!
    @IBOutlet var buttonDonate: UIBarButtonItem!
    
    //MARK: Properties
    var SectionTalks: [[TalkData]] = []
    var FilteredSectionTalks:  [[TalkData]] = []
    var Content: String = ""
    var SelectedSection: Int = 0
    var SelectedRow: Int = 0
    let SearchController = UISearchController(searchResultsController: nil)
    var SearchText = ""
    
    // MARK: Init
    override func viewDidLoad() {
        
        print("talkcontroller: viewdidload")
        super.viewDidLoad()
        
        SectionTalks = TheDataModel.getTalks(content: Content)
        FilteredSectionTalks = SectionTalks
        
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
        
        TheDataModel.TalkController = self
        
  
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("talkcontroller: viewWillAppear")

        super.viewWillAppear(animated)
        
        SectionTalks = TheDataModel.getTalks(content: Content)
        FilteredSectionTalks = SectionTalks
        
        // restore the search state, if any
        if SearchText.characters.count > 0 {
            SearchController.searchBar.text! = SearchText
        }
        
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("talkcontroller: viewWillDisapear")

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
        
        SectionTalks = TheDataModel.getTalks(content: Content)
        FilteredSectionTalks = SectionTalks
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
            playTalkController.TalkList = FilteredSectionTalks[SelectedSection]
        case "DISPLAY_NOTE":
            guard let navController = segue.destination as? UINavigationController, let controller = navController.viewControllers.last as? NoteController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let talk = FilteredSectionTalks[SelectedSection][SelectedRow]
            controller.TalkFileName = talk.FileName
            controller.title = talk.Title
            //print("DISPLAYING NOTE DIALOG FOR \(talk.Title) \(talk.FileName)")
            
        case "DISPLAY_HELP_PAGE":
            guard let navController = segue.destination as? UINavigationController, let controller = navController.viewControllers.last as? HelpController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            controller.setHelpPage(helpPage: Content)
            
        case "DISPLAY_DONATIONS":
            guard let _ = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
        case "DISPLAY_TALKS":
            guard let controller = segue.destination as? TalkController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            controller.Content = KEY_ALLTALKS
            controller.title = "Similar"


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
            
            var sectionsPositionDict : [String: Int] = [:]
            FilteredSectionTalks = []
            for sections in SectionTalks {
                for talkData in sections {
                    let notes = TheDataModel.getNoteForTalk(talkFileName: talkData.FileName).lowercased()
                    
                    let searchedData = talkData.Title.lowercased() + talkData.Speaker.lowercased() + talkData.Date + notes
                    
                    if searchedData.contains(searchText.lowercased()) {
                        
                        if sectionsPositionDict[talkData.Section] == nil {
                            // new section seen.  create new array of talks for this section
                            FilteredSectionTalks.append([talkData])
                            sectionsPositionDict[talkData.Section] = FilteredSectionTalks.count - 1
                        } else {
                            // section already exists.  add talk to the existing array of talks
                            let sectionPosition = sectionsPositionDict[talkData.Section]
                            FilteredSectionTalks[sectionPosition!].append(talkData)
                        }
                    }
                }
            }
        } else {
            FilteredSectionTalks = SectionTalks
        }
        tableView.reloadData()
    }
    
    
    // MARK: - Table Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return FilteredSectionTalks.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return FilteredSectionTalks[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var sectionTitle = ""
        
        if FilteredSectionTalks.count >= section {
            let talksInSection = FilteredSectionTalks[section]
            if talksInSection.count > 0 {
                sectionTitle = talksInSection[0].Section
            }
        }
        
        if sectionTitle.characters.count < 2 {
            sectionTitle = ""
        }
        return sectionTitle
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("TalkCell", owner: self, options: nil)?.first as! TalkCell
        let talk = FilteredSectionTalks[indexPath.section][indexPath.row]
 
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
    
    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        
        view.tintColor = SECTION_BACKGROUND
        header.textLabel?.textColor = SECTION_TEXT
        header.textLabel?.textAlignment = NSTextAlignment.center
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedSection = indexPath.section
        SelectedRow = indexPath.row
        performSegue(withIdentifier: "DISPLAY_TALKPLAYER", sender: self)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        SelectedSection = indexPath.section
        SelectedRow = indexPath.row
        let talk = FilteredSectionTalks[SelectedSection][SelectedRow]

        let noteTalk = UITableViewRowAction(style: .normal, title: "Note") { (action, indexPath) in
            self.viewEditNote()
        }
        
        let shareTalk = UITableViewRowAction(style: .normal, title: "Share") { (action, indexPath) in
            self.shareTalk()
        }
        
        var favoriteTalk : UITableViewRowAction
        if TheDataModel.isFavoriteTalk(talk: talk) {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "UnFavor") { (action, indexPath) in
                self.unFavoriteTalk()
            }
            
        } else {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "Favor") { (action, indexPath) in
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
    private func shareSimilarTalks() {
        
        performSegue(withIdentifier: "DISPLAY_TALKS", sender: self)
    }
    
    private func viewEditNote() {
        
        performSegue(withIdentifier: "DISPLAY_NOTE", sender: self)
    }
    
    func executeDownload(alert: UIAlertAction!) {
        
        let talk = FilteredSectionTalks[SelectedSection][SelectedRow]
        
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
        
        let talk = FilteredSectionTalks[SelectedSection][SelectedRow]
        
        TheDataModel.unsetTalkAsDownload(talk: talk)
    }

    private func favoriteTalk() {
        
        let talk = FilteredSectionTalks[SelectedSection][SelectedRow]
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
    
    private func unFavoriteTalk() {
        
        let talk = FilteredSectionTalks[SelectedSection][SelectedRow]
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
        
        let sharedTalk = FilteredSectionTalks[SelectedSection][SelectedRow]
        
        // save off search state and then turn off search. otherwise the modal will conflict with it
        SearchText = SearchController.searchBar.text!
        SearchController.isActive = false

        TheDataModel.shareTalk(sharedTalk: sharedTalk, controller: self)
        
        // restore search state
        SearchController.isActive = true
        SearchController.searchBar.text = SearchText
    }
    
}
