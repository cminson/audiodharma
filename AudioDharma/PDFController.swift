//
//  PDFController.swift
//  AudioDharma
//
//  Created by Christopher on 10/14/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import WebKit

class PDFController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView?
    
    override func loadView() {
        super.loadView()
        
        webView = WKWebView()
        webView?.navigationDelegate = self
        view = webView
 
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        super.viewDidLoad()
        let url = URL(string: "http://www.virtualdharma.org/sample.pdf")!
        webView?.load(URLRequest(url: url))
        webView?.allowsBackForwardNavigationGestures = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
