//
//  DonationsController.swift
//  AudioDharma
//
//  Created by Christopher on 7/13/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class DonationsController: UIViewController {
    
    @IBOutlet weak var donationContentView: UILabel!
    @IBOutlet weak var cancel: UIBarButtonItem!

    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        donationContentView.sizeToFit()
    }


    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func cancel(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func gotoDonationPage(_ sender: UIButton) {
        
        if let url = URL(string: DONATIONS_PAGE) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
}
