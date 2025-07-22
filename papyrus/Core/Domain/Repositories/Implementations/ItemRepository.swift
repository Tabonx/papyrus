//
//  ItemRepository.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Dependencies

actor ItemRepository: ItemRepositoryProtocol {
    @Dependency(\.persistenceController) var persistenceController

    func fetchAllItems() async throws -> [ItemDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Item.fetchAllItems()
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func fetchItems(searchText: String?) async throws -> [ItemDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Item.fetchItems(searchText: searchText)
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func fetchItem(withId itemId: UUID) async throws -> ItemDTO? {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Item.fetchItem(withId: itemId)
            return try context.fetch(request).first?.toDTO()
        }
    }

    func fetchRecentlyModifiedItems(limit: Int) async throws -> [ItemDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Item.fetchRecentlyModifiedItems(limit: limit)
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func createItem(name: String, price: Decimal, taxRate: Double) async throws -> ItemDTO {
        let context = persistenceController.backgroundContext
        @Dependency(\.date) var date

        return try await context.perform {
            let item = Item(context: context)
            item.id = UUID()
            item.name = name
            item.price = price
            item.taxRate = taxRate
            item.createdAt = date.now
            item.updatedAt = date.now

            try context.save()
            return item.toDTO()
        }
    }

    func updateItem(_ itemID: UUID, name: String?, price: Decimal?, taxRate: Double?) async throws -> ItemDTO {
        let context = persistenceController.backgroundContext
        @Dependency(\.date) var date

        return try await context.perform {
            let itemRequest = Item.fetchItem(withId: itemID)

            guard let contextItem = try context.fetch(itemRequest).first else { throw RepositoryError.itemNotFound }

            // Update properties if provided
            if let name = name {
                contextItem.name = name
            }
            if let price = price {
                contextItem.price = price
            }
            if let taxRate = taxRate {
                contextItem.taxRate = taxRate
            }

            contextItem.updatedAt = date.now

            try context.save()

            return contextItem.toDTO()
        }
    }

    func deleteItem(_ itemID: UUID) async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {
            let itemRequest = Item.fetchItem(withId: itemID)

            guard let contextItem = try context.fetch(itemRequest).first else { throw RepositoryError.itemNotFound }

            context.delete(contextItem)
            try context.save()
        }
    }

    func deleteItems(withIds itemIds: [UUID]) async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = Item.fetchRequest()
            request.sortDescriptors = []
            request.predicate = NSPredicate(format: "id_ IN %@", itemIds)

            let itemsToDelete = try context.fetch(request)
            for item in itemsToDelete {
                context.delete(item)
            }

            try context.save()
        }
    }
}

extension DependencyValues {
    var itemRepository: ItemRepositoryProtocol {
        get { self[ItemRepositoryKey.self] }
        set { self[ItemRepositoryKey.self] = newValue }
    }
}

private enum ItemRepositoryKey: DependencyKey {
    static let liveValue: any ItemRepositoryProtocol = ItemRepository()
}
