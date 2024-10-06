//
//  Madrassah.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import Foundation
import FirebaseFirestore

struct Class: Identifiable, Codable {
    @DocumentID var id: String?
    
    let year: Int
    let gender: String
    
    let teacherIds: [String]
    let studentIds: [String]
    
    var section: String { year >= 7 ? "Seniors" : year >= 3 ? "Juniors" : "Infants" }
}

struct Member: Identifiable, Codable {
    @DocumentID var id: String?
    
    let user: String
    let gender: String
    let year: Int?
    
    let isTeacher: Bool
    
    let classIds: [String]?
}
