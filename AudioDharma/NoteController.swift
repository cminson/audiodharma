//
//  NoteController.swift
//  AudioDharma
//
//  Created by Christopher on 7/30/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit



class NoteController: UIViewController, UITextViewDelegate {

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
        //noteTextView.contentInset = UIEdgeInsetsMake(-60, 0,0,0);
        
        //let borderColor : UIColor = UIColor(red: 0.10, green: 1.00, blue: 0.10, alpha: 1.0)
        let borderColor : UIColor = UIColor(red: 0.0, green: 0.10, blue: 0.0, alpha: 1.0)
        noteTextView.layer.borderWidth = 1.0
        noteTextView.layer.borderColor = borderColor.cgColor
        noteTextView.layer.cornerRadius = 5.0
        
     
        
        noteTextView.text = TheDataModel.getNoteForTalk(talkFileName: TalkFileName)
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
