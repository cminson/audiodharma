//
//  SimilarTalks.swift
//  AudioDharma
//
//  Created by Christopher on 7/7/18.
//  Copyright © 2018 Christopher Minson. All rights reserved.
//


import UIKit
import Social

class SimilarTalkController: TalkController {
    

    
    // MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadDataFromModel()
        
        SearchController.searchResultsUpdater = self
        SearchController.searchBar.delegate = self
        SearchController.delegate = self
        tableView.tableHeaderView = SearchController.searchBar
        
        TheDataModel.TalkController = self
    }
    

    
}
