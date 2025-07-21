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

extension ReceiptItem {
    func toDTO() -> ReceiptItemDTO {
        ReceiptItemDTO(from: self)
    }
}

extension ReceiptItem {
    static func fetchAllReceiptItems() -> NSFetchRequest<ReceiptItem> {
        let request = ReceiptItem.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ReceiptItem.itemName_, ascending: true),
        ]
        return request
    }

    static func fetchReceiptItems(from startDate: Date, to endDate: Date) -> NSFetchRequest<ReceiptItem> {
        let request = ReceiptItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "receipt.createdAt_ >= %@ AND receipt.createdAt_ <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ReceiptItem.itemName_, ascending: true),
        ]
        return request
    }

    static func fetchReceiptItem(withId receiptItemId: UUID) -> NSFetchRequest<ReceiptItem> {
        let request = ReceiptItem.fetchRequest()
        request.predicate = NSPredicate(format: "id_ == %@", receiptItemId as CVarArg)
        request.fetchLimit = 1
        return request
    }

    static func fetchReceiptItems(for receiptId: UUID) -> NSFetchRequest<ReceiptItem> {
        let request = ReceiptItem.fetchRequest()
        request.predicate = NSPredicate(format: "receipt.id_ == %@", receiptId as CVarArg)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ReceiptItem.order_, ascending: true),
            NSSortDescriptor(keyPath: \ReceiptItem.itemName_, ascending: true),
        ]
        return request
    }
}
