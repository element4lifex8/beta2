//
//  placeNode.swift
//  Beta2
//
//  Created by Jason Johnston on 5/17/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import Foundation
import Firebase

public struct placeNode {
    //defined as implicitly unwrapped optionals
    var place: String?
    var placeId: String?
    var category: [String]?
    var city: [String]?
    var location: [String:Double]?   //Dictionary with [lat: xx.xx, lng: xx.xx] structure
    let ref: DatabaseReference?
    
    // Initialize from arbitrary data
    init(place: String, category: [String], city: [String]) {
        self.place = place
        self.placeId = nil
        self.category = category
        self.city = city
        self.location = nil
        self.ref = nil
    }
    
    init() {
        self.place = nil
        self.placeId = nil
        self.category = nil
        self.city = nil
        self.location = nil
        self.ref = nil
    }
    
    mutating func addCity(_ cityName: String)
    {
        if self.city == nil{
            self.city = [cityName]
        }
        else{
            self.city?.append(cityName)
        }
    }
    
    mutating func addCategory(_ catName: String)
    {
        if self.category == nil{
            self.category = [catName]
        }
        else{
            self.category?.append(catName)
        }
    }
    
    //Pass dict with [lat: xx.xx, lng: xx.xx] structure
    mutating func addLocation(_ coord: NSDictionary)
    {
        var myDict = [String: Double] ()
        myDict["lat"]=coord["lat"] as! Double
        myDict["lng"] = coord["lng"] as! Double
        self.location = myDict
//        for (name, value) in coord{
//            self.location?[name as! String] = value as? Double
//        }
    }
    
//    init(snapshot: FDataSnapshot) {
//        key = snapshot.key
//        name = snapshot.value["name"] as! String
//        addedByUser = snapshot.value["addedByUser"] as! String
//        completed = snapshot.value["completed"] as! Bool
//        ref = snapshot.ref
//    }
//    
//    func toAnyObject() -> AnyObject {
//        return [
//            "name": name,
//            "addedByUser": addedByUser,
//            "completed": completed
//        ]
//    }
}
