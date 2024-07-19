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
            VStack(alignment: .leading, spacing: 15) {
                if let summary = event.summary {
                    Text(summary)
                        .font(.system(.title, weight: .bold))
                        .padding(.top)
                    
                    Divider()
                }
                
                if let description = fixedText(text: event.description) {
                    Text(description)
                    
                    Divider()
                }
                
                HStack(alignment: .top) {
                    if let location = fixedText(text: event.location) {
                        Button {
                            openLocation(address: location)
                        } label: {
                            Text(location)
                                .font(.callout)
                                .foregroundStyle(Color.secondary)
                                .multilineTextAlignment(.leading)
                                .underline()
                        }.padding(.trailing)
                    }
                    
                    Spacer()
                    
                    if let start = event.dtStart?.date, let end = event.dtEnd?.date {
                        VStack(alignment: .trailing) {
                            Text(date(date: start))
                            
                            Text(startToEndTime(start: start, end: end))
                        }
                        .font(.callout)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.trailing)
                    }
                }
            }.padding(.horizontal)
        }
    }
    
    private func fixedText(text: String?) -> String? {
        var fixedText = text
        
        fixedText = fixedText?.replacingOccurrences(of: "\\n  \\n", with: "\\n")
        fixedText = fixedText?.replacingOccurrences(of: "\\n", with: "\n\n")
        fixedText = fixedText?.replacingOccurrences(of: "\\", with: "")
        
        return fixedText
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
    
    private func date(date: Date) -> String {
        let month = date.month()
        let day = date.dayOfMonth()
        
        return "\(month) \(day)"
    }
    
    private func startToEndTime(start: Date, end: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        
        let startTime = dateFormatter.string(from: start)
        let endTime = dateFormatter.string(from: end)
        
        return "\(startTime) - \(endTime)"
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
