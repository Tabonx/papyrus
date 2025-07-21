//
//  ReceiptItemRepository.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Dependencies

actor ReceiptItemRepository: ReceiptItemRepositoryProtocol {
    @Dependency(\.date) var date
    @Dependency(\.persistenceController) var persistenceController

    func fetchReceiptItem(withId receiptItemId: UUID) async throws -> ReceiptItemDTO? {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = ReceiptItem.fetchReceiptItem(withId: receiptItemId)
            return try context.fetch(request).first?.toDTO()
        }
    }

    func fetchAllReceiptItems() async throws -> [ReceiptItemDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = ReceiptItem.fetchAllReceiptItems()
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func fetchReceiptItems(from startDate: Date, to endDate: Date) async throws -> [ReceiptItemDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = ReceiptItem.fetchReceiptItems(from: startDate, to: endDate)
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func fetchReceiptItems(for itemId: UUID) async throws -> [ReceiptItemDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = ReceiptItem.fetchReceiptItems(for: itemId)
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func createReceiptItem(
        receiptId: UUID,
        itemName: String,
        unitPrice: Decimal,
        quantity: Int,
        taxRate: Double,
        order: Int,
        linkedItemId: UUID?
    )
        async throws -> ReceiptItemDTO {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            // First, find the receipt
            let receiptRequest = Receipt.fetchReceipt(withID: receiptId)
            guard let receipt = try context.fetch(receiptRequest).first else {
                throw RepositoryError.receiptNotFound
            }

            // Find linked item if provided
            var linkedItem: Item?
            if let linkedItemId = linkedItemId {
                let itemRequest = Item.fetchItem(withId: linkedItemId)
                linkedItem = try context.fetch(itemRequest).first
            }

            // Create the receipt item
            let receiptItem = ReceiptItem(context: context)
            receiptItem.id = UUID()
            receiptItem.itemName = itemName
            receiptItem.unitPrice = unitPrice
            receiptItem.quantity = quantity
            receiptItem.taxRate = taxRate
            receiptItem.order = order
            receiptItem.receipt = receipt
            receiptItem.item = linkedItem

            try context.save()
            return receiptItem.toDTO()
        }
    }

    func updateReceiptItem(
        _ receiptItemId: UUID,
        itemName: String?,
        unitPrice: Decimal?,
        quantity: Int?,
        taxRate: Double?,
        order: Int?,
        linkedItemId: UUID?
    )
        async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = ReceiptItem.fetchReceiptItem(withId: receiptItemId)
            guard let receiptItem = try context.fetch(request).first else {
                throw RepositoryError.itemNotFound
            }

            if let itemName = itemName {
                receiptItem.itemName = itemName
            }
            if let unitPrice = unitPrice {
                receiptItem.unitPrice = unitPrice
            }
            if let quantity = quantity {
                receiptItem.quantity = quantity
            }
            if let taxRate = taxRate {
                receiptItem.taxRate = taxRate
            }
            if let order = order {
                receiptItem.order = order
            }

            // Update linked item if provided
            if let linkedItemId = linkedItemId {
                let itemRequest = Item.fetchItem(withId: linkedItemId)
                receiptItem.item = try context.fetch(itemRequest).first
            }

            try context.save()
        }
    }

    func deleteReceiptItem(_ receiptItemId: UUID) async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = ReceiptItem.fetchReceiptItem(withId: receiptItemId)
            guard let receiptItem = try context.fetch(request).first else {
                throw RepositoryError.itemNotFound
            }

            context.delete(receiptItem)
            try context.save()
        }
    }

    func deleteAllReceiptItems(for receiptId: UUID) async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = ReceiptItem.fetchReceiptItems(for: receiptId)
            let itemsToDelete = try context.fetch(request)

            for item in itemsToDelete {
                context.delete(item)
            }

            try context.save()
        }
    }
}

extension DependencyValues {
    var receiptItemRepository: ReceiptItemRepositoryProtocol {
        get { self[ReceiptItemRepositoryKey.self] }
        set { self[ReceiptItemRepositoryKey.self] = newValue }
    }
}

private enum ReceiptItemRepositoryKey: DependencyKey {
    static let liveValue: any ReceiptItemRepositoryProtocol = ReceiptItemRepository()
}
