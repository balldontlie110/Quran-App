//
//  Amaal.swift
//  Quran
//
//  Created by Ali Earp on 20/07/2024.
//

import Foundation

struct Amaal: Identifiable, Decodable, Hashable, Equatable {
    let id: Int
    
    let title: String
    let subtitle: String?
    let description: String
    
    let sections: [AmaalSection]
    
    static func ==(lhs: Amaal, rhs: Amaal) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct AmaalSection: Identifiable, Decodable {
    let id: Int
    
    let description: String
    let details: [AmaalSectionDetail]
}

struct AmaalSectionDetail: Identifiable, Decodable {
    let id: String
    
    let heading: String?
    let surahId: Int?
    let url: String?
    let body: [AmaalSectionDetailBody]
}

struct AmaalSectionDetailBody: Identifiable, Decodable {
    let id: String
    
    let text: String?
    let transliteration: String?
    let translation: String?
}
