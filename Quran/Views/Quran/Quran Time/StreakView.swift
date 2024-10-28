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
            
            Text("Set the amount of time you want to spend reading Quran every day. The daily goal cannot be changed once a streak has started.")
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
        ScrollViewReader { proxy in
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<firstOfMonth(), id: \.self) { _ in
                    Spacer()
                }
                
                ForEach(Array(groupedDays.indices), id: \.self) { groupIndex in
                    ForEach(Array(groupedDays[groupIndex].indices), id: \.self) { dayIndex in
                        let day = groupedDays[groupIndex][dayIndex]
                        let dayType = DayType(of: day)
                        
                        VStack(spacing: 5) {
                            Text("\(day.streak ? "\(dayIndex + 1)" : "-")")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundStyle(secondaryForegroundColor(for: dayType))
                            
                            Text(day.date.dayOfMonth())
                                .bold()
                                .foregroundStyle(foregroundColor(for: dayType))
                        }
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(backgroundColor(for: dayType))
                        .cornerRadius(10)
                        .onTapGesture {
                            self.selectedDate = day.date
                        }
                        .id(day.date)
                    }
                }
            }
            .padding(5)
            .scrollTargetLayout()
            .onAppear {
                proxy.scrollTo(Calendar.current.startOfDay(for: Date()))
            }
        }
    }
    
    private enum DayType {
        case today, streak, none
        
        init(of day: StreakCalendarDay) {
            if Calendar.current.isDate(day.date, inSameDayAs: Date()) {
                self = .today
            } else if day.streak {
                self = .streak
            } else {
                self = .none
            }
        }
    }
    
    private func backgroundColor(for dayType: DayType) -> Color {
        if dayType == .today {
            return Color.accentColor
        }
        
        if dayType == .streak {
            return Color.streak
        }
        
        return Color(.secondarySystemBackground)
    }
    
    private func foregroundColor(for dayType: DayType) -> Color {
        if dayType == .today {
            return Color.white
        }
        
        if dayType == .streak {
            return Color.black
        }
        
        return Color.primary
    }
    
    private func secondaryForegroundColor(for dayType: DayType) -> Color {
        if dayType == .today {
            return Color.white
        }
        
        if dayType == .streak {
            return Color.black
        }
        
        return Color.secondary
    }
    
    private var groupedDays: [[StreakCalendarDay]] {
        let days = weeks.compactMap({ $0.days?.sortedAllObjects() }).flatMap({ $0 })
        
        if let firstDay = days.first {
            var filledInDays = [StreakCalendarDay(dailyTime: firstDay)]
            
            for index in 1..<days.count {
                if let date = days[index - 1].date, var fillerDate = Calendar.current.date(byAdding: .day, value: 1, to: date), let nextDate = days[index].date {
                    
                    while fillerDate < nextDate {
                        let streakCalendarDay = StreakCalendarDay(date: fillerDate)
                        filledInDays.append(streakCalendarDay)
                        
                        if let followingDate = Calendar.current.date(byAdding: .day, value: 1, to: fillerDate) {
                            fillerDate = followingDate
                        }
                    }
                    
                    let streakCalendarDay = StreakCalendarDay(dailyTime: days[index])
                    filledInDays.append(streakCalendarDay)
                }
            }
            
            var groupedDays: [[StreakCalendarDay]] = []
            var currentGroup: [StreakCalendarDay] = []
            
            for day in filledInDays {
                if let lastDay = currentGroup.last {
                    if day.streak == lastDay.streak {
                        currentGroup.append(day)
                    } else {
                        groupedDays.append(currentGroup)
                        currentGroup = [day]
                    }
                } else {
                    currentGroup.append(day)
                }
            }
            
            if !currentGroup.isEmpty {
                groupedDays.append(currentGroup)
            }
            
            return groupedDays
        }
        
        return []
    }
    
    private func firstOfMonth() -> Int {
        if let first = groupedDays.first?.first?.date {
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
}

struct StreakCalendarDay: Identifiable {
    var id: Date { date }
    
    let date: Date
    let seconds: Int
    
    var streak: Bool {
        let dailyQuranGoal = UserDefaultsController.shared.integer(forKey: "dailyQuranGoal")
        
        return seconds >= (dailyQuranGoal * 60)
    }
    
    init(dailyTime: DailyTime) {
        self.date = dailyTime.date ?? Date()
        self.seconds = Int(dailyTime.seconds)
    }
    
    init(date: Date) {
        self.date = date
        self.seconds = 0
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
