//
//  UserAddTalkTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/28/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class UserAddTalkViewController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    //MARK: Properties
    var sectionTalks: [[TalkData]] = []
    var filteredSectionTalks:  [[TalkData]] = []
    var content: String = ""
    var selectedSection: Int = 0
    var selectedRow: Int = 0
    var currentTitle: String = ""
    let searchController = UISearchController(searchResultsController: nil)
    
    
    //MARK: Actions
    @IBAction func unwindToTalkList(sender: UIStoryboardSegue) {
        /*
         if var sourceViewController = sender.source as? SelectUserListTableViewCell {
         print("entered unwindToTalkList")
         }
         */
    }
    
    // MARK: Init
    override func viewDidLoad() {
        
        //self.tableView.style = UITableViewStyle.UITableViewStylePlain
        print("TabletalkController: viewDidLoad")
        
        super.viewDidLoad()
        
        self.sectionTalks = TheDataModel.getTalks(content: content)
        self.filteredSectionTalks = self.sectionTalks
        
        //searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.delegate = self
        searchController.delegate = self
        
        self.title =  self.currentTitle
    }
    
    deinit {
        self.searchController.view.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        searchController.isActive = false
        
    }
    
    
    
    // MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //searchBar.resignFirstResponder()
    }
    
    
    // MARK: - UISearchControllerDelegate
    func presentSearchController(_ searchController: UISearchController) {
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
    }
    
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            
            var sectionsPositionDict : [String: Int] = [:]
            self.filteredSectionTalks = []
            for sections in self.sectionTalks {
                for talkData in sections {
                    if talkData.title.lowercased().contains(searchText.lowercased()) {
                        
                        if sectionsPositionDict[talkData.section] == nil {
                            // new section seen.  create new array of talks for this section
                            self.filteredSectionTalks.append([talkData])
                            sectionsPositionDict[talkData.section] = self.filteredSectionTalks.count - 1
                        } else {
                            // section already exists.  add talk to the existing array of talks
                            let sectionPosition = sectionsPositionDict[talkData.section]
                            self.filteredSectionTalks[sectionPosition!].append(talkData)
                        }
                    }
                }
            }
            
        } else {
            self.filteredSectionTalks = self.sectionTalks
        }
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.filteredSectionTalks.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredSectionTalks[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle : String
        
        sectionTitle =  self.filteredSectionTalks[section][0].section
        
        return sectionTitle
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //print("cellForRowAt")
        let cellIdentifier = "UserAddTalkTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? UserAddTalkTableViewCell  else {
            fatalError("The dequeued cell is not an instance of UserAddTalkTableViewCell.")
        }
        
        let talk = self.filteredSectionTalks[indexPath.section][indexPath.row]
        
        print(talk)
        print("talk title: ",talk.title)
        cell.title.text = talk.title
               
        
        return cell
    }
    
    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        //print ("enter: willDisplayHeaderView")
        
        let header = view as! UITableViewHeaderFooterView
        
        view.tintColor = UIColor.black
        header.textLabel?.textColor = UIColor.white
        header.textLabel?.textAlignment = NSTextAlignment.center
    }
    
    
    
    
    // MARK: - Navigation
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        print("prepare to seque")
        
        
    }
    

}