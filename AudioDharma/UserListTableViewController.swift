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
    var selectedRow: Int = 0
    
    //MARK: Actions
    @IBAction func unwindToUserList(sender: UIStoryboardSegue) {
        
        print("unwindToUserList")

        if let sourceViewController = sender.source as? UserListViewController, let userList = sourceViewController.userList {
            
            if sourceViewController.editMode == true {
                TheDataModel.userLists[selectedRow].title = userList.title
                self.tableView.reloadData()
                
            } else {
                // Add a new user list.
                let newIndexPath = IndexPath(row: TheDataModel.userLists.count, section: 0)
                
                TheDataModel.userLists.append(userList)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                
            }
            
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    //
    // Pathways:
    // If Plus button  clicked, then add a User List (SHOWADDUSERLIST)
    // If Edit slider button clicked, then edit selected User List (SHOWUSEREDITLIST)
    // If a User List is selected, then show all talks in this list (SHOWUSERTALKS)
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       

        super.prepare(for: segue, sender: sender)
        
        
        switch(segue.identifier ?? "") {
            
        case "SHOWADDUSERLIST":
            os_log("New User List", log: OSLog.default, type: .debug)
            

        case "SHOWEDITUSERLIST":            
 
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let selectedUserList = TheDataModel.userLists[self.selectedRow]

            let userListViewController = navController.viewControllers.last as? UserListViewController

            
            userListViewController?.userList = selectedUserList
            userListViewController?.editMode = true
            print("selectedUserList: \(selectedUserList.title)  \(userListViewController?.userList)")


        case "SHOWUSERTALKS":
            print("SHOWUSERTALKS")
            guard let userTalkTableViewController = segue.destination as? UserTalkTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let selectedUserList = TheDataModel.userLists[self.selectedRow]
            
            var selectedTalks = [TalkData] ()
            for talkFileName in selectedUserList.talkFileNames {
                if let talk = TheDataModel.getTalkForName(name: talkFileName) {
                    print("List View FileName: ", talkFileName)
                    talk.isUserSelected = true
                    selectedTalks.append(talk)
                }
            }

            userTalkTableViewController.selectedTalks = selectedTalks

        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")

        }
 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return TheDataModel.userLists.count
       

    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "UserListTableViewCell"
        
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? UserListTableViewCell  else {
            fatalError("The dequeued cell is not an instance of UserListTableViewCell.")
        }
        
        print("row = \(indexPath.row)")

        let userList = TheDataModel.userLists[indexPath.row]
        
        cell.title.text = userList.title
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            
            let refreshAlert = UIAlertController(title: "Delete List", message: "Are you sure?", preferredStyle: UIAlertControllerStyle.alert)
 

            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                self.tableView.isEditing = false

                print("Handle Ok logic here")
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                self.tableView.isEditing = false

                print("Handle Cancel Logic here")
            }))
            
            self.present(refreshAlert, animated: true, completion: nil)

        }
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit Title") { (action, indexPath) in
            
            self.selectedRow = indexPath.row
            self.performSegue(withIdentifier: "SHOWEDITUSERLIST", sender: self)
            // share item at indexPath
            self.tableView.isEditing = false
        }
        
        
        edit.backgroundColor = UIColor.blue
        
        return [delete, edit]
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didselectrow")
        self.selectedRow = indexPath.row
        
        self.performSegue(withIdentifier: "SHOWUSERTALKS", sender: self)
        
    }



}

