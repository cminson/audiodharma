//
//  SpeakerController.swift
//  AudioDharma
//
//  Created by Christopher on 8/3/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class SpeakerController: BaseController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    //MARK: Properties
    var SelectedRow: Int = 0
    var FilteredAlbums:  [AlbumData] = []
    
    // MARK: Init
    override func viewDidLoad() {
        
        self.tableView.delegate = self
        
        super.viewDidLoad()
        
        FilteredAlbums = TheDataModel.SpeakerAlbums
        
        SearchController.searchResultsUpdater = self
        SearchController.searchBar.delegate = self
        SearchController.delegate = self
        
        SearchController.hidesNavigationBarDuringPresentation = false
        SearchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = SearchController.searchBar
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        SearchController.isActive = false
    }

    deinit {
        
        // this view tends to hang around in the parent.  this clears it
        SearchController.view.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        let backItem = UIBarButtonItem()
        backItem.title = "  "
        navigationItem.backBarButtonItem = backItem
        
        switch segue.identifier ?? "" {
        case "DISPLAY_RESUMETALK":
            guard let navController = segue.destination as? UINavigationController, let playTalkController = navController.viewControllers.last as? PlayTalkController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            
            playTalkController.ResumingLastTalk = true
            playTalkController.CurrentTalkTime = ResumeTalkTime
            playTalkController.CurrentTalk = ResumeTalk
            
        case "DISPLAY_TALKS":
            guard let controller = segue.destination as? TalkController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            let album = FilteredAlbums[SelectedRow]
            controller.Content = album.Content
            controller.title = album.Title
            
        case "DISPLAY_HELP_PAGE":
            guard let navController = segue.destination as? UINavigationController, let _ = navController.viewControllers.last as? HelpController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
        case "DISPLAY_DONATIONS":
            guard let _ = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier!)")
        }
        
        // dismiss any searching - must do this prior to executing the segue
        SearchText = SearchController.searchBar.text!   //  save this off, so as to restore search state upon return
        SearchController.isActive = false
    }
    
    
    // MARK: UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            
            FilteredAlbums = []
            for albumData in TheDataModel.SpeakerAlbums {
                if albumData.Title.lowercased().contains(searchText.lowercased()) {
                        FilteredAlbums.append(albumData)
                }
            }
        } else {
            
            FilteredAlbums = TheDataModel.SpeakerAlbums
        }
        tableView.reloadData()
    }
    
    
    // MARK: Table Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return FilteredAlbums.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("AlbumCell", owner: self, options: nil)?.first as! AlbumCell
        
        
        //print("section = \(indexPath.section) row = \(indexPath.row)")
        let album = FilteredAlbums[indexPath.row]
        
        cell.title.text = album.Title
        cell.albumCover.contentMode = UIView.ContentMode.scaleAspectFit
        if album.Image.count > 0 {
            cell.albumCover.image = UIImage(named: album.Image) ?? UIImage(named: "defaultPhoto")!
        } else {
            cell.albumCover.image = UIImage(named: album.Title) ?? UIImage(named: "defaultPhoto")!
        }
        
        let albumStats = TheDataModel.getAlbumStats(content: album.Content)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value: albumStats.totalTalks))
        cell.statTalkCount.text = formattedNumber
        
        
        cell.statTotalTime.text = albumStats.durationDisplay
        
        cell.title.textColor = MAIN_FONT_COLOR
        cell.statTalkCount.textColor = SECONDARY_FONT_COLOR
        cell.statTotalTime.textColor = SECONDARY_FONT_COLOR
        return cell
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedRow = indexPath.row
        self.performSegue(withIdentifier: "DISPLAY_TALKS", sender: self)
    }
    
}
