//
//  ScanCoordinator.swift
//  Petalogue
//
//  Drives the scan → identify → confirm → reveal/repeat flow and performs
//  the Core Data insert. firstDiscovery is checked BEFORE inserting.
//

import CoreData
import CoreLocation
import UIKit

@MainActor
final class ScanCoordinator: ObservableObject {
    enum Stage: Equatable {
        case idle
        case identifying
        case results
        case reveal
        case repeatFind
    }

    @Published var stage: Stage = .idle
    @Published var capturedImage: UIImage?
    @Published var results: [IdentificationResult] = []
    @Published var confirmedFlower: Flower?
    @Published var errorMessage: String?

    private let identifier: FlowerIdentifying
    private let photoStore: PhotoStoring
    private let catalog: CatalogService

    init(
        identifier: FlowerIdentifying = PlantNetService(),
        photoStore: PhotoStoring = PhotoStore.shared,
        catalog: CatalogService = .shared
    ) {
        self.identifier = identifier
        self.photoStore = photoStore
        self.catalog = catalog
    }

    var isPresenting: Bool { stage != .idle }

    func handle(_ image: UIImage) async {
        capturedImage = image
        stage = .identifying
        do {
            results = try await identifier.identify(image)
            stage = .results
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            stage = .idle
        }
    }

    func confirm(
        _ result: IdentificationResult,
        savePhoto: Bool,
        coordinate: CLLocationCoordinate2D?,
        context: NSManagedObjectContext
    ) {
        guard let flower = catalog.flower(id: result.speciesID) else { return }

        let isFirstDiscovery = !hasSighting(speciesID: flower.id, in: context)

        var photoName: String?
        var thumbName: String?
        if savePhoto, let image = capturedImage,
           let saved = try? photoStore.save(image, for: flower.id) {
            photoName = saved.photo
            thumbName = saved.thumb
        }

        Sighting.create(
            in: context,
            speciesID: flower.id,
            photoFilename: photoName,
            thumbnailFilename: thumbName,
            confidence: result.confidence,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude
        )
        try? context.save()

        confirmedFlower = flower
        stage = isFirstDiscovery ? .reveal : .repeatFind
    }

    func reset() {
        stage = .idle
        capturedImage = nil
        results = []
        confirmedFlower = nil
        errorMessage = nil
    }

    private func hasSighting(speciesID: String, in context: NSManagedObjectContext) -> Bool {
        let request = Sighting.fetchRequest()
        request.predicate = NSPredicate(format: "speciesID == %@", speciesID)
        request.fetchLimit = 1
        let count = (try? context.count(for: request)) ?? 0
        return count > 0
    }
}
