//
//  PersistenceController.swift
//  papyrus
//
//  Created by Pavel Kroupa on 16.07.2025.
//

import CoreData
import Dependencies

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
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

extension DependencyValues {
    var persistenceController: PersistenceController {
        get { self[PersistenceControllerKey.self] }
        set { self[PersistenceControllerKey.self] = newValue }
    }
}

private enum PersistenceControllerKey: DependencyKey {
    static let liveValue = PersistenceController.shared
}
