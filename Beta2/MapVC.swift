//
//  MapVC.swift
//  GoogleToolboxForMac
//
//  Created by Jason Johnston on 8/29/19.
//

import UIKit
import GoogleMaps

class MapVC: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {

    @IBOutlet weak var mapView: GMSMapView!
    
    var locationManager: CLLocationManager? = nil
    
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
        
        
        
        //List user's checkin's on map:
//        let marker = GMSMarker(
    }
    

    //Confirm to CL location delegate
    func startUpdatingLocation() {
        self.locationManager?.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        self.locationManager?.stopUpdatingLocation()
    }

}

//// MARK: - GMSMapViewDelegate
//extension MapViewController: GMSMapViewDelegate {
//    
//}
