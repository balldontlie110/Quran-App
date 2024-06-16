//
//  RootView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Quran", systemImage: "book") {
                QuranView()
            }
            
            Tab("Du'as", systemImage: "book.closed") {
                DuasView()
            }
            
            Tab("Times", systemImage: "calendar") {
                PrayerTimesView()
            }
        }
    }
}

#Preview {
    RootView()
}
