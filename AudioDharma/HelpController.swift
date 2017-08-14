//
//  HelpController.swift
//  AudioDharma
//
//  Created by Christopher on 7/29/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class HelpController: UIViewController {
    
    

    @IBOutlet weak var helpImage01: UIImageView!
    @IBOutlet weak var helpImage02: UIImageView!
    @IBOutlet weak var helpImage03: UIImageView!
    @IBOutlet weak var helpImage04: UIImageView!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        helpImage01.contentMode = UIViewContentMode.scaleAspectFit
        helpImage02.contentMode = UIViewContentMode.scaleAspectFit
        helpImage03.contentMode = UIViewContentMode.scaleAspectFit
        helpImage04.contentMode = UIViewContentMode.scaleAspectFit

    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        dismiss(animated: true, completion: nil)
    }
    

}
