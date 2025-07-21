//
//  ReceiptRepository.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Dependencies

actor ReceiptRepository: ReceiptRepositoryProtocol {
    @Dependency(\.date) var date
    @Dependency(\.persistenceController) var persistenceController

    func fetchAllReceipts() async throws -> [ReceiptDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Receipt.fetchAllReceipts()
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func fetchReceipts(from startDate: Date, to endDate: Date) async throws -> [ReceiptDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Receipt.fetchReceipts(from: startDate, to: endDate)
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func fetchTodaysReceipts() async throws -> [ReceiptDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Receipt.fetchTodaysReceipts()
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func fetchCurrentMonthReceipts() async throws -> [ReceiptDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Receipt.fetchCurrentMonthReceipts()
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func fetchCurrentYearReceipts() async throws -> [ReceiptDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Receipt.fetchCurrentYearReceipts()
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func fetchReceipt(withId receiptId: UUID) async throws -> ReceiptDTO? {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Receipt.fetchReceipt(withID: receiptId)
            return try context.fetch(request).first?.toDTO()
        }
    }

    func fetchReceipt(withNumber receiptNumber: String) async throws -> ReceiptDTO? {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Receipt.fetchReceipt(withNumber: receiptNumber)
            return try context.fetch(request).first?.toDTO()
        }
    }

    func searchReceipts(searchText: String) async throws -> [ReceiptDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Receipt.fetchReceipts(searchText: searchText)
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func createReceipt(
        receiptNumber: String,
        businessId: UUID,
        issuerId: UUID?,
        paymentMethod: String,
        footerText: String?,
        legalPerformanceDate: Date
    )
        async throws -> ReceiptDTO {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let receipt = Receipt(context: context)
            receipt.id = UUID()
            receipt.receiptNumber = receiptNumber
            receipt.createdAt = self.date.now
            receipt.issuedDate = self.date.now
            receipt.paymentMethod = paymentMethod
            receipt.footerText = footerText
            receipt.legalPerformanceDate = legalPerformanceDate

            // Set business relationship
            let businessRequest = Business.fetchBusiness(withId: businessId)

            if let business = try context.fetch(businessRequest).first {
                receipt.business = business
            } else {
                throw RepositoryError.businessNotFound
            }

            // Set issuer relationship if provided
            if let issuerId = issuerId {
                let issuerRequest = Issuer.fetchIssuer(withId: issuerId)

                if let issuer = try context.fetch(issuerRequest).first {
                    receipt.issuer = issuer
                }
            }

            try context.save()
            return receipt.toDTO()
        }
    }

    func updateReceipt(_ receiptId: UUID, footerText: String?, paymentMethod: String?) async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = Receipt.fetchReceipt(withID: receiptId)

            guard let contextReceipt = try context.fetch(request).first else {
                throw RepositoryError.receiptNotFound
            }

            if let footerText = footerText {
                contextReceipt.footerText = footerText
            }

            if let paymentMethod = paymentMethod {
                contextReceipt.paymentMethod = paymentMethod
            }

            try context.save()
        }
    }

    func deleteReceipt(_ receiptId: UUID) async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = Receipt.fetchReceipt(withID: receiptId)

            guard let contextReceipt = try context.fetch(request).first else {
                throw RepositoryError.receiptNotFound
            }

            context.delete(contextReceipt)
            try context.save()
        }
    }

    func getTotalSales(from startDate: Date, to endDate: Date) async throws -> Decimal {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Receipt.fetchReceipts(from: startDate, to: endDate)
            let receipts = try context.fetch(request)

            return receipts.flatMap { $0.items }.reduce(Decimal(0)) { total, item in
                let itemTotal = item.unitPrice * Decimal(item.quantity)
                let tax = itemTotal * Decimal(item.taxRate)
                return total + itemTotal + tax
            }
        }
    }

    func generateNextReceiptNumber() async throws -> String {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: self.date.now)

            // Find the highest receipt number for this year
            let request = Receipt.fetchRequest()
            request.sortDescriptors = []
            request.predicate = NSPredicate(format: "receiptNumber_ BEGINSWITH %@", year)
            request.sortDescriptors = [NSSortDescriptor(key: "receiptNumber_", ascending: false)]
            request.fetchLimit = 1

            let receipts = try context.fetch(request)

            if let lastReceipt = receipts.first,
               lastReceipt.receiptNumber.hasPrefix(year),
               let sequenceString = String(lastReceipt.receiptNumber.dropFirst(4)).nilIfEmpty,
               let sequence = Int(sequenceString) {
                let nextSequence = sequence + 1
                return String(format: "%@%06d", year, nextSequence)
            } else {
                // First receipt of the year
                return String(format: "%@%06d", year, 1)
            }
        }
    }

    func receiptNumberExists(_ receiptNumber: String) async throws -> Bool {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Receipt.fetchReceipt(withNumber: receiptNumber)

            let count = try context.count(for: request)
            return count > 0
        }
    }

    func addReceiptItems(_ receiptId: UUID, items: [CartItem]) async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {

            let receiptRequest = Receipt.fetchReceipt(withID: receiptId)

            guard let receipt = try context.fetch(receiptRequest).first else {
                throw RepositoryError.receiptNotFound
            }

            // Create receipt items
            for (index, cartItem) in items.enumerated() {
                let receiptItem = ReceiptItem(context: context)
                receiptItem.id = UUID()
                receiptItem.itemName = cartItem.name
                receiptItem.unitPrice = cartItem.unitPrice
                receiptItem.quantity = cartItem.quantity
                receiptItem.taxRate = cartItem.taxRate
                receiptItem.order = index
                receiptItem.receipt = receipt

                // Link to original item if it exists

                let itemRequest = Item.fetchItem(withId: cartItem.itemId)

                if let originalItem = try context.fetch(itemRequest).first {
                    receiptItem.item = originalItem
                }
            }

            try context.save()
        }
    }
}

extension DependencyValues {
    var receiptRepository: ReceiptRepositoryProtocol {
        get { self[ReceiptRepositoryKey.self] }
        set { self[ReceiptRepositoryKey.self] = newValue }
    }
}

private enum ReceiptRepositoryKey: DependencyKey {
    static let liveValue: any ReceiptRepositoryProtocol = ReceiptRepository()
}
