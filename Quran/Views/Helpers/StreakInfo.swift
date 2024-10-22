//
//  StreakInfo.swift
//  Quran
//
//  Created by Ali Earp on 21/10/2024.
//

import SwiftUI

struct StreakInfo: View {
    let streak: Int
    let streakDate: Date
    
    let font: Font.TextStyle
    
    var body: some View {
        HStack {
            let readToday = Calendar.current.isDate(streakDate, inSameDayAs: Date())
            
            Image(systemName: "flame.fill")
                .font(.system(font))
                .foregroundStyle(readToday ? Color.streak : Color(.tertiarySystemBackground))
            
            Text(String(streak))
                .font(.system(font, design: .rounded, weight: .bold))
                .foregroundStyle(readToday ? Color.primary : Color(.tertiarySystemBackground))
        }
    }
}

#Preview {
    StreakInfo(streak: 0, streakDate: Date(), font: .body)
}
