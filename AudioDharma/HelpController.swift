//
//  HelpController.swift
//  AudioDharma
//
//  Created by Christopher on 8/24/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class HelpController: UIViewController {
    
    @IBOutlet weak var helpContentView: UILabel!
    
    var HelpText: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        helpContentView.text = HelpText

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func dismissDialog(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }


}
