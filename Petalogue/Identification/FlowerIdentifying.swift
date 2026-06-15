//
//  FlowerIdentifying.swift
//  Petalogue
//
//  The identification contract. PlantNetService (network) is the v1 primary;
//  CreateMLClassifier (offline) drops in behind the same protocol in v1.5.
//

import UIKit

protocol FlowerIdentifying {
    func identify(_ image: UIImage) async throws -> [IdentificationResult]
}

struct IdentificationResult: Identifiable {
    let speciesID: String       // matched catalog id, or "" if not in catalog
    let commonName: String
    let latinName: String
    let confidence: Double      // 0.0–1.0

    var id: String { speciesID.isEmpty ? latinName : speciesID }

    /// Whether this result corresponds to a flower in the v1 catalog.
    var isInCatalog: Bool { !speciesID.isEmpty }
}
