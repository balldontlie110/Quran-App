//
//  QiblaFinder.swift
//  Quran
//
//  Created by Ali Earp on 31/08/2024.
//

import SwiftUI
import CoreLocation

struct QiblaFinder: View {
    @StateObject private var locationManager = LocationManager()
    
    let targetCoordinate = CLLocationCoordinate2D(latitude: 21.422487, longitude: 39.826206)
    
    var body: some View {
        VStack {
            if let userLocation = locationManager.userLocation, let heading = locationManager.heading {
                let bearingToTarget = calculateBearing(from: userLocation.coordinate, to: targetCoordinate)
                let headingAdjustment = bearingToTarget - heading.trueHeading
                
                Spacer()
                
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .animation(.easeInOut, value: headingAdjustment)
                    .foregroundStyle(headingAdjustment < 1 && headingAdjustment > -1 ? Color.green : Color.secondary)
                
                Spacer()
                
                Image(systemName: "arrow.up")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .rotationEffect(Angle(degrees: headingAdjustment))
                    .animation(.easeInOut, value: headingAdjustment)
                    .foregroundStyle(arrowColor(angle: headingAdjustment))
                
                Spacer()
            } else {
                ProgressView()
            }
        }
        .onAppear {
            locationManager.locationManager?.startUpdatingLocation()
            locationManager.locationManager?.startUpdatingHeading()
        }
        .onDisappear {
            locationManager.locationManager?.stopUpdatingLocation()
            locationManager.locationManager?.stopUpdatingHeading()
        }
        .onAppear {
            DispatchQueue.main.async {
                AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
                
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
        }.onDisappear {
            DispatchQueue.main.async {
                AppDelegate.orientationLock = UIInterfaceOrientationMask.allButUpsideDown
            }
        }
        .navigationTitle("Qibla")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func arrowColor(angle: Double) -> Color {
        let increment = 410.0 / 180.0
        let angleMagnitude = angle.magnitude
        
        var red = 0.0
        var green = 0.0
        
        if angleMagnitude * increment > 205.0 {
            red = 255
            green = (180 - angleMagnitude) * increment + 50
        } else {
            red = 255 - ((180 - angleMagnitude) * increment - 205)
            green = 255
        }
        
        let color = Color(red: red / 255, green: green / 255, blue: 0)
        
        return color
    }
}

#Preview {
    QiblaFinder()
}
