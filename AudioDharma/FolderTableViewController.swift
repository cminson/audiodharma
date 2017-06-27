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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("FolderTableViewController viewDidLoad")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return TheDataModel.folderSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        print("Number of rows in section: \(TheDataModel.folderSections[section].count)")
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

        view.tintColor = UIColor.blue
        
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "FolderTableViewCell"
        
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FolderTableViewCell  else {
            fatalError("The dequeued cell is not an instance of FolderTableViewCell.")
        }
        
        print("section = \(indexPath.section) row = \(indexPath.row)")
        let folder = TheDataModel.folderSections[indexPath.section][indexPath.row]
    
        cell.title.text = folder.title
        
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
    
    
    
    /*
     override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
     
     print ("tableview section view setup")
     let width = tableView.bounds.size.width
     let height =  30
     
     let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: height))
     returnedView.backgroundColor = UIColor.green
     
     let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: height))
     label.text = TheDataModel.FolderSections[section][0].title
     returnedView.addSubview(label)
     
     return returnedView
     }
     */
    
    /*
     override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> (UIView!)
     {
     return self.tableView.backgroundColor = UIColor.green
     
     let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30))
     headerView.backgroundColor = UIColor.red
     
     return headerView
     
     }
     */

  

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

    /*
    // MARK: - Navigation

    */
    
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
            talkTableViewController.content = folder.content
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
