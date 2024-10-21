//
//  QuranWidgetBundle.swift
//  QuranWidget
//
//  Created by Ali Earp on 16/06/2024.
//

import WidgetKit
import SwiftUI
import Firebase

@main
struct QuranWidgetBundle: WidgetBundle {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Widget {
        PrayerTimesWidget()
        QuranTimeWidget()
    }
}
