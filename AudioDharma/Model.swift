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
    var durationDisplay: String
}
let KEY_ALLTALKS = "ALL"


class Model {
    
    //MARK: Properties
    var folderSections: [[FolderData]] = []   // 2d array of sections x folders
    var keyToTalks : [String: [[TalkData]]] = [:]  // dictionary keyed by content, value is 2d array of sections x talks
    var keyToFolderStats: [String: FolderStats] = [:] // dictionary keyed by content, value is stat struct for folders
    var nameToTalks: [String: TalkData]   = [String: TalkData] ()  // dictionary keyed by name of talk, value is the talk data (used by userList code to lazily bind)
    var userLists: [UserListData] = []      // all the custom user lists defined by this user

    
    // MARK: Init
    func loadData() {
        
        //loadFoldersFromWeb(jsonLocation: "http://www.ezimba.com/ad/folders01.json")
        //loadTalksFromWeb(jsonLocation: "http://www.ezimba.com/ad/talks01.json")"
        loadTalksFromFile(jsonLocation: "talks02")
        loadFoldersFromFile(jsonLocation: "folders02")
        
        // get user data from storage and compute the stats
        self.userLists = TheDataModel.loadUserListData()
        computeCustomUserListStats()
    }
    
    
    // MARK: Public
    public func saveUserListData() {
        
        print("saveUserListData to: ", UserListData.ArchiveURL.path)
        NSKeyedArchiver.archiveRootObject(TheDataModel.userLists, toFile: UserListData.ArchiveURL.path)
    }
    
    public func loadUserListData() -> [UserListData]  {
        
        print("loadUserList from: ", UserListData.ArchiveURL.path)
        
        if let userListData = NSKeyedUnarchiver.unarchiveObject(withFile: UserListData.ArchiveURL.path) as? [UserListData] {
            return userListData
            
        } else {
            return [UserListData] ()
        }
    }
    
    public func getTalks(content: String) -> [[TalkData]] {
        
        return self.keyToTalks[content] ?? [[TalkData]]()
    }
    
    public func getFolderStats(content: String) -> FolderStats {
        
        return self.keyToFolderStats[content] ?? FolderStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
    }
    
    public func getUserLists() -> [UserListData] {
        
        return self.userLists
    }
    
    func getTalkForName(name: String) -> TalkData? {
        
        return self.nameToTalks[name]
    }
    
    //
    // generate the stats for the user-defined lists.
    //
    public func computeCustomUserListStats() {
        
        var totalSecondsAllLists = 0
        var talkCountAllLists = 0
            
        for userList in self.userLists {
                
            var totalSeconds = 0
            var talkCount = 0
            for talkName in userList.talkFileNames {
                if let talk = nameToTalks[talkName] {
                    totalSeconds += talk.time
                    talkCount += 1
                }
            }
            
            
            talkCountAllLists += talkCount
            totalSecondsAllLists += totalSeconds
            let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            self.keyToFolderStats[userList.title] = stats
        }
        
        let durationDisplayAllLists = self.secondsToDurationDisplay(seconds: totalSecondsAllLists)
            
        let stats = FolderStats(totalTalks: talkCountAllLists, totalSeconds: totalSecondsAllLists, durationDisplay: durationDisplayAllLists)
        self.keyToFolderStats["CUSTOM"] = stats
    }
    
    
    // MARK: Private
    private func loadTalksFromFile(jsonLocation: String) {
        
        var talkCount = 0
        var totalSeconds = 0
        
        let asset = NSDataAsset(name: jsonLocation, bundle: Bundle.main)

        do {
            
            let json =  try JSONSerialization.jsonObject(with: asset!.data) as! [String: AnyObject]
            
            for talk in json["talks"] as? [AnyObject] ?? [] {
                
                let title = talk["title"] as? String ?? ""
                let speaker = talk["speaker"] as? String ?? ""
                let URL = (talk["url"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let duration = talk["duration"] as? String ?? ""
                let date = talk["date"] as? String ?? ""
                let section = ""
                
                
                let seconds = self.converDurationToSeconds(duration: duration)
                totalSeconds += seconds
                
                let urlPhrases = URL.components(separatedBy: "/")
                var fileName = (urlPhrases[urlPhrases.endIndex - 1]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                fileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)

                
                let talkData =  TalkData(title: title,  URL: URL,  fileName: fileName, date: date, duration: duration,  speaker: speaker, section: section, time: seconds )
                
                self.nameToTalks[fileName] = talkData
                              
                // add this talk to  list of all talks
                // Note: there is only one talk section for KEY_ALLTALKS.  all talks are stored in that section
                if self.keyToTalks[KEY_ALLTALKS] == nil {
                    self.keyToTalks[KEY_ALLTALKS] = [[TalkData]] ()
                    self.keyToTalks[KEY_ALLTALKS]?.append([talkData])
                    
                }
                else {
                    self.keyToTalks[KEY_ALLTALKS]?[0].append(talkData)
                }
                
                // add talk to the list of talks for this speaker
                // Note: there is only one talk section for speaker. talks for this spearker are stored in that section
                if self.keyToTalks[speaker] == nil {
                    self.keyToTalks[speaker] = [[TalkData]] ()
                    self.keyToTalks[speaker]?.append([talkData])
                }
                else {
                    self.keyToTalks[speaker]?[0].append(talkData)
                }
                
                talkCount += 1
                print(talkData, talkCount)
            }
        } catch {
            print(error)
        }
        
        let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
        self.keyToFolderStats[KEY_ALLTALKS] = stats
    }
    
    private func loadFoldersFromFile(jsonLocation: String) {
        
        let asset = NSDataAsset(name: jsonLocation, bundle: Bundle.main)

        var folderSectionPositionDict : [String: Int] = [:]
        do {
            
            let json =  try JSONSerialization.jsonObject(with: asset!.data) as! [String: AnyObject]
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
                    
                    let titleTitle = talk["title"] as? String ?? ""
                    let speaker = talk["speaker"] as? String ?? ""
                    let URL = talk["url"] as? String ?? ""
                    let duration = talk["duration"] as? String ?? ""
                    let date = talk["date"] as? String ?? ""
                    let section = talk["section"] as? String ?? ""
                    
                    let totalSeconds = self.converDurationToSeconds(duration: duration)
                    
                    let talkData =  TalkData(title: titleTitle, URL: URL, fileName: "TBD", date: date, duration: duration,  speaker: speaker, section: section, time: totalSeconds)
                    
                    // create the key -> talkData[] entry if it doesn't already exist
                    if self.keyToTalks[content] == nil {
                        //print("folder talks creating key for: \(content)")
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
        let folders = self.folderSections.joined()
        for folder in folders {
            
            let talksInFolder = (self.keyToTalks[folder.content] ?? [[TalkData]]()).joined()
            let talkCount = talksInFolder.count
            
            var totalSeconds = 0
            for talk in talksInFolder {
                totalSeconds += talk.time
            }
            
            let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
            //let durationDisplay = "99,999:00:00"
            
            let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            self.keyToFolderStats[folder.content] = stats
        }
    }
    
    
    private func loadFoldersFromWeb(jsonLocation: String) {
        
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
                
                    
                    // get the optional talk array for this folder 
                    // if exists, store off all the talks in keyToTalks keyed by 'content' id
                    // the value for this key is a 2d array (section x talks)
                    var talkSectionPositionDict : [String: Int] = [:]
                    for talk in talkList {
                        
                        let titleTitle = talk["title"] as? String ?? ""
                        let speaker = talk["speaker"] as? String ?? ""
                        let URL = talk["url"] as? String ?? ""
                        let duration = talk["duration"] as? String ?? ""
                        let date = talk["date"] as? String ?? ""
                        let section = talk["section"] as? String ?? ""
                        
                        let totalSeconds = self.converDurationToSeconds(duration: duration)

                        let talkData =  TalkData(title: titleTitle, URL: URL, fileName: "TBD", date: date, duration: duration,  speaker: speaker, section: section, time: totalSeconds)
                        
                        // create the key -> talkData[] entry if it doesn't already exist
                        if self.keyToTalks[content] == nil {
                            self.keyToTalks[content]  = []
                        }
                        
                        // now add the talk data to this key
                        if talkSectionPositionDict[section] == nil {
                            // new section seen.  create new array of talks for this section
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
            let folders = self.folderSections.joined()
            for folder in folders {
                
                let talksInFolder = (self.keyToTalks[folder.content] ?? [[TalkData]]()).joined()
                let talkCount = talksInFolder.count
                
                var totalSeconds = 0
                for talk in talksInFolder {
                    totalSeconds += talk.time
                 }
                let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
                self.keyToFolderStats[folder.content] = stats
            }
            
        }
        task.resume()
    }
    
    private func loadTalksFromWeb(jsonLocation: String) {
        
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

                for talk in json["talks"] as? [AnyObject] ?? [] {
                    
                    let title = talk["title"] as? String ?? ""
                    let speaker = talk["speaker"] as? String ?? ""
                    let URL = talk["url"] as? String ?? ""
                    let duration = talk["duration"] as? String ?? ""
                    let date = talk["date"] as? String ?? ""
                    let section = ""
                    
                    let urlPhrases = URL.components(separatedBy: "/")
                    let urlFileName = urlPhrases[urlPhrases.endIndex - 1]
                    
                    let seconds = self.converDurationToSeconds(duration: duration)
                    totalSeconds += seconds

                    let talkData =  TalkData(title: title,  URL: URL,  fileName: urlFileName, date: date, duration: duration,  speaker: speaker, section: section, time: seconds)
                    
 
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
            
            let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
            self.keyToFolderStats[KEY_ALLTALKS] = stats

        }
        task.resume()
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
        totalSeconds = (hours * 3600) + (minutes * 60) + seconds
        return totalSeconds
    }
    
    private func secondsToDurationDisplay(seconds: Int) -> String {
    
        let hours = seconds / 3600
        let modHours = seconds % 3600
        let minutes = modHours / 60
        let seconds = modHours % 60
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let hoursStr = numberFormatter.string(from: NSNumber(value:hours)) ?? "0"

        let minutesStr = String(format: "%02d", minutes)
        let secondsStr = String(format: "%02d", seconds)
    
        return hoursStr + ":" + minutesStr + ":" + secondsStr
    }
    
}
