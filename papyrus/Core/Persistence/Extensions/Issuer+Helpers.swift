//
//  Issuer+Helpers.swift
//  papyrus
//
//  Created by Pavel Kroupa on 16.07.2025.
//

import CoreData

extension Issuer {
    public var id: UUID {
        get {
            id_!
        } set {
            id_ = newValue
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

    var receipts: Set<Receipt> {
        get { receipts_ as? Set<Receipt> ?? [] }
        set { receipts_ = newValue as NSSet }
    }
}
