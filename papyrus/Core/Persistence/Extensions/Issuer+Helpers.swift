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

extension Issuer {
    func toDTO() -> IssuerDTO {
        IssuerDTO(from: self)
    }
}

extension Issuer {
    static func fetchAllIssuers() -> NSFetchRequest<Issuer> {
        let request = Issuer.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Issuer.name_, ascending: true),
        ]
        return request
    }

    static func fetchActiveIssuer() -> NSFetchRequest<Issuer> {
        let request = Issuer.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.fetchLimit = 1
        return request
    }

    static func fetchIssuer(withId issuerId: UUID) -> NSFetchRequest<Issuer> {
        let request = Issuer.fetchRequest()
        request.predicate = NSPredicate(format: "id_ == %@", issuerId as CVarArg)
        request.fetchLimit = 1
        return request
    }
}
