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
    var categories: [String]?
    
    //Variables retrieved using google place ID
    var placeAddress: String = ""
    var placeWebsite: String = ""
    var placePhoneNumber: String = ""
    var placeTypes: String = ""
    var openNow : String = ""
    //Google places client
    var placesClient: GMSPlacesClient!
    //Google places web api uses different api key than ios app
    var googleAPIkey = "AIzaSyDF-YomjeVEY8AvjhY81M61j9LPDrez44c"
    //use dispatch groups to make async call using google places web api and google places ios api then fire async call to reload tableview
    var myGroup = DispatchGroup()
    
    //Enumerated defines for table entries
    let phoneNumCell = 1
    let websiteCell = 2
    
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
            
            //Kick off asynch call retrieve opening hours using places web api and add to dispatch group in function
            retrieveOpenHours(placeId: placeId)
            //Add retrieval of place details from places ios Api to dispatch group
            self.myGroup.enter()
            //Reload table view data after completiong cloure call signals that place deets were found
            retrievePlaceData(placeId: placeId){ (deetsComplete: Bool) in
                //Once the other details have been retrieved notify dispatch group
                self.myGroup.leave()
            }
            //Fire async call once places ios and web api calls have finish
            myGroup.notify(queue: .main) {
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
    
    override func viewWillAppear(_ animated: Bool) {
        let screenWidth = view.bounds.width
        
        let googleImageView = UIImageView(image: UIImage(named: "poweredByGoogle")) //Google attribution image view
        
        //Add google attribution to footer view
        //create image view for the center of the footer view
        let googleFrame = CGRect(x: ((self.tableView.tableFooterView?.frame.width)! - googleImageView.frame.width) / 2, y: 10, width: googleImageView.frame.width, height: googleImageView.frame.height)
        let googs = UIImageView(frame: googleFrame)
        googs.addSubview(googleImageView)
        self.tableView.tableFooterView?.addSubview(googs)
        
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
                print("Error fetching days")
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
        //Add the below async call to places web api to dispatch group
        myGroup.enter()
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with:url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else {
                self.openNow = "Hours Unknown"
                return
            }
            
            do {
                //Converts entire returned data to json NSdictionary, there are 3 returned keys, result, status, html_attribution
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary//[String:Any]
                //Gather the result dictionary
                let results = json?["result"] as? NSDictionary  //[[String: Any]] ?? []
                //Collect the opening hours dictionary as a String:Any. Keys are exceptional_date: lists holidays, open_now: "boolean", weekday_text: weekday names and hours, periods: NSArray of key value pairs for the opening times
                guard let weekdayText = (results?["opening_hours"] as? [String:Any])?["weekday_text"] as? [String] else{
                    print("Couldn't convert google web api data from JSON to parse open hours")
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
                print(error)
                self.openNow = "Hours Unknown"
                return
            }
        }).resume()     //All tasks start in a suspended state by default; calling resume() starts the data task.
        
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
//            addressCell.topLabel.text = streetAddress
//            addressCell.bottomLabel.text = cityState
            addressCell.topLabel.text = self.placeAddress
            addressCell.topLabel.lineBreakMode = .byWordWrapping
            addressCell.topLabel.numberOfLines = 2
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
            deetsCell.selectionStyle = .none
            return deetsCell
        case 5:
            let deetsCell: PlaceDeetsTableViewCell = tableView.dequeueReusableCell(withIdentifier: deetsCellIdentifier, for: indexPath) as! PlaceDeetsTableViewCell
            deetsCell.iconImage.image = UIImage(named: "peopleMultiplierIcon")
            deetsCell.iconImage.contentMode = .center
            deetsCell.deetsLabel.text = "Num Friends"
            deetsCell.deetsLabel.font = UIFont(name: "Avenir-Light", size: 16)
            deetsCell.selectionStyle = .none
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
                guard let site = URL(string: self.placeWebsite) else {
                    print("guard website failed")
                    break
                }
                UIApplication.shared.open(site, options: [:], completionHandler: nil)
                break
            
            default:
                break
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
