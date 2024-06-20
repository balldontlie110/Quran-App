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
    private let prayersRenamed = ["Dawn" : "Fajr", "Sunrise" : "Sunrise", "Noon" : "Zuhr", "Sunset" : "Sunset", "Maghrib" : "Maghrib", "Midnight" : "Isha"]
    
    private let columns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if prayerTimes.count != 0 {
                        Divider()
                        
                        HStack(spacing: 0) {
                            Divider()
                            
                            VStack(spacing: 0) {
                                ForEach(prayerTimes, id: \.key) { prayer in
                                    LazyVGrid(columns: columns) {
                                        Text(prayersRenamed[prayer.key] ?? prayer.key)
                                            .font(.system(.title2, weight: .bold))
                                        
                                        Text(prayer.value)
                                            .font(.system(.title2))
                                            .foregroundStyle(Color.secondary)
                                    }.padding(.vertical)
                                    
                                    if prayerTimes.last ?? ("", "") != prayer {
                                        Divider()
                                    }
                                }
                            }
                            
                            Divider()
                        }
                        
                        Divider()
                    }
                }.padding()
            }
            .navigationTitle("Salat Times")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var prayerTimes: [Dictionary<String, String>.Element] {
        prayerTimesModel.prayerTimes.sorted {
            prayers.firstIndex(of: $0.key) ?? 0 < prayers.firstIndex(of: $1.key) ?? 0
        }
    }
}

#Preview {
    PrayerTimesView()
}
