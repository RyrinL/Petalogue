//
//  Flower.swift
//  Petalogue
//
//  Read-only catalog model, decoded from flowers.json.
//

import Foundation

struct Flower: Codable, Identifiable {
    let id: String                  // kebab-case latin, e.g. "prunus-mume"
    let commonName: String
    let chineseName: String
    let latinName: String
    let family: String
    let rarity: Rarity
    let catalogImageName: String    // Asset name, matches id
    let flowerLanguage: String
    let history: String
    let symbolism: String
    let funFact: String
    let careTip: String
    let tags: [String]
}

enum Rarity: String, Codable, CaseIterable {
    case common
    case rare
    case legendary

    /// Sort weight — rarer flowers surface later in the Floradex.
    var sortOrder: Int {
        switch self {
        case .common: return 0
        case .rare: return 1
        case .legendary: return 2
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}
