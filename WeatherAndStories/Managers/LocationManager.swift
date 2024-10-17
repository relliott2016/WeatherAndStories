//
//  LocationManager.swift
//  WeatherAndStories
//
//  Created by Robbie Elliott on 2024-10-10.
//

import SwiftUI
import CoreLocation

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let manager: CLLocationManager
    var lastLocation: CLLocation?
    private(set) var isLocationObtained = false
    private(set) var isProcessComplete = false
    private(set) var authorizationStatus: CLAuthorizationStatus
    private var isConnected: Bool = true

    private override init() {
        self.manager = CLLocationManager()
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        setupManager()
    }

    private func setupManager() {
        print("LocationManager: Setting up")
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func refreshLocation(isConnected: Bool) {
        self.isConnected = isConnected
        isProcessComplete = false
        if isConnected {
            checkLocationAuthorization()
        } else {
            print("LocationManager: Not starting location updates due to no network connection")
        }
    }

    private func checkLocationAuthorization() {
        guard !isProcessComplete && isConnected else { return }
        print("LocationManager: Checking authorization status - \(authorizationStatus.rawValue)")

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location access was denied.")
            completeProcess()
        case .authorizedAlways, .authorizedWhenInUse:
            requestLocation()
        @unknown default:
            break
        }
    }

    private func requestLocation() {
        guard !isProcessComplete && isConnected else { return }
        #if targetEnvironment(simulator)
        self.lastLocation = CLLocation(latitude: 47.4979, longitude: 19.0402) // Budapest, Hungary
        print("LocationManager: Using simulated location")
        self.isLocationObtained = true
        completeProcess()
        #else
        manager.requestLocation()
        #endif
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("LocationManager: Authorization status changed to \(authorizationStatus.rawValue)")
        checkLocationAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, !isProcessComplete else { return }
        lastLocation = location
        isLocationObtained = true
        print("LocationManager: Location updated to \(location.coordinate.latitude), \(location.coordinate.longitude)")
        completeProcess()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager Error: \(error.localizedDescription)")
        completeProcess()
    }

    private func completeProcess() {
        isProcessComplete = true
        manager.stopUpdatingLocation()
        print("LocationManager: Process completed and services stopped")
    }

    func stopLocationUpdates() {
        isProcessComplete = true
        manager.stopUpdatingLocation()
        print("LocationManager: Location updates stopped")
    }
}
