//
//  QuranModel.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import Foundation

class QuranModel: ObservableObject {
    @Published var quran: [Surah] = []
    
    init() {
        getQuran()
    }
    
    private func getQuran() {
        if let path = Bundle.main.path(forResource: "Quran", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonData = try JSONDecoder().decode([Surah].self, from: data)
                
                self.quran = jsonData
            } catch {
                print("Failed to load Quran JSON from local file.")
            }
        }
    }
}
