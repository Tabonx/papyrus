//
//  Receipt+Helpers.swift
//  papyrus
//
//  Created by Pavel Kroupa on 16.07.2025.
//

import CoreData
import Foundation

extension Receipt {
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

    var issuedDate: Date {
        get {
            issuedDate_ ?? .distantPast
        }
        set {
            issuedDate_ = newValue
        }
    }

    var legalPerformanceDate: Date {
        get {
            legalPerformanceDate_ ?? .distantPast
        }
        set {
            legalPerformanceDate_ = newValue
        }
    }

    var paymentMethod: String {
        get {
            paymentMethod_ ?? ""
        }
        set {
            paymentMethod_ = newValue
        }
    }

    var receiptNumber: String {
        get {
            receiptNumber_ ?? ""
        }
        set {
            receiptNumber_ = newValue
        }
    }

    var items: Set<ReceiptItem> {
        get { items_ as? Set<ReceiptItem> ?? [] }
        set { items_ = newValue as NSSet }
    }

    var orderedItems: [ReceiptItem] {
        items.sorted { $0.order < $1.order }
    }
}
