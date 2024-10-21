//
//  NotificationManager.swift
//  Quran
//
//  Created by Ali Earp on 06/07/2024.
//

import SwiftUI
import UserNotifications
import CoreData
import iCalendarParser

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    let moc: NSManagedObjectContext
    
    private let timeBefores: [Int : String] = [
        -5 : "in 5 minutes",
        -10 : "in 10 minutes",
        -15 : "in 15 minutes",
        -30 : "in 30 minutes",
        -60 : "in 1 hour",
        -120 : "in 2 hours",
        -1440 : "tomorrow"
    ]
    
    static let shared = NotificationManager()
    
    private override init() {
        self.moc = PersistenceController.shared.container.viewContext
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.updatePrayerNotifications()
            }
        }
    }
    
    private func fetchPrayerTimes(completion: @escaping ([String : Date]) -> Void) {
        PrayerTimesModel().fetchPrayerTimes { prayerTimes in
            let prayersRenamed = ["Dawn" : "Fajr", "Sunrise" : "Sunrise", "Noon" : "Zuhr", "Sunset" : "Sunset", "Maghrib" : "Maghrib"]
            
            if let keys = Array(prayersRenamed.keys) as? [String], let prayerTimes = prayerTimes?.filter({ keys.contains($0.key) }) {
                var prayerDates: [String : Date] = [:]
                
                for (prayer, time) in prayerTimes {
                    var dateComponents = DateComponents()
                    
                    if let hour = Int(time.dropLast(3)) {
                        if (prayer == "Noon" && hour == 1) || prayer == "Sunset" || prayer == "Maghrib" {
                            dateComponents.hour = hour + 12
                        } else {
                            dateComponents.hour = hour
                        }
                    }
                    
                    dateComponents.minute = Int(time.dropFirst(3))
                    
                    prayerDates[prayersRenamed[prayer] ?? prayer] = Calendar.current.date(from: dateComponents)
                }
            }
        }
    }
    
    func updatePrayerNotifications() {
        fetchPrayerTimes { prayerTimes in
            if let data = UserDefaults.standard.string(forKey: "prayerNotifications")?.data(using: .utf8) {
                let prayerNotifications = (try? JSONDecoder().decode([String : Bool].self, from: data)) ?? [:]
                let activePrayerNotifications = prayerTimes.filter({ prayerNotifications[$0.key] ?? false })
                
                let center = UNUserNotificationCenter.current()
                
                center.removePendingNotificationRequests(withIdentifiers: Array(prayerTimes.keys))
                
                for (prayer, time) in activePrayerNotifications {
                    let content = UNMutableNotificationContent()
                    content.title = "\(prayer) \(prayer != "Sunset" && prayer != "Sunrise" ? "Salaat" : "")"
                    
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
                    let identifier = prayer
                    
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    center.add(request)
                }
            }
        }
    }
    
    func isNotifyingEvent(event: ICEvent, completion: @escaping (Bool, Int?) -> Void) {
        let center = UNUserNotificationCenter.current()
        
        center.getPendingNotificationRequests { requests in
            guard let request = requests.first(where: { request in
                request.identifier == event.uid
            }), let timeBefore = request.content.userInfo["timeBefore"] as? Int else {
                completion(false, nil)
                return
            }
            
            completion(true, timeBefore)
        }
    }
    
    func scheduleEventNotification(event: ICEvent, timeBefore: Int?, completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        
        center.getPendingNotificationRequests { requests in
            if let request = requests.first(where: { request in
                request.identifier == event.uid
            }) {
                center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
                
                if timeBefore == nil {
                    completion(false)
                    return
                }
            }
            
            guard let timeBefore = timeBefore,
                  let time = event.dtStart?.date,
                  let triggerTime = Calendar.current.date(byAdding: .minute, value: timeBefore, to: time),
                  var summary = event.summary,
                  let location = self.fixedLocation(text: event.location) else {
                
                completion(false)
                return
            }
            
            if let timeBeforeString = self.timeBefores[timeBefore] {
                summary += " \(timeBeforeString)"
            }
            
            let content = UNMutableNotificationContent()
            content.title = summary
            content.body = location
            content.sound = .default
            content.userInfo = ["timeBefore" : timeBefore]
            
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let identifier = event.uid
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if error != nil {
                    completion(false)
                    return
                }
                
                completion(true)
            }
        }
    }
    
    private func fixedLocation(text: String?) -> String? {
        if let fixedLocation = text?.split(separator: ",").first {
            var fixedLocation = String(fixedLocation)
            
            fixedLocation = fixedLocation.replacingOccurrences(of: "\\n", with: "\n\n")
            fixedLocation = fixedLocation.replacingOccurrences(of: "\\r", with: "\r")
            fixedLocation = fixedLocation.replacingOccurrences(of: "\\", with: "")
            
            return fixedLocation
        }
        
        return nil
    }
}
