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
import FirebaseAuth
import Alamofire
import SwiftSoup

struct QuranTimeProvider: TimelineProvider {
    let moc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
    
    func placeholder(in context: Context) -> QuranTimeSimpleEntry {
        QuranTimeSimpleEntry(date: Date(), days: [], islamicDay: "", islamicMonth: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuranTimeSimpleEntry) -> ()) {
        fetchDate { islamicDay, islamicMonth in
            fetchWeeks(islamicDay: islamicDay, islamicMonth: islamicMonth) { entry in
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        fetchDate { islamicDay, islamicMonth in
            fetchWeeks(islamicDay: islamicDay, islamicMonth: islamicMonth) { entry in
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                
                completion(timeline)
            }
        }
    }
    
    func fetchWeeks(islamicDay: String?, islamicMonth: String?, completion: @escaping (QuranTimeSimpleEntry) -> ()) {
        let fetchRequest: NSFetchRequest<WeeklyTime> = WeeklyTime.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WeeklyTime.date, ascending: true)]
        
        do {
            let weeks = try moc.fetch(fetchRequest)
            
            if let weekDate = weeks.last?.date, let days = weeks.last?.days?.sortedAllObjects() {
                if let islamicDay = islamicDay, let islamicMonth = islamicMonth {
                    let entry = QuranTimeSimpleEntry(date: weekDate, days: days, islamicDay: islamicDay, islamicMonth: islamicMonth)
                    
                    completion(entry)
                } else {
                    let entry = QuranTimeSimpleEntry(date: weekDate, days: days, islamicDay: "", islamicMonth: "")
                    
                    completion(entry)
                }
            } else {
                if let islamicDay = islamicDay, let islamicMonth = islamicMonth {
                    let entry = QuranTimeSimpleEntry(date: Date(), days: [], islamicDay: islamicDay, islamicMonth: islamicMonth)
                    
                    completion(entry)
                } else {
                    let entry = QuranTimeSimpleEntry(date: Date(), days: [], islamicDay: "", islamicMonth: "")
                    
                    completion(entry)
                }
            }
        } catch {
            if let islamicDay = islamicDay, let islamicMonth = islamicMonth {
                let entry = QuranTimeSimpleEntry(date: Date(), days: [], islamicDay: islamicDay, islamicMonth: islamicMonth)
                
                completion(entry)
            } else {
                let entry = QuranTimeSimpleEntry(date: Date(), days: [], islamicDay: "", islamicMonth: "")
                
                completion(entry)
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
    let entry: QuranTimeProvider.Entry
    
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
                    .font(.title2)
                
                Spacer()
                
                Text(entry.islamicMonth)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.trailing)
                
                Text(entry.islamicDay)
                    .font(.title)
                    .fontWeight(.heavy)
            }
            
            if !entry.days.isEmpty, let endOfSelectedWeek = Calendar.current.date(byAdding: .day, value: 6, to: entry.date) {
                GeometryReader { proxy in
                    Chart {
                        ForEach(entry.days) { day in
                            if let date = day.date {
                                BarMark(x: .value("Date", date), y: .value("Time", Int(day.seconds)))
                            }
                        }
                    }
                    .chartXScale(domain: entry.date...endOfSelectedWeek)
                    .chartXAxis {
                        AxisMarks(preset: .aligned, position: .bottom, values: .stride(by: .day)) { value in
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
                        let desiredCount = min(Int(ceil(proxy.size.height / 30)), 5)
                        
                        AxisMarks(preset: .aligned, position: .trailing, values: .automatic(desiredCount: desiredCount)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                Text(formatTime(value))
                            }
                        }
                    }
                }
            } else {
                Text("Start reading some Quran this week to see your progress update here.")
                    .font(.callout)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func getTimeString() -> String {
        let seconds = entry.days.map({ $0.seconds }).reduce(0, +)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        
        return formatter.string(from: TimeInterval(seconds)) ?? ""
    }
    
    private func formatTime(_ value: AxisValue) -> String {
        if let seconds = value.as(Int.self) {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = seconds == 0 ? [.second] : seconds % 3600 == 0 ? [.hour] : seconds >= 3600 ? [.hour, .minute] : seconds % 60 == 0 ? [.minute] : seconds >= 60 ? [.minute, .second] : [.second]
            formatter.unitsStyle = .positional
            formatter.zeroFormattingBehavior = .pad
            
            if var time = formatter.string(from: TimeInterval(seconds)) {
                time += seconds == 0 ? "s" : seconds % 3600 == 0 ? "h" : seconds >= 3600 || seconds % 60 == 0 ? "m" : "s"
                
                return time
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

extension String {
    func removingCharacters(of characterSet: CharacterSet) -> String {
        return self.filter({ !characterSet.containsCharacter($0) })
    }
}

extension CharacterSet {
    func containsCharacter(_ character: Character) -> Bool {
        return character.unicodeScalars.allSatisfy(contains(_:))
    }
}

struct QuranTimeWidgetEntryView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: QuranTimeProvider.Entry
    
    var body: some View {
        switch widgetFamily {
        case .systemMedium:
            QuranTimeChart(entry: entry)
        case .systemLarge:
            QuranTimeChart(entry: entry)
        case .systemExtraLarge:
            QuranTimeChart(entry: entry)
        default:
            EmptyView()
        }
    }
}

struct QuranTimeWidget: Widget {
    @Environment(\.colorScheme) private var colorScheme
    
    let kind: String = "QuranTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuranTimeProvider()) { entry in
            QuranTimeWidgetEntryView(entry: entry)
                .containerBackground(Color.widget, for: .widget)
        }
        .configurationDisplayName("Quran Time")
        .description("Easily keep track of how long you've spent reading Quran this week.")
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
    }
}
