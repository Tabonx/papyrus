//
//  ReceiptService.swift
//  papyrus
//
//  Created by Pavel Kroupa on 22.07.2025.
//

import Dependencies
import Foundation

protocol ReceiptServiceProtocol {
    func createReceiptFromCart(_ cart: ShoppingCart, paymentMethod: PaymentMethod) async throws -> ReceiptDTO

    func removeItemFromReceipt(receiptItemId: UUID) async throws
}

actor ReceiptService: ReceiptServiceProtocol {
    @Dependency(\.receiptRepository) var receiptRepository
    @Dependency(\.receiptItemRepository) var receiptItemRepository
    @Dependency(\.businessRepository) var businessRepository
    @Dependency(\.issuerRepository) var issuerRepository
    @Dependency(\.date) var date

    func createReceiptFromCart(
        _ cart: ShoppingCart,
        paymentMethod: PaymentMethod,
    )
        async throws -> ReceiptDTO {
        guard await !cart.isEmpty else {
            throw ReceiptServiceError.emptyCart
        }

        guard let activeBusiness = try await businessRepository.fetchActiveBusiness() else {
            throw ReceiptServiceError.businessNotFound
        }

        guard let activeIssuer = try await issuerRepository.fetchActiveIssuer() else {
            throw ReceiptServiceError.issuerNotFound
        }

        let nextReceiptNumber = try await receiptRepository.generateNextReceiptNumber()

        var receipt = try await receiptRepository.createReceipt(
            receiptNumber: nextReceiptNumber,
            businessId: activeBusiness.id,
            issuerId: activeIssuer.id,
            paymentMethod: paymentMethod.rawValue,
            footerText: "TODO",
            legalPerformanceDate: date.now
        )

        receipt = try await receiptRepository.addReceiptItems(receipt.id, items: await cart.items)

        // Clear the cart after successful receipt creation
        await MainActor.run {
            cart.clear()
        }

        return receipt
    }

    func removeItemFromReceipt(receiptItemId: UUID) async throws {
        try await receiptItemRepository.deleteReceiptItem(receiptItemId)
    }
}
