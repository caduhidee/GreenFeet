import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationTripStore: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isTracking = false
    @Published private(set) var statusMessage = "Ready to capture trips."
    @Published private(set) var liveSamples: [GeoSample] = []
    @Published private(set) var trips: [Trip] = []
    @Published private(set) var routeSuggestions: [EcoRouteSuggestion] = []

    private let locationManager = CLLocationManager()
    private let routePlanner = EcoRoutePlanner()

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 20
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = false
    }

    var authorizationDescription: String {
        switch authorizationStatus {
        case .authorizedAlways:
            "Always"
        case .authorizedWhenInUse:
            "When In Use"
        case .denied:
            "Denied"
        case .restricted:
            "Restricted"
        case .notDetermined:
            "Not Determined"
        @unknown default:
            "Unknown"
        }
    }

    func requestLocationAccess() {
        switch authorizationStatus {
        case .notDetermined:
            statusMessage = "Requesting location access."
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            statusMessage = "Upgrading to background location access."
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            statusMessage = "Location access is already enabled."
        case .denied, .restricted:
            statusMessage = "Location access is unavailable in Settings."
        @unknown default:
            statusMessage = "Unknown location authorization state."
        }
    }

    func startTracking() {
        isTracking = true
        locationManager.allowsBackgroundLocationUpdates = true

        guard authorizationStatus == .authorizedAlways else {
            statusMessage = "Grant Always location access to enable background tracking."
            if authorizationStatus == .notDetermined {
                requestLocationAccess()
            }
            return
        }

        locationManager.startUpdatingLocation()
        statusMessage = "Tracking is running in the background."
    }

    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        statusMessage = "Tracking paused."
    }

    func clearTrips() {
        liveSamples.removeAll()
        trips.removeAll()
        routeSuggestions.removeAll()
        statusMessage = "Cleared captured trip data."
    }

    private func ingest(_ locations: [CLLocation]) {
        let samples = locations
            .filter { $0.horizontalAccuracy >= 0 }
            .map(GeoSample.init)

        guard !samples.isEmpty else { return }

        liveSamples.append(contentsOf: samples)
        liveSamples.sort { $0.timestamp < $1.timestamp }
        trips = TripGrouper.group(liveSamples)
        refreshSuggestedRoutes()
    }

    private func refreshSuggestedRoutes() {
        guard let trip = trips.last, trip.sampleCount >= 2 else {
            routeSuggestions = []
            return
        }

        Task {
            let routes = await routePlanner.recommendRoutes(from: trip.origin, to: trip.destination)
            self.routeSuggestions = routes
        }
    }
}

extension LocationTripStore: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedAlways:
            statusMessage = "Background tracking is enabled."
            if isTracking {
                manager.startUpdatingLocation()
            }
        case .authorizedWhenInUse:
            statusMessage = "Foreground tracking is enabled. Ask for Always access to continue in the background."
            if isTracking {
                manager.requestAlwaysAuthorization()
            }
        case .notDetermined:
            statusMessage = "Waiting for location permission."
        case .denied:
            statusMessage = "Location access was denied."
        case .restricted:
            statusMessage = "Location services are restricted."
        @unknown default:
            statusMessage = "Unknown location authorization state."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        ingest(locations)
        statusMessage = "Captured \(locations.count) location update\(locations.count == 1 ? "" : "s")."
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusMessage = error.localizedDescription
    }
}
