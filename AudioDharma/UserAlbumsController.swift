//
//  UserAlbumsController.swift
//  AudioDharma
//
//  Created by Christopher on 6/27/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log


class UserAlbumsController: UITableViewController {
    
    //MARK: Properties
    var SelectedRow: Int = 0
    

    // MARK: Init
    override func viewDidLoad() {
        
        super.viewDidLoad()
                
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

    
    // MARK: Navigation
    //
    // Segue pathways:
    // If Plus button  clicked, then add a User List (SHOWADDUSERLIST)
    // If Edit slider button clicked, then edit selected User List (SHOWUSEREDITLIST)
    // If a User List is selected, then show all talks in this list (SHOWUSERTALKS)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
        super.prepare(for: segue, sender: sender)
        
        print("UserAlbumsSegue: ", segue.identifier)
        switch(segue.identifier ?? "") {
            
        case "DISPLAY_ADD_ALBUM":     // Add a New User Album
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            if let controller = navController.viewControllers.last as? UserAlbumEditController {
                controller.EditMode = false
            }
            
        case "DISPLAY_EDIT_ALBUM":    // Edit an existing User Album
 
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let selectedUserAlbum = TheDataModel.UserAlbums[SelectedRow]

            if let controller = navController.viewControllers.last as? UserAlbumEditController {
                controller.UserAlbum = selectedUserAlbum
                controller.title = "Edit User List"
                controller.EditMode = true
            }

        case "DISPLAY_USER_TALKS":   // Display all talks within the current User List
            guard let controller = segue.destination as? UserTalkController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            // set the userList that we want to show talks for
            //userTalkTableViewController.selectedUserList = TheDataModel.userLists[self.selectedRow]
            controller.SelectedUserListIndex = SelectedRow

            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")

        }
    }
    
    @IBAction func unwindAlbumEditToUserAlbums(sender: UIStoryboardSegue) {
        
        if let controller = sender.source as? UserAlbumEditController, let userAlbum = controller.UserAlbum {
            
            // if edit mode = true, then this is an edit of an existing user album
            // otherwise we are adding a new user album
            if controller.EditMode == true {
                TheDataModel.UserAlbums[SelectedRow].Title = userAlbum.Title
                TheDataModel.UserAlbums[SelectedRow].Image = userAlbum.Image
                
            } else {
                let newIndexPath = IndexPath(row: TheDataModel.UserAlbums.count, section: 0)
                
                TheDataModel.UserAlbums.append(userAlbum)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            
            TheDataModel.saveUserAlbumData()
            TheDataModel.computeUserAlbumStats()
            self.tableView.reloadData()
            TheDataModel.RootController.tableView.reloadData()
        }
    }


    // MARK: Table Data Source
    override func viewWillAppear(_ animated: Bool) {
        
        TheDataModel.computeUserAlbumStats()
        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return TheDataModel.UserAlbums.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("AlbumCell", owner: self, options: nil)?.first as! AlbumCell
        
        let userAlbum = TheDataModel.UserAlbums[indexPath.row]
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

                TheDataModel.UserAlbums.remove(at: indexPath.row)
                TheDataModel.saveUserAlbumData()
                self.tableView.reloadData()
                TheDataModel.RootController.tableView.reloadData()

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
        
        let movedAlbum = TheDataModel.UserAlbums[sourceIndexPath.row]
        TheDataModel.UserAlbums.remove(at: sourceIndexPath.row)
        TheDataModel.UserAlbums.insert(movedAlbum, at: destinationIndexPath.row)
        print("\(sourceIndexPath.row) => \(destinationIndexPath.row) \(movedAlbum.Title)")
      
    }
   
}

