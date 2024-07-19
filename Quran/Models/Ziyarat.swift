//
//  Ziyarat.swift
//  Quran
//
//  Created by Ali Earp on 19/07/2024.
//

import Foundation

struct Ziyarat: Identifiable, Decodable {
    let id: Int
    
    let name: String
    let verses: [ZiyaratVerse]
}

struct ZiyaratVerse: Identifiable, Decodable, Hashable {
    let id: Int
    
    let text: String
    let translation: String
    let transliteration: String
    let gap: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
