//
//  Quran.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import Foundation

struct Surah: Identifiable, Decodable {
    let id: Int
    let name: String
    let transliteration: String
    let translation: String
    let type: String
    let total_verses: Int
    let verses: [Ayat]
}

struct Ayat: Identifiable, Decodable, Equatable {
    let id: Int
    let text: String
    let translation: String
    let audio: String
    
    static func ==(lhs: Ayat, rhs: Ayat) -> Bool {
        return lhs.id == rhs.id
    }
}
