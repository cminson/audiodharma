//
//  NoteViewController.swift
//  AudioDharma
//
//  Created by Christopher on 7/30/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit



class NoteViewController: UIViewController, UITextViewDelegate {

    // MARK: Outlets
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var deleteNoteButton: UIButton!
    
    
    // MARK: Properties
    var TalkFileName: String = ""
    var TextHasBeenChanged: Bool = false
    
    
    // MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        noteTextView.delegate = self
        
        //noteTextView.setContentOffset(CGPoint.zero, animated: false)
        noteTextView.contentInset = UIEdgeInsetsMake(-60, 0,0,0);
        
        let borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        noteTextView.layer.borderWidth = 0.5
        noteTextView.layer.borderColor = borderColor.cgColor
        noteTextView.layer.cornerRadius = 5.0
        
        if let noteText = TheDataModel.UserNotes[TalkFileName] {
            noteTextView.text = noteText.Notes
        }
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: Actions
    @IBAction func deleteNoteText(_ sender: UIButton) {
        
        noteTextView.text = ""
        TextHasBeenChanged = true
    }
    
    
    // MARK: Delegates
    func textFieldShouldReturn(textField: UITextField) -> Bool {

        textField.resignFirstResponder();
        return true;
    }
    
    func textViewDidChange(_ textView: UITextView) {

        TextHasBeenChanged = true
    }

}
