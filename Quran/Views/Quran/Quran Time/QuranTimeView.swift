//
//  QuranTimeView.swift
//  Quran
//
//  Created by Ali Earp on 19/10/2024.
//

import SwiftUI
import Charts

struct QuranTimeView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyTime.date, ascending: true)],
        animation: .default
    )
    
    private var weeks: FetchedResults<WeeklyTime>
    
    @State private var weekly: Bool = true
    
    var body: some View {
        VStack {
            if weekly {
                WeeklyView(weeks: weeks)
            } else {
                LifetimeView(weeks: weeks)
            }
        }.toolbar {
            timeframePicker
        }
    }
    
    @ViewBuilder
    private var timeframePicker: some View {
        if weeks.count > 0 {
            Picker("", selection: $weekly) {
                Text("Weekly")
                    .tag(true)
                
                Text("Lifetime")
                    .tag(false)
            }.pickerStyle(.menu)
        }
    }
}

#Preview {
    QuranTimeView()
}
