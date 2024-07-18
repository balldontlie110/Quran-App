//
//  Translator.swift
//  Quran
//
//  Created by Ali Earp on 07/07/2024.
//

import Foundation

struct Translator: Identifiable, Decodable, Equatable {
    let id: Int
    let name: String
    let author_name: String
    let slug: String?
    let language_name: String
    
    static func ==(lhs: Translator, rhs: Translator) -> Bool {
        return lhs.id == rhs.id
    }
}
