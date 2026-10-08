import CoreLocation
import Testing
@testable import Sustainable_Routes

struct TripGrouperTests {
    @Test
    func groupsSamplesIntoSeparateTripsWhenThereIsALongGap() {
        let start = Date(timeIntervalSince1970: 0)
        let samples = [
            GeoSample(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                timestamp: start,
                horizontalAccuracy: 8,
                speed: 1.2
            ),
            GeoSample(
                coordinate: CLLocationCoordinate2D(latitude: 37.7757, longitude: -122.4186),
                timestamp: start.addingTimeInterval(120),
                horizontalAccuracy: 8,
                speed: 1.3
            ),
            GeoSample(
                coordinate: CLLocationCoordinate2D(latitude: 37.8044, longitude: -122.2711),
                timestamp: start.addingTimeInterval(2 * 60 * 60),
                horizontalAccuracy: 8,
                speed: 8.0
            ),
            GeoSample(
                coordinate: CLLocationCoordinate2D(latitude: 37.8050, longitude: -122.2700),
                timestamp: start.addingTimeInterval(2 * 60 * 60 + 240),
                horizontalAccuracy: 8,
                speed: 8.1
            )
        ]

        let config = TripGrouper.Configuration(
            maximumPauseBetweenSamples: 30 * 60,
            minimumDistanceToSplitTrips: 50_000,
            minimumTripSampleCount: 2,
            walkingSpeedThreshold: 2.0,
            cyclingSpeedThreshold: 7.0
        )

        let trips = TripGrouper.group(samples, configuration: config)

        #expect(trips.count == 2)
        #expect(trips.first?.dominantMode == .walking)
    }

    @Test
    func infersCyclingForModerateMovement() {
        let start = Date(timeIntervalSince1970: 0)
        let samples = [
            GeoSample(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                timestamp: start,
                horizontalAccuracy: 8,
                speed: 4.5
            ),
            GeoSample(
                coordinate: CLLocationCoordinate2D(latitude: 37.7790, longitude: -122.4140),
                timestamp: start.addingTimeInterval(300),
                horizontalAccuracy: 8,
                speed: 4.5
            )
        ]

        let mode = TripGrouper.inferredMode(for: samples)

        #expect(mode == .cycling)
    }
}
