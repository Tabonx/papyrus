//
//  ReceiptDTO.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Foundation

struct ReceiptDTO: Identifiable, Hashable {
    let id: UUID
    let receiptNumber: String
    let createdAt: Date
    let issuedDate: Date
    let legalPerformanceDate: Date?
    let paymentMethod: String
    let footerText: String?
    let issuedBy: String?

    let businessId: UUID
    let issuerId: UUID?
    let items: [ReceiptItemDTO]

    var subtotal: Decimal {
        items.reduce(0) { $0 + $1.subtotal }
    }

    var totalTax: Decimal {
        items.reduce(0) { $0 + $1.taxAmount }
    }

    var total: Decimal {
        subtotal + totalTax
    }

    var formattedSubtotal: String {
        subtotal.formatted(.currency(code: "CZK").presentation(.narrow))
    }

    var formattedTotalTax: String {
        totalTax.formatted(.currency(code: "CZK").presentation(.narrow))
    }

    var formattedTotal: String {
        total.formatted(.currency(code: "CZK").presentation(.narrow))
    }

    var formattedCreatedAt: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    var formattedIssuedDate: String {
        issuedDate.formatted(date: .abbreviated, time: .omitted)
    }

    var paymentMethodDisplayName: String {
        PaymentMethod(rawValue: paymentMethod)?.displayName ?? paymentMethod.capitalized
    }
}

extension ReceiptDTO {
    init(from receipt: Receipt) {
        id = receipt.id
        receiptNumber = receipt.receiptNumber
        createdAt = receipt.createdAt
        issuedDate = receipt.issuedDate
        legalPerformanceDate = receipt.legalPerformanceDate
        paymentMethod = receipt.paymentMethod
        footerText = receipt.footerText
        issuedBy = receipt.issuedBy
        businessId = receipt.business?.id ?? UUID()
        issuerId = receipt.issuer?.id
        items = receipt.items.map { ReceiptItemDTO(from: $0) }
    }
}

enum PaymentMethod: String, CaseIterable {
    case cash
    case card
    case both

    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .card: return "Card"
        case .both: return "Cash + Card"
        }
    }
}
