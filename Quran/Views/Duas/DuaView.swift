//
//  DuaView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI

struct DuaView: View {
    let dua: Dua
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(dua.verses) { verse in
                    Text(verse.arabic)
                        .font(.system(size: 40, weight: .bold))
                        .lineSpacing(10)
                    
                    Text(verse.translation)
                        .font(.system(size: 20))
                    
                    if verse.id != dua.verses.count {
                        Divider()
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.vertical, 5)
            }.padding(.horizontal)
        }
        .navigationTitle(dua.type)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    var duaModel: DuaModel = DuaModel()
    
    if let dua = duaModel.duas.first {
        DuaView(dua: dua)
    }
}
