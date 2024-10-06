//
//  Ibadah.swift
//  Quran
//
//  Created by Ali Earp on 02/09/2024.
//

import Foundation

struct Ibadah: Identifiable, Equatable, Hashable {
    let id: Int
    
    let dua: Dua?
    let ziyarat: Ziyarat?
    let amaal: Amaal?
    
    static func ==(lhs: Ibadah, rhs: Ibadah) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
