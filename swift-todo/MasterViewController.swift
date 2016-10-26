//
//  MasterViewController.swift
//  swift-todo
//
//  Created by Joey on 8/18/16.
//  Copyright © 2016 Oursky Ltd. All rights reserved.
//

import UIKit
import SKYKit

public let ReceivedNotificationFromSkygaer = "ReceivedNotificationFromSkygear"

class MasterViewController: UITableViewController {
    
    let privateDB = SKYContainer.default().privateCloudDatabase

    var detailViewController: DetailViewController? = nil
    var objects = [AnyObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: ReceivedNotificationFromSkygaer), object: nil, queue: OperationQueue.main) { (notification) in
            self.updateData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        
        updateData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "Add To-Do item", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
            let title = alertController.textFields![0].text
            let todo = SKYRecord(recordType: "todo")
            todo?.setObject(title!, forKey: "title" as NSCopying!)
            todo?.setObject(SKYSequence(), forKey: "order" as NSCopying!)
            todo?.setObject(false, forKey: "done" as NSCopying!)
            
            self.privateDB?.save(todo, completion: { (record, error) in
                if (error != nil) {
                    print("error saving todo: \(error)")
                    return
                }
                
                self.objects.insert(todo!, at: 0)
                let indexPath = IndexPath(row: 0, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            })
        }))
        alertController.addTextField { (textField) in
            textField.placeholder = "Title"
        }
        self.present(alertController, animated: true, completion: nil)
    }
    
    func updateData() {
        let query = SKYQuery(recordType: "todo", predicate: NSPredicate(format: "done == false"))
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: false)
        query?.sortDescriptors = [sortDescriptor]
      
        privateDB?.performCachedQuery(query) { (results, cached, error) in
            if (error != nil) {
                print("error querying todos: \(error)")
                return
            }
            
            self.objects = results as! [AnyObject]
            self.tableView.reloadData()
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = objects[(indexPath as NSIndexPath).row] as! SKYRecord
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let object = objects[(indexPath as NSIndexPath).row] as! SKYRecord
        cell.textLabel!.text = object.object(forKey: "title") as? String
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let todo = objects[(indexPath as NSIndexPath).row] as! SKYRecord
            todo.setObject(true, forKey: "done" as NSCopying!)
            self.privateDB?.save(todo, completion: { (record, error) in
                if (error != nil) {
                    print("error saving todo: \(error)")
                    return
                }
                
                self.objects.remove(at: (indexPath as NSIndexPath).row) as! SKYRecord
                tableView.deleteRows(at: [indexPath], with: .fade)
            })
        }
    }


}

