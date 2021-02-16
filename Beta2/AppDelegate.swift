//
//  AppDelegate.swift
//  Beta2
//
//  Created by Jason Johnston on 11/7/15.
//  Copyright © 2015 anuJ. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import CoreData
import Firebase
import GooglePlaces
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var plistVersion: NSString = "0.0"
    
    //Function executes when the app is launched
    //2 facebook delegate methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //I probably should restrict these like it talks about: https://developers.google.com/maps/documentation/ios-sdk/get-api-key#get_key
        //Enable google places api key
        GMSPlacesClient.provideAPIKey(GoogleAPIKeys().GoogleApiGMSPlacesKey)
        //Enable the google maps api key
        GMSServices.provideAPIKey(GoogleAPIKeys().GoogleApiGMServicesKey)
        //change status bar background to solid color so that images can scroll behind it without affecting the status text
        let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        if statusBar.responds(to:#selector(setter: UIView.backgroundColor)) {
            statusBar.backgroundColor = UIColor.black
        }
        //Change status bar text  to light color
        UIApplication.shared.statusBarStyle = .lightContent
        
        //Configure Firebase
        FirebaseApp.configure()
        
        //Ensure NSUserDefault has a default value for each key the app is started
        let defaultsStandard = UserDefaults.standard
//        defaultsStandard.register(defaults: [Helpers.currUserDefaultKey: "0"])
//        defaultsStandard.register(defaults: [Helpers.currUserNameKey: "User"])
//        defaultsStandard.register(defaults: [Helpers.loginTypeDefaultKey: Helpers.userType.new.rawValue])
        //Store the current version of the app and see if its changed since the last version
        //read version from Info.plist
        if let unwrapVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") {
            Helpers().myPrint(text: "Current app version is : \(unwrapVersion)")
            plistVersion = unwrapVersion as! NSString
        }
        //Compare to the version stored in user defaults
        let appVer = Helpers().appVer
        //create a default key for the logout option, default value is true when new app version exists
        //Registering the User default creates a new value and key regardless of what previously existed
        //When appVer returns 0.0 this should be a new install of the app so I'd hope the firebase auth won't exist so don't force them to logout (let firebase auth handle logon)
        if((plistVersion != appVer) && (appVer != "0.0")){
            //Register the defaults key with default of 1 wasn't setting the value still
            defaultsStandard.register(defaults: [Helpers.logoutDefaultKey: 0])
            //Only uncomment when I want a user to be logged out on a new version
            //            defaultsStandard.register(defaults: [Helpers.logoutDefaultKey: 1])
//            Helpers().logoutDefault = 1
            //If I have to logout then update my current version number
            Helpers().appVer = plistVersion
        }else{
            defaultsStandard.register(defaults: [Helpers.logoutDefaultKey: 0])
            Helpers().logoutDefault = 0
        }
        
        //Invalidate the current flag on the home screen status counts
        Helpers().numCheckValDefault = 0
        Helpers().numFriendValDefault = 0
        Helpers().numFollowerValDefault = 0

        //enable firebase to work offline - can cause a delay in items being synced to/from Firebase
//        FIRDatabase.database().persistenceEnabled = true
        
        
        // Override point for customization after application launch.
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
    }
    
//    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
//        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
//    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled: Bool = FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: options[.sourceApplication] as? String, annotation: options[.annotation])
        return handled
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // Call the 'activateApp' method to log an app event for use
        // in Facebook analytics and advertising reporting.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "uk.co.plymouthsoftware.core_data" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "CheckedCoreData", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("Beta2.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            //Attempt to automatically migrate to updated core data model
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }


}

