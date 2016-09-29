//
//  CheckOutCityViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 9/25/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import Firebase

class CheckOutCityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var cityRef: Firebase!
    let currUserDefaultKey = "FBloginVC.currUser"
    private let sharedFbUser = NSUserDefaults.standardUserDefaults()
    
    var currUser: NSString {
        get
        {
            return (sharedFbUser.objectForKey(currUserDefaultKey) as? NSString)!
        }
    }
    
    var myCity:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource=self;
        self.tableView.delegate=self;
        //remove left padding from tableview seperators
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
        //        tableView.registerClass(TestTableViewCell.self,forCellReuseIdentifier: "dataCell")
        self.tableView.backgroundColor=UIColor.clearColor()
        
        cityRef = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
        retrieveFriendCity() {(completedArr:[String]) in
            self.myCity = completedArr
            self.tableView.reloadData()
        }
    }
    
    func retrieveFriendCity(completionClosure: (completedArr: [String]) -> Void) {
        var localCityArr = [String]()
        //Query ordered by child will loop each place in the cityRef
        cityRef.queryOrderedByChild("city").observeEventType(.ChildAdded, withBlock: { snapshot in
            //If the city is a single dict pair this snap.value will return the city name
            if let city = snapshot.value["city"] as? String {
                //Only append city if it doesn't already exist in the local city array
                if(!localCityArr.contains(city)){
                    localCityArr.append(city)
                }
            }else{  //The current city entry has a multi entry list
                for child in snapshot.children {    //each child is either city or cat
                    let rootNode = child as! FDataSnapshot
                    //force downcast only works if root node has children, otherwise value will only be a string
                    let nodeDict = rootNode.value as! NSDictionary
                    for (key, _ ) in nodeDict{
                        if(child.key == "city"){
                            if(!localCityArr.contains(key as! String)){
                                localCityArr.append(key as! String)
                            }
                        }
                    }
                }
            }
            completionClosure(completedArr: localCityArr)
        })

    }
        
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = .clearColor()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myCity.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cellIdentifier = "dataCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! TestTableViewCell   //downcast to my cell class type
        cell.tableCellValue.text = "  \(myCity[indexPath.row])"
        cell.tableCellValue.textColor = UIColor.whiteColor()
        cell.tableCellValue.font = UIFont.systemFontOfSize(24, weight: UIFontWeightLight)
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsetsZero
        return cell
    }

    


}
