//
//  ReceiptItemRepositoryProtocol.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import Foundation

protocol ReceiptItemRepositoryProtocol {
    func fetchReceiptItems(for receiptId: UUID) async throws -> [ReceiptItemDTO]

    func fetchReceiptItem(withId receiptItemId: UUID) async throws -> ReceiptItemDTO?

    func fetchAllReceiptItems() async throws -> [ReceiptItemDTO]

    func fetchReceiptItems(from startDate: Date, to endDate: Date) async throws -> [ReceiptItemDTO]

    func createReceiptItem(
        receiptId: UUID,
        itemName: String,
        unitPrice: Decimal,
        quantity: Int,
        taxRate: Double,
        order: Int,
        linkedItemId: UUID?
    )
        async throws -> ReceiptItemDTO

    func updateReceiptItem(
        _ receiptItemId: UUID,
        itemName: String?,
        unitPrice: Decimal?,
        quantity: Int?,
        taxRate: Double?,
        order: Int?,
        linkedItemId: UUID?
    )
        async throws

    func deleteReceiptItem(_ receiptItemId: UUID) async throws
}
