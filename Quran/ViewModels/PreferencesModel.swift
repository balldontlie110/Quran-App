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
        
        do {
            let preferences = try self.moc.fetch(request)
            
            if let preferences = preferences.first {
                self.preferences = preferences
            } else {
                createPreferences()
            }
        } catch {
            print(error)
        }
    }
    
    private func createPreferences() {
        let preferences = Preferences(context: moc)
        preferences.fontSize = 40.0
        preferences.translationId = 131
        preferences.reciterName = "Ghamadi"
        preferences.reciterSubfolder = "Ghamadi_40kbps"
        
        do {
            try moc.save()
            
            self.preferences = preferences
        } catch {
            print(error)
        }
    }
    
    func updatePreferences(fontSize: Double, translatorId: Int, reciterName: String, reciterSubfolder: String) {
        if let preferences = self.preferences {
            moc.delete(preferences)
            
            let preferences = Preferences(context: moc)
            preferences.fontSize = fontSize
            preferences.translationId = Int64(translatorId)
            preferences.reciterName = reciterName
            preferences.reciterSubfolder = reciterSubfolder
            
            do {
                try moc.save()
                
                self.preferences = preferences
            } catch {
                print(error)
            }
        }
    }
}
