//
//  NewQuestionView.swift
//  Quran
//
//  Created by Ali Earp on 01/07/2024.
//

import SwiftUI
import FirebaseAuth

struct NewQuestionView: View {
    @EnvironmentObject private var quranModel: QuranModel
    
    @StateObject var questionsModel: QuestionsModel
    
    @State private var questionTitle: String = ""
    @State private var question: String = ""
    
    var questionTitleFocused: FocusState<Bool>.Binding
    
    @State private var specificVerse: Bool = false
    
    @State private var surahId: Int = 1
    @State private var verseId: Int = 1
    
    var body: some View {
        LazyVStack(spacing: 0) {
            LazyVStack {
                TextField("Title", text: $questionTitle, axis: .vertical)
                    .fontWeight(.bold)
                    .padding(10)
                    .background(Color.primary.colorInvert())
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .focused(questionTitleFocused)
                
                TextField("Question", text: $question, axis: .vertical)
                    .padding(.trailing, 30)
                    .overlay(alignment: .bottomTrailing) {
                        Button {
                            newQuestion()
                        } label: {
                            Image(systemName: "paperplane.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(10)
                    .background(Color.primary.colorInvert())
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                
                Spacer()
                    .frame(height: 25)
                
                Toggle("Specific Verse", isOn: $specificVerse)
                    .foregroundStyle(Auth.auth().currentUser == nil ? Color.secondary : Color.primary)
                
                if specificVerse {
                    HStack {
                        Picker("Surah", selection: $surahId) {
                            ForEach(quranModel.quran) { surah in
                                Text("\(surah.id). \(surah.transliteration)")
                                    .tag(surah.id)
                            }
                        }
                        
                        Spacer()
                        
                        Picker("Verse", selection: $verseId) {
                            ForEach(quranModel.quran[surahId - 1].verses) { verse in
                                Text("Verse \(verse.id)")
                                    .tag(verse.id)
                            }
                        }
                    }
                    
                    VStack(spacing: 10) {
                        let verse = quranModel.quran[surahId - 1].verses[verseId - 1]
                        
                        HStack {
                            Spacer()
                            
                            let verseText = getVerse(verse)
                            Text(verseText.text)
                                .lineSpacing(20)
                        }.multilineTextAlignment(.trailing)
                        
                        HStack(alignment: .top) {
                            Text("\(verse.id).")
                            
                            if let translation = verse.translations.first(where: { translation in
                                translation.id == UserDefaults.standard.integer(forKey: "translatorId")
                            }) {
                                Text(translation.translation)
                            }
                            
                            Spacer()
                        }.multilineTextAlignment(.leading)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding()
            .disabled(Auth.auth().currentUser == nil)
            
            if Auth.auth().currentUser == nil {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                    Text("You need to be signed in to ask a question.")
                }
                .font(.caption)
                .foregroundStyle(Color.red)
            }
        }
    }
    
    private func newQuestion() {
        if questionTitle != "" && question != "" {
            questionsModel.newQuestion(
                questionTitle: questionTitle,
                question: question,
                surahId: specificVerse ? surahId : nil,
                verseId: specificVerse ? verseId : nil
            )
            
            hideKeyboard()
            
            self.question = ""
            self.questionTitle = ""
            self.specificVerse = false
            self.surahId = 1
            self.verseId = 1
        }
    }
    
    private func getVerse(_ verse: Verse) -> Verse {
        return Verse(id: verse.id, text: verse.text + " " + getArabicNumber(verse.id), translations: [], words: [], audio: "")
    }
    
    private func getArabicNumber(_ number: Int) -> String {
        let arabicNumerals = "٠١٢٣٤٥٦٧٨٩"
        var arabicString = ""
        
        for char in String(number) {
            if let digit = Int(String(char)) {
                let index = arabicNumerals.index(arabicNumerals.startIndex, offsetBy: digit)
                arabicString.append(arabicNumerals[index])
            }
        }
        
        return "(" + arabicString + ")"
    }
}

#Preview {
    @FocusState var questionTitleFocused: Bool
    
    NewQuestionView(questionsModel: QuestionsModel(), questionTitleFocused: $questionTitleFocused)
}
