//
//  AppDelegate.swift
//  HealthKit-Observer
//
//  Created by Mohammad Gharari on 7/8/21.
//

import UIKit
import HealthKit
@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        anchorQuery()
        return true
    }

    
    // MARK: - Healthkit anchor query
    
    
    func anchorQuery() {
        
        let hkStore = HKHealthStore()
        /// first define which data you need to get
        guard let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("*** Unable to get step count type")
            
        }
        
        /// We set the objects which want to read from `Health`
        let readData = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
        
        /// ask for read authorizato to `Health` data
        hkStore.requestAuthorization(toShare: [], read: readData, completion: { (success, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            /// first set an anchor to track the data receives
            var anchor = HKQueryAnchor.init(fromValue: 0)
            
            
            /// save the anchore as data in `UserDefaults`
            if UserDefaults.standard.object(forKey: "Anchor") != nil {
                let data = UserDefaults.standard.object(forKey: "Anchor") as! Data
                anchor = NSKeyedUnarchiver.unarchiveObject(with: data) as! HKQueryAnchor
                
            }
            
            
            /// check if `Health` data is available
            guard HKHealthStore.isHealthDataAvailable() else {
                fatalError("No Healthkit data available")
            }
            
            
            /// Now we set the initializer for the observer
            let query = HKAnchoredObjectQuery(type: stepCount,
                                              predicate: nil,
                                              anchor: anchor,
                                              limit: HKObjectQueryNoLimit,
                                              resultsHandler: { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
                                                /// here the query returns all data from healthkit
                                                /// because we want updates, we have to first get all data
                                                /// and then any changes to those data is an update
                                                
                                                guard let samples = samplesOrNil, let deletedObjects = deletedObjectsOrNil else {
                                                    print("*** An error occured during initial query:\(errorOrNil!.localizedDescription)")
                                                    return
                                                }
                                                
                                                /// here we have new data, so set the anchor to new data
                                                anchor = newAnchor!
                                                
                                                let data:Data = NSKeyedArchiver.archivedData(withRootObject: newAnchor as Any)
                                                UserDefaults.standard.set(data, forKey: "Anchor")
                                                
                                                
                                                /// here we can print new datas
                                                for newSteps in samples {
                                                    print("Samples: \(newSteps)")
                                                }
                                                
                                                
                                                for deletedSteps in deletedObjects {
                                                    print("Deleted: \(deletedSteps)")
                                                }
                                              })
            
            
            
            /// after setting `query`, it's time to set `updateHandler` which is called every time an update occurs in `Healthkit` data
            
            query.updateHandler = { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
                guard let samples = samplesOrNil, let deleted = deletedObjectsOrNil else {
                    print("*** An error occurred during update: \(errorOrNil!.localizedDescription) ***")
                    return
                }
                
                /// we set the anchor to the new anchor we received
                anchor = newAnchor!
                
                /// save the data in `UserDefaults`
                let data:Data = NSKeyedArchiver.archivedData(withRootObject: newAnchor as Any)
                UserDefaults.standard.set(data,forKey: "Anchor")
                
                
                /// now check for any new data
                for steps in samples {
                    print("Samples: \(steps)")
                }
                
                for deleted in deleted {
                    print("Deleted:\(deleted)")
                }
            }
            
            
            /// now excute the `query`
            hkStore.execute(query)
            
            
            
            ///if we want to activate background delivery, set it in `hkStore`
            hkStore.enableBackgroundDelivery(for: stepCount, frequency: .immediate, withCompletion: { _,_ in })
            
        })
    }
    
    
    
    // MARK: -  UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

