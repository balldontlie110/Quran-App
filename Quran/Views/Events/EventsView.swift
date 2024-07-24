//
//  EventsView.swift
//  Quran
//
//  Created by Ali Earp on 18/07/2024.
//

import SwiftUI
import iCalendarParser

struct EventsView: View {
    @EnvironmentObject private var eventsModel: EventsModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(eventsModel.events) { event in
                    NavigationLink {
                        EventView(event: event)
                    } label: {
                        EventCard(event: event)
                    }
                }
            }.padding(.horizontal)
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EventCard: View {
    let event: ICEvent
    
    @State private var isNotifying: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack {
                if let date = event.dtStart?.date {
                    Text(date.day())
                        .lineLimit(1)
                        .minimumScaleFactor(.leastNonzeroMagnitude)
                    
                    Text(date.dayOfMonth())
                        .font(.system(.title, weight: .bold))
                    
                    Text(date.month())
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .frame(width: 80)
            
            VStack(alignment: .leading, spacing: 10) {
                if let startDate = event.dtStart?.date, let endDate = event.dtEnd?.date {
                    Text(startToEnd(start: startDate, end: endDate))
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(.leastNonzeroMagnitude)
                        .foregroundStyle(Color.secondary)
                }
                
                if let summary = event.summary {
                    Text(summary)
                        .lineLimit(3)
                        .minimumScaleFactor(.leastNonzeroMagnitude)
                }
                
                if let location = fixedLocation(text: event.location) {
                    Text(location)
                        .font(.callout)
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer()
            
            if isNotifying {
                Image(systemName: "bell.fill")
            }
        }
        .foregroundStyle(Color.primary)
        .multilineTextAlignment(.leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .onAppear {
            checkIfNotifying()
        }
    }
    
    private func checkIfNotifying() {
        NotificationManager.shared.isNotifyingEvent(event: event) { isNotifying, _ in
            self.isNotifying = isNotifying
        }
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
        let startMonth = start.month()
        let startDayOfMonth = start.dayOfMonth()
        
        let endMonth = end.month()
        let endDayOfMonth = end.dayOfMonth()
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        
        let startTime = dateFormatter.string(from: start)
        let endTime = dateFormatter.string(from: end)
        
        if startMonth == endMonth && startDayOfMonth == endDayOfMonth {
            return "\(startMonth) \(startDayOfMonth) \(startTime) - \(endTime)"
        } else {
            return "\(startMonth) \(startDayOfMonth) \(startTime) - \(endMonth) \(endDayOfMonth) \(endTime)"
        }
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
    
    func year() -> Int {
        let components = Calendar.current.dateComponents([.year], from: self)
        
        if let year = components.year {
            return year
        }
        
        return 0
    }
    
    func time() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        
        return dateFormatter.string(from: self)
    }
}

#Preview {
    EventsView()
}
