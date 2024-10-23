//
//  PrayerTimesWidget.swift
//  QuranWidget
//
//  Created by Ali Earp on 16/06/2024.
//

import WidgetKit
import SwiftUI
import FirebaseAuth
import Alamofire
import SwiftSoup

struct PrayerTimesProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerTimesSimpleEntry {
        PrayerTimesSimpleEntry(date: Date(), prayerTimes: [:], islamicDay: "", islamicMonth: "", islamicYear: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesSimpleEntry) -> ()) {
        fetchPrayerTimes { prayerTimes in
            fetchDate { islamicDay, islamicMonth, islamicYear in
                if let prayerTimes = prayerTimes, let islamicDay = islamicDay, let islamicMonth = islamicMonth, let islamicYear = islamicYear {
                    let entry = PrayerTimesSimpleEntry(date: Date(), prayerTimes: prayerTimes, islamicDay: islamicDay, islamicMonth: islamicMonth, islamicYear: islamicYear)
                    completion(entry)
                }
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [PrayerTimesSimpleEntry] = []
        
        fetchPrayerTimes { prayerTimes in
            fetchDate { islamicDay, islamicMonth, islamicYear in
                if let prayerTimes = prayerTimes, let islamicDay = islamicDay, let islamicMonth = islamicMonth, let islamicYear = islamicYear {
                    let entry = PrayerTimesSimpleEntry(date: Date(), prayerTimes: prayerTimes, islamicDay: islamicDay, islamicMonth: islamicMonth, islamicYear: islamicYear)
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
    
    private let islamicMonths = ["Muharram" : "Muharram", "Safar" : "Safar", "Rabi I" : "Rabi Al Awwal", "Rabi' II" : "Rabi Al Thaani", "Jumada I" : "Jamaada Al Ula", "Jumada II" : "Jamaada Al Thani", "Rajab" : "Rajab", "Shabban" : "Shabaan", "Ramadan" : "Ramadhan", "Shawaal" : "Shawwal", "Thi Alqida" : "Dhu Al Qadah", "Thul-Hijja" : "Dhu Al Hijjah"]
    
    private func fetchDate(completion: @escaping (String?, String?, String?) -> Void) {
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
                        
                        let year = String(splitDate[2])
                        
                        completion(day, month, year)
                    }
                }
            case .failure(_):
                completion(nil, nil, nil)
            }
        }
    }
}

struct PrayerTimesSimpleEntry: TimelineEntry {
    let date: Date
    let prayerTimes: [String : String]
    let islamicDay: String
    let islamicMonth: String
    let islamicYear: String
}

struct PrayerTimesWidgetEntryView : View {
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: PrayerTimesProvider.Entry
    
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
            VStack(spacing: 2.5) {
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
                    
                    if let nextPrayer = (prayerTimes.filter { $0.value > Date() }).min(by: { $0.value < $1.value }), let prayerName = prayersRenamed[nextPrayer.key] {
                        
                        let (hours, minutes) = shortTimeUntilDate(from: Date(), to: nextPrayer.value)
                        
                        Text("\(prayerName) in \(hours == "" ? "" : "\(hours) ")\(minutes == "" ? "" : minutes)")
                            .font(.headline)
                    }
                    
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
                
                Spacer()
                
                let sortedPrayerTimes = prayerTimes.filter {
                    prayers.dropLast().contains($0.key)
                }.sorted {
                    prayers.firstIndex(of: $0.key) ?? 0 < prayers.firstIndex(of: $1.key) ?? 0
                }
                
                LazyVGrid(columns: rows) {
                    ForEach(sortedPrayerTimes, id: \.key) { prayer in
                        Text(prayersRenamed[prayer.key] ?? prayer.key)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                }.font(.system(size: 14))
                
                LazyVGrid(columns: rows) {
                    ForEach(sortedPrayerTimes, id: \.key) { prayer in
                        Text(prayerTimeString(prayer.value))
                            .bold()
                            .multilineTextAlignment(.center)
                    }
                }.font(.system(size: 18))
                
                Spacer()
            }
        case .accessoryInline:
            Label {
                Text("\(entry.islamicDay) \(entry.islamicMonth) \(entry.islamicYear)")
            } icon: {
                Image("crescent")
            }
        case .accessoryRectangular:
            HStack {
                VStack(alignment: .leading) {
                    if let nextPrayer = (prayerTimes.filter { $0.value > Date() }).min(by: { $0.value < $1.value }), let prayerName = prayersRenamed[nextPrayer.key] {
                        
                        Text("\(prayerName) upcoming")
                            .font(.headline)
                        
                        Spacer()
                        
                        let timeUntil = timeUntilDate(date: nextPrayer.value)
                        
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
                if (prayer == "Noon" && hour == 1) || prayer == "Sunset" || prayer == "Maghrib" || (prayer == "Midnight" && hour == 11) {
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
            if let hour = Calendar.current.dateComponents([.hour], from: midnight).hour, hour == 23, let midnight = Calendar.current.date(byAdding: .day, value: -1, to: midnight) {
                
                return (midnight, end)
            }
            
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
            if let endHour = Calendar.current.dateComponents([.hour], from: end).hour, let currentHour = Calendar.current.dateComponents([.hour], from: Date()).hour, endHour == currentHour, let maghrib = Calendar.current.date(byAdding: .day, value: -1, to: maghrib) {
                
                return (maghrib, end)
            }
            
            return (maghrib, end)
        }
        
        return (Date(), end)
    }
}

struct PrayerTimesWidget: Widget {
    let kind: String = "QuranWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            PrayerTimesWidgetEntryView(entry: entry)
                .containerBackground(Color.widget, for: .widget)
        }
        .configurationDisplayName("Prayer Times")
        .description("See prayer times at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular, .accessoryCircular])
    }
}

#Preview(as: .systemSmall) {
    PrayerTimesWidget()
} timeline: {
    let prayerTimesModel: PrayerTimesModel = PrayerTimesModel()
    
    PrayerTimesSimpleEntry(date: .now, prayerTimes: prayerTimesModel.prayerTimes, islamicDay: "", islamicMonth: "", islamicYear: "")
}

#Preview(as: .systemMedium) {
    PrayerTimesWidget()
} timeline: {
    let prayerTimesModel: PrayerTimesModel = PrayerTimesModel()
    
    PrayerTimesSimpleEntry(date: .now, prayerTimes: prayerTimesModel.prayerTimes, islamicDay: "", islamicMonth: "", islamicYear: "")
}
