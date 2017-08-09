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
struct AlbumStats {
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

let MAX_TALKHISTORY_COUNT = 20

let TALK_BASE = "http://www.audiodharma.org"


class Model {
    
    //MARK: Properties
    var AlbumSections: [[AlbumData]] = []   // 2d array of sections x Albums
    var SpeakerAlbums: [AlbumData] = []     // array of Albums for all speakers
    var KeyToTalks : [String: [[TalkData]]] = [:]  // dictionary keyed by content, value is 2d array of sections x talks
    var KeyToAlbumStats: [String: AlbumStats] = [:] // dictionary keyed by content, value is stat struct for Albums
    var NameToTalks: [String: TalkData]   = [String: TalkData] ()  // dictionary keyed by talk filename, value is the talk data (used by userList code to lazily bind)
    
    var TalkHistoryAlbum: [TalkHistoryData] = []
    var TalksBeingPlayed: [TalkData] = []
    
    var KeyAlbumStats: AlbumStats!
    
    
    // MARK: Persistant Data
    var UserAlbums: [UserAlbumData] = []      // all the custom user albums defined by this user.
    var UserNotes: [String: UserNoteData] = [:]      // all the  user notes defined by this user, indexed by fileName
    
    
    // MARK: Init
    func loadData() {
        
        // start getting sangha information from web
        getTalksCurrentlyBeingPlayed()
        
        // get baseline talks and Albums
        loadTalksFromFile(jsonLocation: "talks01")
        loadAlbumsFromFile(jsonLocation: "albums01")
        computeSpeakerStats()

        
        // get user data from storage and compute stats
        UserAlbums = TheDataModel.loadUserAlbumData()
        computeUserAlbumStats()
        UserNotes = TheDataModel.loadUserNoteData()
        computeNotesStats()
        TalkHistoryAlbum = TheDataModel.loadTalkHistoryData()
        computeHistoryStats()
        
     
    }
    
    
    // MARK: Persistant API
    func saveUserAlbumData() {
        
        print("saveUserListData to: ", UserAlbumData.ArchiveURL.path)
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserAlbums, toFile: UserAlbumData.ArchiveURL.path)
    }
    
    func saveUserNoteData() {
        
        print("saveUserNoteData to: ", UserNoteData.ArchiveURL.path)
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserNotes, toFile: UserNoteData.ArchiveURL.path)
    }
    
    func saveTalkHistoryData() {
        
        print("saveTalkHistoryData to: ", TalkHistoryData.ArchiveURL.path)
        NSKeyedArchiver.archiveRootObject(TheDataModel.TalkHistoryAlbum, toFile: TalkHistoryData.ArchiveURL.path)
        
    }


    func loadUserAlbumData() -> [UserAlbumData]  {
        
        print("UserAlbumData from: ", UserAlbumData.ArchiveURL.path)
        
        if let userAlbumData = NSKeyedUnarchiver.unarchiveObject(withFile: UserAlbumData.ArchiveURL.path) as? [UserAlbumData] {
            
            return userAlbumData
        } else {
            
            return [UserAlbumData] ()
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
            for talkHistory in TalkHistoryAlbum {
                let fileName = talkHistory.FileName
                if let talk = NameToTalks[fileName] {
                    talks.append(talk)
                }
            }
            return [talks.reversed()]
            
        case KEY_TALKSBEINGPLAYED:
            
            //self.getTalksBeingPlayed()
            return [TalksBeingPlayed.sorted(by: { $0.Date < $1.Date })]

        default:
            return KeyToTalks[content] ?? [[TalkData]]()
        }
     }
    
    func getAlbumStats(content: String) -> AlbumStats {
        
        switch content {
            
        case KEY_TALKSBEINGPLAYED:
            return KeyAlbumStats

        default:
            return KeyToAlbumStats[content] ?? AlbumStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
            
        }
     }
    
    func getUserAlbums() -> [UserAlbumData] {
        
        return UserAlbums
    }
    
    func updateUserAlbum(updatedAlbum: UserAlbumData) {
        
        for (index, album) in UserAlbums.enumerated() {
        
            if album.Content == updatedAlbum.Content {
            
                UserAlbums[index] = updatedAlbum
                break
            }
        }
    }
    
    func addToUserAlbums(album: UserAlbumData) {
        
        UserAlbums.append(album)
    }
    
    func getUserAlbumTalks(userAlbum: UserAlbumData) -> [TalkData]{
        
        var userAlbumTalks = [TalkData] ()
        
        for talkFileName in userAlbum.TalkFileNames {
            if let talk = getTalkForName(name: talkFileName) {
                userAlbumTalks.append(talk)
            } else {
                print("ERROR: could not locate \(talkFileName)")
            }
        }
        
        return userAlbumTalks
    }
    
    func saveUserAlbumTalks(userAlbum: UserAlbumData, talks: [TalkData]) {

        var userAlbumIndex = 0
        for album in UserAlbums {
            
            if album.Content == userAlbum.Content {
                break
            }
            userAlbumIndex += 1
        }
        
        if userAlbumIndex == UserAlbums.count {
            print("Error: No Index Seen")
            return
        }
        
        var talkFileNames = [String]()
        for talk in talks {
            talkFileNames.append(talk.FileName)
        }
        
        // save the resulting array into the userlist and then persist into storage
        UserAlbums[userAlbumIndex].TalkFileNames = talkFileNames
        
        saveUserAlbumData()
        computeUserAlbumStats()
    }

    
    func getTalkForName(name: String) -> TalkData? {
        
        return NameToTalks[name]
    }
    
    func addToTalkHistory(talk: TalkData) {
                
        if TalkHistoryAlbum.count >= MAX_TALKHISTORY_COUNT {
            TalkHistoryAlbum.remove(at: 0)
        }
        
        let talkHistory = TalkHistoryData(fileName: talk.FileName)
        TalkHistoryAlbum.append(talkHistory)
        
        // save the data, recompute stats, reload root view to display updated stats
        saveTalkHistoryData()
        computeHistoryStats()
    }
    
    func addNoteToTalk(noteText: String, talkFileName: String) {
        
        //
        // if there is a note text for this talk fileName, then save it in the note dictionary
        // otherwise clear this note dictionary entry
        if (noteText.characters.count > 0) {
            UserNotes[talkFileName] = UserNoteData(notes: noteText)
            print("Setting \(talkFileName) to \(noteText)")

        } else {
            UserNotes[talkFileName] = nil
        }
        
        // save the data, recompute stats, reload root view to display updated stats
        saveUserNoteData()
        computeNotesStats()
    }
    
    func getNoteForTalk(talkFileName: String) -> String {
        
        var noteText = ""
        
        if let userNoteData = TheDataModel.UserNotes[talkFileName]   {
            noteText = userNoteData.Notes
        }
        return noteText
    }
    
    func talkHasNotes(talkFileName: String) -> Bool {
 
        if let _ = TheDataModel.UserNotes[talkFileName] {
            return true
        }
        return false
    }

    func shareTalk(sharedTalk: TalkData, controller: UIViewController) {
        
        let titleText = "\(sharedTalk.Title) by \(sharedTalk.Speaker)\n"
        let bylineText = "This talk was shared from the iPhone AudioDharma app"

        let shareText = "\(sharedTalk.Title) by \(sharedTalk.Speaker) \nShared from the iPhone AudioDharma app"
        let objectsToShare: URL = URL(string: TALK_BASE + sharedTalk.URL)!
        
        let sharedObjects:[AnyObject] = [objectsToShare as AnyObject, shareText as AnyObject]
        //let sharedObjects: [AnyObject] = [objectsToShare as AnyObject, bylineText as AnyObject]
        
        let activityViewController = UIActivityViewController(activityItems: sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = controller.view // so that iPads won't crash
                
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
            
            let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            self.KeyAlbumStats = stats
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
    // generate the stats for the notes Album
    //
    func computeNotesStats() {
        
        var talkCount = 0
        var totalSeconds = 0
        
        for (fileName, _) in UserNotes {
            
            if let talk = NameToTalks[fileName] {
                totalSeconds += talk.Time
                talkCount += 1
            }
        }
                
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        
        KeyToAlbumStats[KEY_NOTES] = stats
    }
  
    
    func computeHistoryStats() {
        
        var talkCount = 0
        var totalSeconds = 0
        
        for talkHistory in TalkHistoryAlbum {
            let fileName = talkHistory.FileName
            if let talk = NameToTalks[fileName] {
                totalSeconds += talk.Time
                talkCount += 1
            }
        }
        
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        
        KeyToAlbumStats[KEY_TALKHISTORY] = stats
    }
    
    //
    // generate the stats for the user-defined albums.
    //
    func computeUserAlbumStats() {
        
        var totalUserListCount = 0
        var totalUserTalkSecondsCount = 0
        
        for userAlbum in UserAlbums {
                
            var talkCount = 0
            var totalSeconds = 0
            for talkName in userAlbum.TalkFileNames {
                if let talk = NameToTalks[talkName] {
                    totalSeconds += talk.Time
                    talkCount += 1
                }
            }
            
            totalUserListCount += 1
            totalUserTalkSecondsCount += totalSeconds
            let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            KeyToAlbumStats[userAlbum.Content] = stats
            //print("computerUserAlbumStats: ", userAlbum.Title)
        }
        
        let durationDisplayAllLists = secondsToDurationDisplay(seconds: totalUserTalkSecondsCount)
        let stats = AlbumStats(totalTalks: totalUserListCount, totalSeconds: totalUserTalkSecondsCount, durationDisplay: durationDisplayAllLists)
        
        KeyToAlbumStats[KEY_CUSTOMALBUMS] = stats
    }
    
    //
    // generate the stats for the speaker talk album.
    //
    func computeSpeakerStats() {
        
        var totalSecondsAllLists = 0
        var talkCountAllLists = 0
        
        for album in SpeakerAlbums {
            
            let content = album.Content
            var totalSeconds = 0
            var talkCount = 0
            for talk in (KeyToTalks[content]?[0])! {
                totalSeconds += talk.Time
                talkCount += 1
            }
            
            talkCountAllLists += talkCount
            totalSecondsAllLists += totalSeconds
            let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            KeyToAlbumStats[content] = stats
        }
        
        let durationDisplayAllLists = secondsToDurationDisplay(seconds: totalSecondsAllLists)
        
        let stats = AlbumStats(totalTalks: talkCountAllLists, totalSeconds: totalSecondsAllLists, durationDisplay: durationDisplayAllLists)
        KeyToAlbumStats[KEY_ALLSPEAKERS] = stats
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
                
                let seconds = convertDurationToSeconds(duration: duration)
                totalSeconds += seconds
                
                
                let talkData =  TalkData(title: title,  url: URL,  fileName: fileName, date: date, duration: duration,  speaker: speaker, section: section, time: seconds)
                
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
                    
                    // create a Album for this speaker and add to array of speaker Albums
                    // this array will be referenced by SpeakersTableViewController
                    let albumData =  AlbumData(title: speaker, content: speaker, section: "", image: speaker)
                    SpeakerAlbums.append(albumData)
                }
                else {
                    KeyToTalks[speaker]?[0].append(talkData)
                }
                
                talkCount += 1
            }
        } catch {
            print(error)
        }
        
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
        KeyToAlbumStats[KEY_ALLTALKS] = stats
        
        SpeakerAlbums = SpeakerAlbums.sorted(by: { $0.Content < $1.Content })
    }
    
    private func loadAlbumsFromFile(jsonLocation: String) {
        
        let asset = NSDataAsset(name: jsonLocation, bundle: Bundle.main)

        var AlbumSectionPositionDict : [String: Int] = [:]
        do {
            
            let json =  try JSONSerialization.jsonObject(with: asset!.data) as! [String: AnyObject]
            
            // for each Album entry ...
            // store off the Album into the AlbumSections array
            // also store of the optional list of talks
            for Album in json["albums"] as? [AnyObject] ?? [] {
                
                let title = Album["title"] as? String ?? ""
                let content = Album["content"] as? String ?? ""
                var section = Album["section"] as? String ?? ""
                let image = Album["image"] as? String ?? ""
                let talkList = Album["talks"] as? [AnyObject] ?? []
                let albumData =  AlbumData(title: title, content: content, section: section, image: image)
                
                
                // store Album in the 2D AlbumSection array (section x Album)
                if AlbumSectionPositionDict[section] == nil {
                    // new section seen.  create new array of Albums for this section
                    AlbumSections.append([albumData])
                    AlbumSectionPositionDict[section] = AlbumSections.count - 1
                } else {
                    // section already exists.  add Album to the existing array of Albums
                    let sectionPosition = AlbumSectionPositionDict[section]!
                    AlbumSections[sectionPosition].append(albumData)
                }
                
                // get the optional talk array for this Album
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
                        //print("Album talks creating key for: \(content)")
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
        // now compute stats for the Albums
        // this means calculating the total numberof talks in each Album and total seconds for all talks in Album
        //
        let Albums = AlbumSections.joined()
        for Album in Albums {
            
            let talksInAlbum = (KeyToTalks[Album.Content] ?? [[TalkData]]()).joined()
            let talkCount = talksInAlbum.count
            
            var totalSeconds = 0
            for talk in talksInAlbum {
                totalSeconds += talk.Time
            }
            
            let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            KeyToAlbumStats[Album.Content] = stats
        }
    }
    
    
    private func loadAlbumsFromWeb(jsonLocation: String) {
        
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
            
            var AlbumSectionPositionDict : [String: Int] = [:]
            //parsing the response
            do {
                
                let json =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
                
                // for each Album entry ...
                // store off the Album into the AlbumSections array
                // also store of the optional list of talks
                for Album in json["Albums"] as? [AnyObject] ?? [] {
                    
                    let title = Album["title"] as? String ?? ""
                    let content = Album["content"] as? String ?? ""
                    let section = Album["section"] as? String ?? ""
                    let image = Album["image"] as? String ?? ""
                    let talkList = Album["talks"] as? [AnyObject] ?? []
                    let albumData =  AlbumData(title: title, content: content, section: section, image: image)
                    
                    // store Album in the 2D AlbumSection array (section x Album)
                    if AlbumSectionPositionDict[section] == nil {
                        // new section seen.  create new array of Albums for this section
                        self.AlbumSections.append([albumData])
                        AlbumSectionPositionDict[section] = self.AlbumSections.count - 1
                    } else {
                        // section already exists.  add Album to the existing array of Albums
                        let sectionPosition = AlbumSectionPositionDict[section]!
                        self.AlbumSections[sectionPosition].append(albumData)
                    }
                
                    
                    // get the optional talk array for this Album 
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
            // now compute stats for the Albums
            // this means calculating the total numberof talks in each Album and total seconds for all talks in Album
            //
            let Albums = self.AlbumSections.joined()
            for Album in Albums {
                
                let talksInAlbum = (self.KeyToTalks[Album.Content] ?? [[TalkData]]()).joined()
                let talkCount = talksInAlbum.count
                
                var totalSeconds = 0
                for talk in talksInAlbum {
                    totalSeconds += talk.Time
                 }
                let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
                self.KeyToAlbumStats[Album.Content] = stats
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
            
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
            self.KeyToAlbumStats[KEY_ALLTALKS] = stats

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
