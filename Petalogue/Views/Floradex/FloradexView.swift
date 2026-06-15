//
//  FloradexView.swift
//  Petalogue
//
//  Pokédex-style grid of the whole catalog with a completion progress bar.
//  Undiscovered flowers show as locked silhouettes.
//

import SwiftUI

struct FloradexView: View {
    private let flowers = CatalogService.shared.flowers

    @FetchRequest(sortDescriptors: []) private var sightings: FetchedResults<Sighting>

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 16)]

    private var counts: [String: Int] {
        Dictionary(grouping: sightings, by: { $0.speciesID }).mapValues { $0.count }
    }

    private var discoveredCount: Int {
        let catalogIDs = Set(flowers.map { $0.id })
        return Set(sightings.map { $0.speciesID }).intersection(catalogIDs).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                ProgressHeader(discovered: discoveredCount, total: flowers.count)
                    .padding(.horizontal)
                    .padding(.top, 8)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(flowers) { flower in
                        let count = counts[flower.id] ?? 0
                        if count > 0 {
                            NavigationLink {
                                FlowerDetailView(flower: flower)
                            } label: {
                                FloradexCard(flower: flower, count: count, discovered: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            FloradexCard(flower: flower, count: 0, discovered: false)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Floradex")
        }
    }
}

private struct ProgressHeader: View {
    let discovered: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(discovered) / \(total) discovered")
                .font(.headline)
            ProgressView(value: Double(discovered), total: Double(max(total, 1)))
                .tint(.accentColor)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}
