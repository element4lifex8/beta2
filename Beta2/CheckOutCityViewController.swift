//
//  CheckOutCityViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 9/25/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import FirebaseDatabase

class CheckOutCityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var myCity:[String] = []
    
    var cityRef: FIRDatabaseReference!
    let currUserDefaultKey = "FBloginVC.currUser"
    fileprivate let sharedFbUser = UserDefaults.standard
    
    var currUser: NSString {
        get
        {
            return (sharedFbUser.object(forKey: currUserDefaultKey) as? NSString)!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource=self;
        self.tableView.delegate=self;
        //remove left padding from tableview seperators
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        //        tableView.registerClass(TestTableViewCell.self,forCellReuseIdentifier: "dataCell")
        self.tableView.backgroundColor=UIColor.clear
        //Create top cell separator for 1st cell
        let px = 1 / UIScreen.main.scale
        let frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: px)
        let line: UIView = UIView(frame: frame)
        self.tableView.tableHeaderView = line
        line.backgroundColor = self.tableView.separatorColor
        //Firebase ref to the list of users and their check ins
//        cityRef = Firebase(url:"https://check-inout.firebaseio.com/checked/places")
        cityRef = FIRDatabase.database().reference().child("checked/places")
        retrieveFriendCity() {(completedArr:[String]) in
            self.myCity = completedArr
            self.tableView.reloadData()
        }
    }
    
    func retrieveFriendCity(_ completionClosure: @escaping (_ completedArr: [String]) -> Void) {
        var localCityArr = [String]()
        //Query ordered by child will loop each place in the cityRef
        cityRef.queryOrdered(byChild: "city").observe(.childAdded, with: { snapshot in
            //If the city is a single dict pair this snap.value will return the city name
            if let city = snapshot.value as? NSDictionary {
                //Only append city if it doesn't already exist in the local city array
                if(!localCityArr.contains(city["city"] as? String ?? "Default City")){
                    localCityArr.append((city["city"] as? String ?? "Default City")!)
                }
            }else{  //The current city entry has a multi entry list
                for child in (snapshot.children) {    //each child is either city or cat
                    let rootNode = child as! FIRDataSnapshot
                    //force downcast only works if root node has children, otherwise value will only be a string
                    let nodeDict = rootNode.value as! NSDictionary
                    for (key, _ ) in nodeDict{
                        if((child as AnyObject).key == "city"){
                            if(!localCityArr.contains(key as! String)){
                                localCityArr.append(key as! String)
                            }
                        }
                    }
                }
            }
            completionClosure(localCityArr)
        })

    }
        
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
    }
    
    //Setup subheader and data cell attributes
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myCity.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellIdentifier = "dataCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! TestTableViewCell   //downcast to my cell class type
        cell.tableCellValue.text = "  \(myCity[indexPath.row])"
        cell.tableCellValue.textColor = UIColor.white
        cell.tableCellValue.font = UIFont.systemFont(ofSize: 24, weight: UIFontWeightLight)
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let selectedItem = myCity[indexPath.row]
        self.performSegue(withIdentifier: "myListSegue", sender: self)
    }

    //Pass the FriendId's of the requested list to view
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        let cityName = myCity[self.tableView.indexPathForSelectedRow!.row]
        
        //Create reference to
        
        // Create a new variable to store the instance ofPlayerTableViewController
        let destinationVC = segue.destination as! MyListViewController
        destinationVC.requestedUser = myCity[self.tableView.indexPathForSelectedRow!.row] as NSString?
        destinationVC.headerText = cityName
        
        //Deselect current row so when returning the last selected user is not still selected
        self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
    }
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromMyList(_ sender: UIStoryboardSegue) {
        // empty
    }


}
