//
//  FloradexCard.swift
//  Petalogue
//

import SwiftUI

struct FloradexCard: View {
    let flower: Flower
    let count: Int
    let discovered: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))

                if discovered {
                    image
                } else {
                    Image(systemName: "questionmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .frame(height: 110)
            .overlay(alignment: .topTrailing) {
                if discovered {
                    RarityDot(rarity: flower.rarity)
                        .padding(6)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if count > 1 {
                    Text("×\(count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.thinMaterial))
                        .padding(6)
                }
            }

            Text(discovered ? flower.commonName : "???")
                .font(.subheadline)
                .lineLimit(1)
                .foregroundColor(discovered ? .primary : .secondary)
        }
    }

    @ViewBuilder
    private var image: some View {
        if UIImage(named: flower.catalogImageName) != nil {
            Image(flower.catalogImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            Image(systemName: "leaf.fill")
                .font(.system(size: 36))
                .foregroundColor(flower.rarity.color)
        }
    }
}

private struct RarityDot: View {
    let rarity: Rarity

    var body: some View {
        Circle()
            .fill(rarity.color)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(.white, lineWidth: 1.5))
    }
}
