//
//  ContentView.swift
//  Sustainable Routes
//
//  Created by Caiden Hyde on 5/13/26.
//

import CoreLocation
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: LocationTripStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    controlsCard
                    statsCard

                    if store.trips.isEmpty {
                        emptyStateCard
                    } else {
                        tripsCard
                        routeCard
                    }
                }
                .padding()
            }
            .navigationTitle("Sustainable Routes")
        }
    }

    private var headerCard: some View {
        InfoCard {
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Trip detection is ready")
                        .font(.headline)
                    Text(store.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    private var controlsCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tracking controls")
                    .font(.headline)

                HStack(spacing: 12) {
                    Button {
                        store.requestLocationAccess()
                    } label: {
                        Label("Permissions", systemImage: "location.shield")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        store.isTracking ? store.stopTracking() : store.startTracking()
                    } label: {
                        Label(store.isTracking ? "Stop" : "Start", systemImage: store.isTracking ? "pause.circle.fill" : "play.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        store.clearTrips()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }

                Text("Authorization: \(store.authorizationDescription)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statsCard: some View {
        HStack(spacing: 12) {
            StatPill(title: "Trips", value: "\(store.trips.count)")
            StatPill(title: "Samples", value: "\(store.liveSamples.count)")
            StatPill(title: "Tracking", value: store.isTracking ? "On" : "Off")
        }
    }

    private var emptyStateCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No trips captured yet")
                    .font(.headline)
                Text("Grant location access, then start tracking. The app will group your background location samples into trips and compare eco-friendly route options for each trip.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var tripsCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Captured trips")
                    .font(.headline)

                ForEach(Array(store.trips.enumerated()), id: \.element.id) { index, trip in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Trip \(store.trips.count - index)")
                                    .font(.subheadline.weight(.semibold))
                                Text(trip.startDate.formatted(date: .abbreviated, time: .shortened) + " • " + trip.endDate.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Label(trip.dominantMode.displayName, systemImage: trip.dominantMode.symbolName)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.thinMaterial, in: Capsule())
                        }

                        HStack(spacing: 16) {
                            TripMetric(label: "Distance", value: trip.totalDistance.shortDistanceDescription)
                            TripMetric(label: "Duration", value: trip.duration.shortDurationDescription)
                            TripMetric(label: "Samples", value: "\(trip.sampleCount)")
                        }
                    }

                    if index < store.trips.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var routeCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Eco route suggestions")
                    .font(.headline)

                if let latestTrip = store.trips.last {
                    Text("Comparing the best low-impact options for the latest trip.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if store.routeSuggestions.isEmpty {
                        Text("Route planning will appear after the app has enough points to form a completed trip.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.routeSuggestions) { suggestion in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(suggestion.mode.displayName, systemImage: suggestion.mode.symbolName)
                                        .font(.subheadline.weight(.semibold))

                                    Spacer()

                                    Text(suggestion.source)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text(suggestion.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 16) {
                                    TripMetric(label: "Distance", value: suggestion.distance.shortDistanceDescription)
                                    TripMetric(label: "ETA", value: suggestion.expectedTravelTime.shortDurationDescription)
                                }
                            }

                            if suggestion.id != store.routeSuggestions.last?.id {
                                Divider()
                            }
                        }
                    }

                    Text("Latest trip runs from \(latestTrip.startDate.formatted(date: .omitted, time: .shortened)) to \(latestTrip.endDate.formatted(date: .omitted, time: .shortened)).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct InfoCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }
}

private struct StatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct TripMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension CLLocationDistance {
    var shortDistanceDescription: String {
        if self >= 1_000 {
            return String(format: "%.1f km", self / 1_000)
        } else {
            return String(format: "%.0f m", self)
        }
    }
}

private extension TimeInterval {
    var shortDurationDescription: String {
        let totalSeconds = max(Int(self.rounded()), 0)
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }

        return "\(seconds)s"
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationTripStore())
}
