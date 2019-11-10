//
//  UpdateCatsViewController.swift
//  Beta2
//
//  Created by Jason Johnston on 11/12/17.
//  Copyright © 2017 anuJ. All rights reserved.
//

import UIKit
import FirebaseDatabase

class UpdateCatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var HeaderView: UIView!
    
    //List of categories previously retrieved for displyaing in my list and place deets, they will appear checked here
    var storedCategories: [String]?
    var titleText: String?  //Name of restaurant as store in database, written from place deets
    
    var catButtonList = ["Bar", "Beaches", "Breakfast", "Brewery", "Brunch", "Bucket List", "Coffee Shop", "Dessert", "Dinner", "Food Truck", "Hikes", "Lunch", "Museums", "Night Club", "Parks", "Sight Seeing", "Winery"]
    var catVals = [String]()    //Create array of the final cat value array
    //Array or current selected accessory views
    var selectedCatButt : [Int] = []
    var categoryUpdates = false //Keep track of a category change
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource=self
        self.tableView.delegate=self
        
        //Preselect any of the currently stored categories by adding their index to the selected Cat list
        for (index, _ ) in catButtonList.enumerated(){
            if(storedCategories?.contains(self.catButtonList[index]) ?? false){
                self.selectedCatButt.append(index)
            }
        }
    }
    
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
        buttonView.addSubview(subButt)
        subButt.backgroundColor = UIColor.white
        subButt.layer.borderWidth = 2.0
        subButt.layer.borderColor = UIColor.black.cgColor
        subButt.setTitle("Submit", for: UIControlState())
        subButt.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 36)
        subButt.setTitleColor(UIColor.black, for: UIControlState())
        //add target actions for button tap and make sure it isuser selectable
        //        subButt.isUserInteractionEnabled = true
        subButt.addTarget(self, action: #selector(AddPeopleViewCntroller.submitSelected(_:)), for: .touchUpInside)
        //Add shadow to button
        subButt.layer.shadowOpacity = 0.7
        subButt.layer.shadowOffset = CGSize(width: shadowX, height: shadowY)
        //Radius of 1 only adds shadow to bottom and right
        subButt.layer.shadowRadius = 1
        subButt.layer.shadowColor = UIColor.black.cgColor
//        buttonView.addSubview(subButt)
        
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
        
        //Header view was breaking constraints so try setting height in code
        HeaderView.translatesAutoresizingMaskIntoConstraints = false
        let headerHeight = HeaderView.heightAnchor.constraint(equalToConstant: 100)
        NSLayoutConstraint.activate([headerHeight])

    }
    
    func updateCurrCategories(_ completionClosure: @escaping (_ category: [String]) -> Void){
        
    }
    
    @IBAction func accessoryButtonTapped(_ sender: UIButton) {
        //check or uncheck selected friends, when the user taps a button with a title, the button moves to the highlighted state
        sender.isSelected = sender.state == .highlighted ? true : false
        if(sender.isSelected){
            //Update Tracking arrays of selected accessory buttons
            syncAccessoryView(uncheck: false, idx: sender.tag)
        }else{
            //Keep track of accessory buttons that are unchecked
            syncAccessoryView(uncheck: true, idx: sender.tag)
        }
        
    }
        
    //When a user selects an accessory button (or we preselect for searched users then we store the current location of that user in the table data source to sync the selected accessory view
    func syncAccessoryView(uncheck: Bool, idx: Int){
        if(uncheck){
            //Remove from arrays for indices, staged friends, and searched friends
            if let index = self.selectedCatButt.index(of: idx){
                self.selectedCatButt.remove(at: index)
            }
        }else{
            //Keep track of accessory buttons that are checked so they are reselected when scrolled back into view
            self.selectedCatButt.append(idx)
        }
    }
    
    @IBAction func submitSelected(_ sender: UIButton) {
        guard let checkInName = self.titleText, let storedCatUnrwap = storedCategories else{
            Helpers().myPrint(text: "Unable to unwrap place name or stored categories when passing titleText from Placedeets to Update Cats VC")
            performSegue(withIdentifier: "unwindFromCat", sender: self)
            return
        }
        let userCatRef = Database.database().reference().child("checked/\(Helpers().currUser)/\(checkInName)/category")
        
        //Check if the previously stored categories was updated and that at least 1 category is selected
        if(selectedCatButt.count > 0){
            
            //Map the indices in selected cat butt to an array of category values
            catVals = selectedCatButt.map{catButtonList[$0]}
            //Check if the alphabetically sorted list of stored categories is the same as the sorted list of checked categories in the table
            if((storedCatUnrwap.count != catVals.count) ||
                (storedCatUnrwap.sorted() != catVals.sorted())){
                //Map catVals to dict with catVal[]:"true" and store the new list of categories in firebase
                //Reduce argument specifies the initial value (empty dictionary)
                //Two elements in closure are the dict which in this case is the complete dict we are creating as per the argument to reduce, and then each key from the catVals array will be iterated over and assigned to a non let constant dict to compile the full dict
                //See SO for using anonymous args with swift 4: https://stackoverflow.com/a/46839132/5495979
                let catDict = catVals.reduce([String: String]()){ (dict,key) -> [String: String] in
                    var varDict = dict //dict is a let constant
                    varDict[key] = "true"
                    return varDict
                }
                //Only update the categories if they are different from the originally stored ones
                userCatRef.setValue(catDict)
                //Note that the category was updated so I can reload tableview in place deets
                categoryUpdates = true
            }
        }
        performSegue(withIdentifier: "unwindFromCat", sender: self)
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
        return self.catButtonList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let checkImage = UIImage(named: "tableAccessoryCheck")
        let cell = tableView.dequeueReusableCell(withIdentifier: "catCell", for: indexPath) as! CategoryTableViewCell
        cell.catLabel.text = self.catButtonList[indexPath.row]
        
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
        if(self.selectedCatButt.contains(indexPath.item))
        {
            accessoryButton.isSelected = true
        }
        //Remove seperator insets
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        //Check if an update occured and set the updateCategory variable in the Place Deets VC to reload the table view
        if(categoryUpdates == true){
            let destinationVC = segue.destination as! PlaceDeetsViewController
            destinationVC.categoryUpdate = categoryUpdates
            destinationVC.categories = self.catVals
        }
    
    }  


}
