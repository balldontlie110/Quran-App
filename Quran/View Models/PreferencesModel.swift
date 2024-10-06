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
        preferences.wordByWord = false
        
        try? moc.save()
        
        self.preferences = preferences
    }
    
    func updatePreferences(fontSize: Double? = nil, isDefaultFont: Bool? = nil, translatorId: Int? = nil, translationLanguage: String? = nil, reciterName: String? = nil, reciterSubfolder: String? = nil, wordByWord: Bool? = nil) {
        if let previousPreferences = self.preferences {
            let preferences = Preferences(context: moc)
            preferences.fontSize = fontSize ?? previousPreferences.fontSize
            preferences.isDefaultFont = isDefaultFont ?? previousPreferences.isDefaultFont
            preferences.translationId = Int64(translatorId ?? Int(previousPreferences.translationId))
            preferences.translationLanguage = translationLanguage ?? previousPreferences.translationLanguage
            preferences.reciterName = reciterName ?? previousPreferences.reciterName
            preferences.reciterSubfolder = reciterSubfolder ?? previousPreferences.reciterSubfolder
            preferences.wordByWord = wordByWord ?? previousPreferences.wordByWord
            
            moc.delete(previousPreferences)
            
            try? moc.save()
            
            self.preferences = preferences
        }
    }
}
