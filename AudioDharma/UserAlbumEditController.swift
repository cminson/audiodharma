///
//  AddUserAlbumViewController.swift
//  AudioDharma
//
//  Created by Christopher on 7/11/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

import UIKit
import os.log

class UserAlbumEditController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // MARK: Properties
    var UserAlbum: UserAlbumData? = nil
    var EditMode: Bool = false

    // MARK: Outlets
    @IBOutlet weak var userAlbumTitle: UITextField!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let ImagePicker = UIImagePickerController()

    
    // MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("view loaded: \(String(describing: UserAlbum?.Title))")

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
        
        let title = userAlbumTitle.text ?? ""
        let image = userImageView.image ?? UIImage(named: "flower01")
        UserAlbum = UserAlbumData(title: title, image: image!)
        
    }
    
    // MARK: Actions
    @IBAction func cancel(_ sender: Any) {
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




