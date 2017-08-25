//
//  HelpController.swift
//  AudioDharma
//
//  Created by Christopher on 8/24/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

let TUTORIAL_PAGE = "http://www.cnn.com"

class HelpController: UIViewController {
    
    @IBOutlet weak var helpContentView: UILabel!
    
    var HelpText: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        helpContentView.text = HelpText
        helpContentView.sizeToFit()

    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        helpContentView.sizeToFit()

    }

    @IBAction func launchTutorial(_ sender: UIButton) {
        
        if let url = URL(string: TUTORIAL_PAGE) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
    }
    
    func setHelpPage(helpPage: String) {
    
        let asset = NSDataAsset(name: helpPage, bundle: Bundle.main)
        do {
            let json =  try JSONSerialization.jsonObject(with: asset!.data) as! [String: AnyObject]
            if let helpText = json["text"] as? String {
                HelpText = helpText
            }
    
        } catch {
            print(error)
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func dismissDialog(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }


}
