//
//  AmaalModel.swift
//  Quran
//
//  Created by Ali Earp on 20/07/2024.
//

import Foundation

class AmaalModel: ObservableObject {
    @Published var amaals: [Ibadah] = []
    
    init() {
        getAmaals()
    }
    
    private func getAmaals() {
        if let path = Bundle.main.path(forResource: "Amaals", ofType: "json") {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
               let jsonData = try? JSONDecoder().decode([Amaal].self, from: data) {
                
                self.amaals = jsonData.map { amaal in
                    Ibadah(id: amaal.id, dua: nil, ziyarat: nil, amaal: amaal)
                }
            }
        }
    }
}
