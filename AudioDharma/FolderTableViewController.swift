//
//  FoldersTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class FoldersTableViewController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
//    class FoldersTableViewController: UITableViewController {
    
    
    //MARK: Properties
    var selectedSection: Int = 0
    var selectedRow: Int = 0
    var folderSections: [[FolderData]] = []
    var filteredFolderSections:  [[FolderData]] = []
    let searchController = UISearchController(searchResultsController: nil)

    //var searchController: UISearchController
    
    /*
    //MARK: Init
    required init?(coder aDecoder: NSCoder) {
        self.searchController = UISearchController(searchResultsController: nil)
        super.init(coder: aDecoder)


    }
 */

    override func viewDidLoad() {
        self.tableView.delegate = self
        super.viewDidLoad()

        self.folderSections = TheDataModel.folderSections
        self.filteredFolderSections = self.folderSections
        
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.delegate = self
        searchController.delegate = self

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: UISearchBarDelegate
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
    

    func updateSearchResults(for searchController: UISearchController) {
        
        print("updateSearchResults")
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            
            var sectionsPositionDict : [String: Int] = [:]
            self.filteredFolderSections = []
            for sections in self.folderSections {
                for folderData in sections {
                    if folderData.title.lowercased().contains(searchText.lowercased()) {
                        
                        if sectionsPositionDict[folderData.section] == nil {
                            // new section seen.  create new array of folders for this section
                            self.filteredFolderSections.append([folderData])
                            sectionsPositionDict[folderData.section] = self.filteredFolderSections.count - 1
                        } else {
                            // section already exists.  add folder to the existing array of talks
                            let sectionPosition = sectionsPositionDict[folderData.section]
                            self.filteredFolderSections[sectionPosition!].append(folderData)
                        }
                    }
                }
            }
            
        } else {
            self.filteredFolderSections = self.folderSections
        }
        tableView.reloadData()
    }

    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        print("filtering...")
        
    }



    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.filteredFolderSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        //print("Number of rows in section: \(self.folderSections[section].count)")
        return self.filteredFolderSections[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle : String
        
        sectionTitle =  self.filteredFolderSections[section][0].section
        //print(sectionTitle)
        
        return sectionTitle
        
    }
    
    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        //print ("enter: willDisplayHeaderView")

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
        let folder = self.filteredFolderSections[indexPath.section][indexPath.row]
    
        
        if folder.image.characters.count > 0 {
            cell.listImage.image = UIImage(named: folder.image) ?? UIImage(named: "defaultPhoto")!
        } else {
            cell.listImage.image = UIImage(named: folder.title) ?? UIImage(named: "defaultPhoto")!
            
        }

        cell.title.text = folder.title
        cell.listImage.contentMode = UIViewContentMode.scaleAspectFit
        
        let folderStats = TheDataModel.getFolderStats(content: folder.content)

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value:folderStats.totalTalks))
        cell.statTalkCount.text = formattedNumber
        
        
        cell.statTotalTime.text = folderStats.durationDisplay
        return cell
        
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didselectrow")
        
        self.selectedSection = indexPath.section
        self.selectedRow = indexPath.row
        
        let folder = self.filteredFolderSections[indexPath.section][indexPath.row]
        if (folder.content == "CUSTOM") {
            self.performSegue(withIdentifier: "SHOWUSERLISTS", sender: self)
        } else {
            self.performSegue(withIdentifier: "SHOWTALKS", sender: self)
            
        }

    }
    
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        print("prepare to seque")

        
        let folder = self.filteredFolderSections[self.selectedSection][self.selectedRow]
        print("Folder content: \(folder.content)")
   
        searchController.isActive = false
        switch segue.identifier ?? "" {
            
        case "SHOWTALKS":
            guard let talkTableViewController = segue.destination as? TalkTableViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            //let currentTitle = self.filteredFolderSections[self.selectedSection][self.selectedRow]
            talkTableViewController.content = folder.content
            talkTableViewController.currentTitle = folder.title
            
        case "SHOWUSERLISTS":

            guard let _ = segue.destination as? UserListTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }


            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier!)")
        }

        
    }

    
  
}
