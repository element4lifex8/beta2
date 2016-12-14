//
//  CheckOutPeopleViewController.swift
//  Pods
//
//  Created by Jason Johnston on 9/25/16.
//
//

import UIKit
import FirebaseDatabase
import Foundation

class CheckOutPeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var myFriends:[String] = []
    var myFriendIds: [NSString] = []    //list of Facebook Id's with matching index to myFriends array
    var friendsRef: FIRDatabaseReference!
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
        
//        friendsRef = Firebase(url:"https://check-inout.firebaseio.com/users/\(self.currUser)/friends")
        friendsRef = FIRDatabase.database().reference().child("users/\(self.currUser)/friends")
        retrieveMyFriends() {(friendStr:[String], friendId:[String]) in
            self.myFriends = friendStr
            self.myFriendIds = friendId as [NSString]
            self.tableView.reloadData()
        }
    }
    
    func retrieveMyFriends(_ completionClosure: @escaping (_ friendStr: [String], _ friendId:[String]) -> Void) {
        var localFriendsArr = [String]()
        var localFriendsId = [String]()
        var count=10
        //Retrieve a list of the user's current check in list
        friendsRef.queryOrdered(byChild: "displayName1").observe(.childAdded, with: { snapshot in
            //If the city is a single dict pair this snap.value will return the city name
            if let currFriend = snapshot.value as? NSDictionary {
                if count > 0{
                    print (currFriend)
                };count += 1
                localFriendsArr.append((currFriend["displayName1"] as? String ?? "Default Name")!)
                localFriendsId.append(snapshot.key)
            }
            completionClosure(localFriendsArr, localFriendsId)
        })
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
    }
    
    //Setup data cell height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellIdentifier = "dataCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! TestTableViewCell   //downcast to my cell class type
        cell.tableCellValue.text = "    \(myFriends[indexPath.row])"
        cell.tableCellValue.textColor = UIColor.white
        cell.tableCellValue.font = UIFont.systemFont(ofSize: 24, weight: UIFontWeightLight)
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        // Create an instance of myListVC and pass the variable
//        let controller = MyListViewController(nibName: "MyListViewController", bundle: nil) as MyListViewController
//        controller.requestedUser = selectedUserId as NSString
        // Perform seque to my List VC
        self.performSegue(withIdentifier: "myListSegue", sender: self)
    }
    //Pass the FriendId of the requested list to view
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        let userName = myFriends[self.tableView.indexPathForSelectedRow!.row]
        var firstName = "Friend's List"
        
        //Determine the First Name of the Facebook username before the space
        if let spaceIdx = userName.characters.index(of: " "){
            firstName = userName.substring(to: spaceIdx)
        }
        // Create a new variable to store the instance ofPlayerTableViewController
        let destinationVC = segue.destination as! MyListViewController
        destinationVC.requestedUser = myFriendIds[self.tableView.indexPathForSelectedRow!.row]
        destinationVC.headerText = firstName
        
        //Deselect current row so when returning the last selected user is not still selected
        self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
    }
    
    // Unwind seque from my myListVC
    @IBAction func unwindFromMyList(_ sender: UIStoryboardSegue) {
        // empty
    }

}
