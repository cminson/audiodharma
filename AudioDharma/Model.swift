//
//  Model.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log


// MOVE INTO CLASS TBD
var KeyToTalks : [String: [TalkData]] = [String: [TalkData]]()

let KEY_ALLTALKS = "ALL"

class Model {
    
    //MARK: Properties
    
    var FolderSections: [[FolderData]] = []
    var Talks: [TalkData] = []
    var NameToTalk : [String: TalkData] = [:]

    
    
    init() {
        
    }
    
    func loadData() {
        
        loadTalks(jsonLocation: "http://www.ezimba.com/ad/alltalks01.json")

        loadFolders(jsonLocation: "http://www.ezimba.com/ad/folders02.json")
    }
    
    
    func getTalks(content: String) -> [TalkData] {
        
        var talks: [TalkData]
        
        talks = KeyToTalks[content] ?? [TalkData]()
       
        print(content)
        print(talks.count)
        
        return talks
        
    }
    
    private func loadFolderContent(content: String) {
        
        print("loadFolderContent")
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        
        let url = "http://www.ezimba.com/ad/" + content

        let requestURL : URL? = URL(string: url)
        let urlRequest = URLRequest(url : requestURL!)
        
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("Everyone is fine, file downloaded successfully.")
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            
            //parsing the response
            do {
                
                let json =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
                //print(json)
                
                for talk in json["talks"] as? [AnyObject] ?? [] {
                    
                    let title = talk["title"] as? String ?? ""
                    let speaker = talk["speaker"] as? String ?? ""
                    let talkURL = talk["talk"] as? String ?? ""
                    let duration = talk["duration"] as? String ?? ""
                    let date = talk["date"] as? String ?? ""
                    
                    let talkData =  TalkData(title: title,  talkURL: talkURL,  date: date, duration: duration,  speaker: speaker)
                    
                    self.NameToTalk[content] =  talkData
                    
                    
                    if let _ = KeyToTalks[content]  {
                        KeyToTalks[content]? += [talkData]
                        //print("added to  array for speaker: \(speaker)  \(KeyToTalks[speaker]!.count)")
                        
                        
                    } else {
                        KeyToTalks[content] = [TalkData] ()
                        KeyToTalks[content]? += [talkData]
                        //print("created array for speaker: \(speaker)")
                        
                    }
                    
                }
                
            } catch {
                print(error)
            }
        }
        task.resume()
    }

    
    
    private func loadFolders(jsonLocation: String) {
        
        print("loadFolders")
        let requestURL : URL? = URL(string: jsonLocation)
        let urlRequest = URLRequest(url : requestURL!)
        let config = URLSessionConfiguration.default
        
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("Download Success")
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Download Error: No Data")
                return
            }
            
            //parsing the response
            do {
                
                let json =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
                //print(json)
                
                for folder in json["folders"] as? [AnyObject] ?? [] {
                    
                    let title = folder["title"] as? String ?? ""
                    let content = folder["content"] as? String ?? ""
                    
                    if content.range(of:"json") != nil {
                        self.loadFolderContent(content: content)
                    }
                    
                    //print(title)
                    //print(content)
                    let folderData =  FolderData(title: title, content: content)
                    
                    if content == "HEADER"  {
                        // add new array of folders
                        self.FolderSections.append([folderData])
                    }
                    else {
                        // add to the current array of folders
                        self.FolderSections[self.FolderSections.count - 1] += [folderData]
                    }

                    print(self.FolderSections.count)
                }
                
                
                
            } catch {
                print(error)
            }
            
        }
        task.resume()
    }

    

    
    
    
    private func loadTalks(jsonLocation: String) {
        
        print("loadTalks")
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        
        let requestURL : URL? = URL(string: jsonLocation)
        let urlRequest = URLRequest(url : requestURL!)
        
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("Everyone is fine, file downloaded successfully.")
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            
            //parsing the response
            do {
                
                let json =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
                //print(json)
                
                for talk in json["talks"] as? [AnyObject] ?? [] {
                    
                    let title = talk["title"] as? String ?? ""
                    let speaker = talk["speaker"] as? String ?? ""
                    let talkURL = talk["talk"] as? String ?? ""
                    let duration = talk["duration"] as? String ?? ""
                    let date = talk["date"] as? String ?? ""
                    
                    let urlPhrases = talkURL.components(separatedBy: "/")
                    let urlFileName = urlPhrases[urlPhrases.endIndex - 1]
                    let talkData =  TalkData(title: title,  talkURL: talkURL,  date: date, duration: duration,  speaker: speaker)
                    
                    self.NameToTalk[urlFileName] =  talkData
                    //print(urlFileName, talkData)

                    
                    if let _ = KeyToTalks[KEY_ALLTALKS]  {
                        KeyToTalks[KEY_ALLTALKS]? += [talkData]
                        //print("added to  array for all talks:  \(KeyToTalks[KEY_ALLTALKS]!.count)")
                        
                        
                    } else {
                        KeyToTalks[KEY_ALLTALKS] = [TalkData] ()
                        KeyToTalks[KEY_ALLTALKS]? += [talkData]
                        //print("created array for all talks")
                        
                    }
                    
                   if let _ = KeyToTalks[speaker]  {
                        KeyToTalks[speaker]? += [talkData]
                        //print("added to  array for speaker: \(speaker)  \(KeyToTalks[speaker]!.count)")

                        
                    } else {
                        KeyToTalks[speaker] = [TalkData] ()
                        KeyToTalks[speaker]? += [talkData]
                        //print("created array for speaker: \(speaker)")
                        
                    }
                    
                    self.Talks += [talkData]
                    //print(self.Talks.count)

                }
                
                
                
            } catch {
                print(error)
            }
        }
        task.resume()
        print("finished load")
    }

    /*******************************/
     /*

    private func loadFolderFile() {
        
        let asset = NSDataAsset(name: "folders", bundle: Bundle.main)
        //let json = try? JSONSerialization.jsonObject(with: asset!.data, options: JSONSerialization.ReadingOptions.allowFragments)
        
        do {
            
            let json =  try JSONSerialization.jsonObject(with: asset!.data) as! [String: AnyObject]
            
            
            for folder in json["folders"] as? [AnyObject] ?? [] {
                
                let title = folder["title"] as? String ?? ""
                let content = folder["content"] as? String ?? ""
                print(title)
                print(content)
                
                
                let folderData =  FolderData(title: title, content: content)
                
                self.Folders += [folderData]
                print(self.Folders.count)
            }
        } catch {
            print(error)
        }
        
    }
    
    
    
    
   
    private func OLDloadFolderContent(jsonLocation: String) {
        let asset = NSDataAsset(name: jsonLocation, bundle: Bundle.main)
        print(jsonLocation)
        print(asset!.data)
        
        do {
            
            let json =  try JSONSerialization.jsonObject(with: asset!.data) as! [String]
            
            
            for fileName in json   {
                print(fileName)
            }
        } catch {
            print(error)
        }
        
    }
    
    func OLDgetTalks(content: String) -> [TalkData] {
        
        var talks: [TalkData]
        
        if content.range(of:"json") != nil {
            
            print(content)
            //print(talks.count)
            
            let url = "http://www.ezimba.com/ad/" + content
            
            let x = getFolderContent(jsonLocation: url)
            
            for talk in x {
                print(talk.title)
                print(talk.talkURL)
                print(talk.speaker)
            }
            return x
            
            
        }
        else {
            talks = KeyToTalks[content] ?? [TalkData]()
            
            print(content)
            print(talks.count)
            
            
        }
        
        return talks
        
    }

    private func getFolderContent(jsonLocation: String) -> [TalkData] {
        
        var talksInFolder: [TalkData] = []
        
        print("loadFolderContent")
        let requestURL : URL? = URL(string: jsonLocation)
        let urlRequest = URLRequest(url : requestURL!)
        let config = URLSessionConfiguration.default
        
        
        
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("Everyone is fine, file downloaded successfully.")
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            do {
                
                let json =  try JSONSerialization.jsonObject(with: responseData) as! [String]
                
                for fileName in json   {
                    print(fileName)
                    let talkData = self.NameToTalk[fileName]
                    talksInFolder.append(talkData!)
                    print(talksInFolder.count)
                    /*
                     for x in talksInFolder {
                     print(x.title)
                     print(x.speaker)
                     
                     }
                     */
                }
            } catch {
                print(error)
            }
            
            
            
        }
        task.resume()
        
        print("TASK DONE:")
        print(talksInFolder.count)
        
        for x in talksInFolder {
            print(x.title)
            print(x.speaker)
        }
        
        return talksInFolder
    }
    */

        
    
}
