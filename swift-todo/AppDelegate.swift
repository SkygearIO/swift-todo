//
//  AppDelegate.swift
//  swift-todo
//
//  Created by Joey on 8/18/16.
//  Copyright © 2016 Oursky Ltd. All rights reserved.
//

import UIKit
import SKYKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, SKYContainerDelegate {
    
    var loggedin = false
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        
        SKYContainer.default().configAddress("https://your-endpoint.skygeario.com/") //Your server endpoint
        SKYContainer.default().configure(withAPIKey: "SKYGEAR_API_KEY") //Your Skygear API Key
        SKYContainer.default().delegate = self
        
        registerDevice()
        
        // This will prompt the user for permission to send remote notification
        application.registerUserNotificationSettings(UIUserNotificationSettings())
        application.registerForRemoteNotifications()
        
        return true
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
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Registered for Push notifications with token: \(deviceToken)");
        SKYContainer.default().registerRemoteNotificationDeviceToken(deviceToken) { (deviceID, error) in
            if error != nil {
                print("Failed to register device token: \(error)")
                return
            }
            
            self.addSubscription(deviceID!)
        }
    }
    
    // MARK: - Split view
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.detailItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    
    // MARK: - Skygear
    
    func registerDevice() {
        SKYContainer.default().registerDeviceCompletionHandler { (deviceID, error) in
            if error != nil {
                print("Failed to register device: \(error)")
                return
            }
            
            self.addSubscription(deviceID!)
        }
    }
    
    func addSubscription(_ deviceID: String) {
        let query = SKYQuery(recordType: "todo", predicate: nil)
        let subscription = SKYSubscription(query: query, subscriptionID: "my todos")!
        
        let operation = SKYModifySubscriptionsOperation(deviceID: deviceID, subscriptionsToSave: [subscription])
        operation?.modifySubscriptionsCompletionBlock = { (savedSubscriptions, operationError) in
            DispatchQueue.main.async {
                if operationError != nil {
                    print(operationError)
                }
            }
        };
        
        
        SKYContainer.default().privateCloudDatabase.execute(operation)
    }
    
    func container(_ container: SKYContainer!, didReceive notification: SKYNotification!) {
        print("received notification = \(notification)");
        NotificationCenter.default.post(name: Notification.Name(rawValue: ReceivedNotificationFromSkygaer), object: notification)
    }
    
}

