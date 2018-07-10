//
//  TalkController.swift
//  AudioDharma
//
//  Created by Christopher on 6/15/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import Social

class TalkController: BaseController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    //MARK: Properties
    var SectionTalks: [[TalkData]] = []
    var FilteredSectionTalks:  [[TalkData]] = []
    
    var Content: String = ""
    var SelectedSection: Int = 0
    var SelectedRow: Int = 0
    
    
    // MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()
    
        reloadDataFromModel()

        SearchController.searchResultsUpdater = self
        SearchController.searchBar.delegate = self
        SearchController.delegate = self
        tableView.tableHeaderView = SearchController.searchBar
        
        TheDataModel.TalkController = self
     }
    
    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
        
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
    
    func reloadDataFromModel() {
        
        SectionTalks = []
        FilteredSectionTalks = []
        
        let talkList = TheDataModel.getTalks(content: Content)
        for talk in talkList {
            if talk.Title == SECTION_HEADER { SectionTalks.append([]) }
            else {
                if SectionTalks.count == 0 { SectionTalks.append([]) }
                SectionTalks[SectionTalks.count - 1].append(talk)
            }
        }
        FilteredSectionTalks = SectionTalks
    }
    
    override func reloadModel() {
        
        reloadDataFromModel()
    }

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        let backItem = UIBarButtonItem()
        backItem.title = "  "
        navigationItem.backBarButtonItem = backItem

        
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
            
            playTalkController.ResumingLastTalk = false
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

        case "DISPLAY_SIMILAR_TALKS":
            guard let controller = segue.destination as? TalkController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let talk = FilteredSectionTalks[SelectedSection][SelectedRow]
            controller.Content = "SIMILAR." + talk.FileName
            controller.title = talk.Title + ": Similar Talks"


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
        
        var searchResults = [TalkData] ()
        FilteredSectionTalks = []
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            for talk in SectionTalks.joined() {
                let notes = TheDataModel.getNoteForTalk(talkFileName: talk.FileName).lowercased()
                let searchedData = talk.Title.lowercased() + " " +
                    talk.Speaker.lowercased() + " " + talk.Date + " " + talk.Keys.lowercased() + " " + notes
                if searchedData.contains(searchText.lowercased()) {searchResults.append(talk)}
            }
            FilteredSectionTalks.append(searchResults)
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
        
        if FilteredSectionTalks.count == 1 {return sectionTitle}
        
        if section < FilteredSectionTalks.count  {
            let talksInSection = FilteredSectionTalks[section]
            if talksInSection.count > 0 { sectionTitle = talksInSection[0].Section }
        }
        
        if sectionTitle.count < 2 {sectionTitle = "" }
        return sectionTitle
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("TalkCell", owner: self, options: nil)?.first as! TalkCell
        
        let talk = FilteredSectionTalks[indexPath.section][indexPath.row]
        
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
        cell.duration.textColor = SECONDARY_FONT_COLOR
        cell.date.textColor = SECONDARY_FONT_COLOR

        var talkTitle: String
        if TheDataModel.isDownloadInProgress(talk: talk) {
            talkTitle = "DOWNLOADING: " + talk.Title
        } else {
            
            if self.Content == KEY_ALLTALKS {
                talkTitle = talk.Title + " - " + talk.Speaker
            } else {
                talkTitle = talk.Title
            }
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

        let noteTalk = UITableViewRowAction(style: .normal, title: "note") { (action, indexPath) in
            self.performSegue(withIdentifier: "DISPLAY_NOTE", sender: self)
        }
        
        let shareTalk = UITableViewRowAction(style: .normal, title: "share") { (action, indexPath) in
            self.shareTalk(talk: talk)
        }
        
        var favoriteTalk : UITableViewRowAction
        if TheDataModel.isFavoriteTalk(talk: talk) {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "un-\nlike") { (action, indexPath) in
                self.unFavoriteTalk(talk: talk)
            }
            
        } else {
            favoriteTalk = UITableViewRowAction(style: .normal, title: "like") { (action, indexPath) in
                self.favoriteTalk(talk: talk)
            }
        }
        
        
        let similarTalks = UITableViewRowAction(style: .normal, title: "more") { (action, indexPath) in
            self.performSegue(withIdentifier: "DISPLAY_SIMILAR_TALKS", sender: self)
        }
 
        var downloadTalk : UITableViewRowAction
        if TheDataModel.isDownloadTalk(talk: talk) {
            downloadTalk = UITableViewRowAction(style: .normal, title: "remove") { (action, indexPath) in
                
                let alert = UIAlertController(title: "Delete Downloaded Talk?", message: "Delete talk from local storage", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: self.handlerDeleteDownload))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
                self.mypresent(alert)
            }
            
        } else {
            downloadTalk = UITableViewRowAction(style: .normal, title: "down\nload") { (action, indexPath) in
                
                
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
        
        similarTalks.backgroundColor = BUTTON_SIMILAR_COLOR
        favoriteTalk.backgroundColor = BUTTON_FAVORITE_COLOR
        noteTalk.backgroundColor = BUTTON_NOTE_COLOR
        shareTalk.backgroundColor = BUTTON_SHARE_COLOR
        downloadTalk.backgroundColor = BUTTON_DOWNLOAD_COLOR

        return [downloadTalk, shareTalk, noteTalk, favoriteTalk, similarTalks]
    }

    //MARK: Menu Function
    func handlerAddDownload(alert: UIAlertAction!) {
        
        let talk = FilteredSectionTalks[SelectedSection][SelectedRow]
        self.executeDownload(talk: talk)
    }
    
	func handlerDeleteDownload(alert: UIAlertAction!) {
        
        let talk = FilteredSectionTalks[SelectedSection][SelectedRow]
        self.deleteDownloadedTalk(talk: talk)
    }
    
    
    
    
}
