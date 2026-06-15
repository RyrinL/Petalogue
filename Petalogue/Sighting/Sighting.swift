//
//  Sighting.swift
//  Petalogue
//
//  Private, on-device record of a single flower find. Core Data-backed
//  (SwiftData requires iOS 17; the app targets iOS 16.4).
//  "Discovered" == at least one Sighting exists for a speciesID.
//

import CoreData

@objc(Sighting)
final class Sighting: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var speciesID: String            // FK → Flower.id
    @NSManaged var date: Date
    @NSManaged var photoFilename: String?       // nil = no photo saved
    @NSManaged var thumbnailFilename: String?   // generated at save time
    @NSManaged var confidence: Double           // 0.0–1.0 from classifier
    @NSManaged var latitude: NSNumber?          // optional → Double via `coordinate`
    @NSManaged var longitude: NSNumber?
    @NSManaged var isPublished: Bool            // for v2 global map
}

extension Sighting {
    static func fetchRequest() -> NSFetchRequest<Sighting> {
        NSFetchRequest<Sighting>(entityName: "Sighting")
    }

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    /// Decoded coordinate, or nil if this sighting has no location.
    var coordinate: (latitude: Double, longitude: Double)? {
        guard let lat = latitude?.doubleValue, let lng = longitude?.doubleValue else { return nil }
        return (lat, lng)
    }

    /// Inserts a new Sighting into the given context. Call context.save() to persist.
    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        speciesID: String,
        date: Date = .now,
        photoFilename: String? = nil,
        thumbnailFilename: String? = nil,
        confidence: Double = 0,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isPublished: Bool = false
    ) -> Sighting {
        let sighting = Sighting(context: context)
        sighting.id = UUID()
        sighting.speciesID = speciesID
        sighting.date = date
        sighting.photoFilename = photoFilename
        sighting.thumbnailFilename = thumbnailFilename
        sighting.confidence = confidence
        sighting.latitude = latitude.map(NSNumber.init(value:))
        sighting.longitude = longitude.map(NSNumber.init(value:))
        sighting.isPublished = isPublished
        return sighting
    }
}
