//
//  Quran.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import Foundation

struct Surah: Identifiable, Decodable, Hashable {
    let id: Int
    let name: String
    let transliteration: String
    let translation: String
    let type: String
    let total_verses: Int
    var verses: [Verse]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Verse: Identifiable, Decodable, Equatable, Hashable {
    let id: Int
    let text: String
    var translations: [Translation]
    var words: [Word]
    let audio: String
    
    static func ==(lhs: Verse, rhs: Verse) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Translation: Identifiable, Decodable {
    let id: Int
    let translation: String
}

struct Word: Identifiable, Decodable, Equatable {
    let id: String
    let text: String
    var translations: [WordTranslation]
    
    static func ==(lhs: Word, rhs: Word) -> Bool {
        return lhs.id == rhs.id
    }
}

struct WordTranslation: Identifiable, Decodable {
    let id: String
    let translation: String
}

struct RemoteTranslation: Decodable {
    let translations: [TranslationVerse]
}

struct TranslationVerse: Decodable {
    let resource_id: Int
    let text: String
}
