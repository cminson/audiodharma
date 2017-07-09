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
    var displayTalks: [TalkData] = []
    var filteredTalks:  [TalkData] = []
    var selectedRow: Int = 0
    let searchController = UISearchController(searchResultsController: nil)
    
    var content: String = ""
    var currentTitle: String = ""
    var selectedTalks: [TalkData] = [TalkData] ()
    
    var selectedTalksByNameDict : [String: Bool] = [ : ]
    
    //MARK: Actions
    @IBAction func dismiss(_ sender: UIBarButtonItem) {   // cancel button clicked
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: Init
    override func viewDidLoad() {
        
        print("UserAddtalkTableView: viewDidLoad")
        //self.tableView.style = UITableViewStyle.UITableViewStylePlain
        
        super.viewDidLoad()
        
        // 
        // we display talks which are the union of the selectedTalks
        // and ALL talks.  selectedTalks are shown at the top. 
        //
        
        for talk in self.selectedTalks {
            selectedTalksByNameDict[talk.fileName] = true
            print("Selected Talk: ", talk.title)
            
        }
        
        /*
        var t1 = [1, 2, 3]
        var t2 = t1
        t2[1] = 5
        print(t1, t2)
 */
        
        let allTalks = TheDataModel.getTalks(content: KEY_ALLTALKS).joined()
        for talk in allTalks {
            selectedTalksByNameDict[talk.fileName] = false
        }
        for talk in self.selectedTalks {
            selectedTalksByNameDict[talk.fileName] = true
        }

        
        let setofAllTalks : Set<TalkData> = Set(allTalks)
        let setOfSelectedTalks : Set<TalkData> = Set(self.selectedTalks)
        let xorSet = setofAllTalks.symmetricDifference(setOfSelectedTalks)
        
        self.displayTalks = self.selectedTalks + Array(xorSet)
        self.filteredTalks = self.displayTalks
        
        //searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.delegate = self
        searchController.delegate = self
        
        self.title =  self.currentTitle
    
        //self.tableView.allowsMultipleSelection = true
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
            
            self.filteredTalks = []
            for talk in self.displayTalks {
                if talk.title.lowercased().contains(searchText.lowercased()) {
                    self.filteredTalks.append(talk)
                }
            }
        } else {
            self.filteredTalks = self.displayTalks
        }

        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.filteredTalks.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredTalks.count
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedRow = indexPath.row

        if let cell = tableView.cellForRow(at: indexPath) as? UserAddTalkTableViewCell {
            let talk = self.filteredTalks[indexPath.row]
            
            var userSelected = selectedTalksByNameDict[talk.fileName]
            userSelected = (userSelected == true) ? false : true
            selectedTalksByNameDict[talk.fileName] = userSelected
            
            setSelectedState(talk: talk, cell: cell)
            //cell.backgroundColor = UIColor.green
            updateSelectedTalks(changedTalk: talk)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "UserAddTalkTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? UserAddTalkTableViewCell  else {
            fatalError("The dequeued cell is not an instance of UserAddTalkTableViewCell.")
        }
        let talk = self.filteredTalks[indexPath.row]
        
        /*
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.green
        cell.selectedBackgroundView = backgroundView
 */
        
        cell.title.text = talk.title
        cell.speakerPhoto.image = talk.speakerPhoto
        cell.speakerPhoto.contentMode = UIViewContentMode.scaleAspectFit
        setSelectedState(talk: talk, cell: cell)

        return cell
    }
    
    
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        
        print("useraddtalktable prepare to seque")
        
    }
    

    // MARK: Private
    private func updateSelectedTalks(changedTalk: TalkData) {
        
        // if the changed talk is in our selected list, then the new state is presumably off
        // in that case, removed the talk from selections
        // otherwise the new state is presumably on.
        // in that case, add the talk to selections
        var idx = 0
        for aSelectedTalk in self.selectedTalks {
            if changedTalk.fileName == aSelectedTalk.fileName {
                selectedTalks.remove(at: idx)
                return
            }
            idx += 1
        }
        self.selectedTalks.append(changedTalk)
    }
    
    private func setSelectedState(talk: TalkData, cell: UserAddTalkTableViewCell) {
    
        let userSelected = self.selectedTalksByNameDict[talk.fileName]
        if userSelected == true {
            cell.userSelected.image = UIImage(named: "checkboxon")
            //cell.backgroundColor = UIColor.green
            
        } else {
            cell.userSelected.image = UIImage(named: "checkboxoff")
            //cell.backgroundColor = UIColor.white

            
        }

        
    }
    
  

    
}
