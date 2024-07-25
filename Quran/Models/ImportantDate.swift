//
//  ImportantDate.swift
//  Quran
//
//  Created by Ali Earp on 24/07/2024.
//

import Foundation

struct ImportantMonth: Identifiable, Decodable {
    let id: Int
    
    let monthName: String
    let importantDates: [ImportantDate]
}

struct ImportantDate: Identifiable, Decodable, Hashable {
    let id: String
    
    let month: Int
    let title: String
    let subtitle: String?
    let year: Int?
    let yearType: String?
    let date: Int
    
    func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
}
