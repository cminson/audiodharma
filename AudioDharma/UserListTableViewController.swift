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
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       

        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "AddUserList":
            os_log("New User List", log: OSLog.default, type: .debug)
            

        case "EditUserList":
            print("EditUserList")
            
 
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let userListViewController = navController.viewControllers.last as? UserListViewController

            let selectedUserList = TheDataModel.userLists[selectedRow]
            
            userListViewController?.userList = selectedUserList
            userListViewController?.editMode = true
            print("selectedUserList: \(selectedUserList.title)  \(userListViewController?.userList)")


            
        default:
            //fatalError("Unexpected Segue Identifier; \(segue.identifier)")
            print("Error")
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
            self.performSegue(withIdentifier: "EditUserList", sender: self)
            // share item at indexPath
            self.tableView.isEditing = false
        }
        
        
        edit.backgroundColor = UIColor.blue
        
        return [delete, edit]
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didselectrow")
        
        //self.selectedSection = indexPath.section
        //self.selectedRow = indexPath.row
        
        /*
        let folder = TheDataModel.folderSections[indexPath.section][indexPath.row]
        if (folder.content == "CUSTOM") {
            self.performSegue(withIdentifier: "ShowCustomLists", sender: self)
        } else {
            self.performSegue(withIdentifier: "ShowTalks", sender: self)
            
        }
 */
        
    }


    /*
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]?  {
        // 1
        var shareAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Share" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            // 2
            let shareMenu = UIAlertController(title: nil, message: "Share using", preferredStyle: .ActionSheet)
            
            let twitterAction = UIAlertAction(title: "Twitter", style: UIAlertActionStyle.Default, handler: nil)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
            
            shareMenu.addAction(twitterAction)
            shareMenu.addAction(cancelAction)
            
            
            self.presentViewController(shareMenu, animated: true, completion: nil)
        })
        // 3
        var rateAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Rate" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            // 4
            let rateMenu = UIAlertController(title: nil, message: "Rate this App", preferredStyle: .ActionSheet)
            
            let appRateAction = UIAlertAction(title: "Rate", style: UIAlertActionStyle.Default, handler: nil)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
            
            rateMenu.addAction(appRateAction)
            rateMenu.addAction(cancelAction)
            
            
            self.presentViewController(rateMenu, animated: true, completion: nil)
        })
        // 5
        return [shareAction,rateAction]
    }}
 */

}

