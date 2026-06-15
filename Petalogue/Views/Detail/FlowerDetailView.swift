//
//  FlowerDetailView.swift
//  Petalogue
//
//  The flower's story plus the user's own sightings of it.
//

import SwiftUI

struct FlowerDetailView: View {
    let flower: Flower
    var isRepeatFind: Bool = false

    @FetchRequest private var sightings: FetchedResults<Sighting>

    init(flower: Flower, isRepeatFind: Bool = false) {
        self.flower = flower
        self.isRepeatFind = isRepeatFind
        let request = Sighting.fetchRequest()
        request.predicate = NSPredicate(format: "speciesID == %@", flower.id)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        _sightings = FetchRequest(fetchRequest: request)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isRepeatFind {
                    Label("You've found this one before!", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                }

                header

                story

                if !sightings.isEmpty {
                    sightingsSection
                }
            }
            .padding()
        }
        .navigationTitle(flower.commonName)
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            catalogImage
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flower.chineseName).font(.title3)
                    Text(flower.latinName).font(.subheadline.italic()).foregroundColor(.secondary)
                    Text(flower.family).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                RarityBadge(rarity: flower.rarity)
            }
        }
    }

    private var story: some View {
        VStack(alignment: .leading, spacing: 16) {
            StorySection(title: "Flower Language", icon: "quote.bubble", text: flower.flowerLanguage)
            StorySection(title: "Symbolism", icon: "sparkles", text: flower.symbolism)
            StorySection(title: "History", icon: "book", text: flower.history)
            StorySection(title: "Fun Fact", icon: "lightbulb", text: flower.funFact)
            StorySection(title: "Care Tip", icon: "drop", text: flower.careTip)
        }
    }

    private var sightingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your sightings (\(sightings.count))")
                .font(.headline)
            ForEach(sightings) { sighting in
                SightingRow(sighting: sighting)
            }
        }
    }

    @ViewBuilder
    private var catalogImage: some View {
        if UIImage(named: flower.catalogImageName) != nil {
            Image(flower.catalogImageName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground))
                Image(systemName: "leaf.fill")
                    .font(.system(size: 56))
                    .foregroundColor(flower.rarity.color)
            }
        }
    }
}

private struct StorySection: View {
    let title: String
    let icon: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundColor(.accentColor)
            Text(text)
                .font(.body)
        }
    }
}

private struct SightingRow: View {
    let sighting: Sighting

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(sighting.date, style: .date)
                    .font(.subheadline)
                if sighting.hasLocation {
                    Label("Location saved", systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let name = sighting.thumbnailFilename ?? sighting.photoFilename,
           let image = PhotoStore.shared.load(filename: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color(.tertiarySystemBackground)
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }
        }
    }
}
