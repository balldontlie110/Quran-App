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
    var verses: [Verse]
}

struct Verse: Identifiable, Decodable, Equatable {
    let id: Int
    let text: String
    var translations: [Translation]
    var words: [Word]
    let audio: String
    
    static func ==(lhs: Verse, rhs: Verse) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Translation: Identifiable, Decodable {
    let id: Int
    let translation: String
}

struct Word: Identifiable, Decodable {
    let id: String
    let text: String
    let translation: String
}

struct RemoteTranslation: Decodable {
    let translations: [TranslationVerse]
}

struct TranslationVerse: Decodable {
    let resource_id: Int
    let text: String
}
