//
//  ReceiptRepositoryProtocol 2.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import Foundation

protocol ReceiptRepositoryProtocol: Sendable {
    func fetchAllReceipts() async throws -> [ReceiptDTO]
    func fetchReceipts(from startDate: Date, to endDate: Date) async throws -> [ReceiptDTO]
    func fetchTodaysReceipts() async throws -> [ReceiptDTO]
    func fetchCurrentMonthReceipts() async throws -> [ReceiptDTO]
    func fetchCurrentYearReceipts() async throws -> [ReceiptDTO]
    func fetchReceipt(withId receiptId: UUID) async throws -> ReceiptDTO?
    func fetchReceipt(withNumber receiptNumber: String) async throws -> ReceiptDTO?
    func searchReceipts(searchText: String) async throws -> [ReceiptDTO]
    func createReceipt(
        receiptNumber: String,
        businessId: UUID,
        issuerId: UUID?,
        paymentMethod: String,
        footerText: String?,
        legalPerformanceDate: Date
    )
        async throws -> ReceiptDTO
    func updateReceipt(_ receiptId: UUID, footerText: String?, paymentMethod: String?) async throws -> ReceiptDTO
    func deleteReceipt(_ receiptId: UUID) async throws
    func getTotalSales(from startDate: Date, to endDate: Date) async throws -> Decimal
    func generateNextReceiptNumber() async throws -> String
    func receiptNumberExists(_ receiptNumber: String) async throws -> Bool
    func addReceiptItems(_ receiptId: UUID, items: [ReceiptItemDTO]) async throws -> ReceiptDTO
}
