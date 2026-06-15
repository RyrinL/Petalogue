//
//  RarityBadge.swift
//  Petalogue
//

import SwiftUI

extension Rarity {
    var color: Color {
        switch self {
        case .common: return .green
        case .rare: return .blue
        case .legendary: return .purple
        }
    }

    /// How big a celebration the reveal deserves.
    var confettiCount: Int {
        switch self {
        case .common: return 40
        case .rare: return 80
        case .legendary: return 140
        }
    }
}

struct RarityBadge: View {
    let rarity: Rarity

    var body: some View {
        Text(rarity.displayName)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(rarity.color.opacity(0.18)))
            .overlay(Capsule().stroke(rarity.color, lineWidth: 1))
            .foregroundColor(rarity.color)
    }
}
