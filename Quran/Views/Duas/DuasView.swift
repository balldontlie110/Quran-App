//
//  DuasView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI

struct DuasView: View {
    @StateObject private var duaModel: DuaModel = DuaModel()
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(duaModel.duas) { dua in
                    NavigationLink {
                        DuaView(dua: dua)
                    } label: {
                        HStack(spacing: 15) {
                            Text(String(dua.id))
                                .bold()
                                .overlay {
                                    Image(systemName: "diamond")
                                        .font(.system(size: 40))
                                        .fontWeight(.ultraLight)
                                }
                                .frame(width: 40)
                            
                            VStack(alignment: .leading) {
                                Text(dua.type)
                                    .fontWeight(.heavy)
                                Text(dua.time)
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(Color.secondary)
                            }
                            
                            Spacer()
                        }
                        .foregroundStyle(Color.primary)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
            }.padding(.horizontal)
        }
        .navigationTitle("Du'as")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

#Preview {
    DuasView()
}
