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
    //var activityIndicator: UIActivityIndicatorView!
    
    override func loadView() {
        super.loadView()
        
        webView = WKWebView()
        webView?.navigationDelegate = self
        view = webView
        
/*
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        webView?.addSubview(activityIndicator)
 */
    
    }
    
    @IBAction func fontSizeIncrease(_ sender: UIBarButtonItem) {
    }
    

    @IBAction func fontSizeDecrease(_ sender: UIBarButtonItem) {
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
        
        //activityIndicator.isHidden = false
        webView?.load(URLRequest(url: pdfURL))
        webView?.allowsBackForwardNavigationGestures = true
        //webView?.contentMode = .scaleAspectFit


/*
        pdfURL = URL(string: "http://www.virtualdharma.org/sample.pdf")!
        pdfURL = URL(string: "http://www.insightmeditationcenter.org/articles/noting-transcribed.pdf")!


        if let test = URL(string: "https://www.insightmeditationcenter.org/articles/noting-transcribed.pdf") {
        //if let test = URL(string: "http://www.virtualdharma.org/sample02.pdf") {
            print("Loading URL: ", test)kk
            webView?.load(URLRequest(url: test))
            webView?.allowsBackForwardNavigationGestures = true
        }
 */
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        //activityIndicator.isHidden = true

    }

}
