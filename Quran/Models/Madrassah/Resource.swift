//
//  Resource.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import Foundation
import FirebaseFirestore

struct Resource: Identifiable, Codable {
    @DocumentID var id: String?
    
    let resourceName: String
    let uploadedBy: String
    let downloadURL: String
    let timestamp: Timestamp
}
