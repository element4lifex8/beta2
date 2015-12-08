//
//  CheckedOutListViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 12/6/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit

class CheckedOutListViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    
    let restNameDefaultKey = "CheckInView.restName"
    private let sharedRestName = NSUserDefaults.standardUserDefaults()
    
    var restNameHistory: [String] {
        get
        {
            return sharedRestName.objectForKey(restNameDefaultKey) as? [String] ?? []
        }
        set
        {
            sharedRestName.setObject(newValue, forKey: restNameDefaultKey)
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restNameHistory.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        // Configure the cell...
        let cellIdentifier = "testCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! TestTableViewCell
        cell.tableCellValue.text=restNameHistory[indexPath.row]


        return cell
    }

}
