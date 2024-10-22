//
//  Persistence.swift
//  Quran
//
//  Created by Ali Earp on 16/06/2024.
//

import UIKit
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "QuranApp")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.Ali.Quran") {
                let storeURL = appGroupURL.appendingPathComponent("QuranApp.sqlite")
                
                container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
            } else {
                fatalError("Unable to find App Group container URL. Ensure that the App Group is correctly configured.")
            }
        }
        
        container.loadPersistentStores { description, error in
            
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension NSSet {
    func sortedAllObjects() -> [DailyTime]? {
        return (self.allObjects as? [DailyTime])?.sorted(by: { $0.date ?? Date() < $1.date ?? Date() })
    }
}
