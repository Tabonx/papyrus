//
//  ShoppingCart.swift
//  papyrus
//
//  Created by Pavel Kroupa on 16.07.2025.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class ShoppingCart {
    var items: [CartItem] = []

    var isEmpty: Bool {
        items.isEmpty
    }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Decimal {
        items.reduce(0) { $0 + $1.subtotal }
    }

    var totalTax: Decimal {
        items.reduce(0) { $0 + $1.taxAmount }
    }

    var total: Decimal {
        subtotal + totalTax
    }

    // Formatted totals
    var formattedSubtotal: String {
        subtotal.formatted(.currency(code: "CZK").presentation(.narrow).rounded())
    }

    var formattedTotalTax: String {
        totalTax.formatted(.currency(code: "CZK").presentation(.narrow).rounded())
    }

    var formattedTotal: String {
        total.formatted(.currency(code: "CZK").presentation(.narrow).rounded())
    }

    func addItem(itemId: UUID, name: String, unitPrice: Decimal, taxRate: Double, quantity: Int = 1) {
        if let existingIndex = items.firstIndex(where: { $0.itemId == itemId }) {
            // Update quantity of existing item
            items[existingIndex].quantity += quantity
        } else {
            // Add new item to cart
            let cartItem = CartItem(
                itemId: itemId,
                name: name,
                unitPrice: unitPrice,
                taxRate: taxRate,
                quantity: quantity
            )
            items.append(cartItem)
        }
    }

    func addItem(from item: Item, quantity: Int = 1) {
        addItem(
            itemId: item.id,
            name: item.name,
            unitPrice: item.price,
            taxRate: item.taxRate,
            quantity: quantity
        )
    }

    func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
    }

    func removeItem(withId itemId: UUID) {
        items.removeAll { $0.itemId == itemId }
    }

    func updateQuantity(for itemId: UUID, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.itemId == itemId }) else { return }

        if quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index].quantity = quantity
        }
    }

    func incrementQuantity(for itemId: UUID) {
        if let index = items.firstIndex(where: { $0.itemId == itemId }) {
            items[index].quantity += 1
        }
    }

    func decrementQuantity(for itemId: UUID) {
        if let index = items.firstIndex(where: { $0.itemId == itemId }) {
            let newQuantity = items[index].quantity - 1
            if newQuantity <= 0 {
                items.remove(at: index)
            } else {
                items[index].quantity = newQuantity
            }
        }
    }

    func clear() {
        items.removeAll()
    }

    var canCreateReceipt: Bool {
        !isEmpty
    }
}
