//
//  AddUserListViewController.swift
//  AudioDharma
//
//  Created by Christopher on 7/11/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

import UIKit
import os.log

class AddEditUserListController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    var userList: UserListData? = nil
    var editMode: Bool = false
    
    
    // MARK: Outlets
    @IBOutlet weak var userListTitle: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    // MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("view loaded: \(userList?.title)")
        userListTitle.delegate = self
        userListTitle.text = userList?.title
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        let title = userListTitle.text ?? ""
        self.userList = UserListData(title: title)
        
    }
    
    @IBAction func unwindToUserListView(sender: UIStoryboardSegue) {
        
        print("UserAddTalkViewController")
        
        if let sourceViewController = sender.source as? UserAddTalkViewController {
            //let userTalkList = sourceViewController.filteredSectionTalks
        }
    }
    
    
    // MARK: Actions
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        userListTitle.text = textField.text
    }
    
    
    
    
    
    
    
}
