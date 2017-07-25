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
    var DisplayTalks: [TalkData] = []
    var FilteredTalks:  [TalkData] = []
    var SelectedRow: Int = 0
    let SearchController = UISearchController(searchResultsController: nil)
    
    var Content: String = ""
    var SelectedTalks: [TalkData] = [TalkData] ()
    
    var SelectedTalksByNameDict : [String: Bool] = [ : ]    // dict indexed by talk filename. value bool is user listed or not
    
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
        
        for talk in SelectedTalks {
            SelectedTalksByNameDict[talk.fileName] = true
            print("Selected Talk: ", talk.title)
            
        }
        
        
        let allTalks = TheDataModel.getTalks(content: KEY_ALLTALKS).joined()
        for talk in allTalks {
            SelectedTalksByNameDict[talk.fileName] = false
        }
        for talk in SelectedTalks {
            SelectedTalksByNameDict[talk.fileName] = true
        }

        
        let setofAllTalks : Set<TalkData> = Set(allTalks)
        let setOfSelectedTalks : Set<TalkData> = Set(SelectedTalks)
        let xorSet = setofAllTalks.symmetricDifference(setOfSelectedTalks)
        
        DisplayTalks = SelectedTalks + Array(xorSet)
        FilteredTalks = DisplayTalks
        
        //searchController = UISearchController(searchResultsController: nil)
        SearchController.searchResultsUpdater = self
        SearchController.hidesNavigationBarDuringPresentation = false
        SearchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = SearchController.searchBar
        SearchController.searchBar.delegate = self
        SearchController.delegate = self
        
        //self.tableView.allowsMultipleSelection = true
    }
    
    deinit {
        SearchController.view.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SearchController.isActive = false
        
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
            
            FilteredTalks = []
            for talk in DisplayTalks {
                if talk.title.lowercased().contains(searchText.lowercased()) {
                    FilteredTalks.append(talk)
                }
            }
        } else {
            FilteredTalks = DisplayTalks
        }

        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return FilteredTalks.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FilteredTalks.count
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SelectedRow = indexPath.row

        if let cell = tableView.cellForRow(at: indexPath) as? UserAddTalkTableViewCell {
            let talk = FilteredTalks[indexPath.row]
            
            var userSelected = SelectedTalksByNameDict[talk.fileName]
            userSelected = (userSelected == true) ? false : true
            SelectedTalksByNameDict[talk.fileName] = userSelected
            
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
        let talk = FilteredTalks[indexPath.row]
        
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
        for aSelectedTalk in SelectedTalks {
            if changedTalk.fileName == aSelectedTalk.fileName {
                SelectedTalks.remove(at: idx)
                return
            }
            idx += 1
        }
        SelectedTalks.append(changedTalk)
    }
    
    private func setSelectedState(talk: TalkData, cell: UserAddTalkTableViewCell) {
    
        let userSelected = SelectedTalksByNameDict[talk.fileName]
        if userSelected == true {
            cell.userSelected.image = UIImage(named: "checkboxon")
            //cell.backgroundColor = UIColor.green
            
        } else {
            cell.userSelected.image = UIImage(named: "checkboxoff")
            //cell.backgroundColor = UIColor.white

            
        }

        
    }
    
  

    
}
