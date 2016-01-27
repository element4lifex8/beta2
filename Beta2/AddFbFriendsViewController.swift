//
//  AddFbFriendsViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 1/23/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class AddFbFriendsViewController: UIViewController {

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let request = FBSDKGraphRequest(graphPath:"/me/friends", parameters: nil) //["fields" : "email" : "name"]);
        
        request.startWithCompletionHandler
            {
                (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error == nil
                {
                    let resultdict = result as! NSDictionary
                    let data : NSArray = resultdict.objectForKey("data") as! NSArray
                    print("data \(data)")
                    for i in 0..<data.count
                    {
                        let valueDict : NSDictionary = data[i] as! NSDictionary
                        let id = valueDict.objectForKey("id") as! String
                        print("the id value is \(id)")
                        let fbFriendName = valueDict.objectForKey("name") as! String
                        print ("name \(fbFriendName)")
                        self.authList.append(fbFriendName)
                        self.friendsText.text = "\(self.authList)"
                    }
                    //print a facebook default photo of some randomly selected fried from taggable friends
                    let url = NSURL(string: "https://scontent.xx.fbcdn.net/hprofile-xtp1/v/t1.0-1/p50x50/12208701_10107495141218734_1003556140154763994_n.jpg?oh=46a32f1783c508f8eb0ff2be33b5c4cb&oe=5700219A")
                    let imgdata = NSData(contentsOfURL: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check
                    self.friendImage.contentMode = .ScaleAspectFill

                    self.friendImage.image = UIImage(data: imgdata!)
                    
                }
                else
                {
                    print("Error Getting Friends \(error)");
                }
        }
        //only print 5 of the non-authorized friends to not overrun the buffer
        let unAuthrequest = FBSDKGraphRequest(graphPath:"/me/taggable_friends?limit=5", parameters: nil) //["fields" : "email" : "name"]);
        
        unAuthrequest.startWithCompletionHandler
            {
                (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error == nil
                {
                    //print friend boken
                    let resultdict = result as! NSDictionary
                    let data : NSArray = resultdict.objectForKey("data") as! NSArray
                    print("data \(data)")
                    for i in 0..<data.count
                    {
                        let valueDict : NSDictionary = data[i] as! NSDictionary
                        let fbFriendName = valueDict.objectForKey("name") as! String
                        self.unAuthList.append(fbFriendName)
                        self.unAuthFriends.text = "\(self.unAuthList)"
                    }
                }
                else
                {
                    print("Error Getting Friends \(error)");
                }
        }


    }

    var authList = Array<String>()
    var unAuthList = Array<String>()
    @IBOutlet weak var friendsText: UITextView!
    
    @IBOutlet weak var unAuthFriends: UITextView!

    @IBOutlet weak var friendImage: UIImageView!

    

}
