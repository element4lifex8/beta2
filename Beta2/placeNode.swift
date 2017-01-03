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
    let ref: FIRDatabaseReference?
    
    // Initialize from arbitrary data
    init(place: String, category: [String], city: [String]) {
        self.place = place
        self.placeId = nil
        self.category = category
        self.city = city
        self.ref = nil
    }
    
    init() {
        self.place = nil
        self.placeId = nil
        self.category = nil
        self.city = nil
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
