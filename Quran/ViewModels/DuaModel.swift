//
//  DuaModel.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import Foundation

class DuaModel: ObservableObject {
    @Published var duas: [Dua] = []
    
    init() {
        getDuas()
    }
    
    private func getDuas() {
        if let path = Bundle.main.path(forResource: "Duas", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonData = try JSONDecoder().decode([Dua].self, from: data)
                
                self.duas = jsonData
            } catch {
                print("Failed to load duas JSON from local file.")
            }
        }
    }
}
