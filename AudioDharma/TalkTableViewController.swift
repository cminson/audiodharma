//
//  TalkTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/15/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import Social


class TalkTableViewController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
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
    
    /*
    func  searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        print("searchBarShouldEndEditor")
        return false
    }
     */
    
    
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
        let cellIdentifier = "TalkTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TalkTableViewCell  else {
            fatalError("The dequeued cell is not an instance of TalkTableViewCell.")
        }
        
        let talk = self.filteredSectionTalks[indexPath.section][indexPath.row]
        cell.title.text = talk.title
        cell.speakerPhoto.image = talk.speakerPhoto
        cell.speakerPhoto.contentMode = UIViewContentMode.scaleAspectFit

        
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
        
        switch(segue.identifier ?? "") {
        case "ShowDetail":
            guard let talkDetailViewController = segue.destination as? TalkViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedTalkCell = sender as? TalkTableViewCell else {
                fatalError("Unexpected sender:")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedTalkCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedTalk = self.filteredSectionTalks[indexPath.section][indexPath.row]
            talkDetailViewController.talk = selectedTalk

            
        case "SelectUserList":
            print("SelectUserList")
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier ?? "NONE")")
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let selectUserListForTalk = UITableViewRowAction(style: .normal, title: "Add to User List") { (action, indexPath) in
            
            self.selectedSection = indexPath.section
            self.selectedRow = indexPath.row
            self.performSegue(withIdentifier: "SelectUserList", sender: self)
            self.tableView.isEditing = false
        }
        
        

        let shareFB = UITableViewRowAction(style: .normal, title: "Facebook") { (action, indexPath) in
            self.selectedRow = indexPath.row   
            self.shareFB()
            /*
            self.selectedRow = indexPath.row
            self.performSegue(withIdentifier: "ShareTalk", sender: self)
            // share item at indexPath
            self.tableView.isEditing = false
 */
        }
    
        let shareTwitter = UITableViewRowAction(style: .normal, title: "Twitter") { (action, indexPath) in
            
            //self.shareTwitter()
            self.shareAll()
        }
    
        return [shareFB, shareTwitter, selectUserListForTalk]
}



    //MARK: Private Methods
    private func shareFB() {
    
        let talk = self.filteredSectionTalks[selectedSection][selectedRow]
        //var postText = ("\(talk.title)\n \(talk.talkURL)\nShared from the iPhone Audiodharma app")
        var postText = ("<a title=\(talk.title)\n href=\(talk.talkURL)/>\nShared from the iPhone Audiodharma app")

        
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook){
            let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            facebookSheet.setInitialText(postText)
            self.present(facebookSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func shareTwitter() {
        
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter){
            let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            twitterSheet.setInitialText("Share on Twitter")
            self.present(twitterSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func shareAll() {
        // text to share
        let text = "This is some text that I want to share."
        
        // set up activity view controller
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
    }
}
