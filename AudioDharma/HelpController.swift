//
//  HelpController.swift
//  AudioDharma
//
//  Created by Christopher on 8/24/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

extension String {
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: Data(utf8),
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            print("error: ", error)
            return nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}


class HelpController: UIViewController {

    
    @IBOutlet weak var helpContentView: UILabel!
    
    var HelpText: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let string = "<style>body{font-family: 'Helvetica'; font-size:16px; color:#555555}</style>" + HelpText
        helpContentView.attributedText = string.html2AttributedString
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : MAIN_FONT_COLOR]
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        helpContentView.sizeToFit()
    }
    
    func setHelpPage(helpPage: String) {
        
        // remove spaces, as some keys are derived from names (Gil Fronsdal) and spaces don't work in asset lookup
        let helpKey = String(helpPage.characters.filter { !" ".characters.contains($0) })
        if let asset = NSDataAsset(name: helpKey, bundle: Bundle.main) {
            HelpText = String(data: asset.data, encoding: .utf8)!
        } else {
            // catch-all for screens that don't have a valid key
            if let fallback = NSDataAsset(name: KEY_TALKS, bundle: Bundle.main) {
                HelpText = String(data: fallback.data, encoding: .utf8)!
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
