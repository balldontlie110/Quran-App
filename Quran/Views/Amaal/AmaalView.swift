//
//  AmaalView.swift
//  Quran
//
//  Created by Ali Earp on 20/07/2024.
//

import SwiftUI

struct AmaalView: View {
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
                                    ForEach(detail.body) { verse in
                                        AmaalSectionDetailBodyVerse(verse: verse, lastId: detail.body.last?.id)
                                    }
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

struct AmaalSectionDetailBodyVerse: View {
    @EnvironmentObject private var preferencesModel: PreferencesModel
    
    let verse: AmaalSectionDetailBody
    let lastId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 15) {
                Text(verse.text)
                    .font(.system(size: CGFloat(preferencesModel.preferences?.fontSize ?? 40.0), weight: .bold))
                    .lineSpacing(20)
                
                if let transliteration = verse.transliteration {
                    Text(transliteration)
                        .font(.system(size: 20))
                }
                
                Text(verse.translation)
                    .font(.system(size: 20))
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
