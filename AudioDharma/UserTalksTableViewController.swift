//
//
//  UserTalkTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/15/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class UserTalkTableViewController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    //MARK: Properties
    var sectionTalks: [[TalkData]] = []
    var sectionTalksFiltered:  [[TalkData]] = []
    var content: String = "ALL"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sectionTalks = TheDataModel.getTalks(content: content)
        self.sectionTalksFiltered = self.sectionTalks
        
        
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = true
        tableView.tableHeaderView = searchController.searchBar
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - UISearchControllerDelegate
    
    func presentSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    
    // MARK: - UISearchResultsUpdating
    /*
     func updateSearchResults(for searchController: UISearchController) {
     if let searchText = searchController.searchBar.text, !searchText.isEmpty {
     sectionTalksFiltered = sectionTalks.filter { talk in
     return talk.lowercased().contains(searchText.lowercased())
     }
     
     } else {
     sectionTalksFiltered = sectionTalks
     }
     tableView.reloadData()
     }
     */
    
    func updateSearchResults(for searchController: UISearchController) {
        
        print("updateSearchResults")
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            
            var sectionsPositionDict : [String: Int] = [:]
            sectionTalksFiltered = []
            for sections in sectionTalks {
                for talkData in sections {
                    if talkData.title.lowercased().contains(searchText.lowercased()) {
                        
                        if sectionsPositionDict[talkData.section] == nil {
                            // new section seen.  create new array of talks for this section
                            sectionTalksFiltered.append([talkData])
                            sectionsPositionDict[talkData.section] = sectionTalksFiltered.count - 1
                        } else {
                            // section already exists.  add talk to the existing array of talks
                            let sectionPosition = sectionsPositionDict[talkData.section]
                            sectionTalksFiltered[sectionPosition!].append(talkData)
                        }
                    }
                }
            }
            
        } else {
            sectionTalksFiltered = sectionTalks
        }
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        print("filtering...")
        
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTalksFiltered.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionTalksFiltered[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle : String
        
        sectionTitle =  sectionTalksFiltered[section][0].section
        print(sectionTitle)
        
        return sectionTitle
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "UserTalksTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? UserTalksTableViewCell  else {
            fatalError("The dequeued cell is not an instance of UserTalksTableViewCell.")
        }
        
        
        
        return cell
    }
    
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        print("prepare to seque")
        guard let talkDetailViewController = segue.destination as? TalkViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        guard let selectedTalkCell = sender as? TalkTableViewCell else {
            fatalError("Unexpected sender:")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedTalkCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        
        let selectedTalk = sectionTalks[indexPath.section][indexPath.row]
        talkDetailViewController.talk = selectedTalk
        
    }
    
    
    
    
    
    
}
