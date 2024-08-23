//
//  PreferencesModel.swift
//  Quran
//
//  Created by Ali Earp on 07/07/2024.
//

import Foundation
import CoreData

class PreferencesModel: ObservableObject {
    @Published var preferences: Preferences?
    
    let moc: NSManagedObjectContext
    
    init() {
        self.moc = PersistenceController.shared.container.viewContext
        
        fetchPreferences()
    }
    
    private func fetchPreferences() {
        let request = Preferences.fetchRequest()
        
        if let preferences = try? self.moc.fetch(request) {
            if let preferences = preferences.first {
                self.preferences = preferences
            } else {
                createPreferences()
            }
        }
    }
    
    private func createPreferences() {
        let preferences = Preferences(context: moc)
        preferences.fontSize = 40.0
        preferences.isDefaultFont = true
        preferences.translationId = 131
        preferences.translationLanguage = "en"
        preferences.reciterName = "Ghamadi"
        preferences.reciterSubfolder = "Ghamadi_40kbps"
        
        try? moc.save()
        
        self.preferences = preferences
    }
    
    func updatePreferences(fontSize: Double, isDefaultFont: Bool, translatorId: Int, translationLanguage: String, reciterName: String, reciterSubfolder: String) {
        if let preferences = self.preferences {
            moc.delete(preferences)
            
            let preferences = Preferences(context: moc)
            preferences.fontSize = fontSize
            preferences.isDefaultFont = isDefaultFont
            preferences.translationId = Int64(translatorId)
            preferences.translationLanguage = translationLanguage
            preferences.reciterName = reciterName
            preferences.reciterSubfolder = reciterSubfolder
            
            try? moc.save()
            
            self.preferences = preferences
        }
    }
}
