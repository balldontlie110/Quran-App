//
//  WeeklyView.swift
//  Quran
//
//  Created by Ali Earp on 20/10/2024.
//

import SwiftUI
import Charts

struct WeeklyView: View {
    let weeks: FetchedResults<WeeklyTime>
    
    @State private var selectedWeek: Date?
    @State private var chartSelection: Date?
    
    var body: some View {
        VStack {
            Spacer()
            
            chart
            
            Spacer()
        }
        .overlay(alignment: .top) {
            weekPicker
        }
        .onAppear {
            self.selectedWeek = weeks.last?.date
        }
    }
    
    private var weekPicker: some View {
        HStack {
            if let selectedWeek = selectedWeek, let newWeek = weeks.last(where: { week in
                if let date = week.date {
                    return date < selectedWeek
                }
                
                return false
            })?.date {
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
                    Image(systemName: "chevron.left")
                }.disabled(true)
            }
            
            Spacer()
            
            weekText
            
            Spacer()
            
            if let selectedWeek = selectedWeek, let newWeek = weeks.first(where: { week in
                if let date = week.date {
                    return date > selectedWeek
                }
                
                return false
            })?.date {
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
        if let selectedWeek = selectedWeek, let endDate = Calendar.current.date(byAdding: .day, value: 6, to: selectedWeek) {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMMM"
            
            let start = formatter.string(from: selectedWeek)
            let end = formatter.string(from: endDate)
            
            return Text("\(start) - \(end)")
        }
        
        return Text("")
    }
    
    @ViewBuilder
    var chart: some View {
        if let selectedWeek = selectedWeek, let week = weeks.first(where: { weeklyTime in
            Calendar.current.isDate(weeklyTime.date ?? Date(), inSameDayAs: selectedWeek)
        }) {
            if let days = week.days?.allObjects as? [DailyTime], let endOfSelectedWeek = Calendar.current.date(byAdding: .day, value: 6, to: selectedWeek) {
                Text(totalTimeThisWeek(days: days))
                    .font(.system(.headline, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding()
                
                Chart {
                    ForEach(days) { day in
                        if let date = day.date {
                            let seconds = Int(day.seconds)
                            
                            BarMark(x: .value("Date", date), y: .value("Time", seconds))
                                .annotation(
                                    position: .top,
                                    overflowResolution: .init(x: .fit, y: .disabled)
                                ) {
                                    if chartSelection == date {
                                        Text(getTimeString(seconds))
                                            .font(.caption)
                                            .padding(5)
                                            .background(Color(.secondarySystemBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                    }
                                }
                        }
                    }
                }
                .chartXSelection(value: $chartSelection)
                .chartXScale(domain: selectedWeek...endOfSelectedWeek)
                .chartXAxis {
                    AxisMarks(preset: .aligned, position: .bottom, values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            VStack {
                                let (day, month) = dayAndMonthString(value)
                                
                                Text(day)
                                Text(month)
                            }.multilineTextAlignment(.center)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .aligned, position: .trailing) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            Text(formatValue(value))
                        }
                    }
                }
                .frame(height: 300)
                .padding([.horizontal, .bottom])
            }
        }
    }
    
    private func formatValue(_ value: AxisValue) -> String {
        if let seconds = value.as(Int.self) {
            if seconds < 60 {
                return "\(seconds)s"
            }
            
            if seconds < 3600 {
                let minutes = seconds / 60
                let seconds = seconds % 60
                
                if seconds == 0 {
                    return "\(minutes)m"
                } else {
                    return "\(minutes):\(seconds)s"
                }
            }
            
            let hours = seconds / 3600
            let minutes = seconds % 60
            
            if minutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours):\(minutes)m"
            }
        }
        
        return ""
    }
    
    private func dayAndMonthString(_ value: AxisValue) -> (day: String, month: String) {
        if let date = value.as(Date.self) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "d"
            
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            
            return (dayFormatter.string(from: date), monthFormatter.string(from: date))
        }
        
        return ("", "")
    }
    
    private func totalTimeThisWeek(days: [DailyTime]) -> String {
        let seconds = Int(days.map({ $0.seconds }).reduce(0, +))
        
        return getTimeString(seconds)
    }
    
    private func getTimeString(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        
        return formatter.string(from: TimeInterval(seconds)) ?? ""
    }
}

@available(iOS 18.0, *)
#Preview {
    @Previewable @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyTime.date, ascending: true)],
        animation: .default
    )
    
    var weeks: FetchedResults<WeeklyTime>
    
    WeeklyView(weeks: weeks)
}
