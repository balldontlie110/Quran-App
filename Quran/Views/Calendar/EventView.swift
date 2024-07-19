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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                if let startDate = event.dtStart?.date, let endDate = event.dtEnd?.date {
                    HStack {
                        Spacer()
                        
                        Text(startToEnd(start: startDate, end: endDate))
                    }
                }
                
                if let summary = event.summary {
                    Text(summary)
                        .font(.system(.title, weight: .bold))
                }
                
                if let description = event.description {
                    VStack(alignment: .leading, spacing: 10) {
                        let formatDescription = formatDescription(from: description).sorted { description1, description2 in
                            description1.key < description2.key
                        }
                        
                        ForEach(formatDescription, id: \.key) { key, value in
                            HStack(alignment: .top) {
                                Text(key.time())
                                    .foregroundStyle(Color.secondary)
                                    .bold()
                                
                                Text(value)
                            }
                        }
                    }
                }
                
                if let location = fixedText(text: event.location) {
                    Button {
                        openLocation(address: location)
                    } label: {
                        Text(location)
                            .font(.callout)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.leading)
                            .underline()
                    }
                }
            }.padding(.horizontal)
        }
    }
    
    private func fixedText(text: String?) -> String? {
        var fixedText = text
        
        fixedText = fixedText?.replacingOccurrences(of: "\\n", with: "")
        fixedText = fixedText?.replacingOccurrences(of: "\\r", with: "")
        fixedText = fixedText?.replacingOccurrences(of: "\\", with: "")
        
        return fixedText
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
    
    private func formatDescription(from description: String) -> [Date: String] {
        var result = [Date: String]()
        
        let pattern = #"(\d{1,2}[:.]\d{2})\s+(.*?)(?=\d{1,2}[:.]\d{2}|$)"#
        
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        let range = NSRange(location: 0, length: description.utf16.count)
        
        if let matches = regex?.matches(in: description, options: [], range: range) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            
            for match in matches {
                if let timeRange = Range(match.range(at: 1), in: description), let textRange = Range(match.range(at: 2), in: description) {
                    let timeString = String(description[timeRange]).replacingOccurrences(of: ".", with: ":")
                    let textString = String(description[textRange])
                    
                    if let date = dateFormatter.date(from: timeString) {
                        if let fixedTextString = fixedText(text: textString) {
                            result[date] = fixedTextString
                        }
                    }
                }
            }
            
            return result
        }
        
        return [:]
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
