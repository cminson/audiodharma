///
//  UserAlbumEditController.swift
//  AudioDharma
//
//  Created by Christopher on 7/11/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

import UIKit
import os.log

class UserAlbumEditController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet var buttonHelp: UIBarButtonItem!
    @IBOutlet var buttonDonate: UIBarButtonItem!
    
    // MARK: Properties
    var UserAlbum: UserAlbumData? = nil // album we are editing, if any
    var AddingNewAlbum: Bool = false  // flags if this is an edit of existing Album vs  add of a new Album

    
    // MARK: Outlets
    @IBOutlet weak var userAlbumTitle: UITextField!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let ImagePicker = UIImagePickerController()

    let MAXUSERALBUMIMAGES = 15
    var UserAlbumImageList : [UIImage] = [UIImage] ()
    
    // MARK: Init
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        userImageView.contentMode = UIViewContentMode.scaleAspectFit

        
        for i in 1...MAXUSERALBUMIMAGES {
            
            let name = "useralbumcover" + String(format: "%02d", i)
            if let libraryImage = UIImage(named: name) {
                
                UserAlbumImageList.append(libraryImage)
            }
        }
        
        print("view loaded: \(String(describing: UserAlbum?.Title))")
        
        // we're adding a new record (vs editing an existing)
        if AddingNewAlbum == true {
            
            let count : UInt32 = UInt32(UserAlbumImageList.count - 1)
            let randomNum = Int(arc4random_uniform(count))
            let libraryImage = UserAlbumImageList[randomNum]
            
            UserAlbum = UserAlbumData(title: "Album Title", image: libraryImage)
        }

        if let title = UserAlbum?.Title {
            if title.characters.count > 0 {
                userAlbumTitle.text = title
            }
        }

        if let image = UserAlbum?.Image {
            userImageView.image = image
        } else {
            userImageView.image = UIImage(named: "flower01")
            
        }
        
        userAlbumTitle.delegate = self
        ImagePicker.delegate = self
        
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.toolbar.barStyle = UIBarStyle.blackOpaque
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([buttonHelp, flexibleItem, buttonDonate], animated: false)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
         
        UserAlbum?.Title = userAlbumTitle.text ?? ""
        UserAlbum?.Image = userImageView.image ?? UIImage(named: "flower01")!
        
        //print("Modified UserAlbum: ", UserAlbum?.Title, UserAlbum?.Content)
    }
    
    // MARK: Actions
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        dismiss(animated: true, completion: nil)
    }
        
    @IBAction func loadImage(_ sender: UIButton) {
        ImagePicker.allowsEditing = false
        ImagePicker.sourceType = .photoLibrary
        ImagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        
        present(ImagePicker, animated: true, completion: nil)
    }
    
    
    // MARK: - UIImagePickerControllerDelegate Methods
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any])
    {
    
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        userImageView.contentMode = .scaleAspectFit
        userImageView.image = chosenImage
        dismiss(animated:true, completion: nil)
    }

    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        userAlbumTitle.text = textField.text
    }

}




