//
//  Business+Helpers.swift
//  papyrus
//
//  Created by Pavel Kroupa on 16.07.2025.
//

import CoreData

extension Business {
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

    var items: Set<Item> {
        get { items_ as? Set<Item> ?? [] }
        set { items_ = newValue as NSSet }
    }

    var receipts: Set<Receipt> {
        get { receipts_ as? Set<Receipt> ?? [] }
        set { receipts_ = newValue as NSSet }
    }
}
