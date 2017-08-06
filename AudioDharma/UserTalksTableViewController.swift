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
    var SelectedUserListIndex: Int = 0         // index into the datamodel userlist array, the value is the selected user list to display
    var SelectedTalks: [TalkData]  = [TalkData] ()  // the talk list for the selectedUserList
    var SelectedRow: Int = 0
    
    
    // MARK: Init
    override func viewDidLoad() {
        print("UserTalkTableViewController: viewDidLoad")
        super.viewDidLoad()
        
        //userTalkTableViewController.selectedUserList = TheDataModel.userLists[self.selectedRow]

        // turn the name-only array of talks into an array of actual TALKDATAs (ie: look up name in Model dict)
        for talkFileName in TheDataModel.UserLists[SelectedUserListIndex].TalkFileNames {
            print(talkFileName)
            if let talk = TheDataModel.getTalkForName(name: talkFileName) {
                SelectedTalks.append(talk)
            } else {
                print("ERROR: could not locate \(talkFileName)")
            }
        }
        
        self.title = TheDataModel.UserLists[SelectedUserListIndex].Title
        //self.tableView.isEditing = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

        
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier ?? "" {
            
        case "DISPLAY_EDITUSERTALKS":  // edit the talks within this User List
            
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let addTalkTableViewController = navController.viewControllers.last as? UserEditTalksController
            addTalkTableViewController?.SelectedTalks =  SelectedTalks
            
        case "DISPLAY_TALKPLAYER":   // play the selected talk in the MP3
            
            guard let navController = segue.destination as? UINavigationController, let playTalkController = navController.viewControllers.last as? PlayTalkController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }

            playTalkController.TalkList = SelectedTalks
            playTalkController.CurrentTalkRow = SelectedRow
            
        case "DISPLAY_NOTE":
            guard let navController = segue.destination as? UINavigationController, let noteViewController = navController.viewControllers.last as? NoteViewController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            
            //print(self.selectedSection, self.selectedRow)
            let talk = SelectedTalks[SelectedRow]
            noteViewController.TalkFileName = talk.FileName
            noteViewController.title = talk.Title
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier!)")
        }
     }
    
    @IBAction func unwindEditTalkList(sender: UIStoryboardSegue) {  // called from UserAddTalkViewController
        
        //
        // gather the talks selected in Add Talks and store them off
        //
        if let controller = sender.source as? UserEditTalksController {
            
            SelectedTalks = controller.SelectedTalks
            
            // unpack the  selected talks into talkFileNames (an array of talk filenames strings)
            var talkFileNames = [String]()
            for talk in SelectedTalks {
                talkFileNames.append(talk.FileName)
                //print("adding: ", talk.fileName)
                
            }
            
            // save the resulting array into the userlist and then persist into storage
            TheDataModel.UserLists[SelectedUserListIndex].TalkFileNames = talkFileNames
            
            // DEBUG
            let test1 = TheDataModel.UserLists[SelectedUserListIndex].TalkFileNames
            for talk in test1 {
                print("SAVED: ", talk)
                
            }
            TheDataModel.saveUserListData()
            TheDataModel.computeUserListStats()
            self.tableView.reloadData()
        }
    }
    
    @IBAction func unwindNotesView(sender: UIStoryboardSegue) {   // called from NotesController

        if let controller = sender.source as? NoteViewController {
            
            if controller.TextHasBeenChanged == true {
                
                controller.TextHasBeenChanged = false   // just to make sure ...
                
                let talk = SelectedTalks[SelectedRow]
                let noteText  = controller.noteTextView.text!
                print("noteText = ", noteText)
                
                //
                // if there is a note for this talk fileName, then save it in the note dictionary
                // otherwise clear this note dictionary entry
                if (noteText.characters.count > 2) {
                    TheDataModel.UserNotes[talk.FileName] = UserNoteData(notes: noteText)
                } else {
                    TheDataModel.UserNotes[talk.FileName] = nil
                }
                TheDataModel.saveUserNoteData()
                let indexPath = IndexPath(row: SelectedRow, section: 0)
                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
                
            }
            
        }
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return SelectedTalks.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("TalkCell", owner: self, options: nil)?.first as! TalkCell
        let talk = SelectedTalks[indexPath.row]

        // if there is a Note entry for this talk, then show the note icon in cell
        if let _ = TheDataModel.UserNotes[talk.FileName] {
            cell.noteImage.image = UIImage(named: "noteicon")!
        } else {
            cell.noteImage = nil
        }

        cell.title.text = talk.Title
        cell.speakerPhoto.image = talk.SpeakerPhoto
        cell.duration.text = talk.Duration
        cell.date.text = talk.Date

        return cell
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedRow = indexPath.row
        self.performSegue(withIdentifier: "DISPLAY_TALKPLAYER", sender: self)
    }
 
    #if WANTEDITING
    // REMEMBER: if editing method below is active, then left-swipe Share will not work
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        return false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let movedTalk = SelectedTalks[sourceIndexPath.row]
        SelectedTalks.remove(at: sourceIndexPath.row)
        SelectedTalks.insert(movedTalk, at: destinationIndexPath.row)
        print("\(sourceIndexPath.row) => \(destinationIndexPath.row) \(movedTalk.title)")
        
        
        // unpack the  selected talks into talkFileNames (an array of talk filenames strings)
        var talkFileNames = [String]()
        for talk in SelectedTalks {
            talkFileNames.append(talk.fileName)
        }
        
        // save the resulting array into the userlist and then persist into storage
        TheDataModel.UserLists[SelectedUserListIndex].talkFileNames = talkFileNames
        TheDataModel.saveUserListData()
      }
    #endif
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        print("EditForAction")
        SelectedRow = indexPath.row
        
        let noteTalk = UITableViewRowAction(style: .normal, title: "Notes") { (action, indexPath) in
            self.viewEditNote()
        }

        let shareTalk = UITableViewRowAction(style: .normal, title: "Share") { (action, indexPath) in
            self.shareTalk()
        }
        return [shareTalk, noteTalk]
    }
    
    
    //MARK: Share
    private func viewEditNote() {
        
        self.performSegue(withIdentifier: "DISPLAY_NOTE", sender: self)
    }
    
    private func shareTalk() {
        
        let sharedTalk = SelectedTalks[SelectedRow]
        TheDataModel.shareTalk(sharedTalk: sharedTalk, controller: self)
    }

}
