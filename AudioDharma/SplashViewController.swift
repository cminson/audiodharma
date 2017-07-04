//
//  SplashViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

let TheDataModel = Model()

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        TheDataModel.loadData()
        

        perform(Selector("showNavController"), with: nil, afterDelay: 6)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
     func showNavController() {
        performSegue(withIdentifier: "ShowSeriesList", sender: self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
