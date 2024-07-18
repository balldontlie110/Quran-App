//
//  Reciter.swift
//  Quran
//
//  Created by Ali Earp on 13/07/2024.
//

import Foundation

struct Reciter: Identifiable, Decodable, Equatable {
    var id: String { subfolder }
    
    let name: String
    let subfolder: String
    
    static func ==(lhs: Reciter, rhs: Reciter) -> Bool {
        return lhs.id == rhs.id
    }
}
