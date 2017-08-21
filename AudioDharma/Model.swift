//
//  Model.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import os.log
import ZipArchive

// MARK: App Global Vars
let TheDataModel = Model()
let DEVICE_ID = UIDevice.current.identifierForVendor!.uuidString
//let DEVICE_ID:UInt32 = arc4random_uniform(100000000)
struct AlbumStats {
    var totalTalks: Int
    var totalSeconds: Int
    var durationDisplay: String
}
enum ALBUM_SERIES {                   // all possible states of series displays
    case ALL
    case RECOMMENDED
}

// MARK: App Global Constants
let KEY_ALLTALKS = "KEY_ALLTALKS"
let KEY_ALLSPEAKERS = "KEY_ALLSPEAKERS"
let KEY_CUSTOMALBUMS = "KEY_CUSTOMALBUMS"
let KEY_NOTES = "KEY_NOTES"
let KEY_USER_TALKHISTORY = "KEY_USER_TALKHISTORY"
let KEY_USER_SHAREHISTORY = "KEY_USER_SHAREHISTORY"
let KEY_SANGHA_TALKHISTORY = "KEY_SANGHA_TALKHISTORY"
let KEY_SANGHA_SHAREHISTORY = "KEY_SANGHA_SHAREHISTORY"
let KEY_ALL_SERIES = "KEY_ALL_SERIES"
let KEY_RECOMMENDED_SERIES = "KEY_RECOMMENDED_SERIES"

let URL_REPORTACTIVITY = "http://www.ezimba.com/AD/reportactivity.py"
let URL_GETACTIVITY = "http://www.ezimba.com/AD/activity.json"
let URL_CONFIGURATION = "http://www.ezimba.com/AD/config.zip"

let SECTION_BACKGROUND = UIColor.darkGray
let SECTION_TEXT = UIColor.white

let MAX_TALKHISTORY_COUNT = 100     // maximum number of played talks showed in user or sangha history
let MAX_SHAREHISTORY_COUNT = 100     // maximum number of shared talks showed in user of sangha history

// MARK: Global Config Variables
var MP3_ROOT = "http://www.audiodharma.org" // where to find MP3s on web.  reset by config json
var ACTIVITY_ROOT = "http://www.ezimba.com" // where to report acitivity (history, shares) on web. reset by config json
var ACTIVITY_UPDATE_INTERVAL = 60           // how many seconds until each update of sangha activity

// MARK: Global Variables
var ActivityIsUpdating = false              // flags if an activity update is running or not


class Model {
    
    //MARK: Properties
    var AlbumSections: [[AlbumData]] = []   // 2d array of sections x Albums
    var SpeakerAlbums: [AlbumData] = []     // array of Albums for all speakers
    var SeriesAlbums: [AlbumData] = []     // array of Albums for all series
    var RecommendedAlbums: [AlbumData] = []     // array of recommended Albums

    var KeyToTalks : [String: [[TalkData]]] = [:]  // dictionary keyed by content, value is 2d array of sections x talks

    var KeyToAlbumStats: [String: AlbumStats] = [:] // dictionary keyed by content, value is stat struct for Albums
    var NameToTalks: [String: TalkData]   = [String: TalkData] ()  // dictionary keyed by talk filename, value is the talk data (used by userList code to lazily bind)
    
    var UserTalkHistoryAlbum: [TalkHistoryData] = []    // history of talks for user
    var UserTalkHistoryStats: AlbumStats!
    var UserShareHistoryAlbum: [TalkHistoryData] = []   // history of shared talks for user
    
    var SangaTalkHistoryAlbum: [TalkData] = []          // history of talks for sangha
    var SanghaTalkHistoryStats: AlbumStats!
    
    var SangaShareHistoryAlbum: [TalkData] = []          // history of shares for sangha
    var SanghaShareHistoryStats: AlbumStats!
    
    var AllTalks: [TalkData] = []

    var RootController: UITableViewController!
    
    var UpdatedTalksReady: Bool = false
    var UpdatedTalksJSON: [String: AnyObject] = [String: AnyObject] ()

    
    
    // MARK: Persistant Data
    var UserAlbums: [UserAlbumData] = []      // all the custom user albums defined by this user.
    var UserNotes: [String: UserNoteData] = [:]      // all the  user notes defined by this user, indexed by fileName
    
    
    // MARK: Init
    func loadData() {
        
        // download and install json files.  synchronously wait until complete
        downloadConfiguration(jsonLocation: URL_CONFIGURATION)
        var waitCount = 0
        while UpdatedTalksReady == false {
            sleep(1)
            waitCount += 1
            print(waitCount)
            if waitCount > 20 {
                break
            }
        }
        
        // compute stats and get all user data from storage
        computeRootAlbumStats()
        computeSpeakerStats()
        computeSeriesStats()
        computeRecommendedStats()
        UserAlbums = TheDataModel.loadUserAlbumData()
        computeUserAlbumStats()
        UserNotes = TheDataModel.loadUserNoteData()
        computeNotesStats()
        UserTalkHistoryAlbum = TheDataModel.loadTalkHistoryData()
        computeTalkHistoryStats()
        UserShareHistoryAlbum = TheDataModel.loadShareHistoryData()
        computeShareHistoryStats()


#if FORLATER
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(getTalksCurrentlyBeingPlayed), userInfo: nil, repeats: true)
#endif

    }
    
    
    // MARK: Configuration
    func downloadConfiguration(jsonLocation: String) {
        
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
            print(statusCode)
            
            if (statusCode != 200) {
                print("Download Fail: ", statusCode)
                return
            } else {
                print("Download: Success")
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Download: error")
                return
            }
            
            // store the config data off
            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath = documentPath + "/" + "config.zip"
            let configPath = documentPath + "/" + "config"
            let fileURL = URL(fileURLWithPath: filePath)
            
            do {
                try responseData.write(to: fileURL)
            }
            catch let error as NSError {
                print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
            }

            // unzip it back into json
            let time1 = Date.timeIntervalSinceReferenceDate
            SSZipArchive.unzipFile(atPath: filePath, toDestination: configPath)
            let time2 = Date.timeIntervalSinceReferenceDate
            print("Zip time: ", time2 - time1)
            
            let configURL = URL(fileURLWithPath: documentPath + "/config/config.json")
            var jsonData: Data!
            do {
                jsonData = try Data(contentsOf: configURL)
            }
            catch let error as NSError {
                print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
            }

            self.parseConfiguration(jsonData: jsonData)
            
            // load sangha activity after everything else is processed.  necessary since we refer to Talks array
            self.downloadSanghaActivity()
        }
        task.resume()
    }
    
    
    func parseConfiguration(jsonData: Data) {
        
        do {
            let json =  try JSONSerialization.jsonObject(with: jsonData) as! [String: AnyObject]

            var talkCount = 0
            var totalSeconds = 0
            
            // get global config information
            let config = json["config"]
            MP3_ROOT = config?["MP3_ROOT"] as? String ?? MP3_ROOT
        
            // get all talks
            for talk in json["talks"] as? [AnyObject] ?? [] {
            
                let series = talk["series"] as? String ?? ""
                let title = talk["title"] as? String ?? ""
                let URL = (talk["url"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let speaker = talk["speaker"] as? String ?? ""
                let date = talk["date"] as? String ?? ""
                let duration = talk["duration"] as? String ?? ""
            
                let section = ""
            
                let terms = URL.components(separatedBy: "/")
                let fileName = terms.last ?? ""
            
                let seconds = self.convertDurationToSeconds(duration: duration)
                totalSeconds += seconds
            
            
                let talkData =  TalkData(title: title,  url: URL,  fileName: fileName, date: date, durationDisplay: duration,  speaker: speaker, section: section, durationInSeconds: seconds)
                
                self.NameToTalks[fileName] = talkData
            
                // add this talk to  list of all talks
                // Note: there is only one talk section for KEY_ALLTALKS.  all talks are stored in that section
                self.AllTalks.append(talkData)
            
                // add talk to the list of talks for this speaker
                // Note: there is only one talk section for speaker. talks for this speaker are stored in that section
                if self.KeyToTalks[speaker] == nil {
                    self.KeyToTalks[speaker] = [[TalkData]] ()
                    self.KeyToTalks[speaker]?.append([talkData])
                
                    // create a Album for this speaker and add to array of speaker Albums
                    // this array will be referenced by SpeakersController
                    let albumData =  AlbumData(title: speaker, content: speaker, section: "", image: speaker, date: date)
                    self.SpeakerAlbums.append(albumData)
                }
                else {
                    self.KeyToTalks[speaker]?[0].append(talkData)
                }
            
                // if a series is specified, add to a series list
                if series.characters.count > 1 {
                
                    let seriesKey = "SERIES" + series
                    //print(seriesKey)
                    if self.KeyToTalks[seriesKey] == nil {
                        self.KeyToTalks[seriesKey] = [[TalkData]] ()
                        self.KeyToTalks[seriesKey]?.append([talkData])
                    
                        // create a Album for this series and add to array of series Albums
                        // this array will be referenced by SeriesController
                        let albumData =  AlbumData(title: series, content: seriesKey, section: "", image: speaker, date: date)
                        self.SeriesAlbums.append(albumData)
                    }
                    else {
                        self.KeyToTalks[seriesKey]?[0].append(talkData)
                    }
                }
            
                talkCount += 1
            }
        
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
            self.KeyToAlbumStats[KEY_ALLTALKS] = stats
        
            self.SpeakerAlbums = self.SpeakerAlbums.sorted(by: { $0.Content < $1.Content })
            self.SeriesAlbums = self.SeriesAlbums.sorted(by: { $0.Date > $1.Date })
            
            
            // talks finished.  now get all albums
            var albumSectionPositionDict : [String: Int] = [:]
            for Album in json["albums"] as? [AnyObject] ?? [] {
            
                let section = Album["section"] as? String ?? ""
                let title = Album["title"] as? String ?? ""
                let content = Album["content"] as? String ?? ""
                let image = Album["image"] as? String ?? ""
                let talkList = Album["talks"] as? [AnyObject] ?? []
                let albumData =  AlbumData(title: title, content: content, section: section, image: image, date: "")
            
                //print(albumData)
                // store Album in the 2D AlbumSection array (section x Album)
                if albumSectionPositionDict[section] == nil {
                    // new section seen.  create new array of Albums for this section
                    self.AlbumSections.append([albumData])
                    albumSectionPositionDict[section] = self.AlbumSections.count - 1
                } else {
                    // section already exists.  add Album to the existing array of Albums
                    let sectionPosition = albumSectionPositionDict[section]!
                    self.AlbumSections[sectionPosition].append(albumData)
                }
            
                // get the optional talk array for this Album
                // if exists, store off all the talks in keyToTalks keyed by 'content' id
                // the value for this key is a 2d array (section x talks)
                var talkSectionPositionDict : [String: Int] = [:]
                for talk in talkList {
                
                    var section = talk["section"] as? String ?? ""
                    var series = talk["series"] as? String ?? ""
                    let titleTitle = talk["title"] as? String ?? ""
                    let URL = talk["url"] as? String ?? ""
                    let speaker = talk["speaker"] as? String ?? ""
                    let date = talk["date"] as? String ?? ""
                    let duration = talk["duration"] as? String ?? ""
                
                    if section.range(of:"_") != nil {
                        section = ""
                    }
                
                    let totalSeconds = self.convertDurationToSeconds(duration: duration)
                
                    let urlPhrases = URL.components(separatedBy: "/")
                    var fileName = (urlPhrases[urlPhrases.endIndex - 1]).trimmingCharacters(in: .whitespacesAndNewlines)
                    fileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
                
                    let talkData =  TalkData(title: titleTitle, url: URL, fileName: "TBD", date: date, durationDisplay: duration,  speaker: speaker, section: section, durationInSeconds: totalSeconds)
                    
                    // if a series is specified, add to a series list
                    if series.characters.count > 1 {
                        
                        let seriesKey = "RECOMMENDED" + series
                        //print(seriesKey)
                        if self.KeyToTalks[seriesKey] == nil {
                            self.KeyToTalks[seriesKey] = [[TalkData]] ()
                            self.KeyToTalks[seriesKey]?.append([talkData])
                            
                            // create a Album for this series and add to array of series Albums
                            // this array will be referenced by SeriesController
                            let albumData =  AlbumData(title: series, content: seriesKey, section: "", image: speaker, date: date)
                            self.RecommendedAlbums.append(albumData)
                        }
                        else {
                            self.KeyToTalks[seriesKey]?[0].append(talkData)
                        }
                    }

                
                    // create the key -> talkData[] entry if it doesn't already exist
                    if self.KeyToTalks[content] == nil {
                        //print("Album talks creating key for: \(content)")
                        self.KeyToTalks[content]  = []
                    }
                
                    // now add the talk data to this key
                    if talkSectionPositionDict[section] == nil {
                        // new section seen.  create new array of talks for this section
                        //print("new section seen. creating array for: \(content)")
                        self.KeyToTalks[content]!.append([talkData])
                        talkSectionPositionDict[section] = self.KeyToTalks[content]!.count - 1
                    } else {
                        // section already exists.  add talk to the existing array of talks
                        let sectionPosition = talkSectionPositionDict[section]!
                        self.KeyToTalks[content]![sectionPosition].append(talkData)
                    }
                }
            } // end Album loop
        }  // end do
        catch {
            print(error)
        }
        
        self.UpdatedTalksReady = true
    }
    
    func downloadSanghaActivity() {
        
        ActivityIsUpdating = true
        
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
                ActivityIsUpdating = false
                return
            }
            
            //parse the response
            var talkCount = 0
            var totalSeconds = 0
            var durationDisplay : String
            var stats : AlbumStats
            
            do {
                
                let json =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
                
                for talkHistory in json["sangha_history"] as? [AnyObject] ?? [] {
                    
                    let fileName = talkHistory["filename"] as? String ?? ""
                    let datePlayed = talkHistory["date"] as? String ?? ""
                    let timePlayed = talkHistory["time"] as? String ?? ""
                    let location = talkHistory["location"] as? String ?? ""
                    
                    if let talk = self.NameToTalks[fileName] {
                        
                        talk.DatePlayed = datePlayed
                        talk.TimePlayed = timePlayed
                        talk.Location = location
                        
                        let duration = talk.DurationDisplay
                        let seconds = self.convertDurationToSeconds(duration: duration)
                        totalSeconds += seconds
                        talkCount += 1
                        
                        self.SangaTalkHistoryAlbum.append(talk)
                    }
                }
                var durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
                var stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
                self.SanghaTalkHistoryStats = stats

                talkCount = 0
                totalSeconds = 0
                for talkHistory in json["sangha_shares"] as? [AnyObject] ?? [] {
                    
                    let fileName = talkHistory["filename"] as? String ?? ""
                    let dateShared = talkHistory["date"] as? String ?? ""
                    let timeShared = talkHistory["time"] as? String ?? ""
                    let location = talkHistory["location"] as? String ?? ""
                    
                    if let talk = self.NameToTalks[fileName] {
                        
                        talk.DatePlayed = dateShared
                        talk.TimePlayed = timeShared
                        talk.Location = location
                        
                        let duration = talk.DurationDisplay
                        let seconds = self.convertDurationToSeconds(duration: duration)
                        totalSeconds += seconds
                        talkCount += 1
                        
                        self.SangaShareHistoryAlbum.append(talk)
                    }
                }
                
                durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
                stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
                self.SanghaShareHistoryStats = stats

            } catch {
                ActivityIsUpdating = false
                print(error)
            }
            
            ActivityIsUpdating = false
            self.refreshControllers()

        }
        task.resume()
    }
    
    
    // MARK: Support Functions
    func loadTalksFromFile(jsonLocation: String) {
        
        let asset = NSDataAsset(name: jsonLocation, bundle: Bundle.main)
        do {
            let json =  try JSONSerialization.jsonObject(with: asset!.data) as! [String: AnyObject]
            //parseTalks(json: json)
         } catch {
            print(error)
        }
    }
    
    func refreshControllers() {
        
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
                totalSeconds += talk.DurationInSeconds
            }
            
            let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
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
                    totalSeconds += talk.DurationInSeconds
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
    
    func computeSpeakerStats() {
        
        var totalSecondsAllLists = 0
        var talkCountAllLists = 0
        
        for album in SpeakerAlbums {
            
            let content = album.Content
            var totalSeconds = 0
            var talkCount = 0
            for talk in (KeyToTalks[content]?[0])! {
                totalSeconds += talk.DurationInSeconds
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
    
    func computeSeriesStats() {
        
        var totalSecondsAllLists = 0
        var talkCountAllLists = 0
        
        for album in SeriesAlbums {
            
            let content = album.Content
            var totalSeconds = 0
            var talkCount = 0
            for talk in (KeyToTalks[content]?[0])! {
                totalSeconds += talk.DurationInSeconds
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
        KeyToAlbumStats[KEY_ALL_SERIES] = stats
    }
    
    func computeRecommendedStats() {
        
        var totalSecondsAllLists = 0
        var talkCountAllLists = 0
        
        for album in RecommendedAlbums {
            
            let content = album.Content
            var totalSeconds = 0
            var talkCount = 0
            for talk in (KeyToTalks[content]?[0])! {
                totalSeconds += talk.DurationInSeconds
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
        KeyToAlbumStats[KEY_RECOMMENDED_SERIES] = stats
    }
    
    func computeNotesStats() {
        
        var talkCount = 0
        var totalSeconds = 0
        
        for (fileName, _) in UserNotes {
            
            if let talk = NameToTalks[fileName] {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
        }
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        
        KeyToAlbumStats[KEY_NOTES] = stats
    }
    
    func computeTalkHistoryStats() {
        
        var talkCount = 0
        var totalSeconds = 0
        
        for talkHistory in UserTalkHistoryAlbum {
            let fileName = talkHistory.FileName
            if let talk = NameToTalks[fileName] {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
        }
        
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        
        KeyToAlbumStats[KEY_USER_TALKHISTORY] = stats
    }
    
    func computeShareHistoryStats() {
        var talkCount = 0
        var totalSeconds = 0
    
        for talkHistory in UserShareHistoryAlbum {
            let fileName = talkHistory.FileName
            if let talk = NameToTalks[fileName] {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
        }
    
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
    
        KeyToAlbumStats[KEY_USER_SHAREHISTORY] = stats
    }
    

    // MARK: Persistant API
    func saveUserAlbumData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserAlbums, toFile: UserAlbumData.ArchiveURL.path)
    }
    
    func saveUserNoteData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserNotes, toFile: UserNoteData.ArchiveURL.path)
    }
    
    func saveTalkHistoryData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserTalkHistoryAlbum, toFile: TalkHistoryData.ArchiveTalkHistoryURL.path)
        
    }
    
    func saveShareHistoryData() {
        
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserShareHistoryAlbum, toFile: TalkHistoryData.ArchiveShareHistoryURL.path)
        
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
        
        print("Talk History Path: ", TalkHistoryData.ArchiveTalkHistoryURL.path)
        if let talkHistory = NSKeyedUnarchiver.unarchiveObject(withFile: TalkHistoryData.ArchiveTalkHistoryURL.path)
            as? [TalkHistoryData] {
            
            return talkHistory
        } else {
            
            return [TalkHistoryData] ()
        }
    }
    
    func loadShareHistoryData() -> [TalkHistoryData]  {
        
        print("Talk Share Path: ", TalkHistoryData.ArchiveShareHistoryURL.path)
        if let talkHistory = NSKeyedUnarchiver.unarchiveObject(withFile: TalkHistoryData.ArchiveShareHistoryURL.path)
            as? [TalkHistoryData] {
            
            return talkHistory
        } else {
            
            return [TalkHistoryData] ()
        }
    }

    
    // MARK: API
    func getTalks(content: String) -> [[TalkData]] {
        
        var talkList : [[TalkData]]
        
        switch content {
        case KEY_NOTES:
            var talks = [TalkData] ()
            for (fileName, _) in UserNotes {
                if let talk = NameToTalks[fileName] {
                    talks.append(talk)
                }
            }
            talkList =  [talks]
            
        case KEY_USER_TALKHISTORY:
            var talks = [TalkData] ()
            for talkHistory in UserTalkHistoryAlbum {
                let fileName = talkHistory.FileName
                if let talk = NameToTalks[fileName] {
                    
                    talk.DatePlayed = talkHistory.DatePlayed
                    talk.TimePlayed = talkHistory.TimePlayed
                    talk.Location = talkHistory.Location
                    talks.append(talk)
                }
            }
            talkList =  [talks.reversed()]
            
        case KEY_USER_SHAREHISTORY:
            var talks = [TalkData] ()
            for talkHistory in UserShareHistoryAlbum {
                let fileName = talkHistory.FileName
                if let talk = NameToTalks[fileName] {
                    
                    talk.DatePlayed = talkHistory.DatePlayed
                    talk.TimePlayed = talkHistory.TimePlayed
                    talk.Location = talkHistory.Location
                    talks.append(talk)
                }
            }
            talkList = [talks.reversed()]

        case KEY_SANGHA_TALKHISTORY:
            
            var talks = [TalkData] ()
            for talkHistory in SangaTalkHistoryAlbum {
                let fileName = talkHistory.FileName
                if let talk = NameToTalks[fileName] {
                    talks.append(talk)
                }
            }
            talkList = [talks]
            
        case KEY_SANGHA_SHAREHISTORY:
            
            var talks = [TalkData] ()
            for talkHistory in SangaShareHistoryAlbum {
                let fileName = talkHistory.FileName
                if let talk = NameToTalks[fileName] {
                    talks.append(talk)
                }
            }
            talkList = [talks]

        case KEY_ALL_SERIES:
            talkList = KeyToTalks[content] ?? [[TalkData]]()
 
        case KEY_ALLTALKS:
            talkList =  [AllTalks]

        default:
            talkList =  KeyToTalks[content] ?? [[TalkData]]()
        }
        
        return talkList
    }
    
    func getAlbumStats(content: String) -> AlbumStats {
        
        
        var stats: AlbumStats

        switch content {
        
        case KEY_ALLTALKS:
            stats = KeyToAlbumStats[content] ?? AlbumStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
        
        case KEY_SANGHA_TALKHISTORY:
            stats = SanghaTalkHistoryStats ?? AlbumStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
            
        case KEY_SANGHA_SHAREHISTORY:
            stats = SanghaShareHistoryStats ?? AlbumStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
            
        default:
            stats =  KeyToAlbumStats[content] ?? AlbumStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
            
        }
        
        return stats
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
        
        if UserTalkHistoryAlbum.count >= MAX_TALKHISTORY_COUNT {
            UserTalkHistoryAlbum.remove(at: 0)
        }
        

        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let datePlayed = formatter.string(from: date)
        
        formatter.dateFormat = "HH:mm:ss"
        let timePlayed = formatter.string(from: date)
        
        let talkHistory = TalkHistoryData(fileName: talk.FileName, datePlayed: datePlayed, timePlayed: timePlayed, location: "" )
        UserTalkHistoryAlbum.append(talkHistory)
        
        // save the data, recompute stats, reload root view to display updated stats
        saveTalkHistoryData()
        computeTalkHistoryStats()
        refreshControllers()
    }
    
    func addToShareHistory(talk: TalkData) {
        
        if UserShareHistoryAlbum.count >= MAX_SHAREHISTORY_COUNT {
            UserShareHistoryAlbum.remove(at: 0)
        }
        
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let datePlayed = formatter.string(from: date)
        formatter.dateFormat = "HH:mm:ss"
        let timePlayed = formatter.string(from: date)
        
        let talkHistory = TalkHistoryData(fileName: talk.FileName, datePlayed: datePlayed, timePlayed: timePlayed, location: "" )
        UserShareHistoryAlbum.append(talkHistory)
        
        // save the data, recompute stats, reload root view to display updated stats
        saveShareHistoryData()
        computeShareHistoryStats()
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
        
        addToShareHistory(talk: sharedTalk)
        
        let shareText = "\(sharedTalk.Title) by \(sharedTalk.Speaker) \nShared from the iPhone AudioDharma app"
        let objectsToShare: URL = URL(string: MP3_ROOT + sharedTalk.URL)!
        
        let sharedObjects:[AnyObject] = [objectsToShare as AnyObject, shareText as AnyObject]
        //let sharedObjects: [AnyObject] = [objectsToShare as AnyObject, bylineText as AnyObject]
        
        let activityViewController = UIActivityViewController(activityItems: sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = controller.view // so that iPads won't crash
        
        controller.present(activityViewController, animated: true, completion: nil)
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
    func testload(fileLocation: String) {
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        let requestURL : URL? = URL(string: fileLocation)
        let urlRequest = URLRequest(url : requestURL!)
        
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            print(statusCode)
            
            if (statusCode == 200) {
                print("Download: success")
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Download: error")
                return
            }
            
            print("Response Data Size: ", responseData.count)
            
            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath = documentPath + "/" + "config02.zip"
            let configPath = documentPath + "/" + "config"
            let fileURL = URL(fileURLWithPath: filePath)
            
            do {
                try responseData.write(to: fileURL)
            }
            catch let error as NSError {
                print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
            }
            
            let time1 = Date.timeIntervalSinceReferenceDate
            SSZipArchive.unzipFile(atPath: filePath, toDestination: configPath)
            let time2 = Date.timeIntervalSinceReferenceDate
            print("Zip time: ", time2 - time1)
            
        }
        
        task.resume()
    }
 */
    
    
    
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
    
    #if DEV
    func loadConfigFromWeb(jsonLocation: String) {
    
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
    print(statusCode)
    
    if (statusCode == 200) {
    print("Download: success")
    }
    
    // make sure we got data
    guard let responseData = data else {
    print("Download: error")
    return
    }
    
    // store the config data off
    let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let filePath = documentPath + "/" + "config02.zip"
    let configPath = documentPath + "/" + "config"
    let fileURL = URL(fileURLWithPath: filePath)
    print("Document Path: ", documentPath)
    
    
    do {
    try responseData.write(to: fileURL)
    }
    catch let error as NSError {
    print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
    }
    
    // unzip it back into json
    let time1 = Date.timeIntervalSinceReferenceDate
    SSZipArchive.unzipFile(atPath: filePath, toDestination: configPath)
    let time2 = Date.timeIntervalSinceReferenceDate
    print("Zip time: ", time2 - time1)
    
    let configURL = URL(fileURLWithPath: documentPath + "/config/config02.json")
    var jsonData: Data!
    do {
    jsonData = try Data(contentsOf: configURL)
    }
    catch let error as NSError {
    print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
    }
    
    
    
    do {
    //let json =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
    //let json = jsonData as! [String: AnyObject]
    let json =  try JSONSerialization.jsonObject(with: jsonData) as! [String: AnyObject]
    var talkCount = 0
    var totalSeconds = 0
    
    for talk in json["talks"] as? [AnyObject] ?? [] {
    
    let series = talk["series"] as? String ?? ""
    let title = talk["title"] as? String ?? ""
    let URL = (talk["url"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let speaker = talk["speaker"] as? String ?? ""
    let date = talk["date"] as? String ?? ""
    let duration = talk["duration"] as? String ?? ""
    
    let section = ""
    
    let terms = URL.components(separatedBy: "/")
    let fileName = terms.last ?? ""
    
    let seconds = self.convertDurationToSeconds(duration: duration)
    totalSeconds += seconds
    
    
    let talkData =  TalkData(title: title,  url: URL,  fileName: fileName, date: date, duration: duration,  speaker: speaker, section: section, time: seconds)
    
    //print(talkData)
    
    
    self.NameToTalks[fileName] = talkData
    
    // add this talk to  list of all talks
    // Note: there is only one talk section for KEY_ALLTALKS.  all talks are stored in that section
    self.AllTalks.append(talkData)
    
    // add talk to the list of talks for this speaker
    // Note: there is only one talk section for speaker. talks for this spearker are stored in that section
    if self.KeyToTalks[speaker] == nil {
    self.KeyToTalks[speaker] = [[TalkData]] ()
    self.KeyToTalks[speaker]?.append([talkData])
    
    // create a Album for this speaker and add to array of speaker Albums
    // this array will be referenced by SpeakersController
    let albumData =  AlbumData(title: speaker, content: speaker, section: "", image: speaker, date: date)
    self.SpeakerAlbums.append(albumData)
    }
    else {
    self.KeyToTalks[speaker]?[0].append(talkData)
    }
    
    // if a series is specified, add to a series list
    if series.characters.count > 1 {
    
    let seriesKey = "SERIES" + series
    //print(seriesKey)
    if self.KeyToTalks[seriesKey] == nil {
    self.KeyToTalks[seriesKey] = [[TalkData]] ()
    self.KeyToTalks[seriesKey]?.append([talkData])
    
    // create a Album for this series and add to array of series Albums
    // this array will be referenced by SeriesController
    let albumData =  AlbumData(title: series, content: seriesKey, section: "", image: speaker, date: date)
    self.SeriesAlbums.append(albumData)
    }
    else {
    self.KeyToTalks[seriesKey]?[0].append(talkData)
    }
    }
    
    talkCount += 1
    }
    
    let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: "")
    self.KeyToAlbumStats[KEY_ALLTALKS] = stats
    
    self.SpeakerAlbums = self.SpeakerAlbums.sorted(by: { $0.Content < $1.Content })
    self.SeriesAlbums = self.SeriesAlbums.sorted(by: { $0.Date > $1.Date })
    
    
    var albumSectionPositionDict : [String: Int] = [:]
    
    for Album in json["albums"] as? [AnyObject] ?? [] {
    
    var section = Album["section"] as? String ?? ""
    let title = Album["title"] as? String ?? ""
    let content = Album["content"] as? String ?? ""
    let image = Album["image4"] as? String ?? ""
    let talkList = Album["talks"] as? [AnyObject] ?? []
    let albumData =  AlbumData(title: title, content: content, section: section, image: image, date: "")
    
    //print(albumData)
    // store Album in the 2D AlbumSection array (section x Album)
    if albumSectionPositionDict[section] == nil {
    // new section seen.  create new array of Albums for this section
    self.AlbumSections.append([albumData])
    albumSectionPositionDict[section] = self.AlbumSections.count - 1
    } else {
    // section already exists.  add Album to the existing array of Albums
    let sectionPosition = albumSectionPositionDict[section]!
    self.AlbumSections[sectionPosition].append(albumData)
    }
    
    // get the optional talk array for this Album
    // if exists, store off all the talks in keyToTalks keyed by 'content' id
    // the value for this key is a 2d array (section x talks)
    var talkSectionPositionDict : [String: Int] = [:]
    for talk in talkList {
    
    var section = talk["section"] as? String ?? ""
    let titleTitle = talk["title"] as? String ?? ""
    let URL = talk["url"] as? String ?? ""
    var speaker = talk["speaker"] as? String ?? ""
    let date = talk["date"] as? String ?? ""
    let duration = talk["duration"] as? String ?? ""
    
    if section.range(of:"_") != nil {
    section = ""
    }
    
    let totalSeconds = self.convertDurationToSeconds(duration: duration)
    
    let urlPhrases = URL.components(separatedBy: "/")
    var fileName = (urlPhrases[urlPhrases.endIndex - 1]).trimmingCharacters(in: .whitespacesAndNewlines)
    fileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
    
    let talkData =  TalkData(title: titleTitle, url: URL, fileName: "TBD", date: date, duration: duration,  speaker: speaker, section: section, time: totalSeconds)
    
    // create the key -> talkData[] entry if it doesn't already exist
    if self.KeyToTalks[content] == nil {
    //print("Album talks creating key for: \(content)")
    self.KeyToTalks[content]  = []
    }
    
    // now add the talk data to this key
    if talkSectionPositionDict[section] == nil {
    // new section seen.  create new array of talks for this section
    //print("new section seen. creating array for: \(content)")
    self.KeyToTalks[content]!.append([talkData])
    talkSectionPositionDict[section] = self.KeyToTalks[content]!.count - 1
    } else {
    // section already exists.  add talk to the existing array of talks
    let sectionPosition = talkSectionPositionDict[section]!
    self.KeyToTalks[content]![sectionPosition].append(talkData)
    
    }
    }
    }
    self.UpdatedTalksReady = true
    
    } catch {
    print(error)
    }
    
    
    }
    task.resume()
    }
    #endif

    
}
