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

extension Business {
    func toDTO() -> BusinessDTO {
        BusinessDTO(from: self)
    }
}

extension Business {
    static func fetchPrimaryBusiness() -> NSFetchRequest<Business> {
        let request = Business.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Business.createdAt_, ascending: true),
        ]
        return request
    }

    static func fetchAllBusinesses() -> NSFetchRequest<Business> {
        let request = Business.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Business.name, ascending: true),
        ]
        return request
    }

    static func fetchBusiness(withId businessId: UUID) -> NSFetchRequest<Business> {
        let request = Business.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id_ == %@", businessId as CVarArg)
        request.fetchLimit = 1
        return request
    }
}
