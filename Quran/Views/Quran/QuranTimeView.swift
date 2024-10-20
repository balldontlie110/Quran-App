//
//  QuranTimeView.swift
//  Quran
//
//  Created by Ali Earp on 19/10/2024.
//

import SwiftUI
import Charts

struct QuranTimeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyTime.date, ascending: true)],
        animation: .default
    )
    
    private var weeks: FetchedResults<WeeklyTime>
    
    @State private var selectedWeek: Date?
    
    var body: some View {
        VStack {
            weekPicker
            
            Spacer()
            
            chart
            
            Spacer()
        }.onAppear {
            self.selectedWeek = weeks.last?.date
        }
    }
    
    @ViewBuilder
    private var chart: some View {
        if let selectedWeek = selectedWeek, let week = weeks.first(where: { weeklyTime in
            Calendar.current.isDate(weeklyTime.date ?? Date(), inSameDayAs: selectedWeek)
        }) {
            if let days = week.days?.allObjects as? [DailyTime], let endOfSelectedWeek = Calendar.current.date(byAdding: .day, value: 7, to: selectedWeek) {
                let maxValue = Int(days.map({ $0.seconds }).max() ?? 0)
                let unit = determineTimeUnit(maxValue: maxValue)
                
                Chart {
                    ForEach(days) { day in
                        if let date = day.date {
                            BarMark(x: .value("Date", date), y: .value("Minutes", Int(day.seconds)))
                        }
                    }
                }
                .chartXScale(domain: selectedWeek...endOfSelectedWeek)
                .chartXAxis {
                    AxisMarks(position: .bottom, values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            Text(dayAndMonthString(value: value))
                        }
                    }
                }
                .chartYScale(domain: 0...maxValue)
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            Text(formatValue(value, unit: unit))
                        }
                    }
                }
                .frame(height: 300)
                .padding(.horizontal)
                
                VStack {
                    Text("Total time this week:")
                        .foregroundStyle(Color.secondary)
                    
                    Text(totalTimeThisWeek(days: days))
                }
                .font(.system(.headline, weight: .bold))
                .multilineTextAlignment(.center)
                .padding()
            }
        }
    }
    
    private func determineTimeUnit(maxValue: Int) -> TimeUnit {
        if maxValue >= 3600 {
            return .hours
        } else if maxValue >= 60 {
            return .minutes
        } else {
            return .seconds
        }
    }
    
    private func formatValue(_ value: AxisValue, unit: TimeUnit) -> String {
        if let seconds = value.as(Int.self) {
            switch unit {
            case .hours:
                return "\(seconds / 3600)h"
            case .minutes:
                return "\(seconds / 60)m"
            case .seconds:
                return "\(seconds)s"
            }
        }
        
        return ""
    }
    
    private enum TimeUnit {
        case seconds
        case minutes
        case hours
    }
    
    private func dayAndMonthString(value: AxisValue) -> String {
        if let date = value.as(Date.self) {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            
            return formatter.string(from: date)
        }
        
        return ""
    }
    
    private func totalTimeThisWeek(days: [DailyTime]) -> String {
        let seconds = days.map( { $0.seconds } ).reduce(0, +)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        
        return formatter.string(from: TimeInterval(seconds)) ?? ""
    }
    
    private var weekPicker: some View {
        HStack {
            if let selectedWeek = selectedWeek, let newWeek = Calendar.current.date(byAdding: .day, value: -7, to: selectedWeek), let firstWeekDate = weeks.first?.date, firstWeekDate < selectedWeek {
                Button {
                    Task { @MainActor in
                        self.selectedWeek = newWeek
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
            } else {
                Button {
                    
                } label: {
                    Image(systemName: "chevron.right")
                }.disabled(true)
            }
            
            Spacer()
            
            weekText
            
            Spacer()
            
            if let selectedWeek = selectedWeek, let newWeek = Calendar.current.date(byAdding: .day, value: 7, to: selectedWeek), let firstWeekDate = weeks.first?.date, firstWeekDate < selectedWeek {
                Button {
                    Task { @MainActor in
                        self.selectedWeek = newWeek
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
            } else {
                Button {
                    
                } label: {
                    Image(systemName: "chevron.right")
                }.disabled(true)
            }
        }
        .bold()
        .padding([.horizontal, .top])
    }
    
    private var weekText: Text {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM"
        
        if let selectedWeek = selectedWeek, let endDate = Calendar.current.date(byAdding: .day, value: 6, to: selectedWeek) {
            let start = formatter.string(from: selectedWeek)
            let end = formatter.string(from: endDate)
            
            return Text("\(start) - \(end)")
        }
        
        return Text("")
    }
}

#Preview {
    QuranTimeView()
}
