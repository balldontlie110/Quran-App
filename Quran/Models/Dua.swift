//
//  Dua.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import Foundation

struct Dua: Identifiable, Decodable {
    let id: Int
    let type: String
    let time: String
    let verses: [DuaVerse]
}

struct DuaVerse: Identifiable, Decodable {
    let id: Int
    
    let arabic: String
    let translation: String
}
