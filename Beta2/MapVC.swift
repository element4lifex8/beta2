//
//  MapVC.swift
//  GoogleToolboxForMac
//
//  Created by Jason Johnston on 8/29/19.
//

import UIKit
import GoogleMaps
import FirebaseDatabase
import GooglePlaces

class MapVC: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var menuButton: UIButton!
    
    @IBOutlet weak var statusBarBackground: UIView!
    
    @IBOutlet weak var mapView: GMSMapView!
    let infoMarker = GMSMarker()    //Google's points of interest for GMSMapViewDelegate
    //    @IBOutlet weak var collectionView: UICollectionView!

    var pNodeArr = [placeNode()]

    //If transition to this screen wants to checkout instead of my list, update this var
    //Info from login screen that will be populated here
    var callerWantsCheckOut: Bool?  //Variable set by clalling VC
    
    //Store the user that the list items will be retrieved for

    var myFriends:[String] = []
    var myFriendIds: [String] = []    //list of Facebook Id's with matching index to myFriends array
    
    var locationManager: CLLocationManager? = nil
    var selectedCollection = [Int]()
    var selectedFilters = [String]()
    var placeCoordinates: CLLocationCoordinate2D?
    
    var selectedMarker: Any?    //Treenode Data stored with the marker
    
    //Put retrieved data in Tree to filter by category
    var placeNodeTreeRoot = PlaceNodeTree()
    var catFilters = [String]()
    
    var progMenuView: UIView = UIView()
    let menuWidth: CGFloat = 187.0
    //Table view holds items in list
    var tableView: UITableView = UITableView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var leonNode = placeNode(place:"LEON\'s Full Service", category: ["Bar"], city: ["Decatur, GA"])
        leonNode.location = [ "lat": 33.775381799999998, "lng": -84.295115699999997]
        var pNodeArr = [leonNode]
        
        var coordinates: CLLocationCoordinate2D?
        
        //Initialize CL Location manager so a users current location can be determined
        self.locationManager = CLLocationManager()
        
        if CLLocationManager.authorizationStatus() == .notDetermined{
            self.locationManager?.requestWhenInUseAuthorization()
        }
        
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 200   //To do see if 200 is too zoomed out
        locationManager?.delegate = self
        //Don't start updating if user hasn't granted permission so they are not prompted
        if (CLLocationManager.locationServicesEnabled()){
            startUpdatingLocation()
        }
        
        
        //Only grab the user coordinates if their location services are enabled so we don't prompt them every time to enable them
        if(CLLocationManager.locationServicesEnabled()){
            coordinates = locationManager?.location?.coordinate//CLLocationCoordinate2D(latitude: 37.788204, longitude: -122.411937)
        }else{
            coordinates = nil
        }
        
        //Map view delegate:
        mapView.delegate = self
        
         if let center = coordinates{
            //Change the view on the map to the user's current location
            mapView.camera = GMSCameraPosition(target: center, zoom: 15, bearing: 0, viewingAngle: 0)
         }else{
            let coordNone = CLLocationCoordinate2D(latitude: CLLocationDegrees(0), longitude: CLLocationDegrees(0))
            mapView.camera = GMSCameraPosition(target: coordNone, zoom: 15, bearing: 0, viewingAngle: 0)
        }
        
        //Enable blue dot on map
        mapView.isMyLocationEnabled = true
        //Enable button to center around location
        mapView.settings.myLocationButton = true
        //ToDo: See if this has any effect, zoom is auto enabled so this should only be neccessary for non-storyboard maps
//        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        //Retrieve checkins from firebase, sync with stored core data, display on map
        
        gatherData(){(finished: Bool) in
            if(finished){
                Helpers().myPrint(text: "Done loading map")
            }
        }
        
        //Collection view
//        collectionView.delegate = self
//
//        collectionView?.allowsMultipleSelection = true
//        collectionView.showsHorizontalScrollIndicator = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Grab value of weather the phone has the top notch by checking size of top safe area
        var hasTopNotch: Bool {
            if #available(iOS 13.0,  *) {
                return UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.safeAreaInsets.top ?? 0 > 20
            }else{
                return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
            }
        }
        //Change height of uiview behind status for non top-notch phones
        if(!hasTopNotch){
            statusBarBackground.heightAnchor.constraint(equalToConstant: CGFloat(integerLiteral: 20)).isActive = true
        }
        //Have to also set auto layout in addition to frame height for supporting iPhone X
//        self.heightConstraint = self.autoCompleteTableView?.heightAnchor.constraint(equalToConstant: CGFloat(self.autoCompleteFrameMaxHeight))
//        NSLayoutConstraint.activate([widthConstraint!, self.heightConstraint!])
    }
    //New plans are to fore-go the slider button and have a slide out menu like on the user profile screen (and maspster)
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

        createMenuView()
        
        //Connect tableview delegate
        self.tableView.dataSource=self
        self.tableView.delegate=self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        

//        //Only show toggle when using map for check out screen
//        if let _ = callerWantsCheckOut {
//            //Show toggler
//            mapView.layer.zPosition = mapView.layer.zPosition-1
//        } else {
//            SwitchIcon.isHidden = true
//        }
//        collectionView.reloadData()
    }

    //Confirm to CL location delegate
    func startUpdatingLocation() {
        self.locationManager?.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        self.locationManager?.stopUpdatingLocation()
    }
    
    
    // Use GMSMapViewDelegate to Attach an info window to the POI using the GMSMarker. (POI's are the pins google shows by default)
    func mapView(
        _ mapView: GMSMapView,
        didTapPOIWithPlaceID placeID: String,
        name: String,
        location: CLLocationCoordinate2D
        ) {
//        infoMarker.snippet = "Add me?"
        print("tapped poi")
        infoMarker.userData = [placeID, name] //Adding the place id to user data will allow me to use it and transition to the place deets screen
        infoMarker.position = location
        infoMarker.title = name
        infoMarker.opacity = 0;
        infoMarker.infoWindowAnchor.y = 1
        infoMarker.map = mapView
        mapView.selectedMarker = infoMarker
        
        //remove menu icon even if POI tapped
        if(self.view.bounds.contains(self.progMenuView.frame.origin)){
            animateMenu(dismiss: true)
        }
    }
    
    //Function retrieves friends and cities and returns when both retrievals are finished
    func gatherData(_ completionClosure: @escaping (_ finished: Bool) -> Void) {
        
        //Dispatch group used to sync firebase and facebook api call
        var myGroup = DispatchGroup()
        //Store the user that the list items will be retrieved for (either friends or just curr user
        var currUsers: [String]?
        var myPlaceNodes: [placeNode] = []
        var userRetrievalCount:Int = 0     //Count the number of user's with their info pulled from the dataBase
        let friendsRef = Database.database().reference().child("users/\(Helpers().currUser)/friends")
        var currRef = DatabaseReference()
        self.placeNodeTreeRoot.empty()
        //gooogle Places setup
        let placesClient = GMSPlacesClient.shared()
        
        //Only home screen->check out button sets this, so if nil print curr user's pins
        if(callerWantsCheckOut ?? false)
        {
            //Get list of the user's current friends so they can't add them again
            myGroup.enter()
            _ = Helpers().retrieveMyFriends(friendsRef: friendsRef) {(friendStr:[String], friendId:[String]) in
                self.myFriends = friendStr
                self.myFriendIds = friendId
                //Sort the friends and their IDs by combining into tuple, sorting by the myFriends string array (the first item in each tuple) then seperate back out into two arrays (same thing is done for unAddedFriends in the closure below)
                self.sortFriendArrays(nameArr: &self.myFriends, idArr: &self.myFriendIds)
                currUsers = self.myFriendIds
                myGroup.leave()
            }
            
        } else {  //Only the user's list
            //Fake async request to fire checkin retrieval below
            myGroup.enter()
            currUsers = [Helpers().currUser as String]
            myGroup.leave()
        }
        
        //Retrieve checkins once all user id's are retrieved
        myGroup.notify(queue: DispatchQueue.main) {
            //TODO Need to figure out how to only request data in printable map space
            
            //Place Details lookups cost $17 per 1000 if contact info (website/phone #) or atmostphere data (reviews, price level) is included, so the following request would get everything and rack up a fortune:                     placesClient.lookUpPlaceID(placeId, callback: {
            //Quotas to limit the damage are set here:  https://console.cloud.google.com/google/maps-apis/apis/places-backend.googleapis.com/quotas?project=check-in-out-lists
            
            //populate Core data with map pin data if not present
            
            //Only request basic data from place details and use geometry.location for coordinates (geometry also contains viewport, which contains the preferred viewport when displaying this place on a map as a LatLngBounds if it is known.
            // Specify the place data types to return.
            //                    let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |                        UInt(GMSPlaceField.placeID.rawValue))!
//            let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
//                UInt(GMSPlaceField.coordinate.rawValue) | UInt(GMSPlaceField.types.rawValue))!
            
            for friendId in currUsers!{
                currRef = Database.database().reference().child("checked/\(friendId)")
                Helpers().retrieveWithRef(currRef){ (placeNodeArr: [placeNode]) in
                    userRetrievalCount += 1     //finished retrieving current user's check in info
                    //Grab place id for each user checkin, and use to set marker
                     for node in placeNodeArr{
                        
                        //Add place node to my model unless if already exists in my model
                        //This would happen if viewing a checkout screen and multiple friends checked into the same place
                        //Custom checkins are a special case where the nil placeID could match the nil entry that the myPlaceNodes array is initialized with, so I unwrap and if both entries are nil then one becomes false and one becomes true so they never match
                        if(!myPlaceNodes.contains(where: {element in return ((element.placeId ?? "false") == (node.placeId ?? "true"))}))
                        {
                            myPlaceNodes.append(node)
                        }
                    }
                    
                    if(userRetrievalCount >= (currUsers?.count)! ){  //When data from all friendIds is gathered then generate tree
                        self.placeNodeTreeRoot = Helpers().generateTree(myPlaceNodes, cityFilterEn: false, cityFilterText: nil)
                        self.placeNodeTreeRoot.sortChildNodes()
                        self.reloadMap(treeRoot: self.placeNodeTreeRoot)
                    }
                }
            }
        }
 
    }
    
    //Add pin to map if place node location is available
    func reloadMap(treeRoot: PlaceNodeTree){
        //Clear all current pins
        mapView.clear()

        let nodeArr = treeRoot.getTreeNodes()
        for node in nodeArr{        //Get the place coordinates and then the city, state, country so we can open the maps page reliably
        
            //TODO determine visible map area and add when visible
            if let placeName = node.place, let typeArr = node.category, let placeCoord = node.location {
                let coord = CLLocationCoordinate2D(latitude: placeCoord["lat"]!, longitude: placeCoord["lng"]!)
                let marker = GMSMarker(position: coord)
                //Store entire treenode with marker so its details can be retrieved
                marker.userData = node
                marker.title = "\(placeName)"
                //Get the type of place and print with 1st letter capitalized in pop up
                let firstType = typeArr[0]
                var capType = firstType.uppercased().prefix(1) + firstType.lowercased().dropFirst()
                marker.snippet = String(capType)
                //                            marker.icon = UIImage(named: "Geo-fence")
                //                            marker.icon = UIImage(named: "locationIcon")
                marker.map = self.mapView
                
            } else {
                Helpers().myPrint(text: "can't add custom checkin to mapview")
            }
        }
    }
        
    //combine the friends names and Ids so they can be sorted together and then seperate back out
    //Use "inout" keyword to pass arrays to the function by reference
    func sortFriendArrays(nameArr: inout [String], idArr: inout [String]){
        //Combine the Friends names and IDs into a tuple so I can sort by last name
        // use zip to combine the two arrays and sort that based on the first
        //$0.0 refers to the the first value of the first tuple, and $0.1 refers to the first value of the 2nd tupe, so each tuple is a [unAddedFriend Name, unAddedFriendID] so I'm looking at the first & second item for each iteration and only considering the unAddedFriend name for sorting
        let combinedFriends = zip(nameArr, idArr).sorted {$0.0.lastName() < $1.0.lastName()}
        //Then extract all of the 1st items in each tuple (unAddedFriends names)
        nameArr = combinedFriends.map{$0.0}
        //Then extract all of the 2st items in each tuple (unAddedFriends ids)
        idArr = combinedFriends.map{$0.1}
    }

    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        if(self.view.bounds.contains(self.progMenuView.frame.origin)){
            animateMenu(dismiss: true)
        }
        selectedMarker = marker.userData
        self.performSegue(withIdentifier: "mapToDeets", sender: self)

    }
    
    //will detect whenever an empty map spot is tapped, need to also check when I click on a place that i didn't add!
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("tapped non icon")
        if(self.view.bounds.contains(self.progMenuView.frame.origin)){
            animateMenu(dismiss: true)
        }
    }
    
    
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("TAPPED MARKER")
        if(self.view.bounds.contains(self.progMenuView.frame.origin)){
            animateMenu(dismiss: true)
        }
        return false
    }
    
    
    //Pass the placeId of the placeDeets view
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        //Don't perform prepare for segue when unwinding from list
        if(segue.identifier == "mapToDeets"){
            let destinationVC = segue.destination as! PlaceDeetsViewController
            //get place id for selected place
            //Get index path of selected cell then get corresponding tree node
            if let markerData = selectedMarker as? placeNode{
                destinationVC.titleText = markerData.place
                destinationVC.placeId = markerData.placeId
                destinationVC.categories = markerData.category
            } else if let poiData = selectedMarker as? [String] {    //If I don't have a place node from a check in I should have a [place id,place name] string array from a google place of interest
                destinationVC.placeId = poiData[0]
                destinationVC.titleText = poiData[1]
                destinationVC.categories = [""]
            }
            //Pass whether this is a current user's list:
            //TODO - determine my map or other user
            //                if let _ = nil{
            destinationVC.isMyPlace = false    //If headerText is set then this is not the user
            //                }else{
            //                    destinationVC.isMyPlace = true
            //                }
            
        }
    }
    
    // Unwind seque from placeDeets
    @IBAction func unwindFromDeetsToMap(_ sender: UIStoryboardSegue) {
        // empty
    }
    
    //    Collection view functions
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print ("returning \(Helpers().catButtonList.count) cat items")
        return Helpers().catButtonList.count
    }
  
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "collCell"
        print("next butt")
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! RoundButtCollectionViewCell
        //        Outlet no longer used and label created in code
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        //        cell.myLabel.text = catButtonList[indexPath.item]
        //        cell.myLabel.sizeToFit()
        
        //Create label here since autolayout only worked after scroll
        let catLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 86, height: 25))
        catLabel.center = CGPoint(x: 50, y: 50)
        catLabel.textAlignment = NSTextAlignment.center
        catLabel.text = Helpers().catButtonList[indexPath.item]
        //Adjust font size to fit larger words, and truncate at end
        catLabel.adjustsFontSizeToFitWidth = true
        catLabel.minimumScaleFactor = 0.6
        catLabel.lineBreakMode = .byTruncatingTail
        
        catLabel.textColor = UIColor.white
        cell.contentView.addSubview(catLabel)
        //set cell properties
        cell.backgroundColor = UIColor.clear
        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.borderWidth = 2
        cell.layer.cornerRadius = 0.5 * cell.bounds.size.width
        
//        if(selectedCollection.contains(indexPath.item)){
//            selectCell(cell, indexPath: indexPath)
//        }
        
        return cell
    }
    
    //Slide out Menu to categorize
    func createMenuView(){
        //Label height is 60 and y offset is 20 to display below menu bar
        let labelHeight: CGFloat = 60.0
        let labelOffset: CGFloat = 20.0
        let borderWidth: CGFloat = 2
        //Use safe area for ios11 devices to put menu view below status bar otherwise assume the 20pt status bar height of non iphone X phones
        if #available(iOS 11, *) {
            self.progMenuView = UIView(frame: CGRect(x: self.view.frame.maxX, y: self.view.safeAreaInsets.top, width: self.menuWidth, height: self.view.frame.height))
        }else{
            self.progMenuView = UIView(frame: CGRect(x: self.view.frame.maxX, y: labelOffset, width: self.menuWidth, height: self.view.frame.height))
        }
        self.progMenuView.backgroundColor = .white
        self.progMenuView.layer.borderWidth = borderWidth
        self.progMenuView.layer.borderColor = UIColor.black.cgColor
        
        //Create Cat label at top of menu but start beneath status bar
        let labelView = UIView(frame: CGRect(x: 0, y: 0, width: self.progMenuView.frame.width, height: labelHeight))
        labelView.layer.borderWidth = borderWidth
        labelView.layer.borderColor = UIColor.black.cgColor
        //        let settingsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.progMenuView.frame.width, height: labelHeight))
        
        let settingsLabel = UILabel()
        settingsLabel.font = UIFont(name: "Avenir-Light", size: 24)
        settingsLabel.text = "Categories"
        settingsLabel.sizeToFit()
        //labelview.center wasn't centering so manually created center point
        let myPoint = CGPoint(x: labelView.frame.width / 2, y: labelView.frame.height / 2)
        settingsLabel.center = myPoint
        //Add view heirarchy
        labelView.addSubview(settingsLabel)
        self.progMenuView.addSubview(labelView)
        
        //Calculate Table view to sit beneath label and extend to bottom of screen
        tableView = UITableView(frame: CGRect(x: 0, y: labelHeight + borderWidth, width: self.progMenuView.frame.width, height: self.progMenuView.frame.height - (labelHeight + borderWidth)))
        //Remove seperator lines
        self.tableView.separatorStyle = .none
        //Stop table view from bouncing since cells will not fill the screen
        self.tableView.alwaysBounceVertical = false
        self.tableView.allowsMultipleSelection = true
        self.progMenuView.addSubview(tableView)
        //        tableView.reloadData()
        
    }
    @IBAction func requestMenu(_ sender: UIButton) {
        animateMenu(dismiss: false)
        self.menuButton.isEnabled = false   //Disable settings button so it can't be double pressed
        
    }
    
    func animateMenu(dismiss: Bool){
        //When dismissing I increase X to push the view off the screen
        let xOffset = dismiss ? self.progMenuView.frame.origin.x + self.menuWidth : self.progMenuView.frame.origin.x - self.menuWidth
        //If displaying menu first add to super view
        if(!dismiss){
            self.view.addSubview(self.progMenuView)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            self.progMenuView.frame.origin.x = xOffset
        },completion: {finished in
            //Remove from superview if dismissing
            if(dismiss){
                self.progMenuView.removeFromSuperview()
                self.menuButton.isEnabled = true   //re-enable menu button
            }
        })
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //5 defined settings options
        return Helpers().catButtonList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = Helpers().catButtonList[indexPath.row]
        
        return cell
    }
    
    //Will select and deselect functions added to control when to change category filter
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        //Determine category at current index
        catFilters.append(Helpers().catButtonList[indexPath.row])
        
        //filter tree to all categories not matching the selected category
        self.placeNodeTreeRoot.displayNodeFilter(catFilters)
        reloadMap(treeRoot: self.placeNodeTreeRoot)
        
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
        return indexPath
    }
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        //Remove selected item from list Keeping track of selected items' nodeValue string
        if let index = catFilters.index(of: Helpers().catButtonList[indexPath.item]){
            catFilters.remove(at: index)
        }
        
        //filter tree to all categories not matching the selected category
        self.placeNodeTreeRoot.displayNodeFilter(catFilters)
        reloadMap(treeRoot: self.placeNodeTreeRoot)
        
        tableView.deselectRow(at: indexPath, animated: true)
        return indexPath
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    }
    

    //Detect when user taps outside the menu view and dismiss the menu if it is present
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        print("touches began")
//        super.touchesBegan(touches, with: event)
//
//        if let touch: UITouch = touches.first{
//            if (touch.view == self.view){
//                //dismiss menu if present
//                if(self.view.bounds.contains(self.progMenuView.frame.origin)){
//                    animateMenu(dismiss: true)
//                }
//            }
//        }
//    }

//
//    //For now collection view seems to be axed
//
//    // MARK: - UICollectionViewDelegate protocol
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        var currSection: Int = 0
//        //Keep track of whether a section exists to scroll to
//        var canScroll: Bool = false
//
//        if let cell = collectionView.cellForItem(at: indexPath){
//            selectCell(cell, indexPath: indexPath)
//        }
//        //Keep track of selected items. Items are deselected when scrolled out of view
//        selectedCollection.append(indexPath.item)
//        selectedFilters.append(Helpers().catButtonList[indexPath.item])
//        //        print("Coll \(selectedCollection)")
//
//        //TODO: filter map pins to all categories not matching the selected category
//
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        var currSection: Int = 0
//        //Keep track of whether a section exists to scroll to
//        var canScroll: Bool = false
//
//        let cell = collectionView.cellForItem(at: indexPath)
//        if let imageViews = cell?.contentView.subviews{
//            for case let image as UIImageView in imageViews{
//                image.removeFromSuperview()
//            }
//        }
//        cell?.backgroundColor = UIColor.clear
//        //Remove selected item from list Keeping track of selected items' index path
//        if let index = selectedCollection.index(of: indexPath.item){
//            selectedCollection.remove(at: index)
//        }
//        //Remove selected item from list Keeping track of selected items' nodeValue string
//        if let index = selectedFilters.index(of: catButtonList[indexPath.item]){
//            selectedFilters.remove(at: index)
//        }
//
//        //TODO - un filter map display
//    }
//
//    // change background color when user touches cell
//    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
//        let cell = collectionView.cellForItem(at: indexPath)
//        cell?.backgroundColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 1.0)
//    }
//
//    // change background color back when user releases touch
//    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
//        let cell = collectionView.cellForItem(at: indexPath)
//        cell?.backgroundColor = UIColor.clear
//    }
//
//    func selectCell(_ cell: UICollectionViewCell, indexPath: IndexPath)
//    {
//        let checkImage = UIImage(named: "Check Symbol")
//        let checkImageView = UIImageView(image: checkImage)
//
//        //center check image at point 50,75
//        checkImageView.frame = CGRect(x: 45, y: 70, width: 15, height: 15)
//        //add check image
//        cell.contentView.addSubview(checkImageView)
//        cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
//    }
//
    //Set status bar to same color as background
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }

}

