//
//  QuranModel.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import Foundation

class QuranModel: ObservableObject {
    @Published var quran: [Surah] = []
    @Published var translators: [Translator] = []
    @Published var reciters: [Reciter] = []
    
    @Published var errorMessage: String?
    
    init() {
        getQuran()
        getTranslators()
        getReciters()
    }
    
    private func getQuran() {
        if let path = Bundle.main.path(forResource: "Quran", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonData = try JSONDecoder().decode([Surah].self, from: data)
                
                self.quran = jsonData
            } catch {
                print("Failed to load Quran JSON from local file. \(error)")
            }
        }
    }
    
    func getSurah(_ surahId: Int) -> Surah? {
        if let path = Bundle.main.path(forResource: "Quran", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonData = try JSONDecoder().decode([Surah].self, from: data)
                
                return jsonData.first { $0.id == surahId }
            } catch {
                print("Failed to load Quran JSON from local file. \(error)")
            }
        }
        
        return nil
    }
    
    private func getTranslators() {
        if let path = Bundle.main.path(forResource: "Translators", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonData = try JSONDecoder().decode([Translator].self, from: data)
                
                self.translators = jsonData.sorted { translator1, translator2 in
                    translator1.language_name < translator2.language_name
                }
            } catch {
                print("Failed to load translators JSON from local file. \(error)")
            }
        }
    }
    
    private func getReciters() {
        if let path = Bundle.main.path(forResource: "Reciters", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonData = try JSONDecoder().decode([Reciter].self, from: data)
                
                self.reciters = jsonData.sorted { reciter1, reciter2 in
                    reciter1.name < reciter2.name
                }
            } catch {
                print("Failed to load reciters JSON from local file. \(error)")
            }
        }
    }
    
    func checkLocalTranslation(translationId: Int, completion: @escaping () -> () = {}) {
        self.errorMessage = nil
        
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("translation\(translationId).json")
        
        if FileManager.default.fileExists(atPath: fileURL.path()) {
            getLocalTranslation(translationId: translationId, completion: completion)
        } else {
            downloadTranslation(translationId: translationId, completion: completion)
        }
    }
    
    private func downloadTranslation(translationId: Int, completion: @escaping () -> ()) {
        if let translationUrl = URL(string: "https://api.quran.com/api/v4/quran/translations/\(translationId)") {
            URLSession.shared.dataTask(with: translationUrl) { data, response, error in
                if error != nil {
                    self.errorMessage = "Unable to download translation."
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "Unable to download translation."
                    return
                }
                
                self.saveTranslation(data: data, translationId: translationId, completion: completion)
            }.resume()
        } else {
            self.errorMessage = "Unable to find translation."
        }
    }
    
    private func saveTranslation(data: Data, translationId: Int, completion: @escaping () -> ()) {
        do {
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("translation\(translationId).json")
            
            try data.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
            
            getLocalTranslation(translationId: translationId, completion: completion)
        } catch {
            self.errorMessage = "Unable to save translation."
        }
    }
    
    private func getLocalTranslation(translationId: Int, completion: @escaping () -> ()) {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("translation\(translationId).json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonData = try JSONDecoder().decode(RemoteTranslation.self, from: data)
            let translations = jsonData.translations
            
            var index = 0
            
            for (surahIndex, surah) in self.quran.enumerated() {
                for (verseIndex, _) in surah.verses.enumerated() {
                    let translationId = translations[index].resource_id
                    let text = translations[index].text
                    
                    let newTranslation = Translation(id: translationId, translation: text)
                    
                    if let oldTranslationIndex = self.quran[surahIndex].verses[verseIndex].translations.firstIndex(where: { translation in
                        translation.id == newTranslation.id
                    }) {
                        DispatchQueue.main.async {
                            self.quran[surahIndex].verses[verseIndex].translations.remove(at: oldTranslationIndex)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.quran[surahIndex].verses[verseIndex].translations.append(newTranslation)
                    }
                    
                    index += 1
                }
            }
            
            DispatchQueue.main.async {
                completion()
            }
        } catch {
            self.errorMessage = "Unable to load translation."
        }
    }
}
