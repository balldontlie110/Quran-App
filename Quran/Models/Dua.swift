//
//  Dua.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import Foundation

struct Dua: Identifiable, Decodable {
    let id: Int
    let title: String
    let subtitle: String?
    let verses: [DuaVerse]
    let audio: String
}

struct DuaVerse: Identifiable, Decodable {
    let id: Int
    
    let text: String
    let translation: String
    let transliteration: String
    let audio: Int
}
