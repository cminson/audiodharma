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
    var SelectedUserListIndex: Int = 0         // into into the datamodel userlist array, the value is the selected user list to display
    var SelectedTalks: [TalkData]  = [TalkData] ()  // the talk list for the selectedUserList
    var SelectedRow: Int = 0
    
    
    // MARK: Init
    override func viewDidLoad() {
        print("UserTalkTableViewController: viewDidLoad")
        super.viewDidLoad()
        
        //userTalkTableViewController.selectedUserList = TheDataModel.userLists[self.selectedRow]

        // turn the name-only array of talks into an array of actual TALKDATAs (ie: look up name in Model dict)
        for talkFileName in TheDataModel.UserLists[SelectedUserListIndex].talkFileNames {
            if let talk = TheDataModel.getTalkForName(name: talkFileName) {
                SelectedTalks.append(talk)
            }
        }
        
        //self.title = selectedUserList.title
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
            
            let addTalkTableViewController = navController.viewControllers.last as? UserAddTalkViewController
            addTalkTableViewController?.SelectedTalks =  SelectedTalks
            
        case "DISPLAY_TALKPLAYER2":   // play the selected talk in the MP3
            
            guard let navController = segue.destination as? UINavigationController, let playTalkController = navController.viewControllers.last as? PlayTalkController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }

            playTalkController.TalkList = SelectedTalks
            playTalkController.CurrentTalkRow = SelectedRow
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier!)")
        }
     }
    
    @IBAction func unwindToUserTalkList(sender: UIStoryboardSegue) {   // called from Add Talks
        
        //
        // gather the talks selected in Add Talks and store them off
        //
        if let controller = sender.source as? UserAddTalkViewController {
            
            SelectedTalks = controller.SelectedTalks
            
            // unpack the  selected talks into talkFileNames (an array of talk filenames strings)
            var talkFileNames = [String]()
            for talk in SelectedTalks {
                talkFileNames.append(talk.fileName)
                //print("adding: ", talk.fileName)
                
            }
            
            // save the resulting array into the userlist and then persist into storage
            TheDataModel.UserLists[SelectedUserListIndex].talkFileNames = talkFileNames
            
            // DEBUG
            let test1 = TheDataModel.UserLists[SelectedUserListIndex].talkFileNames
            for talk in test1 {
                print("SAVED: ", talk)
                
            }
            TheDataModel.saveUserListData()
            TheDataModel.computeCustomUserListStats()
            self.tableView.reloadData()
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
        
        let cellIdentifier = "UserTalksTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? UserTalksTableViewCell  else {
            fatalError("The dequeued cell is not an instance of UserTalksTableViewCell.")
        }
        
        let talk = SelectedTalks[indexPath.row]
        cell.title.text = talk.title
        cell.speakerPhoto.image = talk.speakerPhoto
        cell.duration.text = talk.duration
        cell.date.text = talk.date

        return cell
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedRow = indexPath.row
        self.performSegue(withIdentifier: "DISPLAY_TALKPLAYER2", sender: self)
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
        
        let shareTalk = UITableViewRowAction(style: .normal, title: "Share") { (action, indexPath) in
            self.shareTalk()
        }
        return [shareTalk]
    }
    
    
    //MARK: Share
    private func shareTalk() {
        
        print("shareTalk")
        let sharedTalk = SelectedTalks[SelectedRow]
        let shareText = "\(sharedTalk.title)\n\(sharedTalk.speaker)   \(sharedTalk.date)\nShared from the iPhone AudioDharma app"
        
        let objectsToShare:URL = URL(string: sharedTalk.URL)!
        let sharedObjects:[AnyObject] = [objectsToShare as AnyObject, shareText as AnyObject]
        
        // set up activity view controller
        let activityViewController = UIActivityViewController(activityItems: sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
        
    }

}
