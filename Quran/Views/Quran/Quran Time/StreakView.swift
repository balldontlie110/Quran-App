//
//  StreakView.swift
//  Quran
//
//  Created by Ali Earp on 21/10/2024.
//

import SwiftUI

struct StreakView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @AppStorage("streak") private var streak: Int = 0
    @AppStorage("streakDate") private var streakDate: Double = 0.0
    @AppStorage("dailyQuranGoal") private var dailyQuranGoal: Int = 0
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyTime.date, ascending: true)],
        animation: .default
    )
    
    private var weeks: FetchedResults<WeeklyTime>
    
    private let columns: [GridItem] = [GridItem](repeating: GridItem(.flexible()), count: 7)
    
    @State private var selectedDate: Date?
    
    var body: some View {
        VStack(spacing: 0) {
            streakInfo
            
            Divider()
            
            VStack(spacing: 0) {
                dailyQuranGoalPicker
                
                Divider()
                
                LazyVGrid(columns: columns, spacing: 20) {
                    weekdayHeaders
                }
                .padding(.horizontal, 5)
                .padding(.vertical)
                
                Divider()
                
                ScrollView {
                    calendar
                }
            }.background(Color(.systemBackground))
        }
        .background(Calendar.current.isDate(Date(timeIntervalSince1970: streakDate), inSameDayAs: Date()) ? Color.streak : Color(.systemBackground))
        .onTapGesture {
            hideKeyboard()
        }
        .navigationDestination(item: $selectedDate) { selectedDate in
            let weekDate = weeks.first(where: { week in
                if let weekDate = week.date, let startOfSelectedWeek = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: selectedDate).date {
                    
                    return weekDate == startOfSelectedWeek
                }
                
                return false
            })?.date
            
            WeeklyView(weeks: weeks, selectedWeek: weekDate, selectedDate: selectedDate)
        }
    }
    
    @ViewBuilder
    private var streakInfo: some View {
        HStack(alignment: .bottom, spacing: 25) {
            let readToday = Calendar.current.isDate(Date(timeIntervalSince1970: streakDate), inSameDayAs: Date())
            
            Image(systemName: "flame.fill")
                .resizable()
                .scaledToFit()
                .offset(y: 15)
                .frame(height: 150)
                .clipped()
                .foregroundStyle(readToday ? Color.streak : colorScheme == .dark ? Color(.tertiarySystemBackground) : Color.secondary)
                .brightness(readToday ? -0.25 : 0)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(totalTimeTodayString)
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.leading)
                
                Text("\(streak) day\(streak == 1 ? "" : "s")")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(readToday ? Color.primary : colorScheme == .dark ? Color(.tertiarySystemBackground) : Color.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)
            }
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var totalTimeTodayString: String {
        let days = weeks.compactMap({ $0.days?.sortedAllObjects() }).flatMap({ $0 })
        
        if let lastDay = days.first(where: {
            if let date = $0.date {
                return Calendar.current.isDate(date, inSameDayAs: Date())
            }
            
            return false
        }) {
            return "\(getTimeString(Int(lastDay.seconds))) today"
        }
        
        return "0 seconds today"
    }
    
    private func getTimeString(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        
        return formatter.string(from: TimeInterval(seconds)) ?? ""
    }
    
    private var dailyQuranGoalPicker: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Daily Goal")
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(Color.secondary)
                
                Spacer()
                
                TextField("", text: binding())
                    .bold()
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .disabled(streak > 0)
                
                Text("minutes")
                    .bold()
                    .foregroundStyle(Color.secondary)
            }
            
            Text("The daily goal cannot be changed once a streak has started.")
                .foregroundStyle(Color.secondary)
                .font(.caption)
                .multilineTextAlignment(.leading)
        }.padding()
    }
    
    private func binding() -> Binding<String> {
        return Binding(
            get: {
                String(dailyQuranGoal)
            },
            set: { newValue in
                if let minutes = Int(newValue) {
                    dailyQuranGoal = minutes
                }
            }
        )
    }
    
    private var calendar: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(0..<firstOfMonth(), id: \.self) { _ in
                Spacer()
            }
            
            ForEach(days) { day in
                VStack(spacing: 5) {
                    if let date = day.date {
                        if let islamicDay = islamicDay(date: date) {
                            Text(String(islamicDay))
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundStyle(day.seconds >= (dailyQuranGoal * 60) ? Color(.systemBackground) : Color.secondary)
                        }
                        
                        Text(date.dayOfMonth())
                            .bold()
                            .foregroundStyle(day.seconds >= (dailyQuranGoal * 60) ? colorScheme == .dark ? Color(.tertiarySystemBackground) : Color.secondary : Color.primary)
                    }
                }
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .background(day.seconds >= (dailyQuranGoal * 60) ? Color.streak : Color(.secondarySystemBackground))
                .cornerRadius(10)
                .onTapGesture {
                    self.selectedDate = day.date
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.top)
    }
    
    private var days: [DailyTime] {
        let days = weeks.compactMap({ $0.days?.sortedAllObjects() }).flatMap({ $0 })
        
        if let lastDay = days.last, let lastDate = lastDay.date, let interval = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day, interval <= 1 {
            
            var consecutiveDays: [DailyTime] = [lastDay]
            
            for index in (1..<days.count).reversed() {
                let currentDay = days[index]
                let previousDay = days[index - 1]
                if let currentDate = currentDay.date, let previousDate = previousDay.date {
                    if let interval = Calendar.current.dateComponents([.day], from: previousDate, to: currentDate).day, interval <= 1 {
                        consecutiveDays.append(previousDay)
                    }
                }
            }
            
            return consecutiveDays.sorted(by: { $0.date ?? Date() < $1.date ?? Date() })
        }
        
        return []
    }
    
    private func firstOfMonth() -> Int {
        if let first = days.first?.date {
            return Calendar.current.component(.weekday, from: first) - 1
        }
        
        return 0
    }
    
    private var weekdayHeaders: some View {
        ForEach(Calendar.current.shortWeekdaySymbols) { weekday in
            Text(weekday.uppercased())
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(Color.secondary)
        }
    }
    
    private func islamicDay(date: Date) -> Int? {
        let components = Calendar.current.dateComponents([.day, .month, .year], from: date)
        
        guard let day = components.day, let month = components.month, let year = components.year else {
            return nil
        }
        
        let julianDay: Int
        if year > 1582 || (year == 1582 && month > 10) || (year == 1582 && month == 10 && day > 14) {
            julianDay = intPart((1461 * (year + 4800 + intPart((month - 14) / 12))) / 4) + intPart((367 * (month - 2 - 12 * intPart((month - 14) / 12))) / 12) - intPart((3 * (intPart((year + 4900 + intPart((month - 14) / 12)) / 100))) / 4) + day - 32075
        } else {
            julianDay = 367 * year - intPart((7 * (year + 5001 + intPart((month - 9) / 7))) / 4) + intPart((275 * month) / 9) + day + 1729777
        }
        
        var daysSinceEpoch = julianDay - 1948440 + 10632
        let cycles = intPart((daysSinceEpoch - 1) / 10631)
        daysSinceEpoch = daysSinceEpoch - 10631 * cycles + 354
        let adjustedYear = (intPart((10985 - daysSinceEpoch) / 5316)) * (intPart((50 * daysSinceEpoch) / 17719)) + (intPart(daysSinceEpoch / 5670)) * (intPart((43 * daysSinceEpoch) / 15238))
        daysSinceEpoch = daysSinceEpoch - (intPart((30 - adjustedYear) / 15)) * (intPart((17719 * adjustedYear) / 50)) - (intPart(adjustedYear / 16)) * (intPart((15238 * adjustedYear) / 43)) + 29
        let islamicMonth = intPart((24 * daysSinceEpoch) / 709)
        let islamicDay = daysSinceEpoch - intPart((709 * islamicMonth) / 24)
        
        return islamicDay
    }
    
    private func intPart(_ value: Int) -> Int {
        return Int(floor(Double(value)))
    }
}

extension Date: @retroactive Identifiable {
    public var id: UUID {
        UUID()
    }
}

#Preview {
    StreakView()
}
