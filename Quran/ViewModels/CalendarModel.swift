//
//  CalendarModel.swift
//  Quran
//
//  Created by Ali Earp on 18/07/2024.
//

import Foundation
import iCalendarParser
import Alamofire
import SwiftSoup

class CalendarModel: ObservableObject {
    @Published var day: String = ""
    @Published var month: String = ""
    @Published var year: String = ""
    
    @Published var events: [ICEvent] = []
    
    init() {
        fetchDate()
        fetchEvents()
    }
    
    private func fetchDate() {
        let url = "https://najaf.org/english/"

        AF.request(url).responseString { response in
            switch response.result {
            case .success(let html):
                do {
                    let document = try SwiftSoup.parse(html)
                    let elements = try document.select("div.my-time-top strong.my-blue")
                    
                    if let date = try elements.last()?.text() {
                        let splitDate = date.split(separator: " / ")
                        
                        if splitDate.count == 3 {
                            DispatchQueue.main.async {
                                self.day = String(splitDate[0])
                                self.month = String(splitDate[1])
                                self.year = String(splitDate[2])
                            }
                        }
                    }
                } catch {
                    print("Error parsing HTML: \(error)")
                }
            case .failure(let error):
                print("Request failed with error: \(error)")
            }
        }
    }
    
    private func fetchEvents() {
        if let calendarUrl = URL(string: "https://hyderi.org.uk/all-events/list/?hide_subsequent_recurrences=1&ical=1") {
            URLSession.shared.dataTask(with: calendarUrl) { data, response, error in
                if let error = error {
                    print(error)
                    return
                }
                
                guard let data = data else { return }
                
                if let content = String(data: data, encoding: .utf8) {
                    let parser = ICParser()
                    let calendar: ICalendar? = parser.calendar(from: content)
                    
                    guard let calendar = calendar else { return }
                    
                    DispatchQueue.main.async {
                        self.events = calendar.events
                    }
                }
            }.resume()
        }
    }
}
