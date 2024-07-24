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
        }
        
        container.loadPersistentStores { _, _ in
            
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
