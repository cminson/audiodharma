//
//  SelectUserListTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/29/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class SelectUserListTableViewController: UITableViewController {
    
    //MARK: Properties
    var selectedSection: Int = 0
    var selectedRow: Int = 0

    
    //MARK: Navigation

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

     
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return TheDataModel.userLists.count

    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAt")
        let cellIdentifier = "SelectUserListTableViewCell"
        
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SelectUserListTableViewCell  else {
            fatalError("The dequeued cell is not an instance of SelectUserListTableViewCell.")
        }
        
        print("section = \(indexPath.section) row = \(indexPath.row)")
        let userList = TheDataModel.userLists[indexPath.row]
        
        cell.title.text = userList.title
        
        return cell
        
    }

   
}
