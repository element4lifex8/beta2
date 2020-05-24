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

class MapVC: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var mapView: GMSMapView!
    //    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var SwitchIcon: UISwitch!
    
    //If transition to this screen wants to checkout instead of my list, update this var
    //Info from login screen that will be populated here
    var callerWantsCheckOut: Bool?
    
    var locationManager: CLLocationManager? = nil
    var selectedCollection = [Int]()
    var selectedFilters = [String]()
    var placeCoordinates: CLLocationCoordinate2D?
    
    var catButtonList = ["Bar",  "Beaches", "Breakfast", "Brewery", "Brunch", "Bucket List", "Coffee Shop", "Dessert", "Dinner", "Food Truck", "Hikes", "Lodging", "Lunch", "Museums", "Night Club", "Parks", "Sightseeing", "Winery"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        
        //gooogle Places setup
        let placesClient = GMSPlacesClient.shared()
        
        //List user's checkin's on map:
//        let marker = GMSMarker(
        //Assign my user's ref
        let currRef = Database.database().reference().child("checked/\(Helpers().currUser)")
        retrieveWithRef(currRef){ (placeNodeArr: [placeNode]) in
            //Grab place id and use to set marker
            for node in placeNodeArr{
                if let placeId = node.placeId{
                    placesClient.lookUpPlaceID(placeId, callback: { (place, error) -> Void in
                        if let error = error {
                            Helpers().myPrint(text: "lookup place id query error: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let place = place else {
                            Helpers().myPrint(text: "No place details for \(node.placeId)")
                            return
                        }
                        
                        //Get the place coordinates and then the city, state, country so we can open the maps page reliably
                        self.placeCoordinates = place.coordinate
                        if let placeName = node.place, let typeArr = place.types, let placeCoord = self.placeCoordinates{
                            let marker = GMSMarker(position: placeCoord)    //Dangerous force unwrap
                            marker.title = "\(placeName)"
                            //Get the type of place and print with 1st letter capitalized in pop up
                            let firstType = typeArr[0]
                            var capType = firstType.uppercased().prefix(1) + firstType.lowercased().dropFirst()
                            marker.snippet = String(capType)
                            marker.icon = UIImage(named: "Geo-fence")
//                            marker.icon = UIImage(named: "locationIcon")
                            marker.map = self.mapView
                        }
                    })
                } else {
                    print("can't add custom checkin to mapview")
                }
            }
            
        }
        
        //Collection view
//        collectionView.delegate = self
//
//        collectionView?.allowsMultipleSelection = true
//        collectionView.showsHorizontalScrollIndicator = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        //Only show toggle when using map for check out screen
        if let _ = callerWantsCheckOut {
            //Show toggler
            mapView.layer.zPosition = mapView.layer.zPosition-1
        } else {
            SwitchIcon.isHidden = true
        }
//        collectionView.reloadData()
    }

    //Confirm to CL location delegate
    func startUpdatingLocation() {
        self.locationManager?.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        self.locationManager?.stopUpdatingLocation()
    }
    
    //    Collection view functions
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print ("returning \(self.catButtonList.count) cat items")
        return self.catButtonList.count
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
        catLabel.text = self.catButtonList[indexPath.item]
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
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var currSection: Int = 0
        //Keep track of whether a section exists to scroll to
        var canScroll: Bool = false

        if let cell = collectionView.cellForItem(at: indexPath){
            selectCell(cell, indexPath: indexPath)
        }
        //Keep track of selected items. Items are deselected when scrolled out of view
        selectedCollection.append(indexPath.item)
        selectedFilters.append(Helpers().catButtonList[indexPath.item])
        //        print("Coll \(selectedCollection)")

        //TODO: filter map pins to all categories not matching the selected category

    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        var currSection: Int = 0
        //Keep track of whether a section exists to scroll to
        var canScroll: Bool = false
        
        let cell = collectionView.cellForItem(at: indexPath)
        if let imageViews = cell?.contentView.subviews{
            for case let image as UIImageView in imageViews{
                image.removeFromSuperview()
            }
        }
        cell?.backgroundColor = UIColor.clear
        //Remove selected item from list Keeping track of selected items' index path
        if let index = selectedCollection.index(of: indexPath.item){
            selectedCollection.remove(at: index)
        }
        //Remove selected item from list Keeping track of selected items' nodeValue string
        if let index = selectedFilters.index(of: catButtonList[indexPath.item]){
            selectedFilters.remove(at: index)
        }
        
        //TODO - un filter map display
    }

    // change background color when user touches cell
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 1.0)
    }

    // change background color back when user releases touch
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.clear
    }

    func selectCell(_ cell: UICollectionViewCell, indexPath: IndexPath)
    {
        let checkImage = UIImage(named: "Check Symbol")
        let checkImageView = UIImageView(image: checkImage)

        //center check image at point 50,75
        checkImageView.frame = CGRect(x: 45, y: 70, width: 15, height: 15)
        //add check image
        cell.contentView.addSubview(checkImageView)
        cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
    }

}

