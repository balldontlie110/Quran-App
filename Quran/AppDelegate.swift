//
//  AppDelegate.swift
//  Quran
//
//  Created by Ali Earp on 07/07/2024.
//

import SwiftUI
import BackgroundTasks
import AVFoundation
import MediaPlayer

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let backgroundTaskIdentifier = "com.Ali.Quran.refresh"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        scheduleAppRefresh()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        
        NotificationManager.shared.updatePrayerNotifications()
        
        task.expirationHandler = {
            
        }
        
        task.setTaskCompleted(success: true)
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationManager.shared.updatePrayerNotifications()
        completionHandler(.newData)
    }
}
