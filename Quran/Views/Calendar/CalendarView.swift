//
//  CalendarView.swift
//  Quran
//
//  Created by Ali Earp on 20/07/2024.
//

import SwiftUI
import iCalendarParser

struct CalendarView: View {
    @ObservedObject private var calendarModel: CalendarModel = CalendarModel()
    @EnvironmentObject private var eventsModel: EventsModel
    
    @State private var showImportantDates: Bool = false
    
    private let columns: [GridItem] = [GridItem](repeating: GridItem(.flexible()), count: 7)
    
    private let prayerTimesColumns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]
    private let prayers = ["Imsaak", "Dawn", "Sunrise", "Noon", "Sunset", "Maghrib", "Midnight"]
    private let prayersRenamed = ["Dawn" : "Fajr", "Sunrise" : "Sunrise", "Noon" : "Zuhr", "Sunset" : "Sunset", "Maghrib" : "Maghrib", "Midnight" : "Midnight"]
    
    private let islamicMonths = ["Muharram", "Safar", "Rabi Al Awwal", "Rabi Al Thaani", "Jamaada Al Ula", "Jamaada Al Thani", "Rajab", "Shabaan", "Ramadhan", "Shawwal", "Dhu Al Qadah", "Dhu Al Hijjah"]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                datePicker
                calendar
                
                todayButton
                
                dateSection
                
                selectedDateEvents
                importantDates
                
                prayerTimes
            }.padding(.horizontal, 5)
        }
        .scrollIndicators(.hidden)
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
            
            monthYearText
            
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
        .padding([.horizontal, .top])
    }
    
    private var monthYearText: Text {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        return Text(formatter.string(from: calendarModel.currentMonth))
    }
    
    private var calendar: some View {
        LazyVGrid(columns: columns) {
            weekdayHeaders
            
            ForEach(0..<firstOfMonth, id: \.self) { _ in
                Spacer()
            }
            
            calendarDays
        }
        .contentShape(Rectangle())
        .gesture(swipeMonthGesture)
    }
    
    private var weekdayHeaders: some View {
        ForEach(Calendar.current.shortWeekdaySymbols) { weekday in
            Text(weekday.uppercased())
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(Color.secondary)
        }
    }
    
    private var calendarDays: some View {
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
    
    private var swipeMonthGesture: some Gesture {
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
    
    private var todayButton: some View {
        Button {
            calendarModel.selectedDate = Date()
            calendarModel.currentMonth = Date()
        } label: {
            Text("Today")
        }.buttonStyle(BorderedButtonStyle())
    }
    
    @ViewBuilder
    private var importantDates: some View {
        if !importantDatesInMonth.isEmpty {
            LazyVStack(spacing: 10) {
                importantDatesHeader
                
                if showImportantDates {
                    ForEach(importantDatesInMonth.sorted { $0.value < $1.value }, id: \.key.id) { (importantDate, date) in
                        ImportantDateCard(importantDate: importantDate, date: date)
                    }
                }
            }.padding(.horizontal, 10)
        }
    }
    
    @ViewBuilder
    private var importantDatesHeader: some View {
        if importantDatesInMonth.count > 0 {
            HStack {
                VStack(alignment: .leading) {
                    Text("Important Dates This Month")
                        .font(.system(.title3, weight: .bold))
                    
                    Text("(\(currentIslamicMonths))")
                        .bold()
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        showImportantDates.toggle()
                    }
                } label: {
                    Image(systemName: showImportantDates ? "chevron.up" : "chevron.down")
                        .bold()
                }
            }
        }
    }
    
    private var currentIslamicMonths: String {
        let currentIslamicMonths = importantDatesInMonth.compactMap { (importantDate, _) in
            if importantDate.month <= 12 {
                return islamicMonths[importantDate.month - 1]
            }
            
            return nil
        }
        
        let months = Set(currentIslamicMonths).sorted { month1, month2 in
            islamicMonths.firstIndex(of: month1) ?? 0 < islamicMonths.firstIndex(of: month2) ?? 0
        }
        
        return months.joined(separator: "/")
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
    
    @ViewBuilder
    private var selectedDateEvents: some View {
        if !events.isEmpty {
            VStack(spacing: 10) {
                selectedDateEventsHeader
                
                LazyVStack(spacing: 20) {
                    ForEach(events) { event in
                        NavigationLink {
                            EventView(event: event)
                        } label: {
                            EventCard(event: event)
                        }
                    }
                }
            }.padding(.horizontal, 10)
        }
    }
    
    @ViewBuilder
    private var selectedDateEventsHeader: some View {
        if events.count > 0 {
            selectedDateGregorianText
                .multilineTextAlignment(.center)
        }
    }
    
    private var selectedDateGregorianText: Text {
        let day = calendarModel.selectedDate.day()
        let dayOfMonth = calendarModel.selectedDate.dayOfMonth()
        let month = calendarModel.selectedDate.month()
        
        return Text("Events on \(day) \(dayOfMonth) \(month)")
            .font(.system(.title3, weight: .bold))
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
    
    private var dateSection: some View {
        VStack {
            gregorianDateText
            
            islamicDateText
        }
    }
    
    private var gregorianDateText: Text {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        return Text(formatter.string(from: calendarModel.selectedDate))
            .foregroundStyle(Color.secondary)
            .font(.system(.subheadline, weight: .bold))
    }
    
    private var islamicDateText: Text {
        if let (day, month, year) = islamicDate(date: calendarModel.selectedDate), month <= 12 {
            return Text("\(day) \(islamicMonths[month - 1]) \(String(year))")
                .font(.system(.title2, weight: .bold))
        }
        
        return Text("")
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
    
    @ViewBuilder
    private var prayerTimes: some View {
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

struct ImportantDateCard: View {
    let importantDate: ImportantDate
    let date: Date
    
    private let islamicMonths = ["Muharram", "Safar", "Rabi Al Awwal", "Rabi Al Thaani", "Jamaada Al Ula", "Jamaada Al Thani", "Rajab", "Shabaan", "Ramadhan", "Shawwal", "Dhu Al Qadah", "Dhu Al Hijjah"]
    
    var body: some View {
        HStack {
            importantDateInfo
            
            Spacer()
            
            importantDateDateInfo
        }
        .padding(7.5)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
    
    private var importantDateInfo: some View {
        VStack(alignment: .leading) {
            Text(importantDate.title)
                .font(.system(.subheadline, weight: .bold))
            
            Spacer()
            
            if let subtitle = importantDate.subtitle {
                Text(subtitle)
                    .font(.caption)
            }
        }.multilineTextAlignment(.leading)
    }
    
    private var importantDateDateInfo: some View {
        VStack(alignment: .trailing) {
            islamicDateText
            
            Spacer()
            
            gregorianDateText
        }
        .font(.system(.caption, weight: .bold))
        .foregroundStyle(Color.secondary)
        .multilineTextAlignment(.trailing)
    }
    
    private var islamicDateText: some View {
        HStack(spacing: 5) {
            Text(String(importantDate.date))
            
            if importantDate.month <= 12 {
                Text(islamicMonths[importantDate.month - 1])
            }
            
            if let year = importantDate.year, let yearType = importantDate.yearType {
                Text("\(year) \(yearType)")
            }
        }
    }
    
    private var gregorianDateText: Text {
        let day = date.day()
        let dayOfMonth = date.dayOfMonth()
        let month = date.month()
        
        return Text("\(day) \(dayOfMonth) \(month)")
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
            islamicDateText
            
            gregorianDateText
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(isSelected ? 1 : isToday() ? 0.2 : 0))
        .cornerRadius(10)
        .onTapGesture {
            action()
        }
    }
    
    private var islamicDateText: Text {
        Text(islamicDate)
            .font(.caption2)
            .foregroundStyle(colorScheme == .dark ? Color.secondary : Color.gray)
    }
    
    private var gregorianDateText: Text {
        Text("\(Calendar.current.component(.day, from: date))")
            .foregroundStyle(isSelected ? Color.white : Color.primary)
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
