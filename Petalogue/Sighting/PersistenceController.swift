//
//  PersistenceController.swift
//  Petalogue
//
//  Core Data stack with a programmatically-built model (no .xcdatamodeld),
//  so the single Sighting entity lives entirely in code.
//

import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(
            name: "Petalogue",
            managedObjectModel: PersistenceController.makeModel()
        )

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data store failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext { container.viewContext }

    // MARK: - Programmatic model

    private static func makeModel() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = "Sighting"
        entity.managedObjectClassName = NSStringFromClass(Sighting.self)
        entity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("speciesID", .stringAttributeType),
            attribute("date", .dateAttributeType),
            attribute("photoFilename", .stringAttributeType, optional: true),
            attribute("thumbnailFilename", .stringAttributeType, optional: true),
            attribute("confidence", .doubleAttributeType, defaultValue: 0.0),
            attribute("latitude", .doubleAttributeType, optional: true),
            attribute("longitude", .doubleAttributeType, optional: true),
            attribute("isPublished", .booleanAttributeType, defaultValue: false),
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        if let defaultValue {
            attribute.defaultValue = defaultValue
        }
        return attribute
    }
}
