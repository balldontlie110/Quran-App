//
//  AmaalModel.swift
//  Quran
//
//  Created by Ali Earp on 20/07/2024.
//

import Foundation

class AmaalModel: ObservableObject {
    @Published var amaals: [Amaal] = []
    
    init() {
        getAmaals()
    }
    
    private func getAmaals() {
        if let path = Bundle.main.path(forResource: "Amaals", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonData = try JSONDecoder().decode([Amaal].self, from: data)
                
                self.amaals = jsonData
            } catch {
                print("Failed to load amaals JSON from local file. \(error)")
            }
        }
    }
}
