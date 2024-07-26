//
//  BookmarkedVerseCard.swift
//  Quran
//
//  Created by Ali Earp on 05/07/2024.
//

import SwiftUI
import CoreData

struct BookmarkedVerseCard: View {
    @StateObject var quranModel: QuranModel

    let verse: BookmarkedVerse
    
    let removeVerse: (BookmarkedVerse) -> Void

    var body: some View {
        NavigationLink {
            if let surah = quranModel.quran.first(where: { $0.id == Int(verse.surahId) }) {
                SurahView(surah: surah, initialScroll: Int(verse.verseId))
            }
        } label: {
            HStack(alignment: .top, spacing: 15) {
                verseInformation
                
                Spacer()
                
                verseDetails
            }
        }
    }
    
    private var verseInformation: some View {
        VStack(alignment: .leading) {
            verseTitle
            
            Spacer()
            
            verseNumber
        }.multilineTextAlignment(.leading)
    }
    
    private var verseTitle: some View {
        Text(verse.title ?? "")
            .fontWeight(.heavy)
    }
    
    private var verseNumber: some View {
        Text("\(verse.surahName ?? ""): Verse \(verse.verseId)")
            .font(.system(.subheadline, weight: .semibold))
            .foregroundStyle(Color.secondary)
    }
    
    private var verseDetails: some View {
        VStack(alignment: .trailing) {
            verseDate
            
            Spacer()
            
            deleteButton
        }.multilineTextAlignment(.trailing)
    }
    
    private var verseDate: some View {
        Text(getDateString(verse.date))
            .font(.system(.subheadline, weight: .semibold))
            .foregroundStyle(Color.secondary)
    }
    
    private var deleteButton: some View {
        Button {
            removeVerse(verse)
        } label: {
            Image(systemName: "trash")
                .foregroundStyle(Color.red)
        }
    }
    
    private func getDateString(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date ?? Date())
    }
}

@available(iOS 18.0, *)
#Preview {
    @Previewable @Environment(\.managedObjectContext) var viewContext
    
    BookmarkedVerseCard(quranModel: QuranModel(), verse: BookmarkedVerse(context: viewContext)) { _ in
        
    }
}
