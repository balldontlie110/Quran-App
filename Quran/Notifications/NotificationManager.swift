//
//  NotificationManager.swift
//  Quran
//
//  Created by Ali Earp on 06/07/2024.
//

import SwiftUI
import UserNotifications
import CoreData

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    let moc: NSManagedObjectContext
    
    static let shared = NotificationManager()
    
    private override init() {
        self.moc = PersistenceController.shared.container.viewContext
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.updateNotifications()
            } else if let error = error {
                print(error)
            }
        }
    }
    
    func updateNotifications() {
        PrayerTimesModel().fetchPrayerTimes { prayerTimes in
            if let prayerTimes = prayerTimes {
                let request = PrayerNotification.fetchRequest()
                
                do {
                    let prayerNotifications = try self.moc.fetch(request)
                    
                    let prayersRenamed = ["Dawn" : "Fajr", "Sunrise" : "Sunrise", "Noon" : "Zuhr", "Sunset" : "Sunset", "Maghrib" : "Maghrib"]
                    var prayerTimesDates: [String : Date] = [:]
                    
                    for (prayer, time) in prayerTimes.filter({ (prayer, time) in
                        return prayerNotifications.contains { prayerNotification in
                            prayerNotification.prayer == prayersRenamed[prayer] && prayerNotification.active == true
                        }
                    }) {
                        var dateComponents = DateComponents()
                        
                        if let hour = Int(time.dropLast(3)) {
                            if (prayer == "Noon" && hour != 11) || prayer == "Sunset" || prayer == "Maghrib" {
                                dateComponents.hour = hour + 12
                            } else {
                                dateComponents.hour = hour
                            }
                        }
                        
                        dateComponents.minute = Int(time.dropFirst(3))
                        
                        prayerTimesDates[prayersRenamed[prayer] ?? prayer] = Calendar.current.date(from: dateComponents)
                    }
                    
                    self.scheduleNotifications(prayerTimes: prayerTimesDates)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func scheduleNotifications(prayerTimes: [String: Date]) {
        let center = UNUserNotificationCenter.current()
        
        center.removeAllPendingNotificationRequests()
        
        for (prayer, time) in prayerTimes {
            let content = UNMutableNotificationContent()
            content.title = "\(prayer) \(prayer != "Sunset" && prayer != "Sunrise" ? "Salah" : "")"
            
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            content.body = "\(prayer == "Sunset" ? "🌙" : prayer == "Sunrise" ? "☀️" : "🕌") \(prayer) at \(formatter.string(from: time))"
            
            if prayer != "Sunset" && prayer != "Sunrise" {
                content.sound = UNNotificationSound(named: UNNotificationSoundName("Adhan.wav"))
            } else {
                content.sound = .default
            }
            
            let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            
            let identifier = "\(prayer)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print(error)
                }
            }
        }
    }
}
