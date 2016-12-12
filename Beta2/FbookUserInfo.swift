//
//  FbookUserInfo.swift
//  Beta2
//
//  Created by Jason Johnston on 12/9/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import Foundation

class FbookUserInfo{
    var displayName: String?
    var id: String?
    var auth: Bool?
    
    init(){
        self.displayName = nil
        self.id = nil
        self.auth = nil
    }
    
    init(name: String){
        self.displayName = name
        self.id = nil
        self.auth = false
    }
    
    init(name: String, id: String){
        self.displayName = name
        self.id = id
        self.auth = true
    }
    
    
}
