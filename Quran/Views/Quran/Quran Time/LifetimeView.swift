//
//  LifetimeView.swift
//  Quran
//
//  Created by Ali Earp on 20/10/2024.
//

import SwiftUI
import Charts

struct LifetimeView: View {
    let weeks: FetchedResults<WeeklyTime>
    
    @State private var chartSelection: Date?
    
    var body: some View {
        VStack {
            lifetime
            
            chart
        }
    }
    
    @ViewBuilder
    private var chart: some View {
        if let minWeek = weeks.first?.date, let maxWeek = weeks.last?.date {
            let weekDifference = Calendar.current.dateComponents([.weekOfYear], from: minWeek, to: maxWeek)
            let calculatedMinWeek = weekDifference.weekOfYear == 0 ? Calendar.current.date(byAdding: .weekOfYear, value: -1, to: minWeek) ?? minWeek : minWeek
            
            Chart {
                ForEach(weeks) { week in
                    if let date = week.date, let days = week.days?.allObjects as? [DailyTime] {
                        let seconds = Int(days.map({ $0.seconds }).reduce(0, +))
                        
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
                        
                        LineMark(x: .value("Date", date), y: .value("Time", seconds))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.primary)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                }
            }
            .chartXSelection(value: $chartSelection)
            .chartXScale(domain: calculatedMinWeek...maxWeek)
            .chartXAxis {
                AxisMarks(preset: .aligned, position: .bottom, values: .stride(by: .weekOfYear)) { value in
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
    
    private var lifetime: some View {
        Text(getTimeString(totalTimeLifetime()))
            .font(.system(.headline, weight: .bold))
            .multilineTextAlignment(.center)
            .padding()
    }
    
    private func getTimeString(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        
        return formatter.string(from: TimeInterval(seconds)) ?? ""
    }
    
    private func totalTimeLifetime() -> Int {
        var days: [DailyTime] = []
        
        for week in weeks {
            if let weekDays = week.days?.allObjects as? [DailyTime] {
                days += weekDays
            }
        }
        
        let seconds = days.map({ $0.seconds }).reduce(0, +)
        
        return Int(seconds)
    }
}

@available(iOS 18.0, *)
#Preview {
    @Previewable @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyTime.date, ascending: true)],
        animation: .default
    )
    
    var weeks: FetchedResults<WeeklyTime>
    
    LifetimeView(weeks: weeks)
}
