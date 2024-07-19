//
//  CalendarView.swift
//  Quran
//
//  Created by Ali Earp on 18/07/2024.
//

import SwiftUI
import iCalendarParser

struct CalendarView: View {
    @EnvironmentObject private var calendarModel: CalendarModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(calendarModel.events) { event in
                    NavigationLink {
                        EventView(event: event)
                    } label: {
                        Event(event: event)
                    }
                }
            }.padding(.horizontal)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct Event: View {
    let event: ICEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack {
                if let date = event.dtStart?.date {
                    Text(date.day())
                    
                    Text(date.dayOfMonth())
                        .font(.system(.title, weight: .bold))
                }
            }
            .multilineTextAlignment(.center)
            .frame(minWidth: 80)
            
            VStack(alignment: .leading, spacing: 10) {
                if let startDate = event.dtStart?.date, let endDate = event.dtEnd?.date {
                    Text(startToEnd(start: startDate, end: endDate))
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                if let summary = event.summary {
                    Text(summary)
                }
                
                if let location = fixedLocation(text: event.location) {
                    Text(location)
                        .font(.callout)
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer()
        }
        .foregroundStyle(Color.primary)
        .multilineTextAlignment(.leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
    
    private func fixedLocation(text: String?) -> String? {
        if let fixedLocation = text?.split(separator: ",").first {
            var fixedLocation = String(fixedLocation)
            
            fixedLocation = fixedLocation.replacingOccurrences(of: "\\n", with: "\n\n")
            fixedLocation = fixedLocation.replacingOccurrences(of: "\\r", with: "\r")
            fixedLocation = fixedLocation.replacingOccurrences(of: "\\", with: "")
            
            return fixedLocation
        }
        
        return nil
    }
    
    private func startToEnd(start: Date, end: Date) -> String {
        let month = start.month()
        let dayOfMonth = start.dayOfMonth()
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        
        let startTime = dateFormatter.string(from: start)
        let endTime = dateFormatter.string(from: end)
        
        let time = "\(month) \(dayOfMonth) @ \(startTime) - \(endTime)"
        return time
    }
}

extension ICEvent: @retroactive Identifiable {
    public var id: String {
        return self.uid
    }
}

extension Date {
    func day() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        
        return dateFormatter.string(from: self).capitalized
    }
    
    func dayOfMonth() -> String {
        return String(Calendar.current.component(.day, from: self))
    }
    
    func month() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
        
        return dateFormatter.string(from: self).capitalized
    }
    
    func time() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        
        return dateFormatter.string(from: self)
    }
}

#Preview {
    CalendarView()
}
