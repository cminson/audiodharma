//
//  Model.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log


struct FolderStats {
    var totalTalks: Int
    var totalSeconds: Int
}

let KEY_ALLTALKS = "ALL"

class Model {
    
    //MARK: Properties
    var folderSections: [[FolderData]] = []   // 2d array of sections x folders
    var keyToTalks : [String: [[TalkData]]] = [:]  // dictionary keyed by content, value is 2d array of sections x talks
    var keyToFolderStats: [String: FolderStats] = [:] // dictionary keyed by content, value is stat struct for folders
    var userLists: [UserListData] = []

    
    init() {
        loadSampleUserFolders()
    }
    
    func loadSampleUserFolders() {
        
        let t1 = UserListData(title: "List 1")
        let t2 = UserListData(title: "List 2")
        let t3 = UserListData(title: "List 3")
        self.userLists += [t1, t2, t3]
        
    }

    
    func loadData() {
        
        loadAllTalks(jsonLocation: "http://www.ezimba.com/ad/alltalks01.json")
        loadFolders(jsonLocation: "http://www.ezimba.com/ad/folders03.json")
    }
    
    
    func getTalks(content: String) -> [[TalkData]] {
        
        var talks: [[TalkData]]
        
        talks = self.keyToTalks[content] ?? [[TalkData]]()
       
        print(content)
        print(talks.count)
        
        return talks
    }
    
    func getFolderStats(content: String) -> FolderStats {
        let stats = self.keyToFolderStats[content]
        return stats!
    }
    
    func getUserLists() -> [UserListData] {
        return self.userLists
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
            
            var folderSectionPositionDict : [String: Int] = [:]
            //parsing the response
            do {
                
                let json =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
                //print(json)
                
                // for each folder entry ...
                // store off the folder into the folderSections array
                // also store of the optional list of talks
                for folder in json["folders"] as? [AnyObject] ?? [] {
                    
                    let title = folder["title"] as? String ?? ""
                    let content = folder["content"] as? String ?? ""
                    let section = folder["section"] as? String ?? ""
                    let image = folder["image"] as? String ?? ""
                    let talkList = folder["talks"] as? [AnyObject] ?? []
                    let folderData =  FolderData(title: title, content: content, section: section, image: image)
                    
                    // store folder in the 2D folderSection array (section x folder)
                    if folderSectionPositionDict[section] == nil {
                        // new section seen.  create new array of folders for this section
                        self.folderSections.append([folderData])
                        folderSectionPositionDict[section] = self.folderSections.count - 1
                    } else {
                        // section already exists.  add folder to the existing array of folders
                        let sectionPosition = folderSectionPositionDict[section]!
                        self.folderSections[sectionPosition].append(folderData)
                    }
                
                    //print(self.folderSections.count)
                    
                    // get the optional talk array for this folder 
                    // if exists, store off all the talks in keyToTalks keyed by 'content' id
                    // the value for this key is a 2d array (section x talks)
                    var talkSectionPositionDict : [String: Int] = [:]
                    for talk in talkList {
                        print(talk["date"])
                        //print(type(of: talk))
                        
                        let titleTitle = talk["title"] as? String ?? ""
                        let speaker = talk["speaker"] as? String ?? ""
                        let talkURL = talk["talk"] as? String ?? ""
                        let duration = talk["duration"] as? String ?? ""
                        let date = talk["date"] as? String ?? ""
                        let section = talk["section"] as? String ?? ""
                        
                        let totalSeconds = self.converDurationToSeconds(duration: duration)

                        let talkData =  TalkData(title: titleTitle,  talkURL: talkURL,  date: date, duration: duration,  speaker: speaker, section: section, time: totalSeconds)
                        
                        // create the key -> talkData[] entry if it doesn't already exist
                        if self.keyToTalks[content] == nil {
                            print("folder talks creating key for: \(content)")
                            self.keyToTalks[content]  = []
                        }
                        
                        // now add the talk data to this key
                        if talkSectionPositionDict[section] == nil {
                            // new section seen.  create new array of talks for this section
                            //print("new section seen. creating array for: \(content)")
                            self.keyToTalks[content]!.append([talkData])
                            talkSectionPositionDict[section] = self.keyToTalks[content]!.count - 1
                        } else {
                            // section already exists.  add talk to the existing array of talks
                            let sectionPosition = talkSectionPositionDict[section]!
                            self.keyToTalks[content]![sectionPosition].append(talkData)
                            
                        }
                    }
                }
            } catch {
                print(error)
            }
            
            //
            // now compute stats for the folders
            // this means calculating the total numberof talks in each folder and total seconds for all talks in folder
            //
            print("computing stats")
            let folders = self.folderSections.joined()
            for folder in folders {
                
                print("Folder Content: ", folder.content)
                let sectionFolder = self.keyToTalks[folder.content]
                print(sectionFolder?.count)
                let talksInFolder = (self.keyToTalks[folder.content] ?? [[TalkData]]()).joined()
                //print(talksInFolder)
                let talkCount = talksInFolder.count
                
                var totalSeconds = 0
                for talk in talksInFolder {
                    totalSeconds += talk.time
                 }
                let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds)
                print(stats)
                self.keyToFolderStats[folder.content] = stats
            }
            
        }
        task.resume()
    }

    
    private func loadAllTalks(jsonLocation: String) {
        
        print("loadAllTalks: START")
        
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
                print("Download: success")
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Download: error")
                return
            }
            
            //parsing the response
            var talkCount = 0
            var totalSeconds = 0
            do {
                
                let json =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
                //print(json)
                

                for talk in json["talks"] as? [AnyObject] ?? [] {
                    
                    let title = talk["title"] as? String ?? ""
                    let speaker = talk["speaker"] as? String ?? ""
                    let talkURL = talk["talk"] as? String ?? ""
                    let duration = talk["duration"] as? String ?? ""
                    let date = talk["date"] as? String ?? ""
                    let section = ""
                    
                    let urlPhrases = talkURL.components(separatedBy: "/")
                    let urlFileName = urlPhrases[urlPhrases.endIndex - 1]
                    
                    let seconds = self.converDurationToSeconds(duration: duration)
                    totalSeconds += seconds

                    let talkData =  TalkData(title: title,  talkURL: talkURL,  date: date, duration: duration,  speaker: speaker, section: section, time: seconds)
                    
 
                    // add this talk to  list of all talks
                    if self.keyToTalks[KEY_ALLTALKS] == nil {
                        self.keyToTalks[KEY_ALLTALKS] = [[TalkData]] ()
                        
                    }
                    self.keyToTalks[KEY_ALLTALKS]? += [[talkData]]
                    
                    // add talk to the list of talks for this speaker
                    if self.keyToTalks[speaker] == nil {
                        self.keyToTalks[speaker] = [[TalkData]] ()
                    }
                    self.keyToTalks[speaker]? += [[talkData]]
                    
                    talkCount += 1
                }
            } catch {
                print(error)
            }
            
            let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds)
            self.keyToFolderStats[KEY_ALLTALKS] = stats

        }
        task.resume()
        print("loadAllTalks: Finished")
    }

    
    private func converDurationToSeconds(duration: String) -> Int {
        
        var totalSeconds: Int = 0
        var hours : Int = 0
        var minutes : Int = 0
        var seconds : Int = 0
        if duration != "" {
            let durationArray = duration.components(separatedBy: ":")
            let count = durationArray.count
            if (count == 3) {
                hours  = Int(durationArray[0])!
                minutes  = Int(durationArray[1])!
                seconds  = Int(durationArray[2])!
            } else if (count == 2) {
                hours  = 0
                minutes  = Int(durationArray[0])!
                seconds  = Int(durationArray[1])!
                
            } else if (count == 1) {
                hours = 0
                minutes  = 0
                seconds  = Int(durationArray[0])!
                
            } else {
                print("Exception to duration: \(durationArray)")
            }
        }
        totalSeconds = (hours * 3600) + (minutes + 60) + seconds
        return totalSeconds
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

       */

        
    
}
