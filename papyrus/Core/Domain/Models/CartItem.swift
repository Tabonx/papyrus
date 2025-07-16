//
//  CartItem.swift
//  papyrus
//
//  Created by Pavel Kroupa on 16.07.2025.
//

import Foundation

struct CartItem: Identifiable, Equatable {
    let id = UUID()
    let itemId: UUID
    let name: String
    let unitPrice: Decimal
    let taxRate: Double
    var quantity: Int

    var subtotal: Decimal {
        unitPrice * Decimal(quantity)
    }

    var taxAmount: Decimal {
        subtotal * Decimal(taxRate / 100.0)
    }

    var total: Decimal {
        subtotal + taxAmount
    }

    // Simple formatting
    var formattedUnitPrice: String {
        unitPrice.formatted(.currency(code: "CZK").presentation(.narrow).rounded())
    }

    var formattedSubtotal: String {
        subtotal.formatted(.currency(code: "CZK").presentation(.narrow).rounded())
    }

    var formattedTotal: String {
        total.formatted(.currency(code: "CZK").presentation(.narrow).rounded())
    }
}
