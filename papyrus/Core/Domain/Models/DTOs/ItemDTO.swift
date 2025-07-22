//
//  ItemDTO 2.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Foundation

struct ItemDTO: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let price: Decimal
    let taxRate: Double
    let createdAt: Date
    let updatedAt: Date

    var formattedPrice: String {
        price.formatted(.currency(code: "CZK").presentation(.narrow))
    }

    /// Tax rate as percentage for display (21% instead of 0.21)
    var taxRatePercentage: Double {
        taxRate * 100
    }

    var formattedTaxRate: String {
        String(format: "%.1f%%", taxRatePercentage)
    }

    var taxAmountPerUnit: Decimal {
        price * Decimal(taxRate)
    }

    var priceIncludingTax: Decimal {
        price + taxAmountPerUnit
    }

    var formattedPriceIncludingTax: String {
        priceIncludingTax.formatted(.currency(code: "CZK").presentation(.narrow))
    }

    func calculateTotal(quantity: Int) -> Decimal {
        let subtotal = price * Decimal(quantity)
        let tax = subtotal * Decimal(taxRate)
        return subtotal + tax
    }
}

extension ItemDTO {
    init(from item: Item) {
        id = item.id
        name = item.name
        price = item.price
        taxRate = item.taxRate
        createdAt = item.createdAt
        updatedAt = item.updatedAt
    }
}
