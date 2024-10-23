//
//  StreakWidget.swift
//  Quran
//
//  Created by Ali Earp on 21/10/2024.
//

import WidgetKit
import SwiftUI
import FirebaseAuth
import Alamofire
import SwiftSoup

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakSimpleEntry {
        StreakSimpleEntry(date: Date(), streak: 0, streakDate: Date(), islamicDay: "", islamicMonth: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakSimpleEntry) -> ()) {
        fetchDate { islamicDay, islamicMonth in
            if let islamicDay = islamicDay, let islamicMonth = islamicMonth {
                completion(StreakSimpleEntry(date: Date(), streak: UserDefaultsController.shared.integer(forKey: "streak"), streakDate: Date(timeIntervalSince1970: UserDefaultsController.shared.double(forKey: "streakDate")), islamicDay: islamicDay, islamicMonth: islamicMonth))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        fetchDate { islamicDay, islamicMonth in
            if let islamicDay = islamicDay, let islamicMonth = islamicMonth {
                let timeline = Timeline(entries: [StreakSimpleEntry(date: Date(), streak: UserDefaultsController.shared.integer(forKey: "streak"), streakDate: Date(timeIntervalSince1970: UserDefaultsController.shared.double(forKey: "streakDate")), islamicDay: islamicDay, islamicMonth: islamicMonth)], policy: .after(Date()))
                
                completion(timeline)
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

struct StreakSimpleEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let streakDate: Date
    let islamicDay: String
    let islamicMonth: String
}

struct StreakWidgetStreakInfo: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let streak: Int
    let streakDate: Date
    
    var body: some View {
        VStack(spacing: 10) {
            let readToday = Calendar.current.isDate(streakDate, inSameDayAs: Date())
            
            Image(systemName: "flame.fill")
                .font(.system(.largeTitle))
                .foregroundStyle(readToday ? Color.streak : colorScheme == .dark ? Color(.tertiarySystemBackground) : Color.secondary)
            
            Text(String(streak))
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundStyle(readToday ? Color.primary : colorScheme == .dark ? Color(.tertiarySystemBackground) : Color.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StreakWidgetIslamicMonth: View {
    let islamicDay: String
    let islamicMonth: String
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text(islamicMonth)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.trailing)
            
            Text(islamicDay)
                .font(.largeTitle)
                .fontWeight(.heavy)
            
            Spacer()
            
            if let photoURL = Auth.auth().currentUser?.photoURL, let photoData = try? Data(contentsOf: photoURL), let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 30)
                    .clipShape(Circle())
                    .overlay { Circle().stroke(lineWidth: 0.5) }
                    .frame(width: 30, height: 30)
            }
        }.padding()
    }
}

struct StreakWidgetEntryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: StreakProvider.Entry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            StreakWidgetStreakInfo(streak: entry.streak, streakDate: entry.streakDate)
                .containerBackground(Color.widget, for: .widget)
        case .systemMedium:
            HStack(spacing: 0) {
                StreakWidgetStreakInfo(streak: entry.streak, streakDate: entry.streakDate)
                    .background(.fill.tertiary)
                    .padding([.leading, .vertical], -20)
                
                StreakWidgetIslamicMonth(islamicDay: entry.islamicDay, islamicMonth: entry.islamicMonth)
                    .background(Color(.tertiarySystemBackground))
                    .padding([.trailing, .vertical], -20)
            }.containerBackground(.clear, for: .widget)
        default:
            EmptyView()
        }
    }
}

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Easily keep track of how many days in a row you've read Quran.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
