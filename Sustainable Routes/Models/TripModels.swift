import CoreLocation
import Foundation
import MapKit

enum EcoTransportMode: String, CaseIterable, Identifiable {
    case walking
    case cycling
    case transit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .walking: "Walking"
        case .cycling: "Cycling"
        case .transit: "Transit"
        }
    }

    var symbolName: String {
        switch self {
        case .walking: "figure.walk"
        case .cycling: "bicycle"
        case .transit: "bus.fill"
        }
    }

    var mapKitTransportType: MKDirectionsTransportType? {
        switch self {
        case .walking:
            .walking
        case .transit:
            .transit
        case .cycling:
            nil
        }
    }

    var estimatedAverageSpeed: CLLocationSpeed {
        switch self {
        case .walking:
            1.4
        case .cycling:
            4.8
        case .transit:
            10.0
        }
    }
}

struct GeoSample: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let horizontalAccuracy: CLLocationAccuracy
    let speed: CLLocationSpeed

    init(location: CLLocation) {
        coordinate = location.coordinate
        timestamp = location.timestamp
        horizontalAccuracy = location.horizontalAccuracy
        speed = location.speed
    }

    init(coordinate: CLLocationCoordinate2D, timestamp: Date, horizontalAccuracy: CLLocationAccuracy, speed: CLLocationSpeed) {
        self.coordinate = coordinate
        self.timestamp = timestamp
        self.horizontalAccuracy = horizontalAccuracy
        self.speed = speed
    }
}

struct Trip: Identifiable {
    let id = UUID()
    let samples: [GeoSample]
    let totalDistance: CLLocationDistance
    let dominantMode: EcoTransportMode

    var startDate: Date {
        samples.first?.timestamp ?? .now
    }

    var endDate: Date {
        samples.last?.timestamp ?? .now
    }

    var origin: CLLocationCoordinate2D {
        samples.first?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    var destination: CLLocationCoordinate2D {
        samples.last?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    var duration: TimeInterval {
        max(endDate.timeIntervalSince(startDate), 0)
    }

    var averageSpeed: CLLocationSpeed {
        guard duration > 0 else { return dominantMode.estimatedAverageSpeed }
        return totalDistance / duration
    }

    var sampleCount: Int {
        samples.count
    }
}

struct EcoRouteSuggestion: Identifiable {
    let id = UUID()
    let mode: EcoTransportMode
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
    let source: String
    let summary: String
    let polyline: MKPolyline?
}

struct TripGrouper {
    struct Configuration {
        var maximumPauseBetweenSamples: TimeInterval = 15 * 60
        var minimumDistanceToSplitTrips: CLLocationDistance = 1_000
        var minimumTripSampleCount: Int = 2
        var walkingSpeedThreshold: CLLocationSpeed = 2.0
        var cyclingSpeedThreshold: CLLocationSpeed = 7.0

        static let standard = Configuration()
    }

    static func group(_ samples: [GeoSample], configuration: Configuration = .standard) -> [Trip] {
        let orderedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        guard let firstSample = orderedSamples.first else { return [] }

        var groupedSamples: [[GeoSample]] = [[firstSample]]

        for sample in orderedSamples.dropFirst() {
            guard let previous = groupedSamples.last?.last else { continue }

            let gap = sample.timestamp.timeIntervalSince(previous.timestamp)
            let distance = distance(from: previous.coordinate, to: sample.coordinate)
            let shouldSplit = gap > configuration.maximumPauseBetweenSamples || distance > configuration.minimumDistanceToSplitTrips

            if shouldSplit {
                groupedSamples.append([sample])
            } else {
                groupedSamples[groupedSamples.count - 1].append(sample)
            }
        }

        return groupedSamples.compactMap { cluster in
            guard cluster.count >= configuration.minimumTripSampleCount else { return nil }
            return Trip(
                samples: cluster,
                totalDistance: totalDistance(in: cluster),
                dominantMode: inferredMode(for: cluster, configuration: configuration)
            )
        }
    }

    static func totalDistance(in samples: [GeoSample]) -> CLLocationDistance {
        guard samples.count > 1 else { return 0 }

        return zip(samples, samples.dropFirst()).reduce(into: 0) { partialResult, pair in
            partialResult += distance(from: pair.0.coordinate, to: pair.1.coordinate)
        }
    }

    static func inferredMode(for samples: [GeoSample], configuration: Configuration = .standard) -> EcoTransportMode {
        guard samples.count > 1 else { return .walking }

        let duration = max(samples.last!.timestamp.timeIntervalSince(samples.first!.timestamp), 1)
        let totalDistanceMeters = totalDistance(in: samples)
        let averageSpeed = totalDistanceMeters / duration

        if averageSpeed < configuration.walkingSpeedThreshold {
            return .walking
        }

        if averageSpeed < configuration.cyclingSpeedThreshold {
            return .cycling
        }

        return .transit
    }

    private static func distance(from lhs: CLLocationCoordinate2D, to rhs: CLLocationCoordinate2D) -> CLLocationDistance {
        let lhsLocation = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
        let rhsLocation = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude)
        return lhsLocation.distance(from: rhsLocation)
    }
}
