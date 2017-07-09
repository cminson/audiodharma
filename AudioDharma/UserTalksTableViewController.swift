//
//
//  UserTalkTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/15/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

//
// Displays the talks that a user has stored in their User List
//
class UserTalkTableViewController: UITableViewController {
    
    // MARK: Properties
    var userListIndex: Int = 0
    var selectedTalks: [TalkData]  = [TalkData] ()  // contains the array of talks selected user list that called us
    var userListTitle: String = ""
    var selectedRow: Int = 0
    
    
    // MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selectedUserList = TheDataModel.userLists[userListIndex]
        for talkFileName in selectedUserList.talkFileNames {
            if let talk = TheDataModel.getTalkForName(name: talkFileName) {
                selectedTalks.append(talk)
            }
        }
        
        self.title = self.userListTitle
        self.tableView.isEditing = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: Actions
    @IBAction func unwindToUserTalkList(sender: UIStoryboardSegue) {
        
        if let controller = sender.source as? UserAddTalkViewController {
            
            print("UserTalksTableViewController: Unwind")
            self.selectedTalks = controller.selectedTalks
            
            var talkFileNames = [String]()
            for talk in self.selectedTalks {
                talkFileNames.append(talk.fileName)
                
            }
            
            TheDataModel.userLists[userListIndex].talkFileNames = talkFileNames
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier ?? "" {
            
        case "SHOWEDITUSERTALKS":
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let addTalkTableViewController = navController.viewControllers.last as? UserAddTalkViewController
            addTalkTableViewController?.selectedTalks =  selectedTalks
            print("SHOWEDITUSERTALKS: set selected talks")
            
        case "SHOWMP3PLAYER":
            guard let MP3Player = segue.destination as? TalkViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            let selectedTalk = self.selectedTalks[selectedRow]
            
            MP3Player.talk = selectedTalk
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier!)")
        }
     }

    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.selectedTalks.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "UserTalksTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? UserTalksTableViewCell  else {
            fatalError("The dequeued cell is not an instance of UserTalksTableViewCell.")
        }
        
        let talk = self.selectedTalks[indexPath.row]
        cell.title.text = talk.title
        cell.speakerPhoto.image = talk.speakerPhoto
        return cell
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.selectedRow = indexPath.row
        self.performSegue(withIdentifier: "SHOWMP3PLAYER", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let movedTalk = self.selectedTalks[sourceIndexPath.row]
        self.selectedTalks.remove(at: sourceIndexPath.row)
        self.selectedTalks.insert(movedTalk, at: destinationIndexPath.row)
        print("\(sourceIndexPath.row) => \(destinationIndexPath.row) \(movedTalk.title)")
        
        var talkFileNames = [String]()
        for talk in self.selectedTalks {
            talkFileNames.append(talk.fileName)
            
        }
        
        TheDataModel.userLists[userListIndex].talkFileNames = talkFileNames
       
        
 
    }
    
    /*
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let rowData = fruits[indexPath.row]
        return rowData.hasPrefix("A")
    }
 */
    
}
