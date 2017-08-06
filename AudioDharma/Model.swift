//
//  Model.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log

// MARK: App Global Vars
let TheDataModel = Model()
let DEVICE_ID = UIDevice.current.identifierForVendor!.uuidString
//let DEVICE_ID:UInt32 = arc4random_uniform(100000000)
struct FolderStats {
    var totalTalks: Int
    var totalSeconds: Int
    var durationDisplay: String
}

// MARK: App Global Constants
let KEY_ALLTALKS = "KEY_ALLTALKS"
let KEY_ALLSPEAKERS = "KEY_ALLSPEAKERS"
let KEY_CUSTOMALBUMS = "KEY_CUSTOMALBUMS"
let KEY_NOTES = "KEY_NOTES"
let KEY_TALKHISTORY = "KEY_TALKHISTORY"
let KEY_TALKSBEINGPLAYED = "KEY_TALKSBEINGPLAYED"

let URL_REPORTACTIVITY = "http://www.ezimba.com/AD/reportactivity.py"
let URL_GETACTIVITY = "http://www.ezimba.com/AD/test01.json"

let MAX_TALKHISTORY_COUNT = 50

class Model {
    
    //MARK: Properties
    var RootTableView: UITableViewController!   // the top level display.  we keep this handle so we can force reloads when needed
    
    var FolderSections: [[FolderData]] = []   // 2d array of sections x folders
    var SpeakerFolders: [FolderData] = []     // array of folders for all speakers
    var KeyToTalks : [String: [[TalkData]]] = [:]  // dictionary keyed by content, value is 2d array of sections x talks
    var KeyToFolderStats: [String: FolderStats] = [:] // dictionary keyed by content, value is stat struct for folders
    var NameToTalks: [String: TalkData]   = [String: TalkData] ()  // dictionary keyed by talk filename, value is the talk data (used by userList code to lazily bind)
    
    var TalkHistoryList: [TalkHistoryData] = []
    var TalksBeingPlayed: [TalkData] = []
    
    
    // MARK: Persistant Data
    var UserLists: [UserListData] = []      // all the custom user lists defined by this user.
    var UserNotes: [String: UserNoteData] = [:]      // all the  user notes defined by this user, indexed by fileName
    
    
    // MARK: Init
    func loadData() {
        
        // start getting sangha information from web
        TheDataModel.getTalksCurrentlyBeingPlayed()

        // get baseline talks and folders
        loadTalksFromFile(jsonLocation: "talks01")
        loadFoldersFromFile(jsonLocation: "folders01")
        computeSpeakerStats()

        
        // get user data from storage and compute stats
        UserLists = TheDataModel.loadUserListData()
        computeUserListStats()
        UserNotes = TheDataModel.loadUserNoteData()
        computeNotesListStats()
        TalkHistoryList = TheDataModel.loadTalkHistoryData()
        computeHistoryListStats()


    }
    
    
    // MARK: Persistant API
    func saveUserListData() {
        
        print("saveUserListData to: ", UserListData.ArchiveURL.path)
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserLists, toFile: UserListData.ArchiveURL.path)
    }
    
    func saveUserNoteData() {
        
        print("saveUserNoteData to: ", UserNoteData.ArchiveURL.path)
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserNotes, toFile: UserNoteData.ArchiveURL.path)
        
        self.computeNotesListStats()
    }
    
    func saveTalkHistoryData() {
        
        print("saveTalkHistoryData to: ", TalkHistoryData.ArchiveURL.path)
        NSKeyedArchiver.archiveRootObject(TheDataModel.TalkHistoryList, toFile: TalkHistoryData.ArchiveURL.path)
        
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
    
    func loadTalkHistoryData() -> [TalkHistoryData]  {
        
        print("loadTalkHistoryData from: ", TalkHistoryData.ArchiveURL.path)
        
        if let talkHistory = NSKeyedUnarchiver.unarchiveObject(withFile: TalkHistoryData.ArchiveURL.path)
            as? [TalkHistoryData] {
            
            return talkHistory
        } else {
            
            return [TalkHistoryData] ()
        }
    }

    
    // MARK: API
    func getTalks(content: String) -> [[TalkData]] {
        
        switch content {
        case KEY_NOTES:
            var talks = [TalkData] ()
            for (fileName, _) in UserNotes {
                if let talk = NameToTalks[fileName] {
                    talks.append(talk)
                }
            }
            return [talks]
        case KEY_TALKHISTORY:
            var talks = [TalkData] ()
            for talkHistory in TalkHistoryList {
                let fileName = talkHistory.FileName
                if let talk = NameToTalks[fileName] {
                    talks.append(talk)
                }
            }
            return [talks]
            
        case KEY_TALKSBEINGPLAYED:
            
            //self.getTalksBeingPlayed()
            return [TalksBeingPlayed.sorted(by: { $0.Date < $1.Date })]

        default:
            return KeyToTalks[content] ?? [[TalkData]]()
        }
        
        
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
    
    func addToTalkHistory(talk: TalkData) {
        
        let count = TalkHistoryList.count
        
        if count > MAX_TALKHISTORY_COUNT {
            TalkHistoryList.remove(at: 0)
        }
        
        let talkHistory = TalkHistoryData(fileName: talk.FileName)
        TalkHistoryList.append(talkHistory)
        
        computeHistoryListStats()
        saveTalkHistoryData()

        // refresh the top view so that stat display for Recent History will be updated
        RootTableView.tableView.reloadData()
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
    
    func getTalksCurrentlyBeingPlayed() {
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        
        let requestURL : URL? = URL(string: URL_GETACTIVITY)
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
                
                for talkstat in json["talkstats"] as? [AnyObject] ?? [] {
                    
                    let urlFileName = talkstat["filename"] as? String ?? ""
                    let time = talkstat["time"] as? String ?? ""
                    
                    if let talk = self.NameToTalks[urlFileName] {
                        let duration = talk.Duration
                        
                        let seconds = self.convertDurationToSeconds(duration: duration)
                        totalSeconds += seconds
                        talkCount += 1
                        // add this talk to  list of talks being played
                        self.TalksBeingPlayed.append(talk)
                       
                    }
                }
            } catch {
                print(error)
            }
            
            let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
            self.KeyToFolderStats[KEY_TALKSBEINGPLAYED] = stats
            print("TalksBeingPlayed: Done")
            
        }
        task.resume()
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
    // generate the stats for the notes folder
    //
    func computeNotesListStats() {
        
        var talkCount = 0
        var totalSeconds = 0
        
        for (fileName, _) in UserNotes {
            
            if let talk = NameToTalks[fileName] {
                totalSeconds += talk.Time
                talkCount += 1
            }
        }
                
        let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
        let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        
        KeyToFolderStats[KEY_NOTES] = stats
    }
  
    
    func computeHistoryListStats() {
        
        var talkCount = 0
        var totalSeconds = 0
        
        for talkHistory in TalkHistoryList {
            let fileName = talkHistory.FileName
            if let talk = NameToTalks[fileName] {
                totalSeconds += talk.Time
                talkCount += 1
            }
        }
        
        let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
        let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        
        KeyToFolderStats[KEY_TALKHISTORY] = stats
    }
    
    //
    // generate the stats for the user-defined lists.
    //
    func computeUserListStats() {
        
        var totalUserListCount = 0
        var totalUserTalkSecondsCount = 0
        
        for userList in UserLists {
                
            var talkCount = 0
            var totalSeconds = 0
            for talkName in userList.TalkFileNames {
                if let talk = NameToTalks[talkName] {
                    totalSeconds += talk.Time
                    talkCount += 1
                }
            }
            
            totalUserListCount += 1
            totalUserTalkSecondsCount += totalSeconds
            let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            KeyToFolderStats[userList.Title] = stats
        }
        
        let durationDisplayAllLists = self.secondsToDurationDisplay(seconds: totalUserTalkSecondsCount)
        let stats = FolderStats(totalTalks: totalUserListCount, totalSeconds: totalUserTalkSecondsCount, durationDisplay: durationDisplayAllLists)
        
        KeyToFolderStats[KEY_CUSTOMALBUMS] = stats
    }
    
    //
    // generate the stats for the speaker talk album.
    //
    func computeSpeakerStats() {
        
        var totalSecondsAllLists = 0
        var talkCountAllLists = 0
        
        for folder in SpeakerFolders {
            
            let content = folder.content
            var totalSeconds = 0
            var talkCount = 0
            for talk in (KeyToTalks[content]?[0])! {
                totalSeconds += talk.Time
                talkCount += 1
            }
            
            talkCountAllLists += talkCount
            totalSecondsAllLists += totalSeconds
            let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = FolderStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            KeyToFolderStats[content] = stats
        }
        
        let durationDisplayAllLists = self.secondsToDurationDisplay(seconds: totalSecondsAllLists)
        
        let stats = FolderStats(totalTalks: talkCountAllLists, totalSeconds: totalSecondsAllLists, durationDisplay: durationDisplayAllLists)
        KeyToFolderStats[KEY_ALLSPEAKERS] = stats
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
                let fileName = talk["filename"] as? String ?? ""
                let duration = talk["duration"] as? String ?? ""
                let date = talk["date"] as? String ?? ""
                let section = ""
                
                let seconds = self.convertDurationToSeconds(duration: duration)
                totalSeconds += seconds
                
                
                let talkData =  TalkData(title: title,  url: URL,  fileName: fileName, date: date, duration: duration,  speaker: speaker, section: section, time: seconds)
                
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
                    
                    // create a folder for this speaker and add to array of speaker folders
                    // this array will be referenced by SpeakersTableViewController
                    let folderData =  FolderData(title: speaker, content: speaker, section: "", image: speaker)
                    SpeakerFolders.append(folderData)
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
        
        SpeakerFolders = SpeakerFolders.sorted(by: { $0.content < $1.content })
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
                var section = folder["section"] as? String ?? ""
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
                    var section = talk["section"] as? String ?? ""
                    
                    if section.range(of:"_") != nil {
                        section = ""
                    }
                    
                    let totalSeconds = self.convertDurationToSeconds(duration: duration)
                    
                    let urlPhrases = URL.components(separatedBy: "/")
                    var fileName = (urlPhrases[urlPhrases.endIndex - 1]).trimmingCharacters(in: .whitespacesAndNewlines)
                    fileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let talkData =  TalkData(title: titleTitle, url: URL, fileName: "TBD", date: date, duration: duration,  speaker: speaker, section: section, time: totalSeconds)
                    
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

                        let talkData =  TalkData(title: titleTitle, url: URL, fileName: "TBD", date: date, duration: duration,  speaker: speaker, section: section, time: totalSeconds)
                        
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
                    let urlFileName = talk["filename"] as? String ?? ""
                    let duration = talk["duration"] as? String ?? ""
                    let date = talk["date"] as? String ?? ""
                    let section = ""
                    
                    let seconds = self.convertDurationToSeconds(duration: duration)
                    totalSeconds += seconds

                    let talkData =  TalkData(title: title,  url: URL,  fileName: urlFileName, date: date, duration: duration,  speaker: speaker, section: section, time: seconds)
                    
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
