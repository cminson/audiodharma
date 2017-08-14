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
let KEY_ALLSERIES = "KEY_ALLSERIES"

let URL_REPORTACTIVITY = "http://www.ezimba.com/AD/reportactivity.py"
let URL_GETACTIVITY = "http://www.ezimba.com/AD/test01.json"

let MAX_TALKHISTORY_COUNT = 20

let TALK_BASE = "http://www.audiodharma.org"


class Model {
    
    //MARK: Properties
    var AlbumSections: [[AlbumData]] = []   // 2d array of sections x Albums
    var SpeakerAlbums: [AlbumData] = []     // array of Albums for all speakers
    var SeriesAlbums: [AlbumData] = []     // array of Albums for all series

    var KeyToTalks : [String: [[TalkData]]] = [:]  // dictionary keyed by content, value is 2d array of sections x talks

    var KeyToAlbumStats: [String: AlbumStats] = [:] // dictionary keyed by content, value is stat struct for Albums
    var NameToTalks: [String: TalkData]   = [String: TalkData] ()  // dictionary keyed by talk filename, value is the talk data (used by userList code to lazily bind)
    
    var TalkHistoryAlbum: [TalkHistoryData] = []
    var TalksBeingPlayed: [TalkData] = []
    var AllTalks: [TalkData] = []

    var KeyAlbumStats: AlbumStats!
    
    var RootController: UITableViewController!
    
    var UpdatedTalksReady: Bool = false
    var UpdatedTalksJSON: [String: AnyObject] = [String: AnyObject] ()

    
    
    // MARK: Persistant Data
    var UserAlbums: [UserAlbumData] = []      // all the custom user albums defined by this user.
    var UserNotes: [String: UserNoteData] = [:]      // all the  user notes defined by this user, indexed by fileName
    
    
    // MARK: Init
    func loadData() {
        
        // start getting sangha information from web
        loadTalksFromWeb(jsonLocation: "http://www.ezimba.com/AD/updatedtalks.json")
        getTalksCurrentlyBeingPlayed()
        
        // get baseline talks and Albums
        loadTalksFromFile(jsonLocation: "alltalks")
        loadAlbumsFromFile(jsonLocation: "albums02")
        
        var waitCount = 0
        while UpdatedTalksReady == false {
            sleep(1)
            waitCount += 1
            print(waitCount)
            if waitCount > 4 {
                break
            }
        }
        
        if UpdatedTalksReady == true {
            parseTalks(json: UpdatedTalksJSON)
        }

        computeRootAlbumStats()
        computeSpeakerStats()
        computeSeriesStats()
        
        // get user data from storage and compute stats
        UserAlbums = TheDataModel.loadUserAlbumData()
        computeUserAlbumStats()
        UserNotes = TheDataModel.loadUserNoteData()
        computeNotesStats()
        TalkHistoryAlbum = TheDataModel.loadTalkHistoryData()
        computeHistoryStats()

        
    }
    
    func parseTalks(json: [String: AnyObject]) {

        var talkCount = 0
        var totalSeconds = 0

        for talk in json["talks"] as? [AnyObject] ?? [] {
            
            let title = talk["title"] as? String ?? ""
            let series = talk["series"] as? String ?? ""
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
            AllTalks.append(talkData)
           
            // add talk to the list of talks for this speaker
            // Note: there is only one talk section for speaker. talks for this spearker are stored in that section
            if KeyToTalks[speaker] == nil {
                KeyToTalks[speaker] = [[TalkData]] ()
                KeyToTalks[speaker]?.append([talkData])
                
                // create a Album for this speaker and add to array of speaker Albums
                // this array will be referenced by SpeakersController
                let albumData =  AlbumData(title: speaker, content: speaker, section: "", image: speaker, date: date)
                SpeakerAlbums.append(albumData)
            }
            else {
                KeyToTalks[speaker]?[0].append(talkData)
            }
            
            // if a series is specified, add to a series list
            if series.characters.count > 1 {
                
                let seriesKey = "SERIES" + series
                //print(seriesKey)
                if KeyToTalks[seriesKey] == nil {
                    KeyToTalks[seriesKey] = [[TalkData]] ()
                    KeyToTalks[seriesKey]?.append([talkData])
                    
                    // create a Album for this series and add to array of series Albums
                    // this array will be referenced by SeriesController
                    let albumData =  AlbumData(title: series, content: seriesKey, section: "", image: speaker, date: date)
                    SeriesAlbums.append(albumData)
                }
                else {
                    KeyToTalks[seriesKey]?[0].append(talkData)
                }
            }
            
            talkCount += 1
        }
        
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
        KeyToAlbumStats[KEY_ALLTALKS] = stats
        
        SpeakerAlbums = SpeakerAlbums.sorted(by: { $0.Content < $1.Content })
        SeriesAlbums = SeriesAlbums.sorted(by: { $0.Date > $1.Date })
        AllTalks = AllTalks.sorted(by: { $0.Date > $1.Date })
        
    }
    
    
    
    // MARK: Load Data
    func loadTalksFromFile(jsonLocation: String) {
        
        let asset = NSDataAsset(name: jsonLocation, bundle: Bundle.main)
        do {
            let json =  try JSONSerialization.jsonObject(with: asset!.data) as! [String: AnyObject]
            parseTalks(json: json)
         } catch {
            print(error)
        }
    }
    
    func loadTalksFromWeb(jsonLocation: String) {
        
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
            
            do {
                self.UpdatedTalksJSON =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
                self.UpdatedTalksReady = true
                
            } catch {
                print(error)
            }
            
            
        }
        task.resume()
    }

    
    func loadAlbumsFromFile(jsonLocation: String) {
        
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
                let albumData =  AlbumData(title: title, content: content, section: section, image: image, date: "")
                
                
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
        
    }
    
    
    
    func refreshControllers() {
        
        print("refreshControllers")
        DispatchQueue.main.async(execute: {
            print("executing refreshControllers")

            self.RootController.tableView.reloadData()
            return
        })
    }
    
    func computeRootAlbumStats() {
        
        let Albums = self.AlbumSections.joined()
        for Album in Albums {
            
            let talksInAlbum = self.getTalks(content: Album.Content).joined()
            let talkCount = talksInAlbum.count
            
            var totalSeconds = 0
            for talk in talksInAlbum {
                totalSeconds += talk.Time
            }
            
            let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            print(stats)
            self.KeyToAlbumStats[Album.Content] = stats
        }
        
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
    
    //
    // generate the stats for the series talk album.
    //
    func computeSeriesStats() {
        
        var totalSecondsAllLists = 0
        var talkCountAllLists = 0
        
        for album in SeriesAlbums {
            
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
        KeyToAlbumStats[KEY_ALLSERIES] = stats
    }
    
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
    
    
    // MARK: Persistant API
    func saveUserAlbumData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserAlbums, toFile: UserAlbumData.ArchiveURL.path)
    }
    
    func saveUserNoteData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserNotes, toFile: UserNoteData.ArchiveURL.path)
    }
    
    func saveTalkHistoryData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.TalkHistoryAlbum, toFile: TalkHistoryData.ArchiveURL.path)
        
    }
    
    
    func loadUserAlbumData() -> [UserAlbumData]  {
        
        if let userAlbumData = NSKeyedUnarchiver.unarchiveObject(withFile: UserAlbumData.ArchiveURL.path) as? [UserAlbumData] {
            
            return userAlbumData
        } else {
            
            return [UserAlbumData] ()
        }
    }
    
    func loadUserNoteData() -> [String: UserNoteData]  {
        
        if let userNotes = NSKeyedUnarchiver.unarchiveObject(withFile: UserNoteData.ArchiveURL.path)
            as? [String: UserNoteData] {
            
            return userNotes
        } else {
            
            return [String: UserNoteData] ()
        }
    }
    
    func loadTalkHistoryData() -> [TalkHistoryData]  {
        
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
            
        case KEY_ALLSERIES:
            return KeyToTalks[content] ?? [[TalkData]]()
 
        case KEY_ALLTALKS:
            return [AllTalks]

            
        default:
            return KeyToTalks[content] ?? [[TalkData]]()
        }
    }
    
    func getAlbumStats(content: String) -> AlbumStats {
        
        switch content {
            
        case KEY_TALKSBEINGPLAYED:
            return KeyAlbumStats
        case KEY_ALLTALKS:
            let stats = KeyToAlbumStats[content] ?? AlbumStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
            return stats
            
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
    
    func addUserAlbum(album: UserAlbumData) {
        
        UserAlbums.append(album)
    }
    
    func removeUserAlbum(at: Int) {
        
        UserAlbums.remove(at: at)
    }
    
    func removeUserAlbum(userAlbum: UserAlbumData) {
        
        for (index, album) in UserAlbums.enumerated() {
            
            if album.Content == userAlbum.Content {
                
                UserAlbums.remove(at: index)
                break
            }
        }
    }
    
    func getUserAlbumTalks(userAlbum: UserAlbumData) -> [TalkData]{
        
        var userAlbumTalks = [TalkData] ()
        
        for talkFileName in userAlbum.TalkFileNames {
            if let talk = getTalkForName(name: talkFileName) {
                userAlbumTalks.append(talk)
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
        
        //let titleText = "\(sharedTalk.Title) by \(sharedTalk.Speaker)\n"
        //let bylineText = "This talk was shared from the iPhone AudioDharma app"
        
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
    
    func secondsToDurationDisplay(seconds: Int) -> String {
        
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
