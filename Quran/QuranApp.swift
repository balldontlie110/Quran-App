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
        
        initialiseUserDefaults()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .environmentObject(QuranModel())
                .environmentObject(QuranFilterModel())
                .environmentObject(CalendarModel())
                .environmentObject(EventsModel())
                .environmentObject(DuaModel())
                .environmentObject(ZiyaratModel())
                .environmentObject(AmaalModel())
                .environmentObject(MadrassahModel())
                .environmentObject(PrayerTimesModel())
                .environmentObject(AuthenticationModel())
                .environmentObject(AudioPlayer())
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
                .onOpenURL { incomingURL in
                    StripeAPI.handleURLCallback(with: incomingURL)
                }
        }
    }
    
    private func initialiseUserDefaults() {
        if !UserDefaults.standard.bool(forKey: "initialisedUserDefaults") {
            UserDefaults.standard.setValue("{\"Fajr\": false, \"Sunrise\": false, \"Zuhr\": false, \"Sunset\": false, \"Maghrib\": false}", forKey: "prayerNotifications")
            UserDefaults.standard.setValue(40.0, forKey: "fontSize")
            UserDefaults.standard.setValue(1, forKey: "fontNumber")
            UserDefaults.standard.setValue(131, forKey: "translatorId")
            UserDefaults.standard.setValue("en", forKey: "translationLanguage")
            UserDefaults.standard.setValue("Alafasy", forKey: "reciterName")
            UserDefaults.standard.setValue("Alafasy_128kbps", forKey: "reciterSubfolder")
            UserDefaults.standard.setValue(false, forKey: "continuePlaying")
            UserDefaults.standard.setValue(false, forKey: "wordByWord")
            UserDefaults.standard.setValue(true, forKey: "initialisedUserDefaults")
            UserDefaults.standard.synchronize()
        }
    }
}
