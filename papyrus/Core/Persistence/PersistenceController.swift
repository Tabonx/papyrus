//
//  PersistenceController.swift
//  papyrus
//
//  Created by Pavel Kroupa on 16.07.2025.
//

import CoreData
import Dependencies
import os.log

class PersistenceController: ObservableObject, @unchecked Sendable {
    static let shared = PersistenceController()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        Logger.persistence.info("Initializing Core Data stack")
        let container = NSPersistentContainer(name: "Model")

        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                Logger.persistence.error("Failed to load persistent stores: \(error.localizedDescription)")
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            } else {
                Logger.persistence.info("Persistent store loaded successfully")
                if let storeURL = storeDescription.url {
                    Logger.persistence.info("Store URL: \(storeURL.absoluteString)")
                }
            }
        }

        Logger.persistence.info("Core Data stack initialized")

        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private var _backgroundContext: NSManagedObjectContext?

    var backgroundContext: NSManagedObjectContext {
        if let _backgroundContext {
            return _backgroundContext
        }

        let newContext = createBackgroundContext()

        _backgroundContext = newContext

        return newContext
    }

    private func createBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.name = "Background Context"

        return context
    }
}

extension NSManagedObjectContext: @unchecked @retroactive Sendable {}

extension DependencyValues {
    var persistenceController: PersistenceController {
        get { self[PersistenceControllerKey.self] }
        set { self[PersistenceControllerKey.self] = newValue }
    }
}

private enum PersistenceControllerKey: DependencyKey {
    static let liveValue = PersistenceController.shared
}
