//
//  QuranModel.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import Foundation
import Combine

class QuranModel: ObservableObject {
    @Published var quran: [Surah] = []
    @Published var translators: [Translator] = []
    @Published var reciters: [Reciter] = []
    @Published var errorMessage: String?
    
    private let quranFileName = "Quran.json"
    private let translatorsFileName = "Translators.json"
    private let recitersFileName = "Reciters.json"
    private let translationBaseURL = "https://api.quran.com/api/v4/quran/translations/"
    
    init() {
        loadQuran()
        loadTranslators()
        loadReciters()
    }
    
    private func loadQuran() {
        loadLocalData(fileName: quranFileName, type: [Surah].self) { [weak self] result in
            switch result {
            case .success(let surahs):
                self?.quran = surahs
            case .failure(let error):
                self?.errorMessage = "Failed to load Quran: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadTranslators() {
        loadLocalData(fileName: translatorsFileName, type: [Translator].self) { [weak self] result in
            switch result {
            case .success(let translators):
                self?.translators = translators.sorted { $0.language_name < $1.language_name }
            case .failure(let error):
                self?.errorMessage = "Failed to load translators: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadReciters() {
        loadLocalData(fileName: recitersFileName, type: [Reciter].self) { [weak self] result in
            switch result {
            case .success(let reciters):
                self?.reciters = reciters.sorted { $0.name < $1.name }
            case .failure(let error):
                self?.errorMessage = "Failed to load reciters: \(error.localizedDescription)"
            }
        }
    }
    
    func checkLocalTranslation(translationId: Int, completion: @escaping () -> Void = {}) {
        errorMessage = nil
        let fileURL = getTranslationFileURL(for: translationId)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            loadLocalTranslation(translationId: translationId, completion: completion)
        } else {
            downloadTranslation(translationId: translationId, completion: completion)
        }
    }
    
    private func downloadTranslation(translationId: Int, completion: @escaping () -> Void) {
        guard let translationUrl = URL(string: "\(translationBaseURL)\(translationId)") else {
            errorMessage = "Invalid translation URL."
            return
        }
        
        URLSession.shared.dataTask(with: translationUrl) { [weak self] data, _, error in
            if let error = error {
                self?.errorMessage = "Unable to download translation: \(error.localizedDescription)"
                return
            }
            
            guard let data = data else {
                self?.errorMessage = "No data received for translation."
                return
            }
            
            self?.saveTranslation(data: data, translationId: translationId, completion: completion)
        }.resume()
    }
    
    private func saveTranslation(data: Data, translationId: Int, completion: @escaping () -> Void) {
        do {
            let fileURL = getTranslationFileURL(for: translationId)
            try data.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
            loadLocalTranslation(translationId: translationId, completion: completion)
        } catch {
            errorMessage = "Unable to save translation: \(error.localizedDescription)"
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
    
    private func loadLocalTranslation(translationId: Int, completion: @escaping () -> Void) {
        let fileURL = getTranslationFileURL(for: translationId)
        
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonData = try JSONDecoder().decode(RemoteTranslation.self, from: data)
            updateQuran(with: jsonData.translations)
            DispatchQueue.main.async {
                completion()
            }
        } catch {
            errorMessage = "Unable to load translation: \(error.localizedDescription)"
        }
    }
    
    private func updateQuran(with translations: [TranslationVerse]) {
        var translationIndex = 0
        
        for surahIndex in quran.indices {
            for verseIndex in quran[surahIndex].verses.indices {
                let translationId = translations[translationIndex].resource_id
                let text = translations[translationIndex].text
                
                let translation = Translation(id: translationId, translation: text)
                
                if let existingTranslationIndex = quran[surahIndex].verses[verseIndex].translations.firstIndex(where: { $0.id == translation.id }) {
                    DispatchQueue.main.async {
                        self.quran[surahIndex].verses[verseIndex].translations.remove(at: existingTranslationIndex)
                    }
                }
                
                DispatchQueue.main.async {
                    self.quran[surahIndex].verses[verseIndex].translations.append(translation)
                }
                
                translationIndex += 1
            }
        }
    }
    
    private func getTranslationFileURL(for translationId: Int) -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("translation\(translationId).json")
    }
    
    private func loadLocalData<T: Decodable>(fileName: String, type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        if let path = Bundle.main.path(forResource: fileName, ofType: nil) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonData = try JSONDecoder().decode(type, from: data)
                completion(.success(jsonData))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

class QuranFilterModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var quranModel: QuranModel
    @Published var filteredQuran: [Surah] = []
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(quranModel: QuranModel) {
        self.quranModel = quranModel
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { [weak self] text in
                self?.setLoading(true)
                let result = self?.filterQuran(with: text) ?? []
                self?.setLoading(false)
                return result
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredQuran, on: self)
            .store(in: &cancellables)
    }

    private func filterQuran(with searchText: String) -> [Surah] {
        let cleanedSearchText = searchText.lowercasedLettersAndNumbers
        
        guard !cleanedSearchText.isEmpty else { return quranModel.quran }
        
        return quranModel.quran.filter { surah in
            if String(surah.id) == cleanedSearchText {
                return true
            }
            
            if surah.name.lowercasedLettersAndNumbers == cleanedSearchText {
                return true
            }
            
            if surah.transliteration.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                return true
            }
            
            if surah.translation.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                return true
            }
            
            if isSurahToVerse(surah: surah) {
                return true
            }
            
            for verse in surah.verses {
                if verse.text.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                    return true
                }
                
                for translation in verse.translations {
                    if translation.translation.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                        return true
                    }
                }
            }
            
            return false
        }
    }
    
    private func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
    
    func isSurahToVerse(surah: Surah) -> Bool {
        let surahToVerseRegex = "\\d+\\s*:\\s*\\d+"
        let surahToVersePredicate = NSPredicate(format: "SELF MATCHES %@", surahToVerseRegex)
        
        if surahToVersePredicate.evaluate(with: searchText) {
            let components = searchText.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            if let surahId = Int(components.first ?? ""), let verseId = Int(components.last ?? ""), surahId == surah.id && verseId <= surah.total_verses {
                return true
            }
        }
        
        return false
    }
}

extension String {
    var lowercasedLettersAndNumbers: String {
        return String(unicodeScalars.filter(CharacterSet.alphanumerics.contains)).lowercased()
    }
}
