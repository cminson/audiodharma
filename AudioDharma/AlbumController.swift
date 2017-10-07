//
//  AlbumController.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import CoreLocation



class AlbumController: UITableViewController, CLLocationManagerDelegate {
    
    @IBOutlet var buttonHelp: UIBarButtonItem!
    @IBOutlet var buttonDonate: UIBarButtonItem!
    
    //MARK: Properties
    var SelectedSection: Int = 0
    var SelectedRow: Int = 0
    var AlbumSections: [[AlbumData]] = []
    //var FilteredAlbumSections:  [[AlbumData]] = []

    var locationManager: CLLocationManager = CLLocationManager()
    var startLocation: CLLocation!
    
    var HelpPageText = ""
    var BusyIndicator =  UIActivityIndicatorView()

    
    // MARK: Init
    override func viewDidLoad() {
        
        print("viewDidLoad")
        super.viewDidLoad()
        
        BusyIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        BusyIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        BusyIndicator.center = self.view.center
        BusyIndicator.color = UIColor(red:0.00, green:0.39, blue:0.00, alpha:1.0)
        self.view.addSubview(BusyIndicator)
        
        BusyIndicator.isHidden = false
        BusyIndicator.startAnimating()

        self.tableView.delegate = self
        
        TheDataModel.RootController = self
        TheDataModel.loadData()
        
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.toolbar.barStyle = UIBarStyle.blackOpaque
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([buttonHelp, flexibleItem, buttonDonate], animated: false)
        
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        startLocation = nil
        
    }
    
    override func viewWillAppear(_ animated: Bool) {

        print("viewWillAppear")
        super.viewWillAppear(animated)
        
 
    }

    override func viewWillDisappear(_ animated: Bool) {
        
        print("viewWillDisappear")
        super.viewWillDisappear(animated)
    }

    deinit {
        
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    func reloadModel() {

    }
    
    func reportModelLoaded() {
        
        DispatchQueue.main.async {
            self.BusyIndicator.isHidden = true
            self.BusyIndicator.stopAnimating()
        }
    }

    

    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier ?? "" {
            
        case "DISPLAY_TALKS":
            guard let controller = segue.destination as? TalkController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            let Album = TheDataModel.AlbumSections[SelectedSection][SelectedRow]
            controller.Content = Album.Content
            controller.title = Album.Title
            
        case "DISPLAY_USER_ALBUMS":
            guard let _ = segue.destination as? UserAlbumsController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
        case "DISLAY_SPEAKER_ALBUMS":
            guard let _ = segue.destination as? SpeakerController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
        case "DISPLAY_SERIES_ALBUMS":
            guard let controller = segue.destination as? SeriesController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            controller.SeriesType = .ALL
            controller.title = "Series Talks"
            
        case "DISPLAY_RECOMMENDED_TALKS":
            guard let controller = segue.destination as? SeriesController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            controller.SeriesType = .RECOMMENDED
            controller.title = "Recommended Talks"
            
       case "DISPLAY_HISTORY":
            guard let controller = segue.destination as? HistoryController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            let Album = TheDataModel.AlbumSections[SelectedSection][SelectedRow]
            controller.Content = Album.Content
            controller.title = Album.Title
            
        case "DISPLAY_HELP_PAGE":
            guard let navController = segue.destination as? UINavigationController, let controller = navController.viewControllers.last as? HelpController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            controller.setHelpPage(helpPage: KEY_ALBUMROOT)
            
        case "DISPLAY_DONATIONS":
            guard let _ = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }

        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier!)")
        }
        
     }


    // MARK: Table Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return TheDataModel.AlbumSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return TheDataModel.AlbumSections[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return TheDataModel.AlbumSections[section][0].Section
    }
    
    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {

        let header = view as! UITableViewHeaderFooterView
        
        view.tintColor = SECTION_BACKGROUND
        header.textLabel?.textColor = SECTION_TEXT
        header.textLabel?.textAlignment = NSTextAlignment.center
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("AlbumCell", owner: self, options: nil)?.first as! AlbumCell
        
        let Album = TheDataModel.AlbumSections[indexPath.section][indexPath.row]
    
        cell.title.text = Album.Title
        cell.albumCover.contentMode = UIViewContentMode.scaleAspectFit
        if Album.Image.characters.count > 0 {
            cell.albumCover.image = UIImage(named: Album.Image) ?? UIImage(named: "defaultPhoto")!
        } else {
            cell.albumCover.image = UIImage(named: Album.Title) ?? UIImage(named: "defaultPhoto")!
        }
        
        let AlbumStats = TheDataModel.getAlbumStats(content: Album.Content)
        
        if Album.Content == KEY_ALLTALKS {
            print("ALLTALKS STATS: ", AlbumStats)
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value:AlbumStats.totalTalks))
        cell.statTalkCount.text = formattedNumber
        
        
        cell.statTotalTime.text = AlbumStats.durationDisplay
 
        return cell
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SelectedSection = indexPath.section
        SelectedRow = indexPath.row
        
        let Album = TheDataModel.AlbumSections[indexPath.section][indexPath.row]
        
        switch Album.Content {
            
        case KEY_USER_ALBUMS:
            self.performSegue(withIdentifier: "DISPLAY_USER_ALBUMS", sender: self)
            
        case KEY_ALLSPEAKERS:
            self.performSegue(withIdentifier: "DISLAY_SPEAKER_ALBUMS", sender: self)
            
        case KEY_USER_TALKHISTORY:
            self.performSegue(withIdentifier: "DISPLAY_HISTORY", sender: self)
            
        case KEY_USER_SHAREHISTORY:
            self.performSegue(withIdentifier: "DISPLAY_HISTORY", sender: self)
            
        case KEY_USER_FAVORITES:
            self.performSegue(withIdentifier: "DISPLAY_TALKS", sender: self)
            
        case KEY_SANGHA_TALKHISTORY:
            self.performSegue(withIdentifier: "DISPLAY_HISTORY", sender: self)
            
        case KEY_SANGHA_SHAREHISTORY:
            self.performSegue(withIdentifier: "DISPLAY_HISTORY", sender: self)

        case KEY_ALL_SERIES:
            self.performSegue(withIdentifier: "DISPLAY_SERIES_ALBUMS", sender: self)
            
        case KEY_RECOMMENDED_TALKS:
            self.performSegue(withIdentifier: "DISPLAY_RECOMMENDED_TALKS", sender: self)

        default:
            self.performSegue(withIdentifier: "DISPLAY_TALKS", sender: self)
        }
    }
    
    
    // MARK: Location Services
    func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation])
    {
        if TheDataModel.isInternetAvailable() == false {
            return
        }
        
        let latestLocation: CLLocation = locations[locations.count - 1]
        let longitude = latestLocation.coordinate.longitude
        let latitude = latestLocation.coordinate.latitude
        let altitude =  latestLocation.altitude
        
        TheUserLocation.longitude = longitude
        TheUserLocation.latitude = latitude
        TheUserLocation.altitude = altitude
        // latitude.text = String(format: "%.4f", latestLocation.coordinate.latitude)

        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            // Place details
            if let placeMark = placemarks?[0] {
            
            // Address dictionary
            // City
            if let city = placeMark.addressDictionary!["City"] as? String {
                TheUserLocation.city = city
            }
            // Zip code
            if let zip = placeMark.addressDictionary!["ZIP"] as? String {
                TheUserLocation.zip = zip
            }
            // Country
            if let country = placeMark.addressDictionary!["Country"] as? String {
                TheUserLocation.country = country
            }
            }
        })
    }
    
}
