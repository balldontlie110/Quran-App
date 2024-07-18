//
//  QuranApp.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import SwiftUI
import FirebaseCore

@main
struct QuranApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .environmentObject(QuranModel())
                .environmentObject(PreferencesModel())
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
    }
}
