//
//  PrayerTimesView.swift
//  Quran
//
//  Created by Ali Earp on 15/06/2024.
//

import SwiftUI

struct PrayerTimesView: View {
    @StateObject private var prayerTimesModel: PrayerTimesModel = PrayerTimesModel()
    
    private let prayers = ["Imsaak", "Dawn", "Sunrise", "Noon", "Sunset", "Maghrib", "Midnight"]
    private let prayersRenamed = ["Dawn" : "Fajr", "Sunrise" : "Sunrise", "Noon" : "Zuhr", "Sunset" : "Sunset", "Maghrib" : "Maghrib", "Midnight" : "Midnight"]
    
    private let columns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(prayerTimes, id: \.key) { prayer in
                LazyVGrid(columns: columns) {
                    Text(prayersRenamed[prayer.key] ?? prayer.key)
                        .foregroundStyle(Color.secondary)
                    
                    Text(prayerTimeString(prayer.value))
                        .bold()
                }
                .multilineTextAlignment(.center)
                .font(.system(.title2))
                .padding(.vertical, 10)
            }
        }.padding(.horizontal, 50)
    }
    
    private var prayerTimes: [Dictionary<String, Date>.Element] {
        var prayerTimesDates: [String : Date] = [:]
        
        for (prayer, time) in prayerTimesModel.prayerTimes {
            var dateComponents = DateComponents()
            
            if let hour = Int(time.dropLast(3)) {
                if (prayer == "Noon" && hour != 11) || prayer == "Sunset" || prayer == "Maghrib" || prayer == "Midnight" {
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
