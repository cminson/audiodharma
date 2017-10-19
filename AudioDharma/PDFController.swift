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
        
        if CurrentTalk.PDF.count < 2 {
            return
        }
        
        var pdfURL: URL

        if TheDataModel.isFullURL(url: CurrentTalk.PDF) {
            pdfURL  = URL(string: CurrentTalk.PDF)!
            print("PDF: ", pdfURL)
        }
        else if USE_NATIVE_MP3PATHS == true {
            pdfURL  = URL(string: URL_MP3_HOST +  CurrentTalk.PDF)!
            
        } else {
            let urlPhrases = CurrentTalk.PDF.components(separatedBy: "/")
            var fileName = (urlPhrases[urlPhrases.endIndex - 1])
            fileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
            pdfURL  = URL(string: URL_MP3_HOST + "/" + fileName)!
        }

    
        webView?.load(URLRequest(url: pdfURL))
        webView?.allowsBackForwardNavigationGestures = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
