import CoreLocation
import Foundation
import MapKit

@MainActor
final class EcoRoutePlanner {
    func recommendRoutes(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> [EcoRouteSuggestion] {
        async let walking = mapKitSuggestion(for: .walking, origin: origin, destination: destination)
        async let transit = mapKitSuggestion(for: .transit, origin: origin, destination: destination)
        let cycling = Self.estimatedCyclingSuggestion(from: origin, to: destination)

        return await [walking, transit, cycling]
            .compactMap { $0 }
            .sorted { $0.expectedTravelTime < $1.expectedTravelTime }
    }

    static func estimatedCyclingSuggestion(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> EcoRouteSuggestion {
        let distance = distance(from: origin, to: destination)
        let estimatedTime = max(distance / EcoTransportMode.cycling.estimatedAverageSpeed, 60)
        return EcoRouteSuggestion(
            mode: .cycling,
            distance: distance,
            expectedTravelTime: estimatedTime,
            source: "Estimate",
            summary: "Estimated cycling option based on straight-line distance.",
            polyline: nil
        )
    }

    private func mapKitSuggestion(for mode: EcoTransportMode, origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) async -> EcoRouteSuggestion? {
        guard let transportType = mode.mapKitTransportType else { return nil }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = transportType
        request.requestsAlternateRoutes = false

        do {
            let response = try await MKDirections(request: request).calculate()
            guard let route = response.routes.first else { return nil }

            return EcoRouteSuggestion(
                mode: mode,
                distance: route.distance,
                expectedTravelTime: route.expectedTravelTime,
                source: "MapKit",
                summary: "Apple Maps route for \(mode.displayName.lowercased()).",
                polyline: route.polyline
            )
        } catch {
            return nil
        }
    }

    private static func distance(from lhs: CLLocationCoordinate2D, to rhs: CLLocationCoordinate2D) -> CLLocationDistance {
        let lhsLocation = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
        let rhsLocation = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude)
        return lhsLocation.distance(from: rhsLocation)
    }
}
