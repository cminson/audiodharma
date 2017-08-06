//
//  AlbumsTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit


class AlbumController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    //MARK: Properties
    var SelectedSection: Int = 0
    var SelectedRow: Int = 0
    var AlbumSections: [[AlbumData]] = []
    var FilteredAlbumSections:  [[AlbumData]] = []
    let SearchController = UISearchController(searchResultsController: nil)
    var SearchText: String = ""

    
    // MARK: Init
    override func viewDidLoad() {
        
        self.tableView.delegate = self
        TheDataModel.RootTableView = self  // this allows reloads when stats change
        
        TheDataModel.loadData()
        super.viewDidLoad()

        FilteredAlbumSections = TheDataModel.AlbumSections
        
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
        
        switch segue.identifier ?? "" {
            
        case "DISPLAY_TALKS":
            guard let controller = segue.destination as? TalkController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            //let currentTitle = self.filteredAlbumSections[self.selectedSection][self.selectedRow]
            let Album = FilteredAlbumSections[SelectedSection][SelectedRow]
            controller.Content = Album.content
            controller.title = Album.title
            
        case "DISPLAY_USER_ALBUMS":
            guard let _ = segue.destination as? UserAlbumsController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
        case "DISLAY_SPEAKER_ALBUMS":
            guard let _ = segue.destination as? SpeakerController else {
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
        //debug("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    
    // MARK: UISearchControllerDelegate
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
            FilteredAlbumSections = []
            for sections in TheDataModel.AlbumSections {
                for AlbumData in sections {
                    if AlbumData.title.lowercased().contains(searchText.lowercased()) {
                        
                        if sectionsPositionDict[AlbumData.section] == nil {
                            // new section seen.  create new array of Albums for this section
                            FilteredAlbumSections.append([AlbumData])
                            sectionsPositionDict[AlbumData.section] = FilteredAlbumSections.count - 1
                        } else {
                            // section already exists.  add Album to the existing array of talks
                            let sectionPosition = sectionsPositionDict[AlbumData.section]
                            FilteredAlbumSections[sectionPosition!].append(AlbumData)
                        }
                    }
                }
            }            
        } else {
            FilteredAlbumSections = TheDataModel.AlbumSections
        }
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
    }


    // MARK: Table Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return FilteredAlbumSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        return FilteredAlbumSections[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return FilteredAlbumSections[section][0].section
    }
    
    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {

        let header = view as! UITableViewHeaderFooterView
        
        view.tintColor = UIColor.black
        header.textLabel?.textColor = UIColor.white
        header.textLabel?.textAlignment = NSTextAlignment.center
    }
    
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("AlbumCell", owner: self, options: nil)?.first as! AlbumCell

        
        let Album = FilteredAlbumSections[indexPath.section][indexPath.row]
    
        cell.title.text = Album.title
        cell.albumCover.contentMode = UIViewContentMode.scaleAspectFit
        if Album.image.characters.count > 0 {
            cell.albumCover.image = UIImage(named: Album.image) ?? UIImage(named: "defaultPhoto")!
        } else {
            cell.albumCover.image = UIImage(named: Album.title) ?? UIImage(named: "defaultPhoto")!
        }
        
        let AlbumStats = TheDataModel.getAlbumStats(content: Album.content)
        print(Album.content, AlbumStats)

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value:AlbumStats.totalTalks))
        cell.statTalkCount.text = formattedNumber
        
        
        cell.statTotalTime.text = AlbumStats.durationDisplay
 
        return cell
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedSection = indexPath.section
        SelectedRow = indexPath.row
        
        let Album = FilteredAlbumSections[indexPath.section][indexPath.row]
        
        switch Album.content {
            
        case KEY_CUSTOMALBUMS:
            self.performSegue(withIdentifier: "DISPLAY_USER_ALBUMS", sender: self)
            
        case KEY_ALLSPEAKERS:
            self.performSegue(withIdentifier: "DISLAY_SPEAKER_ALBUMS", sender: self)
            
        case KEY_TALKHISTORY:
            self.performSegue(withIdentifier: "DISPLAY_TALKS", sender: self)

        default:
            self.performSegue(withIdentifier: "DISPLAY_TALKS", sender: self)
        }
    }
    
}
