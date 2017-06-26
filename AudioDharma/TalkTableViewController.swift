//
//  TalkTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/15/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class TalkTableViewController: UITableViewController {
    
    //MARK: Properties
    var sectionTalks: [[TalkData]] = []
    var content: String = ""
    
   
    

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.sectionTalks = TheDataModel.getTalks(content: content)
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return sectionTalks.count

    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        //print("Number of rows")
        //print(self.talks.count)
        return sectionTalks[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle : String
        
        sectionTitle =  sectionTalks[section][0].section
        print(sectionTitle)
        
        return sectionTitle
        
    }


    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "TalkTableViewCell"
        
        print("tableview")
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TalkTableViewCell  else {
            fatalError("The dequeued cell is not an instance of TalkTableViewCell.")
        }
        
        let talk = sectionTalks[indexPath.section][indexPath.row]
        print(indexPath.row)
        print(talk.title)
        
        print("in deqeue")
        cell.title.text = talk.title
        cell.speakerPhoto.image = talk.speakerPhoto
        
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        print("prepare to seque")
        guard let talkDetailViewController = segue.destination as? TalkViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        guard let selectedTalkCell = sender as? TalkTableViewCell else {
            fatalError("Unexpected sender:")
        }

        guard let indexPath = tableView.indexPath(for: selectedTalkCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }

        
        let selectedTalk = sectionTalks[indexPath.section][indexPath.row]
        talkDetailViewController.talk = selectedTalk
        
        print("done seque")
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
  
    
    
    //MARK: Private Methods
    private func loadSampleTalks() {
        
        // init(title: String, summary: String, speaker: String, url: String, duration: Float)
        /*
        let photo1 = UIImage(named: "defaultPhoto")
        let photo2 = UIImage(named: "defaultPhoto")
        let photo3 = UIImage(named: "defaultPhoto")
        
        guard let talk1 = TalkData(title: "title 1", summary: "a summary", speaker: "a speaker", photo: photo1, url: "a url", duration: 28.88) else {
            fatalError("Unable to instantiate talk1")
        }
        guard let talk2 = TalkData(title: "title 2", summary: "a summary", speaker: "a speaker", photo: photo2, url: "a url", duration: 28.88) else {
            fatalError("Unable to instantiate talk1")
        }
        guard let talk3 = TalkData(title: "title 3", summary: "a summary", speaker: "a speaker", photo: photo3, url: "a url", duration: 28.88) else {
            fatalError("Unable to instantiate talk1")
        }
       
        talks += [talk1, talk2, talk3]
 */
        
    }
    
    /*
    if let path = NSBundle.mainBundle().pathForResource("test", ofType: "json")
    {
        if let jsonData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)
        {
            if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary
            {
                if let persons : NSArray = jsonResult["person"] as? NSArray
                {
                    // Do stuff
                }
            }
        }
    }
 */
    
    /*
    
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
                print(json)
                
                for talk in json["talks"] as? [AnyObject] ?? [] {
                    
                    let title = talk["title"] as? String ?? ""
                    let speaker = talk["speaker"] as? String ?? ""
                    let talkURL = talk["talk"] as? String ?? ""
                    let duration = talk["duration"] as? String ?? ""
                    let date = talk["date"] as? String ?? ""
                    
                    print(title)
                    print(talkURL)
                    print(date)
                    print(duration)
                    print(speaker)

                    print(title, talkURL, date, duration, speaker)
                    let talkData =  TalkData(title: title,  talkURL: talkURL,  date: date, duration: duration,  speaker: speaker)
                    
                    self.talks += [talkData]
                    print(self.talks.count)
                }
                
                
                
            } catch {
                print(error)
            }
            self.tableView.reloadData()
        }
        task.resume()
        print("finished load")
    }
 */

    
            
            
    

}
