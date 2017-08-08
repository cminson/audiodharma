//
//  UserAlbumsController.swift
//  AudioDharma
//
//  Created by Christopher on 6/27/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log


class UserAlbumsController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating   {
    
    //MARK: Properties
    var SelectedRow: Int = 0
    var FilteredUserAlbums:  [UserAlbumData] = []
    let SearchController = UISearchController(searchResultsController: nil)
    var SearchText: String = ""

    
    // MARK: Init
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        SearchController.searchResultsUpdater = self
        SearchController.searchBar.delegate = self
        SearchController.delegate = self
        
        SearchController.hidesNavigationBarDuringPresentation = false
        SearchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = SearchController.searchBar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        FilteredUserAlbums = TheDataModel.UserAlbums
        TheDataModel.computeUserAlbumStats()
        
        if SearchText.characters.count > 0 {
            SearchController.searchBar.text! = SearchText
        }
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        SearchController.isActive = false
    }


    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        
        // this view tends to hang around in the parent.  this clears it
        SearchController.view.removeFromSuperview()
    }

    
    // MARK: Navigation
    //
    // Segue pathways:
    // If Plus button  clicked, then add a User List (SHOWADDUSERLIST)
    // If Edit slider button clicked, then edit selected User List (SHOWUSEREDITLIST)
    // If a User List is selected, then show all talks in this list (SHOWUSERTALKS)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "DISPLAY_ADD_ALBUM":     // Add a New User Album
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            if let controller = navController.viewControllers.last as? UserAlbumEditController {
                controller.AddingNewAlbum = true
            }
            
        case "DISPLAY_EDIT_ALBUM":    // Edit an existing User Album
 
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let selectedUserAlbum = FilteredUserAlbums[SelectedRow]

            if let controller = navController.viewControllers.last as? UserAlbumEditController {
                controller.UserAlbum = selectedUserAlbum
                controller.title = "Edit User List"
                controller.AddingNewAlbum = false
            }

        case "DISPLAY_USER_TALKS":   // Display all talks within the current User List
            guard let controller = segue.destination as? UserTalkController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            // set the userAlbum  that we want to show talks for
            let selectedUserAlbum = FilteredUserAlbums[SelectedRow]
            controller.UserAlbum = selectedUserAlbum

            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")

        }
    }
    
    @IBAction func unwindAlbumEditToUserAlbums(sender: UIStoryboardSegue) {
        
        if let controller = sender.source as? UserAlbumEditController, let controllerUserAlbum = controller.UserAlbum {
            
            // if true, adding a new album.  otherwise editing an existing
            if controller.AddingNewAlbum == true {
                let newIndexPath = IndexPath(row: FilteredUserAlbums.count, section: 0)
                
                FilteredUserAlbums.append(controllerUserAlbum)
                TheDataModel.addToUserAlbums(album: controllerUserAlbum)
                tableView.insertRows(at: [newIndexPath], with: .automatic)

            } else {
                FilteredUserAlbums[SelectedRow] = controllerUserAlbum
                //userAlbum.Title = controllerUserAlbum.Title
                //userAlbum.Image = controllerUserAlbum.Image
                TheDataModel.updateUserAlbum(updatedAlbum: controllerUserAlbum)
                
            }
            
            TheDataModel.saveUserAlbumData()
            TheDataModel.computeUserAlbumStats()
            self.tableView.reloadData()
            //TheDataModel.RootController.tableView.reloadData()
        }
    }
    
     
    // MARK: UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            
            FilteredUserAlbums = []
            for album in TheDataModel.UserAlbums {
                if album.Title.lowercased().contains(searchText.lowercased()) {
                    FilteredUserAlbums.append(album)
                }
            }
        } else {
            FilteredUserAlbums = TheDataModel.UserAlbums
        }
        tableView.reloadData()
    }
    

    // MARK: Table Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return FilteredUserAlbums.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("AlbumCell", owner: self, options: nil)?.first as! AlbumCell
        
        let userAlbum = FilteredUserAlbums[indexPath.row]
        cell.title.text = userAlbum.Title
        cell.albumCover.contentMode = UIViewContentMode.scaleAspectFit
        cell.albumCover.image = userAlbum.Image
        
        let albumStats = TheDataModel.getAlbumStats(content: userAlbum.Content)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value: albumStats.totalTalks))
        cell.statTalkCount.text = formattedNumber
        
        
        cell.statTotalTime.text = albumStats.durationDisplay

        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            
            let refreshAlert = UIAlertController(title: "Delete Album", message: "Are you sure?", preferredStyle: UIAlertControllerStyle.alert)
 

            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                self.tableView.isEditing = false

                self.FilteredUserAlbums.remove(at: indexPath.row)
                
                TheDataModel.saveUserAlbumData()
                TheDataModel.computeUserAlbumStats()

                self.tableView.reloadData()
                //TheDataModel.RootController.tableView.reloadData()
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                self.tableView.isEditing = false
            }))
            
            self.present(refreshAlert, animated: true, completion: nil)
        }
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
            
            self.SelectedRow = indexPath.row
            self.performSegue(withIdentifier: "DISPLAY_EDIT_ALBUM", sender: self)
            // share item at indexPath
            self.tableView.isEditing = false
        }
    
        edit.backgroundColor = UIColor.blue
        
        return [delete, edit]
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedRow = indexPath.row
        self.performSegue(withIdentifier: "DISPLAY_USER_TALKS", sender: self)
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let movedAlbum = FilteredUserAlbums[sourceIndexPath.row]
        FilteredUserAlbums.remove(at: sourceIndexPath.row)
        FilteredUserAlbums.insert(movedAlbum, at: destinationIndexPath.row)
        print("\(sourceIndexPath.row) => \(destinationIndexPath.row) \(movedAlbum.Title)")
      
    }
   
}

