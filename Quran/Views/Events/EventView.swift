//
//  EventView.swift
//  Quran
//
//  Created by Ali Earp on 18/07/2024.
//

import SwiftUI
import iCalendarParser
import CoreLocation
import MapKit

struct EventView: View {
    let event: ICEvent
    
    private let timeBefores: [Int? : String] = [
        nil : "Remove Notification",
        0 : "At time of event",
        -5 : "5 minutes before",
        -10 : "10 minutes before",
        -15 : "15 minutes before",
        -30 : "30 minutes before",
        -60 : "1 hour before",
        -120 : "2 hours before",
        -1440 : "1 day before"
    ]
    
    @State private var isNotifying: Bool = false
    @State private var timeBefore: Int? = nil
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 15) {
                header
                
                Divider()
                
                description
                url
                
                information
            }.padding(.horizontal)
        }
        .onAppear {
            checkIfNotifying()
        }
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            summary
            
            Spacer()
            
            notificationButton
                .padding(.top, 2.5)
        }
    }
    
    private var summary: some View {
        Group {
            if let summary = event.summary {
                Text(summary)
                    .font(.system(.title2, weight: .bold))
            }
        }
    }
    
    private var notificationButton: some View {
        Menu {
            ForEach(
                timeBefores.sorted { $0.key ?? 1 > $1.key ?? 1 },
                id: \.key
            ) { timeBefore in
                if isNotifying || timeBefore.key != nil {
                    Button {
                        NotificationManager.shared.scheduleEventNotification(event: event, timeBefore: timeBefore.key) { isNotifying in
                            self.isNotifying = isNotifying
                            self.timeBefore = timeBefore.key
                        }
                    } label: {
                        HStack {
                            Text(timeBefore.value)
                            
                            Spacer()
                            
                            if timeBefore.key == self.timeBefore {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: isNotifying ? "bell.fill" : "bell")
                .font(.system(size: 20))
                .foregroundStyle(Color.primary)
        }
    }
    
    private var description: some View {
        Group {
            if let description = splitText(text: fixedText(text: event.description), by: "\n") {
                LazyVStack(alignment: .leading, spacing: 7.5) {
                    ForEach(description) { part in
                        Text(part)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                if event.url == nil {
                    Divider()
                }
            }
        }
    }
    
    private var url: some View {
        Group {
            if let url = event.url {
                Link(destination: url) {
                    HStack(alignment: .top) {
                        Text("URL:")
                        Text(url.absoluteString)
                    }
                    .foregroundStyle(Color.accentColor)
                    .multilineTextAlignment(.leading)
                }
                
                Divider()
            }
        }
    }
    
    private var information: some View {
        GeometryReader { geometry in
            HStack(alignment: .top) {
                location
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                time
                    .frame(maxWidth: geometry.size.width / 3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var location: some View {
        Group {
            if let location = fixedText(text: event.location) {
                Button {
                    openLocation(address: location)
                } label: {
                    Text(location)
                        .font(.callout)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.leading)
                        .underline()
                }.padding(.trailing, 10)
            }
        }
    }
    
    private var time: some View {
        Group {
            if let start = event.dtStart?.date, let end = event.dtEnd?.date {
                Text(startToEnd(start: start, end: end))
                    .font(.callout)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    private func checkIfNotifying() {
        NotificationManager.shared.isNotifyingEvent(event: event) { isNotifying, timeBefore in
            DispatchQueue.main.async {
                self.isNotifying = isNotifying
                self.timeBefore = timeBefore
            }
        }
    }
    
    private func fixedText(text: String?) -> String? {
        var fixedText = text
        
        fixedText = fixedText?.replacingOccurrences(of: "\\n", with: "\n")
        fixedText = fixedText?.replacingOccurrences(of: "\\", with: "")
        
        return fixedText
    }
    
    private func splitText(text: String?, by delimeter: String) -> [String]? {
        return text?.components(separatedBy: delimeter)
    }
    
    private func fixedLocation(text: String?) -> String? {
        if let fixedLocation = text?.split(separator: ",").first {
            var fixedLocation = String(fixedLocation)
            
            fixedLocation = fixedLocation.replacingOccurrences(of: "\\n", with: "\n")
            fixedLocation = fixedLocation.replacingOccurrences(of: "\\r", with: "\r")
            fixedLocation = fixedLocation.replacingOccurrences(of: "\\", with: "")
            
            return fixedLocation
        }
        
        return nil
    }
    
    private func startToEnd(start: Date, end: Date) -> String {
        let startDay = start.day()
        let endDay = end.day()
        
        let startMonth = start.month()
        let startDayOfMonth = start.dayOfMonth()
        
        let endMonth = end.month()
        let endDayOfMonth = end.dayOfMonth()
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        
        let startTime = dateFormatter.string(from: start)
        let endTime = dateFormatter.string(from: end)
        
        if startMonth == endMonth && startDayOfMonth == endDayOfMonth {
            return "\(startDay) \(startMonth) \(startDayOfMonth) \(startTime) - \(endTime)"
        } else {
            return "\(startDay) \(startMonth) \(startDayOfMonth) \(startTime) - \(endDay) \(endMonth) \(endDayOfMonth) \(endTime)"
        }
    }
    
    private func openLocation(address: String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { placemarks, error in
            guard let placemarks = placemarks?.first else {
                return
            }
            
            let location = placemarks.location?.coordinate
            
            if let lat = location?.latitude, let lon = location?.longitude{
                let destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)))
                destination.name = fixedLocation(text: address)
                
                MKMapItem.openMaps(
                    with: [destination]
                )
            }
        }
    }
}

#Preview {
    EventView(event: ICEvent())
}
