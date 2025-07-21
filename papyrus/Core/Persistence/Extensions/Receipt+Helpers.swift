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

extension Receipt {
    func toDTO() -> ReceiptDTO {
        ReceiptDTO(from: self)
    }
}

extension Receipt {
    static func fetchAllReceipts() -> NSFetchRequest<Receipt> {
        let request = Receipt.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Receipt.createdAt, ascending: false),
        ]
        return request
    }

    static func fetchReceipts(from startDate: Date, to endDate: Date) -> NSFetchRequest<Receipt> {
        let request = fetchAllReceipts()
        request.predicate = NSPredicate(
            format: "createdAt_ >= %@ AND createdAt_ <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        return request
    }

    static func fetchTodaysReceipts() -> NSFetchRequest<Receipt> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return fetchReceipts(from: startOfDay, to: endOfDay)
    }

    static func fetchCurrentMonthReceipts() -> NSFetchRequest<Receipt> {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now

        return fetchReceipts(from: startOfMonth, to: endOfMonth)
    }

    static func fetchCurrentYearReceipts() -> NSFetchRequest<Receipt> {
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
        let endOfYear = calendar.dateInterval(of: .year, for: now)?.end ?? now

        return fetchReceipts(from: startOfYear, to: endOfYear)
    }

    static func fetchReceipt(withNumber receiptNumber: String) -> NSFetchRequest<Receipt> {
        let request = Receipt.fetchRequest()
        request.predicate = NSPredicate(format: "receiptNumber_ == %@", receiptNumber)
        request.fetchLimit = 1
        return request
    }

    static func fetchReceipt(withID receiptID: UUID) -> NSFetchRequest<Receipt> {
        let request = Receipt.fetchRequest()
        request.predicate = NSPredicate(format: "id_ == %@", receiptID as CVarArg)
        request.fetchLimit = 1
        return request
    }

    static func fetchReceipts(searchText: String) -> NSFetchRequest<Receipt> {
        let request = fetchAllReceipts()
        request.predicate = NSPredicate(
            format: "receiptNumber_ CONTAINS[cd] %@",
            searchText
        )
        return request
    }
}
