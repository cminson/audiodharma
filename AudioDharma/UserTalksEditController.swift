//
//  UserTalksEditController.swift
//  AudioDharma
//
//  Created by Christopher on 6/28/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class UserTalksEditController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    @IBOutlet var buttonDonate: UIBarButtonItem!
    @IBOutlet var buttonHelp: UIBarButtonItem!
    
    //MARK: Properties
    var DisplayTalks: [TalkData] = []
    var FilteredTalks:  [TalkData] = []
    var SelectedRow: Int = 0
    let SearchController = UISearchController(searchResultsController: nil)
    
    var Content: String = ""
    var SelectedTalks: [TalkData] = [TalkData] ()
    
    var SelectedTalksByNameDict : [String: Bool] = [ : ]    // is this filename in an album
    
    // MARK: Init
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // 
        // we display talks which are the union of the selectedTalks
        // and ALL talks.  selectedTalks are shown at the top. 
        //
        
        for talk in SelectedTalks {
            SelectedTalksByNameDict[talk.FileName] = true
            //print("Selected Talk: ", talk.fileName, talk.title)
        }
        
        
        let allTalks = TheDataModel.getTalks(content: KEY_ALLTALKS).joined()
        for talk in allTalks {
            SelectedTalksByNameDict[talk.FileName] = false
        }
        for talk in SelectedTalks {
            SelectedTalksByNameDict[talk.FileName] = true
        }

        // xor the selectedTalks from Alltalks, so that selectedTalks won't be displayed twice
        let setofAllTalks : Set<TalkData> = Set(allTalks)
        let setOfSelectedTalks : Set<TalkData> = Set(SelectedTalks)
        let xorSet = setofAllTalks.symmetricDifference(setOfSelectedTalks)
        
        DisplayTalks = SelectedTalks + Array(xorSet).sorted(by: { $0.Date > $1.Date })
        FilteredTalks = DisplayTalks
        //FilteredTalks = DisplayTalks
        
        //searchController = UISearchController(searchResultsController: nil)
        SearchController.searchResultsUpdater = self
        SearchController.hidesNavigationBarDuringPresentation = false
        SearchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = SearchController.searchBar
        SearchController.searchBar.delegate = self
        SearchController.delegate = self
        
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.toolbar.barStyle = UIBarStyle.blackOpaque
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([buttonHelp, flexibleItem, buttonDonate], animated: false)
        
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

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "DISPLAY_HELP_PAGE":
            guard let navController = segue.destination as? UINavigationController, let controller = navController.viewControllers.last as? HelpController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            controller.setHelpPage(helpPage: KEY_USEREDIT_TALKS)
            
        default:
            //fatalError("Unexpected Segue Identifier; \(segue.identifier ?? "NONE")")
           
            print("Unexpected Segue Identifier: \(segue.identifier ?? "NONE")")

        }
    }

    
    //MARK: Actions
    @IBAction func dismiss(_ sender: UIBarButtonItem) {   // cancel button clicked
        dismiss(animated: true, completion: nil)
    }
    

    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
 
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            
            FilteredTalks = []
            for talk in DisplayTalks {
                if talk.Title.lowercased().contains(searchText.lowercased()) {
                    FilteredTalks.append(talk)
                }
            }
        } else {
            FilteredTalks = DisplayTalks
        }
        tableView.reloadData()
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FilteredTalks.count
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SelectedRow = indexPath.row

        if let cell = tableView.cellForRow(at: indexPath) as? TalkCell {
            let talk = FilteredTalks[indexPath.row]
            
            var userSelected = SelectedTalksByNameDict[talk.FileName]
            userSelected = (userSelected == true) ? false : true
            SelectedTalksByNameDict[talk.FileName] = userSelected
            //print("DidSelectRow for \(talk.fileName)  \(userSelected)")
            
            // set the checkbox in the cell to reflect it's current selection state.
            // gets a checkmark if selected, otherwise an empty box
            setSelectedState(talk: talk, cell: cell)

            let backgroundView = UIView()
            if userSelected == true {
                SelectedTalks.append(talk)
                backgroundView.backgroundColor = UIColor.green

            } else {
                var idx = 0
                for selectedTalk in SelectedTalks {
                    if talk.FileName == selectedTalk.FileName {
                        SelectedTalks.remove(at: idx)
                        backgroundView.backgroundColor = UIColor.white
                        break
                    }
                    idx += 1
                }
            }
            cell.selectedBackgroundView = backgroundView
         }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("TalkCell", owner: self, options: nil)?.first as! TalkCell
        let talk = FilteredTalks[indexPath.row]
        
        // if there is a Note entry for this talk, then show the note icon in cell
        if TheDataModel.talkHasNotes(talkFileName: talk.FileName) == true {
            cell.noteImage.image = UIImage(named: "noteicon")!
        } else {
            cell.noteImage = nil
        }

        cell.title.text = talk.Title
        cell.speakerPhoto.image = talk.SpeakerPhoto
        cell.speakerPhoto.contentMode = UIViewContentMode.scaleAspectFit
        cell.duration.text = talk.DurationDisplay
        cell.date.text = talk.Date

        setSelectedState(talk: talk, cell: cell)
        
        return cell
    }
    
    
    // MARK: Private
    private func updateSelectedTalks(changedTalk: TalkData) {
        
        // if the changed talk is in our selected list, then the new state is presumably off
        // in that case, removed the talk from selections
        // otherwise the new state is presumably on.
        // in that case, add the talk to selections
        var idx = 0
        for selectedTalk in SelectedTalks {
            if changedTalk.FileName == selectedTalk.FileName {
                SelectedTalks.remove(at: idx)
                return
            }
            idx += 1
        }
    
        //print(" new selected talk: ", changedTalk.Title, changedTalk.FileName)
        SelectedTalks.append(changedTalk)
    }
    
    private func setSelectedState(talk: TalkData, cell: TalkCell) {
    
        let userSelected = SelectedTalksByNameDict[talk.FileName]
        if userSelected == true {
            //cell.userSelected.image = UIImage(named: "checkboxon")
            cell.backgroundColor = UIColor.green
            
        } else {
            //cell.userSelected.image = UIImage(named: "checkboxoff")
            cell.backgroundColor = UIColor.white
        }
    }
    
}
