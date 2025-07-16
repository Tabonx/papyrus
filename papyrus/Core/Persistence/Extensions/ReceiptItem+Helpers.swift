//
//  ReceiptItem+Helpers.swift
//  papyrus
//
//  Created by Pavel Kroupa on 16.07.2025.
//

import CoreData
import Foundation

extension ReceiptItem {
    public var id: UUID {
        get {
            id_!
        } set {
            id_ = newValue
        }
    }

    var itemName: String {
        get {
            itemName_ ?? ""
        }
        set {
            itemName_ = newValue
        }
    }

    var quantity: Int {
        get {
            Int(quantity_)
        }
        set {
            quantity_ = Int64(newValue)
        }
    }

    var order: Int {
        get {
            Int(order_)
        }
        set {
            order_ = Int64(newValue)
        }
    }

    var unitPrice: Decimal {
        get {
            unitPrice_?.decimalValue ?? 0
        }
        set {
            unitPrice_ = NSDecimalNumber(decimal: newValue)
        }
    }
}
