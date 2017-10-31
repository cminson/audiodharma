//
//  PDFController.swift
//  AudioDharma
//
//  Created by Christopher on 10/14/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import WebKit

class PDFController: UIViewController, WKNavigationDelegate, UIWebViewDelegate {
    
    var webView: WKWebView?
    var CurrentTalk : TalkData!
    var activityIndicator: UIActivityIndicatorView!
    
    override func loadView() {
        
        super.loadView()
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = false
        activityIndicator.isHidden = false

        self.webView = WKWebView()
        self.webView?.navigationDelegate = self
        self.webView?.addSubview(activityIndicator)
        self.webView?.bringSubview(toFront: activityIndicator)

        self.view = self.webView
        activityIndicator.startAnimating()
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
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        activityIndicator.isHidden = true
    }
    
}
