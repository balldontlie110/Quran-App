//
//  CalendarModel.swift
//  Quran
//
//  Created by Ali Earp on 22/07/2024.
//

import Foundation
import Alamofire
import SwiftSoup

struct PrayerTimes {
    let date: String
    let midnight: String
    let maghrib: String
    let sunset: String
    let noon: String
    let sunrise: String
    let dawn: String
    let imsaak: String
}

struct MonthPrayerTimes {
    let monthName: String
    let days: [PrayerTimes]
}

class CalendarModel: ObservableObject {
    @Published var day: String = ""
    @Published var month: String = ""
    @Published var year: String = ""
    
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var importantDates: [ImportantDate] = []
    
    @Published var prayerTimes: [MonthPrayerTimes] = []
    
    init() {
        load()
    }
    
    func load() {
        fetchDate()
        fetchImportantDates()
        
        fetchPrayerTimes { prayerTimes in
            if let prayerTimes = prayerTimes {
                self.prayerTimes = prayerTimes
            }
        }
    }
    
    private let islamicMonths = ["Muharram" : "Muharram", "Safar" : "Safar", "Rabi I" : "Rabi Al Awwal", "Rabi' II" : "Rabi Al Thaani", "Jumada I" : "Jamaada Al Ula", "Jumada II" : "Jamaada Al Thani", "Rajab" : "Rajab", "Shabban" : "Shabaan", "Ramadan" : "Ramadhan", "Shawaal" : "Shawwal", "Thi Alqida" : "Dhu Al Qadah", "Thul-Hijja" : "Dhu Al Hijjah"]
    
    private func fetchDate() {
        let url = "https://najaf.org/english/?cachebust=\(UUID().uuidString)"

        AF.request(url).responseString { response in
            switch response.result {
            case .success(let html):
                if let document = try? SwiftSoup.parse(html), let elements = try? document.select("div.my-time-top strong.my-blue") {
                    if let date = try? elements.last()?.text() {
                        let splitDate = date.split(separator: " / ")
                        
                        if splitDate.count == 3 {
                            DispatchQueue.main.async {
                                self.day = String(splitDate[0])
                                
                                let islamicMonth = String(splitDate[1])
                                
                                self.month = self.islamicMonths[islamicMonth] ?? islamicMonth
                                self.year = String(splitDate[2])
                            }
                        }
                    }
                }
            case .failure(_):
                return
            }
        }
    }
    
    private func fetchImportantDates() {
        if let path = Bundle.main.path(forResource: "ImportantDates", ofType: "json") {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
               let jsonData = try? JSONDecoder().decode([ImportantMonth].self, from: data) {
                var importantDates: [ImportantDate] = []
                
                for month in jsonData {
                    importantDates += month.importantDates
                }
                
                DispatchQueue.main.async {
                    self.importantDates = importantDates
                }
            }
        }
    }
    
    private func fetchPrayerTimes(completion: @escaping ([MonthPrayerTimes]?) -> Void) {
        let url = "https://najaf.org/english/prayer/london"
        
        AF.request(url).responseString { response in
            switch response.result {
            case .success(let html):
                if let document = try? SwiftSoup.parse(html), let tables = try? document.select("div.col-lg-12.mb-5 > table.my-table.small") {
                    var monthPrayerTimesArray = [MonthPrayerTimes]()
                    
                    for table in tables {
                        if let caption = try? table.select("caption > h5").first()?.text() ?? "", let rows = try? table.select("tbody > tr") {
                            var daysArray = [PrayerTimes]()
                            
                            for row in rows {
                                if let cells = try? row.select("td") {
                                    if cells.count == 8 {
                                        let prayerTimes = PrayerTimes(
                                            date: (try? cells[7].text()) ?? "",
                                            midnight: (try? cells[0].text()) ?? "",
                                            maghrib: (try? cells[1].text()) ?? "",
                                            sunset: (try? cells[2].text()) ?? "",
                                            noon: (try? cells[3].text()) ?? "",
                                            sunrise: (try? cells[4].text()) ?? "",
                                            dawn: (try? cells[5].text()) ?? "",
                                            imsaak: (try? cells[6].text()) ?? ""
                                        )
                                        
                                        daysArray.append(prayerTimes)
                                    }
                                }
                            }
                            
                            let monthPrayerTimes = MonthPrayerTimes(monthName: caption, days: daysArray)
                            monthPrayerTimesArray.append(monthPrayerTimes)
                        }
                    }
                    
                    completion(monthPrayerTimesArray)
                }
            case .failure(_):
                completion(nil)
            }
        }
    }
    
    func getPrayerTimes(for date: Date) -> PrayerTimes? {
        if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year) {
            let month = Calendar.current.component(.month, from: date)
            let day = Calendar.current.component(.day, from: date)
            
            let monthNames = Calendar.current.monthSymbols
            
            if let monthPrayerTimes = prayerTimes.first(where: { monthPrayerTime in
                if monthNames.count <= 12 && month <= 12 {
                    let monthName = monthPrayerTime.monthName.split(separator: " - ").last?.uppercased()
                    return monthName == monthNames[month - 1].uppercased()
                }
                
                return false
                
            }) {
                
                if let dayPrayerTimes = monthPrayerTimes.days.first(where: { dayPrayerTime in
                    dayPrayerTime.date == String(day)
                }) {
                    
                    return dayPrayerTimes
                }
            }
        }
        
        return nil
    }
}
