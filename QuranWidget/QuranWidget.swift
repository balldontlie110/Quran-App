//
//  QuranWidget.swift
//  QuranWidget
//
//  Created by Ali Earp on 16/06/2024.
//

import WidgetKit
import SwiftUI
import Alamofire
import SwiftSoup

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), prayerTimes: [:], islamicDate: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        fetchPrayerTimes { prayerTimes in
            fetchDate { islamicDate in
                if let prayerTimes = prayerTimes, let islamicDate = islamicDate {
                    let entry = SimpleEntry(date: Date(), prayerTimes: prayerTimes, islamicDate: islamicDate)
                    completion(entry)
                }
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        fetchPrayerTimes { prayerTimes in
            fetchDate { islamicDate in
                if let prayerTimes = prayerTimes, let islamicDate = islamicDate {
                    let entry = SimpleEntry(date: Date(), prayerTimes: prayerTimes, islamicDate: islamicDate)
                    entries.append(entry)
                }
                
                if let updateDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) {
                    let timeline = Timeline(entries: entries, policy: .after(updateDate))
                    completion(timeline)
                }
            }
        }
    }
    
    private func fetchPrayerTimes(completion: @escaping ([String: String]?) -> Void) {
        let url = "https://najaf.org/english/?cachebust=\(UUID().uuidString)"

        AF.request(url).responseString { response in
            switch response.result {
            case .success(let html):
                if let document = try? SwiftSoup.parse(html),
                   let prayerTimeDiv = try? document.select("#prayer_time").first(),
                   let prayerItems = try? prayerTimeDiv.select("ul > li") {
                    
                    var prayerTimes: [String : String] = [:]
                    
                    for item in prayerItems {
                        if let prayerName = try? item.text().letters,
                           let prayerTime = try? item.select("span").text() {
                            prayerTimes[prayerName] = prayerTime
                        }
                    }
                    
                    completion(prayerTimes)
                }
            case .failure(_):
                completion(nil)
            }
        }
    }
    
    private func fetchDate(completion: @escaping (String?) -> Void) {
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
                        let month = String(splitDate[1])
                        let year = String(splitDate[2])
                        
                        let islamicDate = "\(day) \(month) \(year)"
                        
                        completion(islamicDate)
                    }
                }
            case .failure(_):
                completion(nil)
            }
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let prayerTimes: [String : String]
    let islamicDate: String
}

struct QuranWidgetEntryView : View {
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: Provider.Entry
    
    private let prayers = ["Dawn", "Sunrise", "Noon", "Sunset", "Maghrib", "Midnight"]
    private let prayersRenamed = ["Dawn" : "Fajr", "Sunrise" : "Sunrise", "Noon" : "Zuhr", "Sunset" : "Sunset", "Maghrib" : "Maghrib", "Midnight" : "Midnight"]
    
    private let columns: [GridItem] = [GridItem](repeating: GridItem(.flexible()), count: 2)
    private let rows: [GridItem] = [GridItem](repeating: GridItem(.flexible()), count: 5)
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            LazyVStack(spacing: 0) {
                let prayerTimes = prayerTimes.filter {
                    prayers.dropLast().contains($0.key)
                }.sorted {
                    prayers.firstIndex(of: $0.key) ?? 0 < prayers.firstIndex(of: $1.key) ?? 0
                }
                
                ForEach(prayerTimes, id: \.key) { prayer in
                    LazyVGrid(columns: columns) {
                        Text(prayersRenamed[prayer.key] ?? prayer.key)
                            .foregroundStyle(Color.secondary)
                        
                        Text(prayerTimeString(prayer.value))
                            .bold()
                    }
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                    .padding(.vertical, 5)
                }
            }
        case .systemMedium:
            VStack(spacing: 0) {
                Spacer()
                
                Text(entry.islamicDate)
                    .bold()
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                let prayerTimes = prayerTimes.filter {
                    prayers.dropLast().contains($0.key)
                }.sorted {
                    prayers.firstIndex(of: $0.key) ?? 0 < prayers.firstIndex(of: $1.key) ?? 0
                }
                
                LazyVGrid(columns: rows) {
                    ForEach(prayerTimes, id: \.key) { prayer in
                        Text(prayersRenamed[prayer.key] ?? prayer.key)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                }.font(.system(size: 14))
                
                Spacer()
                
                LazyVGrid(columns: rows) {
                    ForEach(prayerTimes, id: \.key) { prayer in
                        Text(prayerTimeString(prayer.value))
                            .bold()
                            .multilineTextAlignment(.center)
                    }
                }.font(.system(size: 18))
                
                Spacer()
            }
        case .accessoryInline:
            Label {
                Text(entry.islamicDate)
            } icon: {
                Image("crescent")
            }
        case .accessoryRectangular:
            HStack {
                VStack(alignment: .leading) {
                    if let nextPrayer = (prayerTimes.filter { $0.value > Date() }).min(by: { $0.value < $1.value }), let prayerName = prayersRenamed[nextPrayer.key] {
                        
                        let timeUntil = timeUntilDate(date: nextPrayer.value)
                        
                        Text("\(prayerName) upcoming")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(timeUntil)
                        
                        Spacer()
                        
                        Text("\(prayerName == "Sunset" ? "🌙" : prayerName == "Sunrise" ? "☀️" : prayerName == "Midnight" ? "🌑" : "🕌") \(prayerTimeString(nextPrayer.value))")
                    }
                }.multilineTextAlignment(.leading)
                
                Spacer()
            }
        case .accessoryCircular:
            if let nextPrayer = (prayerTimes.filter { $0.value > Date() }).min(by: { $0.value < $1.value }) {
                let (start, end) = prayerStartAndEnd(prayer: nextPrayer)
                
                let totalTimeInterval = end.timeIntervalSince(start)
                let remainingTimeInterval = end.timeIntervalSince(Date())
                
                Gauge(value: remainingTimeInterval / totalTimeInterval) {
                    VStack {
                        if nextPrayer.key == "Dawn" {
                            Text("Fajr starts")
                        } else if nextPrayer.key == "Sunrise" {
                            Text("Fajr ends")
                        } else if nextPrayer.key == "Noon" {
                            Text("Zuhr starts")
                        } else if nextPrayer.key == "Sunset" {
                            Text("Zuhr ends")
                        } else if nextPrayer.key == "Maghrib" {
                            Text("Maghrib starts")
                        } else if nextPrayer.key == "Midnight" {
                            Text("Maghrib ends")
                        }
                        
                        let (hours, minutes) = shortTimeUntilDate(from: Date(), to: end)
                        
                        if hours != "" {
                            Text(hours)
                        }
                        
                        if minutes != "" {
                            Text(minutes)
                        }
                    }.multilineTextAlignment(.center)
                }.gaugeStyle(.accessoryCircularCapacity)
            }
        default:
            EmptyView()
        }
    }
    
    private var prayerTimes: [String : Date] {
        let filteredPrayerTimes = entry.prayerTimes.filter { prayerTime in
            prayers.contains { prayer in
                prayer == prayerTime.key
            }
        }
        
        var prayerTimesDates: [String : Date] = [:]
        
        for (prayer, time) in filteredPrayerTimes {
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            
            if let hour = Int(time.dropLast(3)) {
                if (prayer == "Noon" && hour == 1) || prayer == "Sunset" || prayer == "Maghrib" || prayer == "Midnight" {
                    dateComponents.hour = hour + 12
                } else {
                    dateComponents.hour = hour
                }
            }
            
            dateComponents.minute = Int(time.dropFirst(3))
            
            prayerTimesDates[prayer] = Calendar.current.date(from: dateComponents)
        }
        
        return prayerTimesDates
    }
    
    private func prayerTimeString(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    private func timeUntilDate(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        formatter.unitsStyle = .full
        
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func shortTimeUntilDate(from startDate: Date, to endDate: Date) -> (hours: String, minutes: String) {
        let interval = Int(endDate.timeIntervalSince(startDate))
        
        let minute = 60
        let hour = 3600
        
        let hours = interval / hour
        let minutes = (interval % hour) / minute
        
        var hoursString = ""
        var minutesString = ""
        
        if hours > 0 {
            hoursString = "\(hours) hr\(hours == 1 ? "" : "s")"
        }
        
        if minutes > 0 {
            minutesString = "\(minutes) min\(minutes == 1 ? "" : "s")"
        }
        
        return (hoursString, minutesString)
    }
    
    private func prayerStartAndEnd(prayer: Dictionary<String, Date>.Element) -> (start: Date, end: Date) {
        let prayerName = prayer.key
        let end = prayer.value
        
        if prayerName == "Dawn", let midnight = prayerTimes.first(where: { $0.key == "Midnight" })?.value {
            return (midnight, end)
        } else if prayerName == "Sunrise", let fajr = prayerTimes.first(where: { $0.key == "Dawn" })?.value {
            return (fajr, end)
        } else if prayerName == "Noon", let sunrise = prayerTimes.first(where: { $0.key == "Sunrise" })?.value {
            return (sunrise, end)
        } else if prayerName == "Sunset", let zuhr = prayerTimes.first(where: { $0.key == "Noon" })?.value {
            return (zuhr, end)
        } else if prayerName == "Maghrib", let sunset = prayerTimes.first(where: { $0.key == "Sunset" })?.value {
            return (sunset, end)
        } else if prayerName == "Midnight", let maghrib = prayerTimes.first(where: { $0.key == "Maghrib" })?.value {
            return (maghrib, end)
        }
        
        return (Date(), end)
    }
}

struct QuranWidget: Widget {
    let kind: String = "QuranWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                QuranWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                QuranWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Prayer Times")
        .description("See prayer times at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular, .accessoryCircular])
    }
}

#Preview(as: .systemSmall) {
    QuranWidget()
} timeline: {
    let prayerTimesModel: PrayerTimesModel = PrayerTimesModel()
    
    SimpleEntry(date: .now, prayerTimes: prayerTimesModel.prayerTimes, islamicDate: "")
}

#Preview(as: .systemMedium) {
    QuranWidget()
} timeline: {
    let prayerTimesModel: PrayerTimesModel = PrayerTimesModel()
    
    SimpleEntry(date: .now, prayerTimes: prayerTimesModel.prayerTimes, islamicDate: "")
}
