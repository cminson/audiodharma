//
//  Model.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log


var KeyToTalks : [String: [TalkData]] = [String: [TalkData]]()
let KEY_ALLTALKS = "ALL"

class Model {
    
    //MARK: Properties
    var Folders = [FolderData]()
    var Talks = [TalkData]()
    
    
    init() {
         //KeyToTalks = [String: [TalkData]]()
    }
    
    func loadData() {
        
        //loadFolders(jsonLocation: "http://www.ezimba.com/ad/t1.json")
        //loadFolders(jsonLocation: "http://www.ezimba.com/ad/folders01.json")
        loadFolderFile()

        loadTalks(jsonLocation: "http://www.ezimba.com/ad/config01.json")
    }
    
    func getTalks(key: String) -> [TalkData] {
        
        let talks = KeyToTalks[key] ?? [TalkData]()
        
        return talks
        
    }
    
    private func loadFolderFile() {
        
        let asset = NSDataAsset(name: "folders", bundle: Bundle.main)
        //let json = try? JSONSerialization.jsonObject(with: asset!.data, options: JSONSerialization.ReadingOptions.allowFragments)
        
        do {

            let json =  try JSONSerialization.jsonObject(with: asset!.data) as! [String: AnyObject]


            for folder in json["folders"] as? [AnyObject] ?? [] {
            
                let title = folder["title"] as? String ?? ""
                let key = folder["key"] as? String ?? ""
            
                //print(title)
                //print(key)
                let folderData =  FolderData(title: title, key: key)
            
                self.Folders += [folderData]
                print(self.Folders.count)
            }
        } catch {
            print(error)
        }

    }
    
    private func loadFolders(jsonLocation: String) {
        
        print("loadFolders")
        let requestURL : URL? = URL(string: jsonLocation)
        let urlRequest = URLRequest(url : requestURL!)
        let session = URLSession.shared
        
        
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
                
                for folder in json["folders"] as? [AnyObject] ?? [] {
                    
                    let title = folder["title"] as? String ?? ""
                    let key = folder["key"] as? String ?? ""
                    
                    //print(title)
                    //print(key)
                    let folderData =  FolderData(title: title, key: key)
                    
                    self.Folders += [folderData]
                    print(self.Folders.count)
                }
                
                
                
            } catch {
                print(error)
            }

        }
        task.resume()
    }
    
    private func loadTalks(jsonLocation: String) {
        
        print("loadTalks")
        let requestURL : URL? = URL(string: jsonLocation)
        let urlRequest = URLRequest(url : requestURL!)
        let session = URLSession.shared
        
        
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
                    
                    //print(title)
                    //print(talkURL)
                    //print(date)
                    //print(duration)
                    //print(speaker)
                    
                    //print(title, talkURL, date, duration, speaker)
                    let talkData =  TalkData(title: title,  talkURL: talkURL,  date: date, duration: duration,  speaker: speaker)
                    
                    //self.Talks += [talkData]
                    //print(self.Talks.count)
                    
                    if let _ = KeyToTalks[KEY_ALLTALKS]  {
                        KeyToTalks[KEY_ALLTALKS]? += [talkData]
                        print("added to  array for all talks:  \(KeyToTalks[KEY_ALLTALKS]!.count)")
                        
                        
                    } else {
                        KeyToTalks[KEY_ALLTALKS] = [TalkData] ()
                        KeyToTalks[KEY_ALLTALKS]? += [talkData]
                        print("created array for all talks")
                        
                    }
                    
                   if let _ = KeyToTalks[speaker]  {
                        KeyToTalks[speaker]? += [talkData]
                        print("added to  array for speaker: \(speaker)  \(KeyToTalks[speaker]!.count)")

                        
                    } else {
                        KeyToTalks[speaker] = [TalkData] ()
                        KeyToTalks[speaker]? += [talkData]
                        print("created array for speaker: \(speaker)")
                        
                    }
                }
                
                
                
            } catch {
                print(error)
            }
        }
        task.resume()
        print("finished load")
    }


        
    
}
