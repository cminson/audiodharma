//
//
//  UserTalkTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/15/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class UserTalkTableViewController: UITableViewController {
    
    // MARK: Properties
    var selectedTalks: [TalkData]  = [TalkData] ()  // contains the array of talks selected user list that called us
    var userListTitle: String = ""
    
    
    // MARK: Actions
    @IBAction func unwindToUserTalkList(sender: UIStoryboardSegue) {
        
        print("unwindToUserTalkTableList")
        
        if let sourceViewController = sender.source as? UserAddTalkViewController {
            
                self.tableView.reloadData()
            
        }
        
    }
    
    // MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.userListTitle
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        print(segue.destination)
        switch segue.identifier ?? "" {
            
        case "SHOWEDITUSERTALKS":
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            
            let addTalkTableViewController = navController.viewControllers.last as? UserAddTalkViewController
            
            addTalkTableViewController?.selectedTalks =  selectedTalks

            
            
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier!)")
        }

        
    }
    
    
    
    
    
    
}
