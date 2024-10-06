//
//  LocationManager.swift
//  Quran
//
//  Created by Ali Earp on 31/08/2024.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    
    @Published var heading: CLHeading?
    @Published var userLocation: CLLocation?
    
    override init() {
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.requestWhenInUseAuthorization()
        self.locationManager?.startUpdatingLocation()
        self.locationManager?.startUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}

func calculateBearing(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
    let lat1 = coordinate1.latitude.degreesToRadians
    let lon1 = coordinate1.longitude.degreesToRadians

    let lat2 = coordinate2.latitude.degreesToRadians
    let lon2 = coordinate2.longitude.degreesToRadians

    let dLon = lon2 - lon1

    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    let radiansBearing = atan2(y, x)

    return radiansBearing.radiansToDegrees
}

extension Double {
    var degreesToRadians: Double { self * .pi / 180.0 }
    var radiansToDegrees: Double { self * 180.0 / .pi }
}

