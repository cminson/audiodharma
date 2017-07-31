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
    var FolderSections: [[FolderData]] = []   // 2d array of sections x folders
    var KeyToTalks : [String: [[TalkData]]] = [:]  // dictionary keyed by content, value is 2d array of sections x talks
    var KeyToFolderStats: [String: FolderStats] = [:] // dictionary keyed by content, value is stat struct for folders
    var NameToTalks: [String: TalkData]   = [String: TalkData] ()  // dictionary keyed by name of talk, value is the talk data (used by userList code to lazily bind)
    
    
    // MARK: Persistant Data
    var UserLists: [UserListData] = []      // all the custom user lists defined by this user.
    var UserNotes: [String: UserNoteData] = [:]      // all the  user notes defined by this user, indexed by fileName
    
    
    // MARK: Init
    func loadData() {
        
        // get user data from storage
        UserLists = TheDataModel.loadUserListData()
        UserNotes = TheDataModel.loadUserNoteData()

        //loadFoldersFromWeb(jsonLocation: "http://www.ezimba.com/ad/folders01.json")
        //loadTalksFromWeb(jsonLocation: "http://www.ezimba.com/ad/talks01.json")"
        // get baseline talks and folders
        loadTalksFromFile(jsonLocation: "talks02")
        loadFoldersFromFile(jsonLocation: "folders02")
        
        // compute stats for custom albums (computing number of talks inside each one)
        computeCustomUserListStats()
    }
    
    
    // MARK: Persistant API
    func saveUserListData() {
        
        print("saveUserListData to: ", UserListData.ArchiveURL.path)
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserLists, toFile: UserListData.ArchiveURL.path)
    }
    
    func saveUserNoteData() {
        
        print("saveUserNoteData to: ", UserNoteData.ArchiveURL.path)
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserNotes, toFile: UserNoteData.ArchiveURL.path)
    }

    func loadUserListData() -> [UserListData]  {
        
        print("loadUserList from: ", UserListData.ArchiveURL.path)
        
        if let userListData = NSKeyedUnarchiver.unarchiveObject(withFile: UserListData.ArchiveURL.path) as? [UserListData] {
            
            return userListData
        } else {
            
            return [UserListData] ()
        }
    }
    
    func loadUserNoteData() -> [String: UserNoteData]  {
        
        print("loadUserNoteData from: ", UserNoteData.ArchiveURL.path)
        
        if let userNotes = NSKeyedUnarchiver.unarchiveObject(withFile: UserNoteData.ArchiveURL.path)
            as? [String: UserNoteData] {
            
            return userNotes
        } else {
            
            return [String: UserNoteData] ()
        }
    }

    
    // MARK: API
    func getTalks(content: String) -> [[TalkData]] {
        
        return KeyToTalks[content] ?? [[TalkData]]()
    }
    
    func getFolderStats(content: String) -> FolderStats {
        
        return KeyToFolderStats[content] ?? FolderStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
    }
    
    func getUserLists() -> [UserListData] {
        
        return UserLists
    }
    
    func getTalkForName(name: String) -> TalkData? {
        
        return NameToTalks[name]
    }
    
    func shareTalk(sharedTalk: TalkData, controller: UIViewController) {
        
        print("shareTalk")
        let shareText = "\(sharedTalk.Title)\n\(sharedTalk.Speaker)   \(sharedTalk.Date)\nShared from the iPhone AudioDharma app"
        
        let objectsToShare:URL = URL(string: sharedTalk.URL)!
        let sharedObjects:[AnyObject] = [objectsToShare as AnyObject, shareText as AnyObject]
        
        // set up activity view controller
        let activityViewController = UIActivityViewController(activityItems: sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = controller.view // so that iPads won't crash
                
        // present the view controller
        controller.present(activityViewController, animated: true, completion: nil)
        
    }

    func convertDurationToSeconds(duration: String) -> Int {
        
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
    
    //
    // generate the stats for the user-defined lists.
    //
    func computeCustomUserListStats() {
        
        var totalSecondsAllLists = 0
        var talkCountAllLists = 0
            
        for userList in UserLists {
                
            var totalSeconds = 0
            var talkCount = 0
            for talkName in userList.TalkFileNames {
                if let talk = NameToTalks[talkName] {
                    totalSeconds += talk.Time
                    talkCount += 1
                }
            }
            
            talkCountAllLists += talkCount
            totalSecondsAllLists += totalSeconds
            let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            KeyToFolderStats[userList.Title] = stats
        }
        
        let durationDisplayAllLists = self.secondsToDurationDisplay(seconds: totalSecondsAllLists)
            
        let stats = FolderStats(totalTalks: talkCountAllLists, totalSeconds: totalSecondsAllLists, durationDisplay: durationDisplayAllLists)
        KeyToFolderStats["CUSTOM"] = stats
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
                
                let seconds = self.convertDurationToSeconds(duration: duration)
                totalSeconds += seconds
                
                let urlPhrases = URL.components(separatedBy: "/")
                var fileName = (urlPhrases[urlPhrases.endIndex - 1]).trimmingCharacters(in: .whitespacesAndNewlines)
                fileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)

                if let noteData = UserNotes[fileName] {
                    if noteData.Notes.characters.count < 2 {
                        UserNotes[fileName] = nil
                    }
                }
                let hasNotes = UserNotes[fileName] != nil
                
                let talkData =  TalkData(title: title,  url: URL,  fileName: fileName, date: date, duration: duration,  speaker: speaker, section: section, time: seconds, hasNotes: hasNotes )
                
                //print(fileName)
                NameToTalks[fileName] = talkData
                              
                // add this talk to  list of all talks
                // Note: there is only one talk section for KEY_ALLTALKS.  all talks are stored in that section
                if KeyToTalks[KEY_ALLTALKS] == nil {
                    KeyToTalks[KEY_ALLTALKS] = [[TalkData]] ()
                    KeyToTalks[KEY_ALLTALKS]?.append([talkData])
                    
                }
                else {
                    KeyToTalks[KEY_ALLTALKS]?[0].append(talkData)
                }
                
                // add talk to the list of talks for this speaker
                // Note: there is only one talk section for speaker. talks for this spearker are stored in that section
                if KeyToTalks[speaker] == nil {
                    KeyToTalks[speaker] = [[TalkData]] ()
                    KeyToTalks[speaker]?.append([talkData])
                }
                else {
                    KeyToTalks[speaker]?[0].append(talkData)
                }
                
                talkCount += 1
                //print(talkData, talkCount)
            }
        } catch {
            print(error)
        }
        
        let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
        KeyToFolderStats[KEY_ALLTALKS] = stats
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
                    FolderSections.append([folderData])
                    folderSectionPositionDict[section] = FolderSections.count - 1
                } else {
                    // section already exists.  add folder to the existing array of folders
                    let sectionPosition = folderSectionPositionDict[section]!
                    FolderSections[sectionPosition].append(folderData)
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
                    
                    let totalSeconds = self.convertDurationToSeconds(duration: duration)
                    
                    let urlPhrases = URL.components(separatedBy: "/")
                    var fileName = (urlPhrases[urlPhrases.endIndex - 1]).trimmingCharacters(in: .whitespacesAndNewlines)
                    fileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let hasNotes = UserNotes[fileName] != nil
                    let talkData =  TalkData(title: titleTitle, url: URL, fileName: "TBD", date: date, duration: duration,  speaker: speaker, section: section, time: totalSeconds, hasNotes: hasNotes)
                    
                    // create the key -> talkData[] entry if it doesn't already exist
                    if KeyToTalks[content] == nil {
                        //print("folder talks creating key for: \(content)")
                        KeyToTalks[content]  = []
                    }
                    
                    // now add the talk data to this key
                    if talkSectionPositionDict[section] == nil {
                        // new section seen.  create new array of talks for this section
                        //print("new section seen. creating array for: \(content)")
                        KeyToTalks[content]!.append([talkData])
                        talkSectionPositionDict[section] = KeyToTalks[content]!.count - 1
                    } else {
                        // section already exists.  add talk to the existing array of talks
                        let sectionPosition = talkSectionPositionDict[section]!
                        KeyToTalks[content]![sectionPosition].append(talkData)
                        
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
        let folders = FolderSections.joined()
        for folder in folders {
            
            let talksInFolder = (KeyToTalks[folder.content] ?? [[TalkData]]()).joined()
            let talkCount = talksInFolder.count
            
            var totalSeconds = 0
            for talk in talksInFolder {
                totalSeconds += talk.Time
            }
            
            let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            KeyToFolderStats[folder.content] = stats
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
                        self.FolderSections.append([folderData])
                        folderSectionPositionDict[section] = self.FolderSections.count - 1
                    } else {
                        // section already exists.  add folder to the existing array of folders
                        let sectionPosition = folderSectionPositionDict[section]!
                        self.FolderSections[sectionPosition].append(folderData)
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
                        
                        let totalSeconds = self.convertDurationToSeconds(duration: duration)

                        let hasNotes = false // TBD DEV
                        let talkData =  TalkData(title: titleTitle, url: URL, fileName: "TBD", date: date, duration: duration,  speaker: speaker, section: section, time: totalSeconds, hasNotes: hasNotes)
                        
                        // create the key -> talkData[] entry if it doesn't already exist
                        if self.KeyToTalks[content] == nil {
                            self.KeyToTalks[content]  = []
                        }
                        
                        // now add the talk data to this key
                        if talkSectionPositionDict[section] == nil {
                            // new section seen.  create new array of talks for this section
                            self.KeyToTalks[content]!.append([talkData])
                            talkSectionPositionDict[section] = self.KeyToTalks[content]!.count - 1
                        } else {
                            // section already exists.  add talk to the existing array of talks
                            let sectionPosition = talkSectionPositionDict[section]!
                            self.KeyToTalks[content]![sectionPosition].append(talkData)
                            
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
            let folders = self.FolderSections.joined()
            for folder in folders {
                
                let talksInFolder = (self.KeyToTalks[folder.content] ?? [[TalkData]]()).joined()
                let talkCount = talksInFolder.count
                
                var totalSeconds = 0
                for talk in talksInFolder {
                    totalSeconds += talk.Time
                 }
                let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
                self.KeyToFolderStats[folder.content] = stats
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
                    
                    let seconds = self.convertDurationToSeconds(duration: duration)
                    totalSeconds += seconds

                    let hasNotes = false // TBD DEV
                    let talkData =  TalkData(title: title,  url: URL,  fileName: urlFileName, date: date, duration: duration,  speaker: speaker, section: section, time: seconds, hasNotes: hasNotes)
                    
 
                    // add this talk to  list of all talks
                    if self.KeyToTalks[KEY_ALLTALKS] == nil {
                        self.KeyToTalks[KEY_ALLTALKS] = [[TalkData]] ()
                        
                    }
                    self.KeyToTalks[KEY_ALLTALKS]? += [[talkData]]
                    
                    // add talk to the list of talks for this speaker
                    if self.KeyToTalks[speaker] == nil {
                        self.KeyToTalks[speaker] = [[TalkData]] ()
                    }
                    self.KeyToTalks[speaker]? += [[talkData]]
                    
                    talkCount += 1
                }
            } catch {
                print(error)
            }
            
            let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
            self.KeyToFolderStats[KEY_ALLTALKS] = stats

        }
        task.resume()
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
    
    /*
     func generateTalkKey(name: String, date: String, duration: String) -> String {
     
     let key = name + "+!+" + date + "+!+" + duration
     return key
     }
     
     func unpackTalkKey(key: String) -> (name: String, date: String, duration: String) {
     
     let keyPartsArray = key.components(separatedBy: "+!+")
     
     let name = keyPartsArray[0]
     let date = keyPartsArray[1]
     let duration = keyPartsArray[2]
     
     return(name, date, duration)
     }
     */
    
}
