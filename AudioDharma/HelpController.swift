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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let string = "<style>body{font-family: 'Helvetica'; font-size:16px; color:#555555}</style>" + HELP_PAGE

        helpContentView.attributedText = string.html2AttributedString
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : MAIN_FONT_COLOR]
        helpContentView.textColor = MAIN_FONT_COLOR
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        helpContentView.sizeToFit()
    }
    
    
    //
    // Deprecated, BUT keep it around as useful template
    //
    func xsetHelpPage(helpKey: String) {
        
        //Deprecated: used when keys have spaces in them and must be filtered
        //let helpKey = String(helpPage.filter { !" ".contains($0) })

        if let asset = NSDataAsset(name: helpKey, bundle: Bundle.main) {
            HELP_PAGE = String(data: asset.data, encoding: .utf8)!
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func dismissDialog(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }


}
