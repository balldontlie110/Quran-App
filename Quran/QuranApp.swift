//
//  QuranApp.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import SwiftUI

@main
struct QuranApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
