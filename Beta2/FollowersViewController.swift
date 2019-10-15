//
//  FollowersTableViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 10/4/18.
//  Copyright © 2018 anuJ. All rights reserved.
//

import UIKit
import FirebaseDatabase

class FollowersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{

    @IBOutlet weak var tableView: UITableView!
    var followersName:[String] = []
    var followersId:[NSString] = []
    var frienddName:[String] = []
    var friendId:[String] = []
    var friendsValid = 0
    var followerHandler: FIRDatabaseHandle?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.tableView.dataSource=self
        self.tableView.delegate=self
        //remove left padding from tableview seperators
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        //        tableView.registerClass(TestTableViewCell.self,forCellReuseIdentifier: "dataCell")
        self.tableView.backgroundColor=UIColor.clear
        //Create top cell separator for 1st cell
        let px = 1 / UIScreen.main.scale
        let frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height:  px)
        let line: UIView = UIView(frame: frame)
        self.tableView.tableHeaderView = line
        line.backgroundColor = self.tableView.separatorColor
        
        //Clear flag to display notification of new followers on home screen anytime this screen is viewed
        Helpers().displayFollowersNote = NSNumber(value: 0)

        //Begin displaying activity monitor before retrieving from backend
        var loadingView: UIView = UIView()
        var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50,  height: 50)) as UIActivityIndicatorView
        //Show activity monitor while waiting
        Helpers().displayActMon(display: true, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
        
        //Retrieve list of friends from Firebase to compare to the retrieved followers
        let _ = Helpers().retrieveMyFriends(friendsRef: FIRDatabase.database().reference().child("users/\(Helpers().currUser as String)/friends")) {(friendStr:[String], friendId:[String]) in
            self.friendId = friendId
            self.frienddName = friendStr
            self.friendsValid = 1   //mark friend arrays as having been filled from firebase
        }
        
        //Retrieve list of followers
        retrieveFollowersFromFirebase{(finished:Bool, friendCount: Int)
            in
            if(finished){
                //Finish displaying activity montior before reloading tableView
                Helpers().displayActMon(display: false, superView: self.view, loadingView: &loadingView, activityIndicator: &activityIndicator)
                self.tableView.reloadData()
                //Check if a new follower was found and add notification flag
                if(Helpers().numFollowersDefault.compare(NSNumber(value: self.followersName.count)) == .orderedAscending)
                {
                    //print("disp foll: \(Helpers().displayFollowersNote)")
                    Helpers().displayFollowersNote = 1
                    //print("disp foll: \(Helpers().displayFollowersNote)")
                }
                //Update number of followers in user defaults
                Helpers().numFollowersDefault = NSNumber(value: self.followersName.count)
            }
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func retrieveFollowersFromFirebase(_ completionClosure: @escaping (_ finished: Bool, _ friendCount: Int) -> Void) {
        let followerRef = FIRDatabase.database().reference().child("users/\(Helpers().currUser)/followers")
        var friendCount = 0
        self.followerHandler = followerRef.queryOrdered(byChild: "displayName1").observe(.value, with: { snapshot in
        
            guard let nsSnapDict = snapshot.value as? NSDictionary else{
                //If snapshot fails just call completion closure with empty arrays
                completionClosure(false, 0)
                return
            }
            
            for ( followID , displayName ) in nsSnapDict{
                //Cast displayName dict [key = "displayName1", value = followers's name] or quit before storing to name or Id array
                guard let nameDict = displayName as? NSDictionary else{
                    completionClosure(false, 0)
                    return
                }

                if let fId = followID as? NSString, let name = nameDict["displayName1"] as? String{
                    //If user doesn't exist then add new user
                    if(!self.followersId.contains(fId)){
                        self.followersId.append(fId)  //Append curr friend ID
                        self.followersName.append(name)
                        friendCount += 1
                    }
                }
            }
            completionClosure(true, friendCount)
        })
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.followersName.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "catCell", for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = "    \(self.followersName[indexPath.row])"
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.light)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Ensure the follower is already a friend of the user, or display popup to add friend
        //If the friends failed to retrieve from firebase to compare then unconditionally allow viewing the follower's list (security fail?)
        if(self.friendsValid == 1 && !(self.friendId.contains(self.followersId[indexPath.row] as String))){
            //Display popup to add friend or don't segue
            let alert = UIAlertController(title: "Become Friends?", message: "You're not following \(self.followersName[indexPath.row]), do you want to follow them so you can view their list?", preferredStyle: .alert)
            //Exit function if user clicks now and allow them to reconfigure the check in
            let CancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            //Perform the delete operation in the closure called by the confirm action
            let ConfirmAction = UIAlertAction(title: "Yes", style: .default, handler: { UIAlertAction in
                Helpers().addNewFriend(friendId: self.followersId[indexPath.row], friendName: self.followersName[indexPath.row])
                //Update the retrieved friend list to include this newly added friend in case I rewind to this screen then try to segue again to this same user I won't re-display the popup
                self.friendId.append(self.followersId[indexPath.row] as String)
                self.frienddName.append(self.followersName[indexPath.row])
                
                //Already a friend Perform seque to my List VC
                self.performSegue(withIdentifier: "showFollowerList", sender: self)
            })
            
            alert.addAction(CancelAction)
            alert.addAction(ConfirmAction)
            self.modalPresentationStyle = .overCurrentContext
            self.present(alert, animated: true, completion: nil)
        }else{
            //Already a friend Perform seque to my List VC
            self.performSegue(withIdentifier: "showFollowerList", sender: self)
        }
    }
    
    //Setup data cell height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50
    }
 
    // Unwind seque from my myListVC
    @IBAction func unwindFromMyList(_ sender: UIStoryboardSegue) {
        // empty
    }
    

    //Pass the FriendId of the requested list to view
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if(segue.identifier == "showFollowerList"){  //only perform if going to MyListVC
            var nameId: String
            // Create a new variable to store the instance ofPlayerTableViewController
            let destinationVC = segue.destination as! MyListViewController
            
            var userName: String = ""
            nameId = "Friend's List"      //Default should it fail
            if let selectedIdx = self.tableView.indexPathForSelectedRow{
                userName = followersName[selectedIdx.row]
                //need to retrieve friends ID too
                destinationVC.myFriendIds = [self.followersId[selectedIdx.row]]
            }
            
            //Determine the First Name of the Facebook username before the space
            if let spaceIdx = userName.characters.index(of: " "){
                nameId = userName.substring(to: spaceIdx)
            }
            
            destinationVC.headerText = nameId
        }
    }
}
