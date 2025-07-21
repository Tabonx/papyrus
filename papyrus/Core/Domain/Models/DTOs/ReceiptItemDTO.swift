//
//  ReceiptItemDTO.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Foundation

struct ReceiptItemDTO: Identifiable, Hashable {
    let id: UUID
    let itemName: String
    let unitPrice: Decimal
    let quantity: Int
    let taxRate: Double
    let order: Int

    // Original item ID if linked
    let itemId: UUID?

    var subtotal: Decimal {
        unitPrice * Decimal(quantity)
    }

    var taxAmount: Decimal {
        subtotal * Decimal(taxRate)
    }

    var total: Decimal {
        subtotal + taxAmount
    }

    var formattedUnitPrice: String {
        unitPrice.formatted(.currency(code: "CZK").presentation(.narrow))
    }

    var formattedSubtotal: String {
        subtotal.formatted(.currency(code: "CZK").presentation(.narrow))
    }

    var formattedTaxAmount: String {
        taxAmount.formatted(.currency(code: "CZK").presentation(.narrow))
    }

    var formattedTotal: String {
        total.formatted(.currency(code: "CZK").presentation(.narrow))
    }

    var formattedTaxRate: String {
        String(format: "%.1f%%", taxRate * 100)
    }
}

extension ReceiptItemDTO {
    init(from receiptItem: ReceiptItem) {
        id = receiptItem.id
        itemName = receiptItem.itemName
        unitPrice = receiptItem.unitPrice
        quantity = Int(receiptItem.quantity)
        taxRate = receiptItem.taxRate
        order = Int(receiptItem.order)
        itemId = receiptItem.item?.id
    }
}
