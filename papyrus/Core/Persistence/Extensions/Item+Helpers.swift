//
//  Item+Helpers.swift
//  papyrus
//
//  Created by Pavel Kroupa on 16.07.2025.
//

import CoreData
import Foundation

extension Item {
    public var id: UUID {
        get {
            id_!
        } set {
            id_ = newValue
        }
    }

    var createdAt: Date {
        get {
            createdAt_ ?? .distantPast
        }
        set {
            createdAt_ = newValue
        }
    }

    var updatedAt: Date {
        get {
            updatedAt_ ?? .distantPast
        }
        set {
            updatedAt_ = newValue
        }
    }

    var name: String {
        get {
            name_ ?? ""
        }
        set {
            name_ = newValue
        }
    }

    var price: Decimal {
        get {
            price_?.decimalValue ?? 0
        }
        set {
            price_ = NSDecimalNumber(decimal: newValue)
        }
    }

    var receiptItems: Set<ReceiptItem> {
        get { receiptItems_ as? Set<ReceiptItem> ?? [] }
        set { receiptItems_ = newValue as NSSet }
    }
}
