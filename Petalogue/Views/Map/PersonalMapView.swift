//
//  PersonalMapView.swift
//  Petalogue
//
//  Exact-location map of the user's own discoveries (those with coordinates).
//

import MapKit
import SwiftUI

struct PersonalMapView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)])
    private var sightings: FetchedResults<Sighting>

    // Default to Nanjing — the catalog's home region.
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.7969),
        span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
    )

    private var pins: [SightingPin] {
        sightings.compactMap { sighting in
            guard let coordinate = sighting.coordinate else { return nil }
            return SightingPin(
                id: sighting.id,
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
                flower: CatalogService.shared.flower(id: sighting.speciesID)
            )
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if pins.isEmpty {
                    ContentUnavailable(
                        title: "No places yet",
                        message: "Turn on “Record where I found it” when you confirm a flower, and your finds will appear here.",
                        systemImage: "mappin.slash"
                    )
                } else {
                    Map(coordinateRegion: $region, annotationItems: pins) { pin in
                        MapAnnotation(coordinate: pin.coordinate) {
                            VStack(spacing: 2) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(pin.flower?.rarity.color ?? .accentColor)
                                if let name = pin.flower?.commonName {
                                    Text(name)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 4)
                                        .background(Capsule().fill(.thinMaterial))
                                }
                            }
                        }
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .navigationTitle("My Map")
        }
    }
}

private struct SightingPin: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let flower: Flower?
}

private struct ContentUnavailable: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(title).font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
