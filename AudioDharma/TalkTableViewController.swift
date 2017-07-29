//
//  TalkTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/15/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import Social

class TalkTableViewController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
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
        
        //self.tableView.style = UITableViewStyle.UITableViewStylePlain
        print("view did load")
        super.viewDidLoad()
        
        SectionTalks = TheDataModel.getTalks(content: Content)
        FilteredSectionTalks = SectionTalks
        
        SearchController.searchResultsUpdater = self
        SearchController.searchBar.delegate = self
        SearchController.delegate = self
        SearchController.hidesNavigationBarDuringPresentation = false
        SearchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = SearchController.searchBar
        
    }
    
    deinit {
        
        // this view tends to hang around in the parent.  this clears it
        SearchController.view.removeFromSuperview()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    // restore the search state, if any
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)

        if SearchText.characters.count > 0 {
            SearchController.searchBar.text! = SearchText
        }

    }

    // TBD
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        SearchController.isActive = false
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "DISPLAY_TALKPLAYER1":
            print("DISPLAY_TALKPLAYER1")

            guard let navController = segue.destination as? UINavigationController, let playTalkController = navController.viewControllers.last as? PlayTalkController
                else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            //print(self.selectedSection, self.selectedRow)
            playTalkController.CurrentTalkRow = SelectedRow
            playTalkController.TalkList = FilteredSectionTalks[SelectedSection]
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier ?? "NONE")")            
        }
        
        // dismiss any searching - must do this prior to executing the segue
        // NOTE:  must do this on the return, as it will reset filteredSectionTalks and give us the wrong indexing if done earlier
        SearchText = SearchController.searchBar.text!   //  save this off, so as to restore search state upon return
        SearchController.isActive = false
        
    }

    @IBAction func unwindToTalkList(sender: UIStoryboardSegue) {
        // TBD
    }

    
    // MARK: UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //searchBar.resignFirstResponder()
    }
    
    
    // MARK: UISearchControllerDelegate
    func presentSearchController(_ searchController: UISearchController) {
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
    }
    
    
    // MARK: UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            
            var sectionsPositionDict : [String: Int] = [:]
            FilteredSectionTalks = []
            for sections in SectionTalks {
                for talkData in sections {
                    if talkData.title.lowercased().contains(searchText.lowercased()) {
                        
                        if sectionsPositionDict[talkData.section] == nil {
                            // new section seen.  create new array of talks for this section
                            FilteredSectionTalks.append([talkData])
                            sectionsPositionDict[talkData.section] = FilteredSectionTalks.count - 1
                        } else {
                            // section already exists.  add talk to the existing array of talks
                            let sectionPosition = sectionsPositionDict[talkData.section]
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
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }


    // MARK: - Table Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        //print("Number of sections: \(self.filteredSectionTalks.count)")
        return FilteredSectionTalks.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //print("Section: \(section)  Number of rows: \(self.filteredSectionTalks[section].count)")
        return FilteredSectionTalks[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return FilteredSectionTalks[section][0].section
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "TalkTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TalkTableViewCell  else {
            fatalError("The dequeued cell is not an instance of TalkTableViewCell.")
        }
        
        let talk = FilteredSectionTalks[indexPath.section][indexPath.row]
        
        cell.title.text = talk.title
        cell.speakerPhoto.image = talk.speakerPhoto
        cell.speakerPhoto.contentMode = UIViewContentMode.scaleAspectFit
        cell.duration.text = talk.duration
        cell.date.text = talk.date
        
        return cell
    }
    
    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        
        view.tintColor = UIColor.black
        header.textLabel?.textColor = UIColor.white
        header.textLabel?.textAlignment = NSTextAlignment.center
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedSection = indexPath.section
        SelectedRow = indexPath.row
        //print("Seleced Section: \(SelectedSection)   Selected Row: \(SelectedRow)")
        self.performSegue(withIdentifier: "DISPLAY_TALKPLAYER1", sender: self)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        SelectedSection = indexPath.section
        SelectedRow = indexPath.row

        let shareTalk = UITableViewRowAction(style: .normal, title: "Share") { (action, indexPath) in
            self.shareTalk()
        }
        return [shareTalk]
    }


    //MARK: Share
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
