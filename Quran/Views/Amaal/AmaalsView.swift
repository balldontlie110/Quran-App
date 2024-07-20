//
//  AmaalsView.swift
//  Quran
//
//  Created by Ali Earp on 20/07/2024.
//

import SwiftUI

struct AmaalsView: View {
    @StateObject private var amaalModel: AmaalModel = AmaalModel()
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(amaalModel.amaals) { amaal in
                    NavigationLink {
                        AmaalView(amaal: amaal)
                    } label: {
                        HStack(spacing: 15) {
                            Text(String(amaal.id))
                                .bold()
                                .overlay {
                                    Image(systemName: "diamond")
                                        .font(.system(size: 40))
                                        .fontWeight(.ultraLight)
                                }
                                .frame(width: 40)
                            
                            VStack(alignment: .leading) {
                                Text(amaal.title)
                                    .fontWeight(.heavy)
                                
                                if let subtitle = amaal.subtitle {
                                    Text(subtitle)
                                        .font(.system(.subheadline, weight: .semibold))
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            
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
        .navigationTitle("Amaals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

#Preview {
    AmaalsView()
}
