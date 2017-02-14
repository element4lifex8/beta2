//
//  PlaceDeetsViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 2/2/17.
//  Copyright © 2017 anuJ. All rights reserved.
//

import UIKit
import GooglePlaces

class PlaceDeetsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    //    Variables set by another view controller
    //Store the place ID whose info is requested by the MyListVC
    var placeId: String?
    var titleText: String?
    
    //Variables retrieved using google place ID
    var placeAddress: String = ""
    var placeWebsite: String = ""
    var placePhoneNumber: String = ""
    var placeTypes: String = ""
    //Google places client
    var placesClient: GMSPlacesClient!
    
    //Enumerated defines for table entries
    let phoneNumCell = 1
    let websiteCell = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource=self
        self.tableView.delegate=self
        self.titleLabel.text = (titleText ?? "Place Not Found")
        self.titleLabel.font = UIFont(name: "Avenir-Light", size: 26)
        self.titleLabel.textAlignment = .center
        self.titleLabel.adjustsFontSizeToFitWidth = true
        
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
            
            //Reload table view data after completiong cloure call signals that place deets were found
            retrievePlaceData(placeId: placeId){ (deetsComplete: Bool) in
                activityIndicator.stopAnimating()
                loadingView.removeFromSuperview()
                self.tableView.reloadData()
            }
        }else{
            print("No place Id found")
        }
        //Remove empty lines from table view bottom by adding empty footer
        self.tableView.tableFooterView = UIView()
        //remove left padding from tableview seperators
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
    }

    func retrievePlaceData(placeId: String, completionClosure: @escaping (_ deetsComplete: Bool) -> Void)
    {
        placesClient.lookUpPlaceID(placeId, callback: { (place, error) -> Void in
            if let error = error {
                print("lookup place id query error: \(error.localizedDescription)")
                return
            }
            
            guard let place = place else {
                print("No place details for \(placeId)")
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
            
            //Keep track of the number of times POI or establishment appears and subtract from total index
            //and since index is 0 based and count is 1 based start at 1
            var stupidTypes = 1
            //Concatenate string of place types
            for (index,item) in (place.types).enumerated(){
                //Add place types if they aren't the obvious ones
                if((item != "point_of_interest") && (item != "establishment")){
                    //Spaces are retrieved with an underscore instead, replace with space
                    let type = item.replacingOccurrences(of: "_", with: " ")
                    //Don't add comma seperated value if last entry in the list
                    if index < (place.types).count - stupidTypes{
                        self.placeTypes += "\(type), "
                    }else{
                        self.placeTypes += type
                    }
                }else{
                    stupidTypes += 1
                }
            }
            //remove trailing comma and space if the last entries in place type were establishment and place of interest
            self.placeTypes = self.placeTypes.trimmingCharacters(in: .whitespaces)
            //Check if last character (before the null character) is a comma
            let idx = self.placeTypes.index(self.placeTypes.endIndex, offsetBy: -1)
            if(self.placeTypes[idx] == ","){
                self.placeTypes = self.placeTypes.substring(to: idx)
            }
                    
            //Call completion closure so table view for details can be populated
            completionClosure(true)
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //6 defined Detail entries
        return 6
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
            addressCell.topLabel.text = streetAddress
            addressCell.bottomLabel.text = cityState
            addressCell.topLabel.font = UIFont(name: "Avenir-Light", size: 16)
            addressCell.bottomLabel.font = UIFont(name: "Avenir-Light", size: 16)
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
            deetsCell.deetsLabel.text = "hours"
            deetsCell.deetsLabel.font = UIFont(name: "Avenir-Light", size: 16)
            return deetsCell
        case 4:
            let deetsCell: PlaceDeetsTableViewCell = tableView.dequeueReusableCell(withIdentifier: deetsCellIdentifier, for: indexPath) as! PlaceDeetsTableViewCell
            deetsCell.iconImage.image = UIImage(named: "categoryIcon")
            deetsCell.iconImage.contentMode = .center
            deetsCell.deetsLabel.text = self.placeTypes
            deetsCell.deetsLabel.font = UIFont(name: "Avenir-Light", size: 16)
            return deetsCell
        case 5:
            let deetsCell: PlaceDeetsTableViewCell = tableView.dequeueReusableCell(withIdentifier: deetsCellIdentifier, for: indexPath) as! PlaceDeetsTableViewCell
            deetsCell.iconImage.image = UIImage(named: "peopleMultiplierIcon")
            deetsCell.iconImage.contentMode = .center
            deetsCell.deetsLabel.text = "Num Friends"
            deetsCell.deetsLabel.font = UIFont(name: "Avenir-Light", size: 16)
            return deetsCell
        default:
            print("Table entries exceed place details")
            //Default cell value to return
            let deetsCell: PlaceDeetsTableViewCell = tableView.dequeueReusableCell(withIdentifier: deetsCellIdentifier, for: indexPath) as! PlaceDeetsTableViewCell
            deetsCell.deetsLabel.text = "Gimme da Deets"
            return deetsCell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(indexPath.row){
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
                print("Incorrectly constructed phone number")
                break
            }

            UIApplication.shared.open(number, options: [:], completionHandler: nil)
            break
            
            //open websitre url
            case self.websiteCell:
                guard let number = URL(string: self.placeWebsite) else {
                    print("guard website failed")
                    break
                }
                UIApplication.shared.open(number, options: [:], completionHandler: nil)
                break
            
            default:
                break
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
