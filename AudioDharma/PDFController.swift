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
    var CurrentTalk : TalkData!
    
    override func loadView() {
        super.loadView()
        
        webView = WKWebView()
        webView?.navigationDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        super.viewDidLoad()
        
        if CurrentTalk.PDF.count < 2 {
            return
        }
        
        var pdfURL: URL
        if USE_NATIVE_MP3PATHS == true {
            pdfURL  = URL(string: URL_MP3_HOST +  CurrentTalk.PDF)!
            
        } else {
            let urlPhrases = CurrentTalk.PDF.components(separatedBy: "/")
            var fileName = (urlPhrases[urlPhrases.endIndex - 1])
            fileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
            pdfURL  = URL(string: URL_MP3_HOST + "/" + fileName)!
        }
        // DEV TEST
        pdfURL = URL(string: "www.virtualdharma.org/sample.pdf")!

        webView?.load(URLRequest(url: pdfURL))
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
