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
                .defaultAppStorage(UserDefaultsController.shared)
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
        if !UserDefaultsController.shared.bool(forKey: "initialisedUserDefaults") {
            UserDefaultsController.shared.setValue("{\"Fajr\": false, \"Sunrise\": false, \"Zuhr\": false, \"Sunset\": false, \"Maghrib\": false}", forKey: "prayerNotifications")
            UserDefaultsController.shared.setValue(40.0, forKey: "fontSize")
            UserDefaultsController.shared.setValue(1, forKey: "fontNumber")
            UserDefaultsController.shared.setValue(131, forKey: "translatorId")
            UserDefaultsController.shared.setValue("en", forKey: "translationLanguage")
            UserDefaultsController.shared.setValue("Alafasy", forKey: "reciterName")
            UserDefaultsController.shared.setValue("Alafasy_128kbps", forKey: "reciterSubfolder")
            UserDefaultsController.shared.setValue(false, forKey: "continuePlaying")
            UserDefaultsController.shared.setValue(false, forKey: "wordByWord")
            UserDefaultsController.shared.setValue(0, forKey: "streak")
            UserDefaultsController.shared.setValue(nil, forKey: "streakDate")
            UserDefaultsController.shared.setValue(15, forKey: "dailyQuranGoal")
            UserDefaultsController.shared.setValue(nil, forKey: "streakWidgetUpdate")
            UserDefaultsController.shared.setValue(true, forKey: "initialisedUserDefaults")
            UserDefaultsController.shared.synchronize()
        }
    }
}
