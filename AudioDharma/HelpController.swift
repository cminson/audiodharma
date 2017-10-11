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
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        helpContentView.sizeToFit()

    }
    
    func setHelpPage(helpPage: String) {
    
        // remove spaces, as some keys are derived from names (Gil Fronsdal) and spaces don't work in asset lookup
        let helpKey = String(helpPage.characters.filter { !" ".characters.contains($0) })
        //print("Help Key: ", helpKey)
        if let asset = NSDataAsset(name: helpKey, bundle: Bundle.main) {
            do {
                let json =  try JSONSerialization.jsonObject(with: asset.data) as! [String: AnyObject]
                if let helpText = json["text"] as? String {
                    HelpText = helpText
                }
    
            } catch {
                print(error)
            }
        } else {
            // catch-all for screens that don't have a valid key
            if let asset = NSDataAsset(name: KEY_TALKS, bundle: Bundle.main) {
                do {
                    let json =  try JSONSerialization.jsonObject(with: asset.data) as! [String: AnyObject]
                    if let helpText = json["text"] as? String {
                        HelpText = helpText
                    }
                    
                } catch {
                    print(error)
                }
            }            
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func dismissDialog(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }


}
