//
//  AddPeopleViewCntroller.swift
//  Beta2
//
//  Created by Jason Johnston on 10/29/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit

class AddPeopleViewCntroller: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var selectedFBfriends = [FbookUserInfo]()
    var facebookAuthFriends = [String](), facebookAuthIds = [String]()
    var facebookTaggableFriends = [String](), facebooktaggableIds = [String]()
    var facebookFriendMaster = [String]()
    var myFriends:[String] = []
    var myFriendIds: [NSString] = []    //list of Facebook Id's with matching index to myFriends array
    var selectedAccessButt: [Int] = []     //List of users who are selected to add as friends
    var selectedIds: [String] = []     //List of users id's who are selected to add as friends
    var friendsRef: FIRDatabaseReference!
    
    let currUserDefaultKey = "FBloginVC.currUser"
    fileprivate let sharedFbUser = UserDefaults.standard
    
    var currUser: NSString {
        get
        {
            return (sharedFbUser.object(forKey: currUserDefaultKey) as? NSString)!
        }
    }
    
    //Must add submit button in viewDidAppear so that it is added over top of the tablewview (bringSubview to front in viewDidLoad would not put the view on top of the tableview
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Add submit button view
        let shadowX: CGFloat = 2.0, shadowY:CGFloat = 1.0
        let buttViewHeight:CGFloat = 50, buttViewWidth:CGFloat = 150
        let buttonView = UIView(frame: CGRect(x: 0, y: 0, width: buttViewWidth, height: buttViewHeight))
        buttonView.backgroundColor = UIColor.clear
        //allow autolayout constrainsts to be set on buttonView
        buttonView.translatesAutoresizingMaskIntoConstraints = false
       
        //Put button view on top of table
        buttonView.layer.zPosition = tableView.layer.zPosition + 1
        view.addSubview(buttonView)
        
        //Create submit button to add to container view
        let buttonWidth:CGFloat = 150, buttonHeight:CGFloat = 50
        let subButt = UIButton(frame: CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight))
        subButt.backgroundColor = UIColor.white
        subButt.layer.borderWidth = 2.0
        subButt.layer.borderColor = UIColor.black.cgColor
        subButt.setTitle("Submit", for: UIControlState())
        subButt.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 36)
        subButt.setTitleColor(UIColor.black, for: UIControlState())
        //add target actions for button tap
        subButt.addTarget(self, action: #selector(AddPeopleViewCntroller.submitSelected(_:)), for: .touchUpInside)
        //Add shadow to button
        subButt.layer.shadowOpacity = 0.7
        subButt.layer.shadowOffset = CGSize(width: shadowX, height: shadowY)
        //Radius of 1 only adds shadow to bottom and right
        subButt.layer.shadowRadius = 1
        subButt.layer.shadowColor = UIColor.black.cgColor
        buttonView.addSubview(subButt)
        
        //Set Button view width/height constraints so it doesn't default to zero at runtime
        let widthConstraint = buttonView.widthAnchor.constraint(equalToConstant: buttViewWidth)
        let heightConstraint = buttonView.heightAnchor.constraint(equalToConstant: buttViewHeight)
        NSLayoutConstraint.activate([widthConstraint, heightConstraint])
        
        //        Screen default to 400x800 so I can only pin to the left and top to create my constraints
        //From top measure to the bottom of the button and subtract 50 from bottom margin and 50 for button height
        let pinBottom = NSLayoutConstraint(item: buttonView, attribute: .top, relatedBy: .equal, toItem: view , attribute: .top, multiplier: 1.0, constant: view.bounds.height - 50 - buttViewHeight)
        //Pin left of button to center of screen minus the button width
        let pinLeft = NSLayoutConstraint(item: buttonView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: (view.bounds.width/2) - (buttViewWidth/2))
        view.addConstraint(pinBottom)
        view.addConstraint(pinLeft)

    }
    
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
        let frame = CGRect(x: view.frame.width/2, y: view.frame.height/2, width: self.tableView.frame.size.width, height: px)
        let line: UIView = UIView(frame: frame)
        self.tableView.tableHeaderView = line
        line.backgroundColor = self.tableView.separatorColor
        
        
//        friendsRef = Firebase(url:"https://check-inout.firebaseio.com/users/\(self.currUser)/friends")
        friendsRef = FIRDatabase.database().reference().child("users/\(self.currUser)/friends")
        
        sortFacebookFriends(){(finished: Bool) in
            self.facebookTaggableFriends.sort(by: <)
            self.tableView.reloadData()
        }
       
        
//        retrieveMyFriends() {(friendStr:[String], friendId:[String]) in
//            self.myFriends = friendStr
//            self.myFriendIds = friendId
//            
//        }
        
    }
    
    func sortFacebookFriends(_ completionClosure: @escaping (_ finished: Bool) -> Void){
        var finishedAuth = false, finishedUnauth = false
        retrieveAuthFacebookFriends() {(displayName: [String], taggableId: [String]) in
            self.facebookAuthFriends = displayName
            self.facebookAuthIds = taggableId
            finishedAuth = true
            //Call completion closure only when all friends have been retrieved
            if(finishedAuth && finishedUnauth){
                completionClosure(true)
            }
        }
        
        retrieveUnauthFacebookFriends() {(displayName: [String], unAuthId: [String]) in
            self.facebookTaggableFriends = displayName
            self.facebooktaggableIds = unAuthId
            finishedUnauth = true
            //Call completion closure only when all friends have been retrieved
            if(finishedAuth && finishedUnauth){
                completionClosure(true)
            }
        }
    }
    
    //Retrieve friends who have not authorized CIO
    func retrieveUnauthFacebookFriends(_ completionClosure: @escaping (_ displayName: [String], _ taggableId: [String]) -> Void){
        //Taggable friends just provides a reference list of friends that can be tagged or mentioned in stories published to Facebook
        let unAuthrequest = FBSDKGraphRequest(graphPath:"/me/taggable_friends?limit=5000", parameters: ["fields" : "name"]);
        var unAuthFriends = [String]()
        var unAuthId = [String]()
        unAuthrequest?.start(completionHandler: { (connection, result, error) -> Void in
            if error == nil{
                let resultdict = result as! NSDictionary
                let data : NSArray = resultdict.object(forKey: "data") as! NSArray
//                print("unauth data \(data)")
                for i in 0..<data.count{
                    let valueDict : NSDictionary = data[i] as! NSDictionary
                    let fbFriendName = valueDict.object(forKey: "name") as! String
                    unAuthFriends.append(fbFriendName)
                }
            }
            else{
                print("Error Getting Friends \(error)");
            }
          
            completionClosure(unAuthFriends, unAuthId)
        })
    }

    

    func retrieveAuthFacebookFriends(_ completionClosure: @escaping (_ displayName: [String], _ friendId: [String]) -> Void){
        //Create request to retrieve friends who have authorized CIO
        let request = FBSDKGraphRequest(graphPath:"/me/friends", parameters: ["fields" : "id, name"]);
        var authFriends = [String]()
        var authId = [String]()
        
        request?.start(completionHandler: { (connection, result, error) -> Void in
            if error == nil
            {
                //Result is cast to an NSDict consiting of [id: value, name: value] for auth friends
                let resultdict = result as! NSDictionary
                print("Friends \(resultdict)")
                let data : NSArray = resultdict.object(forKey: "data") as! NSArray
//                print("data \(data)")
                //extract dict entries id & name as string for each authorized friend
                for i in 0..<data.count
                {
                    let valueDict : NSDictionary = data[i] as! NSDictionary
                    if let id = valueDict.object(forKey: "id"){
                        authId.append(id as! String)
//                        print("the id value is \(id)")
                    }
                    if let fbFriendName = valueDict.object(forKey: "name"){
    //                    print ("name \(fbFriendName)")
                        authFriends.append(fbFriendName  as! String)
                    }
                }
            }
            completionClosure(authFriends, authId)
        })
    }
        
    //retrieve a list of all the user's friends
    func retrieveMyFriends(_ completionClosure: @escaping (_ friendStr: [String], _ friendId:[String]) -> Void) {
        var localFriendsArr = [String]()
        var localFriendsId = [String]()
        //Retrieve a list of the user's current check in list
        friendsRef.queryOrdered(byChild: "displayName1").observe(.childAdded, with: { snapshot in
            //If the city is a single dict pair this snap.value will return the city name
            if let currFriend = snapshot.value as? NSDictionary{
                localFriendsArr.append((currFriend["displayName1"] as? String ?? "Default Name")!)
                localFriendsId.append((snapshot.key))
            }
            completionClosure(localFriendsArr, localFriendsId)
        })
    }
    
     @IBAction func submitSelected(_ sender: UIButton) {
        print("people selected")
//         let userChecked = Firebase(url:"https://check-inout.firebaseio.com/users/\(self.currUser)/friends")
        let userChecked = FIRDatabase.database().reference().child("users/\(self.currUser)/friends")
        for friend in selectedFBfriends{
            //Add id of curr friend with their display name stored underneath
           let friendInfo = ["displayName1" : friend.displayName!]
        userChecked.child(byAppendingPath: friend.id!).setValue(friendInfo)
        }
        performSegue(withIdentifier: "returnToCheckOut", sender: self)
    }
    
    
    @IBAction func accessoryButtonTapped(_ sender: UIButton) {
        let friendName = facebookTaggableFriends[sender.tag]
        var FBfriend: FbookUserInfo
        //check or uncheck selected friends
        sender.isSelected = sender.state == .highlighted ? true : false
        if(sender.isSelected){
            //Keep track of accessory buttons that are checked so they are reselected when scrolled back into view
            selectedAccessButt.append(sender.tag)
            //Add authorized friends to add to friends list, and create list of unauth friends to notify about the app.
            //friend index will only exist if friend is an auth user
            if let friendIndex = facebookAuthFriends.index(of: friendName){
                FBfriend = FbookUserInfo(name: friendName, id: facebookAuthIds[friendIndex])
            }else{
                FBfriend = FbookUserInfo(name: friendName)
            }
            selectedFBfriends.append(FBfriend)
        }else{
            //Keep track of accessory buttons that are checked
            if let index = selectedAccessButt.index(of: sender.tag){
                selectedAccessButt.remove(at: index)
            }
            //wish I understood these closures, came from here: http://stackoverflow.com/questions/34081580/array-of-any-and-contains
            if let fbIndex = selectedFBfriends.index(where: {$0.displayName == friendName} )    {
                    selectedFBfriends.remove(at: fbIndex)
            }
        }
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
            return facebookTaggableFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let checkImage = UIImage(named: "tableAccessoryCheck")
        let cellIdentifier = "friendCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! FriendTableViewCell   //downcast to my cell class type
        //display table data from either friends list or city list
        cell.nameLabel.text = "    \(facebookTaggableFriends[indexPath.row])"
        cell.nameLabel.textColor = UIColor.black
        cell.nameLabel.font = UIFont(name: "Avenir-Light", size: 18)
        //Set available tag
        if(facebookAuthFriends.contains(facebookTaggableFriends[indexPath.row]))
        {
            cell.isAvailableLabel.text = "    Available"
        }else{
            cell.isAvailableLabel.text = "    Invite to Check-In-Out"
        }
        cell.isAvailableLabel.textColor = UIColor.black
        cell.isAvailableLabel.font = UIFont(name: "Avenir-Light", size: 12)
        
        //Add custom accessory view for check button
        let accessoryButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        accessoryButton.layer.cornerRadius = 0.5 * accessoryButton.bounds.size.width
        accessoryButton.backgroundColor = UIColor.clear
        accessoryButton.layer.borderWidth = 2.0
        accessoryButton.layer.borderColor = UIColor.black.cgColor
        accessoryButton.setImage(checkImage, for: .selected)
//        accessoryButton.contentMode = .ScaleAspectFill
        accessoryButton.tag = indexPath.row //store row index of selected button
        accessoryButton.addTarget(self, action: #selector(AddPeopleViewCntroller.accessoryButtonTapped(_:)), for: .touchUpInside)

        cell.accessoryView = accessoryButton as UIView
        
        //Reselect accessory button when scrolled back into view
        if(selectedAccessButt.contains(indexPath.item)){
            accessoryButton.isSelected = true
        }
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }

}