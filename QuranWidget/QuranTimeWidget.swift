//
//  QuranTimeWidget.swift
//  Quran
//
//  Created by Ali Earp on 20/10/2024.
//

import WidgetKit
import SwiftUI
import CoreData
import Charts
import SDWebImageSwiftUI
import FirebaseAuth
import Alamofire
import SwiftSoup

struct QuranTimeProvider: TimelineProvider {
    let moc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
    
    func placeholder(in context: Context) -> QuranTimeSimpleEntry {
        QuranTimeSimpleEntry(date: Date(), days: [], islamicDay: "", islamicMonth: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuranTimeSimpleEntry) -> ()) {
        let fetchRequest: NSFetchRequest<WeeklyTime> = WeeklyTime.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WeeklyTime.date, ascending: true)]
        
        do {
            let weeks = try moc.fetch(fetchRequest)
            
            if let week = weeks.last, let weekDate = week.date, let days = week.days?.allObjects as? [DailyTime] {
                fetchDate { islamicDay, islamicMonth in
                    if let islamicDay = islamicDay, let islamicMonth = islamicMonth {
                        completion(QuranTimeSimpleEntry(date: weekDate, days: days, islamicDay: islamicDay, islamicMonth: islamicMonth))
                    }
                }
            }
        } catch {
            fetchDate { islamicDay, islamicMonth in
                if let islamicDay = islamicDay, let islamicMonth = islamicMonth {
                    completion(QuranTimeSimpleEntry(date: Date(), days: [], islamicDay: islamicDay, islamicMonth: islamicMonth))
                }
            }
            
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let fetchRequest: NSFetchRequest<WeeklyTime> = WeeklyTime.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WeeklyTime.date, ascending: true)]
        
        do {
            let weeks = try moc.fetch(fetchRequest)
            
            if let week = weeks.last, let weekDate = week.date, let days = weeks.last?.days?.allObjects as? [DailyTime] {
                fetchDate { islamicDay, islamicMonth in
                    if let islamicDay = islamicDay, let islamicMonth = islamicMonth {
                        let timeline = Timeline(entries: [QuranTimeSimpleEntry(date: weekDate, days: days, islamicDay: islamicDay, islamicMonth: islamicMonth)], policy: .after(Date()))
                        completion(timeline)
                    }
                }
            }
        } catch {
            fetchDate { islamicDay, islamicMonth in
                if let islamicDay = islamicDay, let islamicMonth = islamicMonth {
                    let timeline = Timeline(entries: [QuranTimeSimpleEntry(date: Date(), days: [], islamicDay: islamicDay, islamicMonth: islamicMonth)], policy: .after(Date()))
                    completion(timeline)
                }
            }
        }
    }
    
    private let islamicMonths = ["Muharram" : "Muharram", "Safar" : "Safar", "Rabi I" : "Rabi Al Awwal", "Rabi' II" : "Rabi Al Thaani", "Jumada I" : "Jamaada Al Ula", "Jumada II" : "Jamaada Al Thani", "Rajab" : "Rajab", "Shabban" : "Shabaan", "Ramadan" : "Ramadhan", "Shawaal" : "Shawwal", "Thi Alqida" : "Dhu Al Qadah", "Thul-Hijja" : "Dhu Al Hijjah"]
    
    private func fetchDate(completion: @escaping (_ day: String?, _ month: String?) -> Void) {
        let url = "https://najaf.org/english/"
        
        AF.request(url).responseString { response in
            switch response.result {
            case .success(let html):
                if let document = try? SwiftSoup.parse(html),
                   let elements = try? document.select("div.my-time-top strong.my-blue"),
                   let date = try? elements.last()?.text() {
                    let splitDate = date.split(separator: " / ")
                    
                    if splitDate.count == 3 {
                        let day = String(splitDate[0])
                        
                        let islamicMonth = String(splitDate[1])
                        let month = self.islamicMonths[islamicMonth] ?? islamicMonth
                        
                        completion(day, month)
                    }
                }
            case .failure(_):
                completion(nil, nil)
            }
        }
    }
}

struct QuranTimeSimpleEntry: TimelineEntry {
    let date: Date
    let days: [DailyTime]
    let islamicDay: String
    let islamicMonth: String
}

struct QuranTimeChart: View {
    let weekDate: Date
    let days: [DailyTime]
    
    let islamicDay: String
    let islamicMonth: String
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                if let photoURL = Auth.auth().currentUser?.photoURL, let photoData = try? Data(contentsOf: photoURL), let uiImage = UIImage(data: photoData) {
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 30)
                        .clipShape(Circle())
                        .overlay { Circle().stroke(lineWidth: 0.5) }
                        .frame(width: 30, height: 30)
                }
                
                Text(getTimeString())
                    .font(.title)
                
                Spacer()
                
                HStack {
                    Text(islamicMonth)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.trailing)
                    
                    Text(islamicDay)
                        .font(.title)
                        .fontWeight(.heavy)
                }
            }
            
            if let endOfSelectedWeek = Calendar.current.date(byAdding: .day, value: 6, to: weekDate) {
                Chart {
                    ForEach(days) { day in
                        if let date = day.date {
                            BarMark(x: .value("Date", date), y: .value("Time", Int(day.seconds)))
                        }
                    }
                }
                .chartXScale(domain: weekDate...endOfSelectedWeek)
                .chartXAxis {
                    AxisMarks(preset: .extended, position: .bottom, values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            VStack {
                                Text(dayString(value))
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
            }
        }
    }
    
    private func getTimeString() -> String {
        let seconds = days.map({ $0.seconds }).reduce(0, +)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        
        return formatter.string(from: TimeInterval(seconds)) ?? ""
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
    
    private func dayString(_ value: AxisValue) -> String {
        if let date = value.as(Date.self) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "d"
            
            return dayFormatter.string(from: date)
        }
        
        return ""
    }
}

struct QuranTimeWidgetEntryView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: QuranTimeProvider.Entry
    
    var body: some View {
        switch widgetFamily {
        case .systemMedium:
            QuranTimeChart(weekDate: entry.date, days: entry.days, islamicDay: entry.islamicDay, islamicMonth: entry.islamicMonth)
        case .systemLarge:
            QuranTimeChart(weekDate: entry.date, days: entry.days, islamicDay: entry.islamicDay, islamicMonth: entry.islamicMonth)
        case .systemExtraLarge:
            QuranTimeChart(weekDate: entry.date, days: entry.days, islamicDay: entry.islamicDay, islamicMonth: entry.islamicMonth)
        default:
            EmptyView()
        }
    }
}

struct QuranTimeWidget: Widget {
    let kind: String = "QuranTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuranTimeProvider()) { entry in
            if #available(iOS 17.0, *) {
                QuranTimeWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                QuranTimeWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Quran Time")
        .description("Easily keep track of how long you've spent reading Quran this week.")
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
    }
}
