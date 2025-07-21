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

extension Item {
    func toDTO() -> ItemDTO {
        ItemDTO(from: self)
    }
}

extension Item {
    static func fetchAllItems() -> NSFetchRequest<Item> {
        let request = Item.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "name_", ascending: true),
        ]
        return request
    }

    static func fetchItems(searchText: String? = nil) -> NSFetchRequest<Item> {
        let request = fetchAllItems()

        if let searchText = searchText, !searchText.isEmpty {
            request.predicate = NSPredicate(
                format: "name_ CONTAINS[cd] %@",
                searchText
            )
        }

        return request
    }

    static func fetchItem(withId itemId: UUID) -> NSFetchRequest<Item> {
        let request = Item.fetchRequest()
        request.predicate = NSPredicate(format: "id_ == %@", itemId as CVarArg)
        request.fetchLimit = 1
        return request
    }

    static func fetchRecentlyModifiedItems(limit: Int = 5) -> NSFetchRequest<Item> {
        let request = Item.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "updatedAt_", ascending: false),
        ]
        request.fetchLimit = limit
        return request
    }
}
