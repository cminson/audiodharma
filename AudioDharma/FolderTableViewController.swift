//
//  FoldersTableViewController.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit

class FoldersTableViewController: UITableViewController {
    
    
    //MARK: Properties
    var selectedSection: Int = 0
    var selectedRow: Int = 0

    
    //MARK: Init
    override func viewDidLoad() {
        self.tableView.delegate = self

        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TheDataModel.folderSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        //print("Number of rows in section: \(TheDataModel.folderSections[section].count)")
        return TheDataModel.folderSections[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle : String
        
        sectionTitle =  TheDataModel.folderSections[section][0].section
        print(sectionTitle)
        
        return sectionTitle
        
    }
    
    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        print ("enter: willDisplayHeaderView")

        let header = view as! UITableViewHeaderFooterView
        
        view.tintColor = UIColor.black
        header.textLabel?.textColor = UIColor.white
        header.textLabel?.textAlignment = NSTextAlignment.center
    }
    
    /*
    override public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 90.0
    }
     */
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "FolderTableViewCell"
        
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FolderTableViewCell  else {
            fatalError("The dequeued cell is not an instance of FolderTableViewCell.")
        }
        
        print("section = \(indexPath.section) row = \(indexPath.row)")
        let folder = TheDataModel.folderSections[indexPath.section][indexPath.row]
    
        
        let listImage = UIImage(named: "") ?? UIImage(named: "defaultPhoto")!

        cell.title.text = folder.title
        
        cell.listImage.contentMode = UIViewContentMode.scaleAspectFit
        cell.listImage.image = listImage
        
        return cell
        
    }
    
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didselectrow")
        
        self.selectedSection = indexPath.section
        self.selectedRow = indexPath.row
        
        let folder = TheDataModel.folderSections[indexPath.section][indexPath.row]
        if (folder.content == "CUSTOM") {
            self.performSegue(withIdentifier: "ShowCustomLists", sender: self)
        } else {
            self.performSegue(withIdentifier: "ShowTalks", sender: self)
            
        }

    }
    
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        print("prepare to seque")

        
        let folder = TheDataModel.folderSections[self.selectedSection][self.selectedRow]
        print("Folder content: \(folder.content)")
   
        
        switch segue.identifier ?? "" {
            
        case "ShowTalks":
            guard let talkTableViewController = segue.destination as? TalkTableViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            let currentTitle = TheDataModel.folderSections[selectedSection][selectedRow]
            talkTableViewController.content = folder.content
            talkTableViewController.currentTitle = currentTitle.title
            
        case "ShowCustomLists":

            guard let _ = segue.destination as? UserListTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }


            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier!)")
        }

        
    }

    
    /*
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
                print(json)
                
                for folder in json["folders"] as? [AnyObject] ?? [] {
                    
                    let title = folder["title"] as? String ?? ""
                    
                    print(title)
                    let folderData =  FolderData(title: title)
                    
                    self.Folders += [folderData]
                    print(self.Folders.count)
                }
                
                
                
            } catch {
                print(error)
            }
            self.tableView.reloadData()
        }
        task.resume()
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
                
                for folder in json["talks"] as? [AnyObject] ?? [] {
                    
                    let title = folder["title"] as? String ?? ""
                    
                    print(title)
                    let folderData =  FolderData(title: title)
                    
                    self.Folders += [folderData]
                    print(self.Folders.count)
                }
                
                
                
            } catch {
                print(error)
            }
            self.tableView.reloadData()
        }
        task.resume()
    }
 */



}
