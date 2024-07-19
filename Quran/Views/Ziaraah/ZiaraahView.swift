//
//  ZiaraahView.swift
//  Quran
//
//  Created by Ali Earp on 19/07/2024.
//

import SwiftUI

struct ZiaraahView: View {
    @StateObject private var ziyaratModel: ZiyaratModel = ZiyaratModel()
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(ziyaratModel.ziaraah) { ziyarat in
                    NavigationLink {
                        ZiyaratView(ziyarat: ziyarat)
                    } label: {
                        HStack(spacing: 15) {
                            Text(String(ziyarat.id))
                                .bold()
                                .overlay {
                                    Image(systemName: "diamond")
                                        .font(.system(size: 40))
                                        .fontWeight(.ultraLight)
                                }
                                .frame(width: 40)
                            
                            Text(ziyarat.name)
                                .fontWeight(.heavy)
                            
                            Spacer()
                        }
                        .foregroundStyle(Color.primary)
                        .padding()
                        .frame(height: 75)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
            }.padding(.horizontal)
        }
        .navigationTitle("Ziaraah")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

#Preview {
    ZiaraahView()
}
