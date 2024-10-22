//
//  QuestionCard.swift
//  Quran
//
//  Created by Ali Earp on 03/07/2024.
//

import SwiftUI
import FirebaseFirestore

struct QuestionCard: View {
    let quran: [Surah]
    
    let question: Question
    let userProfiles: [UserProfile]

    let detailView: Bool
  
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Group {
                VStack(alignment: .leading, spacing: 10) {
                    Text(question.questionTitle)
                        .font(.system(.title3, weight: .bold))
                    
                    Text(question.question)
                }.multilineTextAlignment(.leading)
                
                if let surahId = question.surahId, let verseId = question.verseId {
                    VStack(spacing: 10) {
                        let verse = quran[surahId - 1].verses[verseId - 1]
                        
                        HStack {
                            Spacer()
                            
                            let verseText = getVerse(verse)
                            Text(verseText.text)
                                .lineSpacing(20)
                        }.multilineTextAlignment(.trailing)
                        
                        HStack(alignment: .top) {
                            Text("\(verse.id).")
                            
                            if let translation = verse.translations.first(where: { translation in
                                translation.id == UserDefaultsController.shared.integer(forKey: "translatorId")
                            }) {
                                Text(translation.translation)
                            }
                            
                            Spacer()
                        }.multilineTextAlignment(.leading)
                    }
                }
            }.foregroundStyle(Color.primary)
            
            HStack {
                Spacer()
                
                UserProfileSection(userProfiles: userProfiles, uid: question.questionuid, timestamp: question.timestamp)
            }
            
            let answersCount = question.answersCount > 0 ? String(question.answersCount) : "no"
            let plural = question.answersCount == 1 ? "" : "s"

            if !detailView {
                Text("This question has \(answersCount) answer\(plural).")
                    .foregroundStyle(Color.secondary)
                    .font(.system(.caption, weight: .semibold))
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
        .padding(.vertical, 5)
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
    QuestionCard(quran: [], question: Question(id: "", questionTitle: "", questionuid: "", question: "", timestamp: Timestamp(), surahId: 0, verseId: 0, answered: false, answersCount: 0), userProfiles: [], detailView: false)
}
