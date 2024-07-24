//
//  QuranApp.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import SwiftUI
import FirebaseCore
import Stripe

@main
struct QuranApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        FirebaseApp.configure()
        
        StripeAPI.defaultPublishableKey = "pk_test_51Pe4tQ2MMIgwRw7skabvi1bZLAmJBVMG8T5PYugUmLp9giwIaY5IjfK8XfPVI1tUh98MSbcIt49Fh7mBp5HatF9I008DVb0UWm"
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .environmentObject(QuranModel())
                .environmentObject(CalendarModel())
                .environmentObject(EventsModel())
                .environmentObject(DuaModel())
                .environmentObject(ZiyaratModel())
                .environmentObject(AmaalModel())
                .environmentObject(AuthenticationModel())
                .environmentObject(PreferencesModel())
                .environmentObject(AudioPlayer())
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
                .onOpenURL { incomingURL in
                    StripeAPI.handleURLCallback(with: incomingURL)
                }
        }
    }
}
