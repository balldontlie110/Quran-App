//
//  CalendarView.swift
//  Quran
//
//  Created by Ali Earp on 20/07/2024.
//

import SwiftUI
import iCalendarParser

struct CalendarView: View {
    @EnvironmentObject private var calendarModel: CalendarModel
    @EnvironmentObject private var eventsModel: EventsModel
    
    private let columns: [GridItem] = [GridItem](repeating: GridItem(.flexible()), count: 7)
    
    private let prayerTimesColumns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]
    private let prayers = ["Imsaak", "Dawn", "Sunrise", "Noon", "Sunset", "Maghrib", "Midnight"]
    private let prayersRenamed = ["Dawn" : "Fajr", "Sunrise" : "Sunrise", "Noon" : "Zuhr", "Sunset" : "Sunset", "Maghrib" : "Maghrib", "Midnight" : "Midnight"]
    
    private let islamicMonths = ["Muharram", "Safar", "Rabi Al Awwal", "Rabi Al Thaani", "Jamaada Al Ula", "Jamaada Al Thani", "Rajab", "Shabaan", "Ramadan", "Shawwal", "Dhu Al Qadah", "Dhu Al Hijjah"]
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    datePicker
                    calendar
                    
                    todayButton
                    
                    importantDates
                    todaysEvents
                    
                    dateSection
                    prayerTimes
                    
                    Spacer()
                }.padding(.horizontal, 5)
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var datePicker: some View {
        HStack {
            Button {
                if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: calendarModel.currentMonth) {
                    Task { @MainActor in
                        calendarModel.currentMonth = newMonth
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
            }
            
            Spacer()
            
            Text(monthYearText)
            
            Spacer()
            
            Button {
                if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: calendarModel.currentMonth) {
                    Task { @MainActor in
                        calendarModel.currentMonth = newMonth
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .bold()
        .padding()
    }
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        return formatter.string(from: calendarModel.currentMonth)
    }
    
    private var calendar: some View {
        LazyVGrid(columns: columns) {
            ForEach(Calendar.current.shortWeekdaySymbols) { weekday in
                Text(weekday.uppercased())
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(Color.secondary)
            }
            
            ForEach(0..<firstOfMonth, id: \.self) { _ in
                Spacer()
            }
            
            ForEach(datesInMonth.sorted { $0.key < $1.key }, id: \.key) { date in
                CalendarDay(
                    date: date.key,
                    isSelected: Calendar.current.isDate(date.key, inSameDayAs: calendarModel.selectedDate),
                    islamicDate: String(date.value.day)
                ) {
                    calendarModel.selectedDate = date.key
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 25)
                .onEnded { value in
                    if value.translation.width > 0 {
                        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: calendarModel.currentMonth) {
                            Task { @MainActor in
                                calendarModel.currentMonth = newMonth
                            }
                        }
                    }
                    
                    if value.translation.width < 0 {
                        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: calendarModel.currentMonth) {
                            Task { @MainActor in
                                calendarModel.currentMonth = newMonth
                            }
                        }
                    }
                }
        )
    }
    
    private var firstOfMonth: Int {
        if let interval = Calendar.current.dateInterval(of: .month, for: calendarModel.currentMonth) {
            return Calendar.current.component(.weekday, from: interval.start) - 1
        }
        
        return 0
    }
    
    private var datesInMonth: [Date : (day: Int, month: Int)] {
        var dates: [Date : (Int, Int)] = [:]
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: calendarModel.currentMonth)
        let month = calendar.component(.month, from: calendarModel.currentMonth)
        
        var components = DateComponents(year: year, month: month, day: 1)
        
        guard let startDate = calendar.date(from: components), let range = calendar.range(of: .day, in: .month, for: startDate) else {
            return dates
        }
        
        for day in range {
            components.day = day
            
            if let date = calendar.date(from: components), let islamicDate = islamicDate(date: date) {
                dates[date] = (islamicDate.day, islamicDate.month)
            }
        }
        
        return dates
    }
    
    private var importantDates: some View {
        LazyVStack(spacing: 10) {
            if importantDatesInMonth.count > 0 {
                let months = Set(currentIslamicMonths).joined(separator: "/")
                
                Text("Important Dates This Month (\(months))")
                    .font(.system(.title3, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            
            ForEach(importantDatesInMonth.sorted { $0.value < $1.value }, id: \.key.id) { (importantDate, date) in
                HStack {
                    VStack(alignment: .leading) {
                        Text(importantDate.title)
                            .font(.system(.subheadline, weight: .bold))
                        
                        Spacer()
                        
                        if let subtitle = importantDate.subtitle {
                            Text(subtitle)
                                .font(.caption)
                        }
                    }.multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        HStack(spacing: 5) {
                            Text(String(importantDate.date))
                            
                            if importantDate.month <= 12 {
                                Text(islamicMonths[importantDate.month - 1])
                            }
                            
                            if let year = importantDate.year, let yearType = importantDate.yearType {
                                Text("\(year) \(yearType)")
                            }
                        }
                        
                        Spacer()
                        
                        Text(gregorianDateMedium(date: date))
                    }
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.trailing)
                }
                .padding(7.5)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, importantDatesInMonth.count > 0 ? 20 : 0)
    }
    
    private var importantDatesInMonth: [ImportantDate : Date] {
        let dates = calendarModel.importantDates.compactMap { importantDate in
            for date in datesInMonth {
                if importantDate.month == date.value.month && importantDate.date == date.value.day {
                    return date.key
                }
            }
            
            return nil
        }
        
        let importantDates = calendarModel.importantDates.filter { importantDate in
            for date in datesInMonth {
                if importantDate.month == date.value.month && importantDate.date == date.value.day {
                    return true
                }
            }
            
            return false
        }
        
        return Dictionary(uniqueKeysWithValues: zip(importantDates, dates))
    }
    
    private var currentIslamicMonths: [String] {
        return importantDatesInMonth.compactMap { (importantDate, _) in
            if importantDate.month <= 12 {
                return islamicMonths[importantDate.month - 1]
            }
            
            return nil
        }
    }
    
    private var todayButton: some View {
        Button {
            calendarModel.selectedDate = Date()
            calendarModel.currentMonth = Date()
        } label: {
            Text("Today")
        }
        .buttonStyle(BorderedButtonStyle())
        .padding(.vertical)
    }
    
    private var dateSection: some View {
        VStack(spacing: 10) {
            Text(gregorianDateFull(date: calendarModel.selectedDate))
                .foregroundStyle(Color.secondary)
                .font(.system(.subheadline, weight: .bold))
            
            HStack {
                Text(islamicDateText)
            }.font(.system(.title2, weight: .bold))
        }
    }
    
    private func gregorianDateFull(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        return formatter.string(from: date)
    }
    
    private func gregorianDateMedium(date: Date) -> String {
        let day = date.day()
        let dayOfMonth = date.dayOfMonth()
        let month = date.month()
        
        return "\(day) \(dayOfMonth) \(month)"
    }
    
    private var todaysEvents: some View {
        VStack(spacing: 10) {
            if events.count > 0 {
                Text("Events On \(gregorianDateMedium(date: calendarModel.selectedDate))")
                    .font(.system(.title3, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            
            LazyVStack(spacing: 20) {
                ForEach(events) { event in
                    NavigationLink {
                        EventView(event: event)
                    } label: {
                        EventCard(event: event)
                    }
                }
            }
        }
        .padding(.horizontal, -5)
        .padding(.horizontal)
        .padding(.bottom, events.count > 0 ? 20 : 0)
    }
    
    private var events: [ICEvent] {
        return eventsModel.events.filter { event in
            if let start = event.dtStart?.date, let end = event.dtEnd?.date {
                let dateInterval = DateInterval(start: Calendar.current.startOfDay(for: start), end: Calendar.current.startOfDay(for: end))
                
                return dateInterval.contains(Calendar.current.startOfDay(for: calendarModel.selectedDate))
            }
            
            return false
        }
    }
    
    private var islamicDateText: String {
        if let (day, month, year) = islamicDate(date: calendarModel.selectedDate) {
            if month <= 12 {
                return "\(day) \(islamicMonths[month - 1]) \(String(year))"
            }
        }
        
        return ""
    }
    
    private func islamicDate(date: Date) -> (day: Int, month: Int, year: Int)? {
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
        let islamicYear = 30 * cycles + adjustedYear - 30
        
        return (islamicDay, islamicMonth, islamicYear)
    }
    
    private func intPart(_ value: Int) -> Int {
        return Int(floor(Double(value)))
    }
    
    private var prayerTimes: some View {
        Group {
            if let prayerTimes = calendarModel.getPrayerTimes(for: calendarModel.selectedDate) {
                LazyVGrid(columns: prayerTimesColumns) {
                    Group {
                        PrayerTimeRow(prayer: "Imsaak", time: prayerTimes.imsaak)
                        PrayerTimeRow(prayer: "Fajr", time: prayerTimes.dawn)
                        PrayerTimeRow(prayer: "Sunrise", time: prayerTimes.sunrise)
                        PrayerTimeRow(prayer: "Zuhr", time: prayerTimes.noon)
                        PrayerTimeRow(prayer: "Sunset", time: prayerTimes.sunset)
                        PrayerTimeRow(prayer: "Maghrib", time: prayerTimes.maghrib)
                        PrayerTimeRow(prayer: "Midnight", time: prayerTimes.midnight)
                    }.padding(.vertical, 7.5)
                }
                .multilineTextAlignment(.center)
                .font(.system(.title2))
                .padding(.horizontal, 50)
            }
        }
    }
}

struct CalendarDay: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var date: Date
    var isSelected: Bool
    var islamicDate: String
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 5) {
            Text(islamicDate)
                .font(.caption2)
                .foregroundStyle(colorScheme == .dark ? Color.secondary : Color.gray)
            
            Text("\(Calendar.current.component(.day, from: date))")
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(isSelected ? 1 : isToday() ? 0.2 : 0))
        .cornerRadius(10)
        .onTapGesture {
            action()
        }
    }
    
    private func isToday() -> Bool {
        return Calendar.current.isDateInToday(date)
    }
}

struct PrayerTimeRow: View {
    let prayer: String
    let time: String
    
    var body: some View {
        Text(prayer)
            .foregroundStyle(Color.secondary)
        
        Text(time)
            .bold()
    }
}

#Preview {
    CalendarView()
}
