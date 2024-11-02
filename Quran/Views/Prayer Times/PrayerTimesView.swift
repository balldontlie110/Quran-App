//
//  PrayerTimesView.swift
//  Quran
//
//  Created by Ali Earp on 15/06/2024.
//

import SwiftUI

struct PrayerTimesView: View {
    @EnvironmentObject private var prayerTimesModel: PrayerTimesModel
    
    private let prayers = ["Imsaak", "Dawn", "Sunrise", "Noon", "Sunset", "Maghrib", "Midnight"]
    private let prayersRenamed = ["Dawn" : "Fajr", "Sunrise" : "Sunrise", "Noon" : "Zuhr", "Sunset" : "Sunset", "Maghrib" : "Maghrib", "Midnight" : "Midnight"]
    
    private let columns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(prayerTimes, id: \.key) { prayer in
                Text(prayersRenamed[prayer.key] ?? prayer.key)
                    .foregroundStyle(Color.secondary)
                
                Text(prayerTimeString(prayer.value))
                    .bold()
            }.padding(.vertical, 5)
        }
        .multilineTextAlignment(.center)
        .font(.system(.title2))
    }
    
    private var prayerTimes: [Dictionary<String, Date>.Element] {
        var prayerTimesDates: [String : Date] = [:]
        
        for (prayer, time) in prayerTimesModel.prayerTimes {
            var dateComponents = DateComponents()
            
            if let hour = Int(time.dropLast(3)) {
                if prayer == "Midnight", let maghribTime = prayerTimesModel.prayerTimes["Maghrib"], let maghribHour = Int(maghribTime.dropLast(3)) {
                    if hour > maghribHour {
                        dateComponents.hour = hour + 12
                    }
                } else if (prayer == "Noon" && hour == 1) || prayer == "Sunset" || prayer == "Maghrib" {
                    dateComponents.hour = hour + 12
                } else {
                    dateComponents.hour = hour
                }
            }
            
            dateComponents.minute = Int(time.dropFirst(3))
            
            prayerTimesDates[prayer] = Calendar.current.date(from: dateComponents)
        }
        
        return prayerTimesDates.sorted {
            prayers.firstIndex(of: $0.key) ?? 0 < prayers.firstIndex(of: $1.key) ?? 0
        }
    }
    
    private func prayerTimeString(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}

#Preview {
    PrayerTimesView()
}
