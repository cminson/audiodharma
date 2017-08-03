//
//  SpeakersTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 8/3/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class SpeakersTableViewController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    //MARK: Properties
    var SelectedRow: Int = 0
    var FilteredFolders:  [FolderData] = []
    let SearchController = UISearchController(searchResultsController: nil)
    var SearchText: String = ""
    var Test: Int = 0
    

    // MARK: Init
    override func viewDidLoad() {
        
        self.tableView.delegate = self
        
        super.viewDidLoad()
        
        FilteredFolders = TheDataModel.SpeakerFolders
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        
        SearchController.isActive = false
    }
    
    
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        print("FolderTableView: Segue")
        switch segue.identifier ?? "" {
            
        case "SHOWTALKS":
            guard let talkTableViewController = segue.destination as? TalkTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            let folder = FilteredFolders[SelectedRow]
            talkTableViewController.Content = folder.content
            talkTableViewController.title = folder.title
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier!)")
        }
        
        // dismiss any searching - must do this prior to executing the segue
        SearchText = SearchController.searchBar.text!   //  save this off, so as to restore search state upon return
        SearchController.isActive = false
    }
    
    
    // MARK: UISearchBarDelegate
    func presentSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    
    // MARK: UISearchControllerDelegate
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
    
    
    // MARK: UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            
            FilteredFolders = []
            for folderData in TheDataModel.SpeakerFolders {
                if folderData.title.lowercased().contains(searchText.lowercased()) {
                        FilteredFolders.append(folderData)
                }
            }
        } else {
            
            FilteredFolders = TheDataModel.SpeakerFolders
        }
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        print("filtering...")
    }
    
    
    // MARK: Table Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return FilteredFolders.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("FolderCell", owner: self, options: nil)?.first as! FolderCell
        
        
        //print("section = \(indexPath.section) row = \(indexPath.row)")
        let folder = FilteredFolders[indexPath.row]
        
        cell.title.text = folder.title
        cell.listImage.contentMode = UIViewContentMode.scaleAspectFit
        if folder.image.characters.count > 0 {
            cell.listImage.image = UIImage(named: folder.image) ?? UIImage(named: "defaultPhoto")!
        } else {
            cell.listImage.image = UIImage(named: folder.title) ?? UIImage(named: "defaultPhoto")!
        }
        
        let folderStats = TheDataModel.getFolderStats(content: folder.content)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value:folderStats.totalTalks))
        cell.statTalkCount.text = formattedNumber
        
        
        cell.statTotalTime.text = folderStats.durationDisplay
        
        return cell
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedRow = indexPath.row
        self.performSegue(withIdentifier: "SHOWTALKS", sender: self)
    }
}
