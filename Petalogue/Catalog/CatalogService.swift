//
//  CatalogService.swift
//  Petalogue
//
//  Decodes the bundled flowers.json once at launch and provides lookups.
//

import Foundation

final class CatalogService {
    static let shared = CatalogService()

    /// All catalog flowers, in the order they appear in flowers.json.
    let flowers: [Flower]

    private let byID: [String: Flower]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "flowers", withExtension: "json") else {
            fatalError("CatalogService: flowers.json not found in bundle.")
        }
        do {
            let data = try Data(contentsOf: url)
            self.flowers = try JSONDecoder().decode([Flower].self, from: data)
        } catch {
            fatalError("CatalogService: failed to decode flowers.json — \(error)")
        }
        self.byID = Dictionary(uniqueKeysWithValues: flowers.map { ($0.id, $0) })
    }

    /// Catalog entry for a given species id (Flower.id), if it exists.
    func flower(id: String) -> Flower? {
        byID[id]
    }

    /// Matches a Pl@ntNet latin name to a catalog entry by normalized comparison.
    /// Synonyms can be added to the catalog later if a real mismatch appears.
    func match(latinName: String) -> Flower? {
        let normalized = latinName
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return flowers.first { $0.latinName.lowercased() == normalized }
    }
}
