//
//  PlaceDeetsViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 2/2/17.
//  Copyright © 2017 anuJ. All rights reserved.
//

import UIKit
import GooglePlaces
import FirebaseDatabase

class PlaceDeetsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    //    Variables set by another view controller
    //Store the place ID whose info is requested by the MyListVC
    var placeId: String?
    var titleText: String?
    var categories: [String]?
    var categoryUpdate: Bool?
    var isMyPlace: Bool?    //keeps track of whether this is my place or Not
    
    //Variables retrieved using google place ID
    var placeAddress: String = ""
    var placeWebsite: String = ""
    var placePhoneNumber: String = ""
    var placeTypes: String = ""
    var openNow : String = ""
    var placeCoordinates: CLLocationCoordinate2D?
    var googleCityState = [String : String]()
    //retrieve number of friends with this check in from firebase
    var friendString: String = ""

    var commentList = [String]()
    var commentPtr = 0  //Keep track of which item in comment list to display
    //Google places client
    var placesClient: GMSPlacesClient!
    //Google places web api uses different api key than ios app
    var googleAPIkey = "AIzaSyBkZgZI20bfFpBBC-t-AGKTpXRcQZPS9ck"
    //use dispatch groups to make async call using google places web api and google places ios api then fire async call to reload tableview
    var myGroup = DispatchGroup()
    
    //Helper file returns get propery of the existing user's facebook ID
    var currUser = Helpers().returnCurrUser()
    
    //Enumerated defines for table entries
    let addressCell = 0
    let phoneNumCell = 1
    let websiteCell = 2
    let timesCell = 3
    let categoryCell = 4
    let commentCell = 6
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource=self
        self.tableView.delegate=self
        //Stop table view from bouncing since cells will not fill the screen
        self.tableView.alwaysBounceVertical = false
        
        //gooogle Places setup
        placesClient = GMSPlacesClient.shared()
        
        if let placeId = self.placeId{
            //Create container view then loading for activity indicator to prevent background from overshadowing white color
            let loadingView: UIView = UIView()
            
            loadingView.frame = CGRect(x: 0,y: 0,width: 80,height: 80)
            loadingView.center = view.center
            loadingView.backgroundColor = UIColor(red: 0x44/255, green: 0x44/255, blue: 0x44/255, alpha: 0.7)
            loadingView.clipsToBounds = true
            loadingView.layer.cornerRadius = 10
            //Start activity indicator while making google request
            let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame:   CGRect(x: 0, y: 0, width: 50,  height: 50)) as UIActivityIndicatorView
            activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2,y: loadingView.frame.size.height / 2);
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
            activityIndicator.hidesWhenStopped = true
            
            loadingView.addSubview(activityIndicator)
            view.addSubview(loadingView)
            activityIndicator.startAnimating()
            
            //Store categories that were passed from mylist:
            if let cats = self.categories{
                for (index,cat) in cats.enumerated(){
                    if(index == 0){
                        self.placeTypes = cat
                    }else{
                        self.placeTypes = self.placeTypes + "/" + cat
                    }
                }
            }
            
            self.myGroup.enter()
            //Retrieve an dict of my friends facebook [Id's: Name] and pass to a function that compares the check in's user list to my friend list
            gatherFriendList(){(myFriends: [String: String]) in
                
                //Kick off asynch call to firebase to determine if other friends have also checked in at this place
                self.countNumFriends(friendList: myFriends){(friendMatch: [String : String]) in
                    //If they have checked in at this place then I need to get comments they made about this place
                    self.gatherFriendComments(friendList: friendMatch)
                }
                self.myGroup.leave()  //Leave group that was entered before gathering friend list, since the countNumFriends & gatherFriendComments enters its own dispatch group
            }
            
            //Kick off asynch call retrieve opening hours using places web api and add to dispatch group in function
            retrieveOpenHours(placeId: placeId)
            //Add retrieval of place details from places ios Api to dispatch group
            self.myGroup.enter()
            //Reload table view data after completion cloure call signals that place deets were found
            retrievePlaceData(placeId: placeId){ (deetsComplete: Bool) in
                //Once the other details have been retrieved notify dispatch group
                self.myGroup.leave()
            }
            //Fire async call once places ios and web api, and firebase calls have finish
            myGroup.notify(queue: .main) {
                activityIndicator.stopAnimating()
                loadingView.removeFromSuperview()
                self.tableView.reloadData()
            }
            
        }//printing message to the user that no place id exists was added to view did appear
        
        //Remove empty lines from table view bottom by adding empty footer
        self.tableView.tableFooterView = UIView()
        //remove left padding from tableview seperators
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        
        //BS estimated row height so I can use automatic row height for comment cell
        self.tableView.estimatedRowHeight = 50
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let screenWidth = view.bounds.width
        
        self.titleLabel.text = (titleText ?? "Place Not Found")
        self.titleLabel.font = UIFont(name: "Avenir-Light", size: 26)
        self.titleLabel.textAlignment = .center
        //Shrink the label to fit in 2 line max without touching the back button...go!
        self.titleLabel.adjustsFontSizeToFitWidth = true
        self.titleLabel.lineBreakMode = .byTruncatingTail
        self.titleLabel.numberOfLines = 2
        //Label is centered but I only want text to grow to the point of reaching the left back button, which is 72px from the left edge of screen
        let maxWidth = screenWidth - (72 * 2)
        self.titleLabel.preferredMaxLayoutWidth = maxWidth
        
        
        //Add google attribution to footer view
        let googleImageView = UIImageView(image: UIImage(named: "poweredByGoogle")) //Google attribution image view
        self.tableView.tableFooterView?.addSubview(googleImageView)
        //Auto layout center google attribution in footer view, 8 pt down from top of footer
        googleImageView.translatesAutoresizingMaskIntoConstraints = false    //First turn off auto created constraints when calling addSubView
        NSLayoutConstraint(item: googleImageView, attribute: .centerX, relatedBy: .equal, toItem: self.tableView.tableFooterView, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: googleImageView, attribute: .top, relatedBy: .equal, toItem: self.tableView.tableFooterView, attribute: .top, multiplier: 1, constant: 8).isActive = true
//        googleImageView.centerXAnchor.constraint(equalTo: self.tableView.centerXAnchor).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (self.placeId == nil){
            let alert = UIAlertController(title: "Custom Check In", message: "Sometimes the user knows something the internet doesn't. Ask them directly", preferredStyle: .alert)
            let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(CancelAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        //Check if unwinding from updating categories and categories were updated
        if((self.categoryUpdate ?? false) == true){
            //Uddate string for categories
            //Store categories that were passed from mylist:
            if let cats = self.categories{
                for (index,cat) in cats.enumerated(){
                    if(index == 0){
                        self.placeTypes = cat
                    }else{
                        self.placeTypes = self.placeTypes + "/" + cat
                    }
                }
            }
            self.tableView.reloadData()
        }
    
    }
    
    func gatherFriendList(_ completionClosure: @escaping ( _ myFriends: [String: String]) -> Void){
        //Array to hold friends that will be returned by completion closure
        var tempFriends: [String: String] = [String: String]()
        //firebase ref to current user's friends
        let friendRef = FIRDatabase.database().reference().child("users/\(self.currUser)/friends")
        friendRef.observeSingleEvent(of: .value, with: { snapshot in
            //Each item under friends is a user:"true" dictionary item
            if let friendList = snapshot.value as? NSDictionary{
                //Loop over each friend and store in temp array
                //Name child is a dict of 1 entry : ["displayName1" : their name] that must be cast from AnyObject
                for (user, nameChild) in friendList{
                    //Have to get the value for the "displayName1" key that is a child of the retrieve Facebook ID Node
                    if let nameDict = nameChild as? NSDictionary{
                    
                        //If nodeDict can't be unwrapped then the value returned from the friends node has no children (no displayName1 key: user's name value)
                        if let nameString = nameDict["displayName1"] as? String{
                            tempFriends[user as! String] = nameString
                        }else{
                            tempFriends[user as! String] = ""
                        }
                    }
                    
                }
            }
            //Add the current user to the friend list
            tempFriends[Helpers().currUser as String] = Helpers().currDisplayName as String
            completionClosure(tempFriends)
        })
    }
    
    func countNumFriends(friendList:[String: String], _ completionClosure: @escaping ( _ friendMatch: [String: String]) -> Void){
        var numFriends = 0
        var matchedDict: [String: String] = [String: String]()
        //Reference to master list
        let refCheckedPlaces = FIRDatabase.database().reference().child("places")
        guard let placeName = self.titleText else {return}
        let myRef = refCheckedPlaces.child(placeName).child("users")
        //Get a list of all of my current friends:
        
        //Add firebase retrieval to dispatch group
        myGroup.enter()
        //Retrieve a list of the user's current check in list
        myRef.observeSingleEvent(of: .value, with: { snapshot in

            //Each item under the places check in is a user:"true" dictionary item
            if let currUsers = snapshot.value as? NSDictionary{
                //Loop over each user who has checked in here and see that user is in my friend's list
                //Name child is a dict of 1 entry : ["displayName1" : their name]
                for (user, _) in currUsers{

                    if( (friendList.keys).contains((user as! String)) ){
                        numFriends += 1
                        //store matching friend id so I can access that friends comments about a place
                        matchedDict[user as! String] = friendList[user as! String]
                    }
                }
            }
            
            self.friendString = "\(numFriends) Other People Checked In Here"
            self.myGroup.leave()
            
            //Call completion closure so I then retrieve the friends comments if they exist
                //Event though I don't need to pass a class member it was that or figure out passing empty closure
            completionClosure(matchedDict)
        })
    }
    
    //All matching friends for a check in will have their individual list searched for a comment
    func gatherFriendComments(friendList:[String: String]){
        
        guard let placeName = self.titleText else {return}
        let refCheckedPlaces = FIRDatabase.database().reference().child("checked")
//        let userRef = refCheckedPlaces.child(placeName).child("users")
        //Get a list of all of my current friends:
        
        //Loop over all friends and place a request for their comment on this check in
        for (userId, userName) in friendList{
            //Add each firebase retrieval to dispatch group
            myGroup.enter()
            //Retrieve a list of the user's current check in list
            refCheckedPlaces.child("\(userId)/\(placeName)/comment").observeSingleEvent(of: .value, with: { snapshot in
                //Check if the value of the snapshot is non-null
                if(snapshot.exists())
                {
                    //If comment exists then store as a comment string with the user's name
                    if let comment = snapshot.value{
                        
                        //gather users first letter & last initial, answer from SO: https://stackoverflow.com/a/47165223/5495979
                        var formattedName = ""
                        if let lastInitialRange = userName.range(of: " ", options: .backwards, range: userName.startIndex..<userName.endIndex) {
                            formattedName = String(userName[userName.startIndex..<userName.index(lastInitialRange.upperBound, offsetBy: 1)])
                        }
                        self.commentList.append("\(formattedName). said: \"\(comment)\"")
                    }
                }
                self.myGroup.leave()
            })
        }
    }
    
    func getDayOfWeek() -> String? {
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        guard let year =  components.year else {return nil}
        guard let month = components.month else {return nil}
        guard let day = components.day else {return nil}

        let dateString = "\(year)-\(month)-\(day)"


        let formatter  = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let todayDate = formatter.date(from: dateString) {
            let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
            let myComponents = myCalendar.components(.weekday, from: todayDate)
            guard let weekDay = myComponents.weekday else {return nil}
            switch weekDay {
            case 1:
                return "Sun"
            case 2:
                return "Mon"
            case 3:
                return "Tue"
            case 4:
                return "Wed"
            case 5:
                return "Thu"
            case 6:
                return "Fri"
            case 7:
                return "Sat"
            default:
                Helpers().myPrint(text: "Error fetching days")
                return "Day"
            }
        } else {
            return nil
        }
        
    }
    
    
    func retrieveOpenHours(placeId: String){
        //Hours must be retrieved using async web api
        //Generate url that includes place id and api key
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json?placeid=" + placeId + "&key=" + googleAPIkey
        Helpers().myPrint(text: urlString)
        //Add the below async call to places web api to dispatch group
        myGroup.enter()
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with:url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else {
                self.openNow = "Hours Unknown"
                self.myGroup.leave()    //Notify that we gave up on this async call and return
                return
            }
            
            do {
                //Converts entire returned data to json NSdictionary, there are 3 returned keys, result, status, html_attribution
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary//[String:Any]
                //Gather the result dictionary
                let results = json?["result"] as? NSDictionary  //[[String: Any]] ?? []
                //Collect the opening hours dictionary as a String:Any. Keys are exceptional_date: lists holidays, open_now: "boolean", weekday_text: weekday names and hours, periods: NSArray of key value pairs for the opening times
                guard let weekdayText = (results?["opening_hours"] as? [String:Any])?["weekday_text"] as? [String] else{
                    self.myGroup.leave()    //Open Hours weren't provide, notify async group that this call was aborted
                    Helpers().myPrint(text: "Couldn't convert google web api data from JSON to parse open hours")
                    self.openNow = "Hours Unknown"
                    return
                }
                
                let today = self.getDayOfWeek()
                //Match the first 3 letters of today's weekday string to google's array of weekday hours
                //Array of hours returned in the form : [Day String: open - close]
                for day in weekdayText{
                    if today == day.substring(to: day.index(day.startIndex, offsetBy: 3)){
                        if let colonIndex = day.characters.index(of:":"){
                            self.openNow = "Today" + day.substring(from: colonIndex)
                        }else{
                            self.openNow = "Hours Unknown"
                        }
                    }
                }
                //Notify dispatch group that places web api async call is finished
                self.myGroup.leave()
            } catch let error as NSError {
                let errorString = String(describing: error)
                Helpers().myPrint(text: errorString)
                self.myGroup.leave()    //Failed to use google web api, notify async group that this call was aborted
                Helpers().myPrint(text: "Google web api call failed")
                self.openNow = "Hours Unknown"
                return
            }
        }).resume()     //All tasks start in a suspended state by default; calling resume() starts the data task.
        
    }

    func retrievePlaceData(placeId: String, completionClosure: @escaping (_ deetsComplete: Bool) -> Void)
    {
        placesClient.lookUpPlaceID(placeId, callback: { (place, error) -> Void in
            if let error = error {
                Helpers().myPrint(text: "lookup place id query error: \(error.localizedDescription)")
                return
            }
            
            guard let place = place else {
                Helpers().myPrint(text: "No place details for \(placeId)")
                return
            }
            
            if let address = place.formattedAddress{
                 self.placeAddress = address
            }
            if let phoneNum = place.phoneNumber {
                    self.placePhoneNumber = phoneNum
            }
            if let websiteURL = place.website{
                self.placeWebsite = String(describing:websiteURL)
            }
            
            //Get the place coordinates and then the city, state, country so we can open the maps page reliably
            self.placeCoordinates = place.coordinate
            
            //Address components apprar to a dictionary of [type : name]
            //Cast to dictionary where the keys are the location type
            if let addressArray = place.addressComponents as NSArray?{
                for i in 0..<addressArray.count {
                    //Cast each enty in the array
                    let dics : GMSAddressComponent = addressArray[i] as! GMSAddressComponent
                    let str : NSString = dics.type as NSString
                    
                    if (str == "country") {
                        self.googleCityState["Country"] = dics.name
                    }
                    //State of the check in
                    else if (str == "administrative_area_level_1") {
                        self.googleCityState["State"] = dics.name
                    }
                        //State of the check in
                    else if (str == "locality") {
                        self.googleCityState["City"] = dics.name
                    }
                    //County of the Check in
//                    else if (str == "administrative_area_level_2") {
//                        self.googleCityState?["City"] = dics.name
//                    }
                }
            }

            
            
//            //Keep track of the number of times POI or establishment appears and subtract from total index
//            //and since index is 0 based and count is 1 based start at 1
//            //This doesn't work since POI and establishment are always last so the final place type still has a comma & space after it, so the next block removes those
//            var stupidTypes = 1
//            //Concatenate string of place types
//            for (index,item) in (place.types).enumerated(){
//                //Add place types if they aren't the obvious ones
//                if((item != "point_of_interest") && (item != "establishment")){
//                    //Spaces are retrieved with an underscore instead, replace with space
//                    let type = item.replacingOccurrences(of: "_", with: " ")
//                    //Don't add comma seperated value if last entry in the list
//                    if index < (place.types).count - stupidTypes{
//                        self.placeTypes += "\(type), "
//                    }else{
//                        self.placeTypes += type
//                    }
//                }else{
//                    stupidTypes += 1
//                }
//            }
//            //remove trailing comma and space if the last entries in place type were establishment and place of interest
//            self.placeTypes = self.placeTypes.trimmingCharacters(in: .whitespaces)
//            //Check if last character (before the null character) is a comma
//            let idx = self.placeTypes.index(self.placeTypes.endIndex, offsetBy: -1)
//            if(self.placeTypes[idx] == ","){
//                self.placeTypes = self.placeTypes.substring(to: idx)
//            }
            
            //Call completion closure so table view for details can be populated
            completionClosure(true)
        })
        
    }
    
    //Setup data cell height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        //Address cell is 75, deets cells are 50, and comment cell sizes automatically
        switch(indexPath.item){
            case (self.addressCell):
                return 75
                break
        case (self.commentCell):
                return UITableViewAutomaticDimension
                break
        default:
                return 50
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //6 defined Detail entries, with an optional comment cell
        if(self.commentList.count > 0){
            return 7
        }else{
            return 6
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        //Instantiate both cell types that either can be returned.
        let deetsCellIdentifier = "deetsCell"
        let addressCellIdentifier = "addressCell"
        
        //Redundant code to instantiate the requested table cell in each case statement because when I initialized the cell before the switch statement and returned the cell at the end of the function I had to return to opposite of the cell I expected to get the correct operation
        switch(indexPath.row){
        case 0 :
            //Find the first comma in the place address and seperate street address on first line from city state on bottom line
            var streetAddress: String = ""
            var cityState: String = ""
            if let firstComma = self.placeAddress.characters.index(of: ","){
                streetAddress = self.placeAddress.substring(to: firstComma)
                //Get index after the 1st comma and increment by 2 to remove the following space
                let afterComma = self.placeAddress.index(firstComma, offsetBy: 2)
                cityState = self.placeAddress.substring(from: afterComma)
            }
            
            let addressCell: AddressTableViewCell =  tableView.dequeueReusableCell(withIdentifier: addressCellIdentifier, for: indexPath) as! AddressTableViewCell
//            addressCell.topLabel.text = streetAddress
//            addressCell.bottomLabel.text = cityState
            addressCell.topLabel.text = self.placeAddress
//            addressCell.topLabel.lineBreakMode = .byWordWrapping
            
            addressCell.topLabel.font = UIFont(name: "Avenir-Light", size: 16)
//            addressCell.bottomLabel.font = UIFont(name: "Avenir-Light", size: 16)
            addressCell.topLabel.adjustsFontSizeToFitWidth = true
            self.titleLabel.lineBreakMode = .byTruncatingTail
            addressCell.topLabel.numberOfLines = 2
            return addressCell
        case 1:
            let deetsCell: PlaceDeetsTableViewCell = tableView.dequeueReusableCell(withIdentifier: deetsCellIdentifier, for: indexPath) as! PlaceDeetsTableViewCell
            
            deetsCell.iconImage.image = UIImage(named: "cellPhone")
            deetsCell.iconImage.contentMode = .center
            deetsCell.deetsLabel.text = self.placePhoneNumber
            deetsCell.deetsLabel.font = UIFont(name: "Avenir-Light", size: 16)
            return deetsCell
        case 2:
            let deetsCell: PlaceDeetsTableViewCell = tableView.dequeueReusableCell(withIdentifier: deetsCellIdentifier, for: indexPath) as! PlaceDeetsTableViewCell
            deetsCell.iconImage.image = UIImage(named: "internetIcon")
            deetsCell.iconImage.contentMode = .center
            deetsCell.deetsLabel.text = self.placeWebsite
            deetsCell.deetsLabel.font = UIFont(name: "Avenir-Light", size: 16)
            return deetsCell
        case 3:
            let deetsCell: PlaceDeetsTableViewCell = tableView.dequeueReusableCell(withIdentifier: deetsCellIdentifier, for: indexPath) as! PlaceDeetsTableViewCell
            deetsCell.iconImage.image = UIImage(named: "clock")
            deetsCell.iconImage.contentMode = .center
            deetsCell.deetsLabel.text = self.openNow
            deetsCell.deetsLabel.font = UIFont(name: "Avenir-Light", size: 16)
            deetsCell.selectionStyle = .none
            return deetsCell
        case 4:
            let deetsCell: PlaceDeetsTableViewCell = tableView.dequeueReusableCell(withIdentifier: deetsCellIdentifier, for: indexPath) as! PlaceDeetsTableViewCell
            deetsCell.iconImage.image = UIImage(named: "categoryIcon")
            deetsCell.iconImage.contentMode = .center
            deetsCell.deetsLabel.text = self.placeTypes
            deetsCell.deetsLabel.font = UIFont(name: "Avenir-Light", size: 16)
            //Disable category update when not my list or can't unwrap class member
            if(!(self.isMyPlace ?? false)){
                //other user's list
                deetsCell.selectionStyle = .none
                deetsCell.isUserInteractionEnabled = false
            }
            return deetsCell
        case 5:
            let deetsCell: PlaceDeetsTableViewCell = tableView.dequeueReusableCell(withIdentifier: deetsCellIdentifier, for: indexPath) as! PlaceDeetsTableViewCell
            deetsCell.iconImage.image = UIImage(named: "peopleMultiplierIcon")
            deetsCell.iconImage.contentMode = .center
            deetsCell.deetsLabel.text = self.friendString
            deetsCell.deetsLabel.font = UIFont(name: "Avenir-Light", size: 16)
            deetsCell.selectionStyle = .none
            return deetsCell
        case commentCell:   //Cell 6
            let commentCell: CommentsTableViewCell = tableView.dequeueReusableCell(withIdentifier: "commentsCell", for: indexPath) as! CommentsTableViewCell
            commentCell.contentImage.image = UIImage(named: "Human Commenting")
            commentCell.contentImage.contentMode = .center
            commentCell.commentLabel.font = UIFont(name: "Avenir-Light", size: 16)
            //Set comment text if any exist, and set multiple comments image if more than 1 exist
            if(commentList.count > 0){
                commentCell.commentLabel.text = self.commentList[self.commentPtr]
                if(commentList.count > 1){
                    commentCell.multipleCommentImage.image = UIImage(named: "More Comments icon")
//                    commentCell.multipleContentImage.contentMode = .center
                }
            }
           return commentCell

        default:
            Helpers().myPrint(text: "Table entries exceed place details")
            //Default cell value to return
            let deetsCell: PlaceDeetsTableViewCell = tableView.dequeueReusableCell(withIdentifier: deetsCellIdentifier, for: indexPath) as! PlaceDeetsTableViewCell
            deetsCell.deetsLabel.text = "Gimme da Deets"
            return deetsCell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(indexPath.row){
            //open googleMaps with coordinates
            case self.addressCell:
                var latitude, longitude: CLLocationDegrees
                if let coord = self.placeCoordinates{
                    latitude = coord.latitude
                    longitude = coord.longitude
                }else{
                    break
                }
                //Need to replace and spaces in a places name with "+", and unwrap optional
                guard var placePlus = self.titleText?.replacingOccurrences(of: " ", with: "+") else {break}
                //Google balks at certain characters in url name string so remove funny characters
                //Firebase Keys must be non-empty and cannot contain '.' '#' '$' '[' or ']'
                if let index = placePlus.characters.index(of: ".") {
                    placePlus.remove(at: index)
                }
                if let index = placePlus.characters.index(of: "#") {
                    placePlus.remove(at: index)
                }
                if let index = placePlus.characters.index(of: "$") {
                    placePlus.remove(at: index)
                }
                if let index = placePlus.characters.index(of: "[") {
                    placePlus.remove(at: index)
                }
                if let index = placePlus.characters.index(of: "]") {
                    placePlus.remove(at: index)
                }
                if let index = placePlus.characters.index(of: "&") {
                    placePlus.remove(at: index)
                }
                //Create query in the url string of place name+city+state+country
                var cityState: String = ""
                if var city = self.googleCityState["City"]{
                    city = city.replacingOccurrences(of: " ", with: "+")
                    cityState = city
                }
                if var state = self.googleCityState["State"]{
                    state = state.replacingOccurrences(of: " ", with: "+")
                    if (!cityState.isEmpty){
                        cityState += "+\(state)"
                    }else{
                        cityState = state
                    }
                }
                if var country = self.googleCityState["Country"]{
                    country = country.replacingOccurrences(of: " ", with: "+")
                    if (!cityState.isEmpty){
                        cityState += "+\(country)"
                    }else{
                        cityState = country
                    }
                }
                let mapsString = "comgooglemaps://?q=\(placePlus)+\(cityState)&center=\(latitude),\(longitude)=14&views=traffic"
                let mapsUrl = URL(string: mapsString)
                guard let urlWrapper = mapsUrl else {break}
                //Open google maps and query the name of the place at the coordinates provided from the places api
                if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                    UIApplication.shared.open(urlWrapper)
                } else {    //If they don't have google maps app this will alert the user
                    let alert = UIAlertController(title: "You don't use Google maps!?", message: "It looks like you don't have google maps installed on your phone! Feel free to copy this address and paste into the navigation app of your choice", preferredStyle: .alert)
                    //Exit function if user clicks now and allow them to reconfigure the check in
                    let CancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(CancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                break
            
            //open telephone app and call place
            case self.phoneNumCell:
                var telNum = self.placePhoneNumber
            
            //overly verbose formatting of phone num
//            //create offset from original index once characters are removed
//            var idxOffset: Int = 0
//            for idx in telNum.characters.indices{
//                //only iterate until end index is reached
//                if(idx < telNum.endIndex){
//                    //create index that subtracts the number of previously deleted characters
//                    var currIdx: String.Index
//                    //Don't decrement by 0 if no characters have been deleted yet
//                    currIdx = telNum.index(idx, offsetBy: -idxOffset)
//                    //check if the char in the phone number is a digit
//                    if(!(telNum[currIdx] > "0" && telNum[currIdx] < "9") || telNum[currIdx] != "-"){
//                        telNum.remove(at: currIdx)
//                        //increment offset to subtract from futrue indices to delete to prevent going out of string's index bounds
//                        idxOffset += 1
//                    }
//                }
//            }
            var newNum = String(telNum.characters.map{("0"..."9").contains($0) ? $0 : " "})
            //This will replace any leading whitespace in the phone number
            newNum = newNum.trimmingCharacters(in: .whitespaces)
            //After trimming leading and trailing whitespace replace inner whitespace with dash
            newNum = newNum.replacingOccurrences(of: " ", with: "-")

            guard let number = URL(string: "telprompt://" +  newNum) else {
                Helpers().myPrint(text: "Incorrectly constructed phone number")
                break
            }

            UIApplication.shared.open(number, options: [:], completionHandler: nil)
            break
            
            //open websitre url
            case self.websiteCell:
                guard let site = URL(string: self.placeWebsite) else {
                    Helpers().myPrint(text: "guard website failed")
                    break
                }
                UIApplication.shared.open(site, options: [:], completionHandler: nil)
                break
            
            //Segue to update categories cell
        case self.categoryCell:            
            performSegue(withIdentifier: "segueToCats", sender: self)
            break
            
        case self.commentCell:
            //Increment to next comment if exists or loop around to beginning of array and redisplay comments
            if(self.commentPtr >= (self.commentList.count - 1 )){
                self.commentPtr = 0
            }else{
                self.commentPtr += 1
            }
            self.tableView.reloadData()
            break
        default:
            Helpers().myPrint(text: "non selectable cell")
            break
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //Allow copy paste for cells:
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        if(indexPath.row == self.addressCell){
            let cell = tableView.cellForRow(at: indexPath) as! AddressTableViewCell
            return (cell.topLabel?.text != nil)
        }else{
            let cell = tableView.cellForRow(at: indexPath) as! PlaceDeetsTableViewCell
            return (cell.deetsLabel?.text != nil)
        }
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }
    
    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(copy(_:)) {
            if(indexPath.row == self.addressCell){
                let cell = tableView.cellForRow(at: indexPath) as! AddressTableViewCell
                let pasteboard = UIPasteboard.general
                pasteboard.string = cell.topLabel?.text
            }else{
                let cell = tableView.cellForRow(at: indexPath) as! PlaceDeetsTableViewCell
                let pasteboard = UIPasteboard.general
                pasteboard.string = cell.deetsLabel?.text
            }
        }
    }
    
    // Unwind seque from category updates
    @IBAction func unwindFromCat(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        //Don't perform prepare for segue when unwinding from list, only for updating categories
        if(segue.identifier == "segueToCats"){
            let destinationVC = segue.destination as! UpdateCatsViewController
            destinationVC.storedCategories = self.categories
            destinationVC.titleText = self.titleText    //Store check in name
            
            //Since the category cell can be selected I need to deselect it
//            if let itemPath = self.tableView.indexPathForSelectedRow{
//                self.tableView.deselectRow(at: itemPath, animated: true)
//            }
        }
    }
    
}
