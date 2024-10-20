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
    private let wbwTranslationBaseURL = "https://github.com/hablullah/data-quran/raw/master/word-translation/"
    
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
    
    func checkLocalTranslation(translatorId: Int, completion: @escaping () -> Void = {}) {
        errorMessage = nil
        let fileURL = getTranslationFileURL(for: translatorId)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            getLocalTranslation(translatorId: translatorId, completion: completion)
        } else {
            downloadTranslation(translatorId: translatorId, completion: completion)
        }
    }
    
    private func downloadTranslation(translatorId: Int, completion: @escaping () -> Void) {
        guard let translationUrl = URL(string: "\(translationBaseURL)\(translatorId)") else {
            errorMessage = "Unable to download translation"
            return
        }
        
        URLSession.shared.dataTask(with: translationUrl) { [weak self] data, _, error in
            if error != nil {
                self?.errorMessage = "Unable to download translation."
                return
            }
            
            guard let data = data else {
                self?.errorMessage = "Unable to download translation"
                return
            }
            
            self?.saveTranslation(data: data, translatorId: translatorId, completion: completion)
        }.resume()
    }
    
    private func saveTranslation(data: Data, translatorId: Int, completion: @escaping () -> Void) {
        do {
            let fileURL = getTranslationFileURL(for: translatorId)
            try data.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
            
            getLocalTranslation(translatorId: translatorId, completion: completion)
        } catch {
            errorMessage = "Unable to save translation."
        }
    }
    
    private func getLocalTranslation(translatorId: Int, completion: @escaping () -> ()) {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("translation\(translatorId).json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonData = try JSONDecoder().decode(RemoteTranslation.self, from: data)
            let translations = jsonData.translations
            
            var index = 0
            
            for (surahIndex, surah) in self.quran.enumerated() {
                for (verseIndex, _) in surah.verses.enumerated() {
                    let translatorId = translations[index].resource_id
                    let text = translations[index].text
                    
                    let newTranslation = Translation(id: translatorId, translation: text)
                    
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
    
    private func getTranslationFileURL(for translatorId: Int) -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("translation\(translatorId).json")
    }
    
    func checkLocalWBWTranslation(wbwTranslationId: String, completion: @escaping () -> Void = {}) {
        errorMessage = nil
        let fileURL = getWBWTranslationFileURL(for: wbwTranslationId)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            getLocalWBWTranslation(wbwTranslationId: wbwTranslationId, completion: completion)
        } else {
            downloadWBWTranslation(wbwTranslationId: wbwTranslationId, completion: completion)
        }
    }
    
    private func downloadWBWTranslation(wbwTranslationId: String, completion: @escaping () -> Void) {
        guard let wbwTranslationUrl = URL(string: "\(wbwTranslationBaseURL)\(wbwTranslationId)-qurancom.json") else {
            errorMessage = "Unable to download word by word translation."
            return
        }
        
        URLSession.shared.dataTask(with: wbwTranslationUrl) { [weak self] data, _, error in
            if error != nil {
                self?.errorMessage = "Unable to download word by word translation."
                return
            }
            
            guard let data = data else {
                self?.errorMessage = "Unable to download word by word translation."
                return
            }
            
            self?.saveWBWTranslation(data: data, wbwTranslationId: wbwTranslationId, completion: completion)
        }.resume()
    }
    
    private func saveWBWTranslation(data: Data, wbwTranslationId: String, completion: @escaping () -> Void) {
        do {
            let fileURL = getWBWTranslationFileURL(for: wbwTranslationId)
            try data.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
            
            getLocalWBWTranslation(wbwTranslationId: wbwTranslationId, completion: completion)
        } catch {
            errorMessage = "Unable to save word by word translation."
        }
    }
    
    private func getLocalWBWTranslation(wbwTranslationId: String, completion: @escaping () -> ()) {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("wbwTranslation\(wbwTranslationId).json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonData = try JSONDecoder().decode([String : String].self, from: data)
            let translations = Array(jsonData).sorted { $0.key < $1.key }
            
            var quran = self.quran
            var index = 0
            
            for (surahIndex, surah) in quran.enumerated() {
                for (verseIndex, verse) in surah.verses.enumerated() {
                    for (wordIndex, _) in verse.words.enumerated() {
                        let text = translations[index].value
                        
                        let newTranslation = WordTranslation(id: wbwTranslationId, translation: text)
                        
                        if let oldTranslationIndex = quran[surahIndex].verses[verseIndex].words[wordIndex].translations.firstIndex(where: { translation in
                            translation.id == newTranslation.id
                        }) {
                            quran[surahIndex].verses[verseIndex].words[wordIndex].translations.remove(at: oldTranslationIndex)
                        }
                        
                        quran[surahIndex].verses[verseIndex].words[wordIndex].translations.append(newTranslation)
                        
                        index += 1
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.quran = quran
            }
            
            DispatchQueue.main.async {
                completion()
            }
        } catch {
            self.errorMessage = "Unable to load word by word translation."
        }
    }
    
    private func getWBWTranslationFileURL(for wbwTranslationId: String) -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("wbwTranslation\(wbwTranslationId).json")
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
    @Published var versesContainingText: [String : Verse] = [:]
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.quranModel = QuranModel()
        
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
        DispatchQueue.main.async {
            self.versesContainingText = [:]
        }
        
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
            
            if let verse = surahToVerse(surah: surah) {
                DispatchQueue.main.async {
                    self.versesContainingText["\(surah.id):\(verse.id)"] = verse
                }
            }
            
            for verse in surah.verses {
                if verse.text.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                    DispatchQueue.main.async {
                        self.versesContainingText["\(surah.id):\(verse.id)"] = verse
                    }
                }
                
                if let translation = verse.translations.first(where: { translation in
                    translation.id == UserDefaults.standard.integer(forKey: "translatorId")
                }) {
                    if translation.translation.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                        DispatchQueue.main.async {
                            self.versesContainingText["\(surah.id):\(verse.id)"] = verse
                        }
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
    
    func surahToVerse(surah: Surah) -> Verse? {
        let surahToVerseRegex = "\\d+\\s*:\\s*\\d+"
        let surahToVersePredicate = NSPredicate(format: "SELF MATCHES %@", surahToVerseRegex)
        
        if surahToVersePredicate.evaluate(with: searchText) {
            let components = searchText.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            if let surahId = Int(components.first ?? ""), let verseId = Int(components.last ?? ""), surahId == surah.id && verseId <= surah.total_verses {
                if let verse = surah.verses.first(where: { verse in
                    verse.id == verseId
                }) {
                    return verse
                }
            }
        }
        
        return nil
    }
}

extension String {
    var lowercasedLettersAndNumbers: String {
        let lettersNumbersAndBracketsCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "[](){}"))
        let lowercasedLettersAndNumbers = String(unicodeScalars.filter(lettersNumbersAndBracketsCharacterSet.contains)).lowercased()
        
        return lowercasedLettersAndNumbers.removeTextInBrackets()
    }
    
    func removeTextInBrackets() -> String {
        let pattern = "\\[[^\\]]*\\]|\\([^\\)]*\\)|\\{[^\\}]*\\}"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return self }
        
        return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.count), withTemplate: "")
    }
}

extension Character {
    func isBracket() -> Bool {
        return "[](){}".contains(self)
    }
}
