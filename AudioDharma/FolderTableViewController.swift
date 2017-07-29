//
//  FoldersTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class FoldersTableViewController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    //MARK: Properties
    var SelectedSection: Int = 0
    var SelectedRow: Int = 0
    var FolderSections: [[FolderData]] = []
    var FilteredFolderSections:  [[FolderData]] = []
    let SearchController = UISearchController(searchResultsController: nil)
    var SearchText: String = ""

    
    // MARK: Init
    override func viewDidLoad() {
        
        self.tableView.delegate = self
        
        TheDataModel.loadData()
        super.viewDidLoad()

        FilteredFolderSections = TheDataModel.FolderSections
        
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
            //let currentTitle = self.filteredFolderSections[self.selectedSection][self.selectedRow]
            let folder = FilteredFolderSections[SelectedSection][SelectedRow]
            talkTableViewController.Content = folder.content
            talkTableViewController.title = folder.title
            
        case "SHOWUSERLISTS":
            guard let _ = segue.destination as? UserListTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
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
        
        print("updateSearchResults")
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            
            var sectionsPositionDict : [String: Int] = [:]
            FilteredFolderSections = []
            for sections in TheDataModel.FolderSections {
                for folderData in sections {
                    if folderData.title.lowercased().contains(searchText.lowercased()) {
                        
                        if sectionsPositionDict[folderData.section] == nil {
                            // new section seen.  create new array of folders for this section
                            FilteredFolderSections.append([folderData])
                            sectionsPositionDict[folderData.section] = FilteredFolderSections.count - 1
                        } else {
                            // section already exists.  add folder to the existing array of talks
                            let sectionPosition = sectionsPositionDict[folderData.section]
                            FilteredFolderSections[sectionPosition!].append(folderData)
                        }
                    }
                }
            }            
        } else {
            FilteredFolderSections = TheDataModel.FolderSections
        }
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        print("filtering...")
    }


    // MARK: Table Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return FilteredFolderSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        //print("Number of rows in section: \(TheDataModel.folderSections[section].count)")
        return FilteredFolderSections[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return FilteredFolderSections[section][0].section
    }
    
    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {

        let header = view as! UITableViewHeaderFooterView
        
        view.tintColor = UIColor.black
        header.textLabel?.textColor = UIColor.white
        header.textLabel?.textAlignment = NSTextAlignment.center
    }
    
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "FolderTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FolderTableViewCell  else {
            fatalError("The dequeued cell is not an instance of FolderTableViewCell.")
        }
        
        //print("section = \(indexPath.section) row = \(indexPath.row)")
        let folder = FilteredFolderSections[indexPath.section][indexPath.row]
    

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
        
        SelectedSection = indexPath.section
        SelectedRow = indexPath.row
        
        let folder = FilteredFolderSections[indexPath.section][indexPath.row]
        if (folder.content == "CUSTOM") {
            self.performSegue(withIdentifier: "SHOWUSERLISTS", sender: self)
        } else {
            self.performSegue(withIdentifier: "SHOWTALKS", sender: self)
        }
    }
    
}
