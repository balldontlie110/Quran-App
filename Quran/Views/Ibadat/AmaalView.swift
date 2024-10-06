//
//  AmaalView.swift
//  Quran
//
//  Created by Ali Earp on 20/07/2024.
//

import SwiftUI

struct AmaalView: View {
    @EnvironmentObject private var quranModel: QuranModel
    
    let amaal: Amaal
    
    @State private var revealedBodies: [String] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                description
                
                LazyVStack(spacing: 35) {
                    ForEach(amaal.sections) { section in
                        LazyVStack(spacing: 10) {
                            Text(section.description)
                                .font(.system(.headline, weight: .bold))
                            
                            ForEach(section.details) { detail in
                                AmaalSectionDetailHeading(revealedBodies: $revealedBodies, detail: detail)
                                
                                if detail.heading == nil || revealedBodies.contains(detail.id) {
                                    if let surahId = detail.surahId, let surah = quranModel.quran.first(where: { surah in
                                        surah.id == surahId
                                    }) {
                                        ForEach(surah.verses) { verse in
                                            SurahVerse(verse: verse, lastId: surah.total_verses)
                                        }
                                    } else {
                                        ForEach(detail.body) { verse in
                                            AmaalSectionDetailBodyVerse(verse: verse, lastId: detail.body.last?.id)
                                        }
                                    }
                                }
                                
                                if let urlString = detail.url, let url = URL(string: urlString) {
                                    Link("Salaam e Akhir by Asad Jahan", destination: url)
                                }
                            }
                        }
                    }
                }.padding(.horizontal)
            }
            .multilineTextAlignment(.center)
        }
        .navigationTitle(amaal.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var description: some View {
        Group {
            Text(amaal.description)
                .font(.system(.headline, weight: .bold))
                .padding(.horizontal)
            
            Divider()
                .padding(.vertical, 10)
        }
    }
}

struct AmaalSectionDetailHeading: View {
    @Binding var revealedBodies: [String]
    
    let detail: AmaalSectionDetail
    
    var body: some View {
        VStack {
            if let heading = detail.heading {
                HStack {
                    Text(heading)
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(Color.secondary)
                    
                    Button {
                        if revealedBodies.contains(detail.id) {
                            revealedBodies.remove(detail.id)
                        } else {
                            revealedBodies.append(detail.id)
                        }
                    } label: {
                        Image(systemName: revealedBodies.contains(detail.id) ? "chevron.up" : "chevron.down")
                            .bold()
                    }
                }
            }
        }
    }
}

struct SurahVerse: View {
    @EnvironmentObject private var preferencesModel: PreferencesModel
    
    let verse: Verse
    let lastId: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 15) {
                if let isDefaultFont = preferencesModel.preferences?.isDefaultFont {
                    let defaultFont = Font.system(size: CGFloat(preferencesModel.preferences?.fontSize ?? 40.0), weight: .bold)
                    let uthmanicFont = Font.custom("KFGQPC Uthmanic Script HAFS Regular", size: CGFloat(preferencesModel.preferences?.fontSize ?? 40.0))
                    
                    let font = isDefaultFont ? defaultFont : uthmanicFont
                    
                    Text(verse.text)
                        .font(font)
                        .lineSpacing(20)
                        .multilineTextAlignment(.center)
                }
                
                if let translation = verse.translations.first(where: { translation in
                    translation.id == Int(preferencesModel.preferences?.translationId ?? 131)
                }) {
                    Text(translation.translation)
                        .font(.system(size: 20))
                }
            }.padding(.vertical)
            
            if verse.id != lastId {
                Divider()
            }
        }
    }
}

struct AmaalSectionDetailBodyVerse: View {
    @EnvironmentObject private var preferencesModel: PreferencesModel
    
    let verse: AmaalSectionDetailBody
    let lastId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 15) {
                if let text = verse.text {
                    if let isDefaultFont = preferencesModel.preferences?.isDefaultFont {
                        let defaultFont = Font.system(size: CGFloat(preferencesModel.preferences?.fontSize ?? 40.0), weight: .bold)
                        let uthmanicFont = Font.custom("KFGQPC Uthmanic Script HAFS Regular", size: CGFloat(preferencesModel.preferences?.fontSize ?? 40.0))
                        
                        let font = isDefaultFont ? defaultFont : uthmanicFont
                        
                        Text(text)
                            .font(font)
                            .lineSpacing(20)
                            .multilineTextAlignment(.center)
                    }
                }
                
                if let transliteration = verse.transliteration {
                    Text(transliteration)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.secondary)
                }
                
                if let translation = verse.translation {
                    Text(translation)
                        .font(.system(size: 20))
                }
            }.padding(.vertical)
            
            if verse.id != lastId {
                Divider()
            }
        }
    }
}

#Preview {
    AmaalView(amaal: Amaal(id: 0, title: "", subtitle: nil, description: "", sections: []))
}
