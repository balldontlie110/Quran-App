//
//  EventsModel.swift
//  Quran
//
//  Created by Ali Earp on 18/07/2024.
//

import Foundation
import iCalendarParser
import Alamofire
import SwiftSoup

class EventsModel: ObservableObject {
    @Published var events: [ICEvent] = []
    
    init() {
        fetchEvents()
    }
    
    private func fetchEvents() {
        if let calendarUrl = URL(string: "https://hyderi.org.uk/all-events/list/?hide_subsequent_recurrences=1&ical=1") {
            URLSession.shared.dataTask(with: calendarUrl) { data, response, error in
                if error != nil {
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
