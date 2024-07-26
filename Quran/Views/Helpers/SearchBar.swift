//
//  SearchBar.swift
//  Quran
//
//  Created by Ali Earp on 25/07/2024.
//

import SwiftUI

struct SearchBar: View {
    let placeholder: String
    
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            magnifyingGlassSymbol
            
            textField
            
            clearTextButton
        }
        .padding(5)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
    
    private var magnifyingGlassSymbol: some View {
        Image(systemName: "magnifyingglass")
            .foregroundStyle(Color.secondary)
    }
    
    private var textField: some View {
        TextField(placeholder, text: $searchText)
    }
    
    @ViewBuilder
    private var clearTextButton: some View {
        if searchText != "" {
            Button {
                searchText = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview {
    SearchBar(placeholder: "", searchText: .constant(""))
}
