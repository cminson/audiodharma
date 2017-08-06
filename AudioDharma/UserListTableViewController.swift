//
//  UserListTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/27/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log


class UserListTableViewController: UITableViewController {
    
    //MARK: Properties
    var SelectedRow: Int = 0
    
    // MARK: Init
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // TDB DEV DONT NEED?
        /*
        let savedUserList = TheDataModel.loadUserListData()
        TheDataModel.UserLists = savedUserList
        print("UserListTableViewController: getting userLists: \(savedUserList) ")
         */
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

    
    // MARK: Navigation
    //
    // Seque pathways:
    // If Plus button  clicked, then add a User List (SHOWADDUSERLIST)
    // If Edit slider button clicked, then edit selected User List (SHOWUSEREDITLIST)
    // If a User List is selected, then show all talks in this list (SHOWUSERTALKS)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "SHOWADDUSERLIST":     // Add a New User List
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            if let addEditUserListController = navController.viewControllers.last as? AddEditUserListController {
                addEditUserListController.EditMode = false
            }
            
        case "SHOWEDITUSERLIST":    // Edit an existing User List
 
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let selectedUserList = TheDataModel.UserLists[SelectedRow]

            if let addEditUserListController = navController.viewControllers.last as? AddEditUserListController {
                addEditUserListController.UserList = selectedUserList
                addEditUserListController.title = "Edit User List"
                addEditUserListController.EditMode = true
            }

        case "SHOWUSERTALKS":   // Display all talks within the current User List
            guard let userTalkTableViewController = segue.destination as? UserTalkTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            // set the userList that we want to show talks for
            //userTalkTableViewController.selectedUserList = TheDataModel.userLists[self.selectedRow]
            userTalkTableViewController.SelectedUserListIndex = SelectedRow

            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")

        }
    }
    
    @IBAction func unwindToUserList(sender: UIStoryboardSegue) {
        
        if let addEditUserListController = sender.source as? AddEditUserListController, let userList = addEditUserListController.UserList {
            
            // if edit mode = true, then this is an edit of an existing user list
            // otherwise we are adding a new user list
            if addEditUserListController.EditMode == true {
                TheDataModel.UserLists[SelectedRow].Title = userList.Title
                TheDataModel.UserLists[SelectedRow].Image = userList.Image
                TheDataModel.saveUserListData()
                self.tableView.reloadData()
                
            } else {
                let newIndexPath = IndexPath(row: TheDataModel.UserLists.count, section: 0)
                
                TheDataModel.UserLists.append(userList)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                TheDataModel.saveUserListData()
            }
        }
    }


    // MARK: Table Data Source
    override func viewWillAppear(_ animated: Bool) {
        
        TheDataModel.computeUserListStats()
        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return TheDataModel.UserLists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("FolderCell", owner: self, options: nil)?.first as! FolderCell
        
        let userList = TheDataModel.UserLists[indexPath.row]
        cell.title.text = userList.Title
        cell.listImage.contentMode = UIViewContentMode.scaleAspectFit
        cell.listImage.image = userList.Image
        
        let folderStats = TheDataModel.getFolderStats(content: userList.Title)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value:folderStats.totalTalks))
        cell.statTalkCount.text = formattedNumber
        
        
        cell.statTotalTime.text = folderStats.durationDisplay

        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            
            let refreshAlert = UIAlertController(title: "Delete Album", message: "Are you sure?", preferredStyle: UIAlertControllerStyle.alert)
 

            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                self.tableView.isEditing = false

                TheDataModel.UserLists.remove(at: indexPath.row)
                TheDataModel.saveUserListData()
                self.tableView.reloadData()
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                self.tableView.isEditing = false
            }))
            
            self.present(refreshAlert, animated: true, completion: nil)
        }
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
            
            self.SelectedRow = indexPath.row
            self.performSegue(withIdentifier: "SHOWEDITUSERLIST", sender: self)
            // share item at indexPath
            self.tableView.isEditing = false
        }
    
        edit.backgroundColor = UIColor.blue
        
        return [delete, edit]
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedRow = indexPath.row
        self.performSegue(withIdentifier: "SHOWUSERTALKS", sender: self)
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let movedFolder = TheDataModel.UserLists[sourceIndexPath.row]
        TheDataModel.UserLists.remove(at: sourceIndexPath.row)
        TheDataModel.UserLists.insert(movedFolder, at: destinationIndexPath.row)
        print("\(sourceIndexPath.row) => \(destinationIndexPath.row) \(movedFolder.Title)")
      
    }
   
}

