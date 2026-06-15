//
//  LocationProvider.swift
//  Petalogue
//
//  One-shot "where am I" helper for opt-in location tagging of a sighting.
//

import CoreLocation

final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Requests a single location fix. Returns nil if denied or unavailable.
    func requestOneShot() async -> CLLocationCoordinate2D? {
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            return nil
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            if status == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            resume(with: nil)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        resume(with: locations.first?.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(with: nil)
    }

    private func resume(with coordinate: CLLocationCoordinate2D?) {
        continuation?.resume(returning: coordinate)
        continuation = nil
    }
}
