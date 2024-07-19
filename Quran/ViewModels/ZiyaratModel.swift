//
//  ZiyaratModel.swift
//  Quran
//
//  Created by Ali Earp on 19/07/2024.
//

import Foundation

class ZiyaratModel: ObservableObject {
    @Published var ziaraah: [Ziyarat] = []
    
    init() {
        getZiaraah()
    }
    
    private func getZiaraah() {
        if let path = Bundle.main.path(forResource: "Ziaraah", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonData = try JSONDecoder().decode([Ziyarat].self, from: data)
                
                self.ziaraah = jsonData
            } catch {
                print("Failed to load ziaraah JSON from local file.")
            }
        }
    }
}
