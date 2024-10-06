//
//  NextPrayerView.swift
//  Quran
//
//  Created by Ali Earp on 01/09/2024.
//

import SwiftUI

struct NextPrayerView: View {
    @EnvironmentObject private var prayerTimesModel: PrayerTimesModel
    
    private let prayers = ["Dawn", "Sunrise", "Noon", "Sunset", "Maghrib", "Midnight"]
    private let prayersRenamed = ["Dawn" : "Fajr", "Sunrise" : "Sunrise", "Noon" : "Zuhr", "Sunset" : "Sunset", "Maghrib" : "Maghrib", "Midnight" : "Midnight"]
    
    @State private var date: Date = Date()
    
    var body: some View {
        VStack {
            if let nextPrayer = nextPrayer {
                Group {
                    if nextPrayer.key == "Dawn" {
                        Text("Fajr starts in")
                    } else if nextPrayer.key == "Sunrise" {
                        Text("Fajr ends in")
                    } else if nextPrayer.key == "Noon" {
                        Text("Zuhr starts in")
                    } else if nextPrayer.key == "Sunset" {
                        Text("Zuhr ends in")
                    } else if nextPrayer.key == "Maghrib" {
                        Text("Maghrib starts in")
                    } else if nextPrayer.key == "Midnight" {
                        Text("Maghrib ends in")
                    }
                }.foregroundStyle(Color.secondary)
                
                Text("\(timeRemaining.hours)\(timeRemaining.minutes)\(timeRemaining.seconds)")
                    .font(.headline)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.top)
        .onAppear {
            startTimer()
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.date = Date()
        }
    }
    
    private var nextPrayer: Dictionary<String, Date>.Element? {
        return (prayerTimes.filter { $0.value > date }).min(by: { $0.value < $1.value })
    }
    
    private var timeRemaining: (hours: String, minutes: String, seconds: String) {
        var hoursString = ""
        var minutesString = ""
        var secondsString = ""
        
        if let nextPrayer = nextPrayer {
            let interval = Int(nextPrayer.value.timeIntervalSince(date))
            
            let second = 1
            let minute = 60
            let hour = 3600
            
            let hours = interval / hour
            let minutes = (interval % hour) / minute
            let seconds = ((interval % hour) % minute) / second
            
            if hours > 0 {
                hoursString = "\(hours) hour\(minutes == 1 ? "" : "s") "
            }
            
            if minutes > 0 {
                minutesString = "\(minutes) minute\(minutes == 1 ? "" : "s") "
            }
            
            if seconds > 0 {
                secondsString = "\(seconds) second\(seconds == 1 ? "" : "s")"
            }
        }
        
        return (hoursString, minutesString, secondsString)
    }
    
    private var prayerTimes: [String : Date] {
        let filteredPrayerTimes = prayerTimesModel.prayerTimes.filter { prayerTime in
            prayers.contains { prayer in
                prayer == prayerTime.key
            }
        }
        
        var prayerTimesDates: [String : Date] = [:]
        
        for (prayer, time) in filteredPrayerTimes {
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            
            if let hour = Int(time.dropLast(3)) {
                if (prayer == "Noon" && hour == 1) || prayer == "Sunset" || prayer == "Maghrib" || prayer == "Midnight" {
                    dateComponents.hour = hour + 12
                } else {
                    dateComponents.hour = hour
                }
            }
            
            dateComponents.minute = Int(time.dropFirst(3))
            dateComponents.second = 0
            
            prayerTimesDates[prayer] = Calendar.current.date(from: dateComponents)
        }
        
        return prayerTimesDates
    }
}

#Preview {
    NextPrayerView()
}
