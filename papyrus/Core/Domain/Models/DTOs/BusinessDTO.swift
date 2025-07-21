//
//  BusinessDTO.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Foundation

struct BusinessDTO: Identifiable, Hashable {
    let id: UUID
    let name: String
    let address: String?
    let email: String?
    let website: String?
    let defaultTaxRate: Double
    let defaultCurrency: String
    let createdAt: Date
    let updatedAt: Date

    var formattedDefaultTaxRate: String {
        String(format: "%.1f%%", defaultTaxRate * 100)
    }

    var formattedAddress: String {
        [name, address].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: "\n")
    }

    var contactInfo: String {
        [email, website].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " • ")
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            defaultTaxRate >= 0 &&
            defaultTaxRate <= 1.0 &&
            !defaultCurrency.isEmpty
    }
}

extension BusinessDTO {
    init(from business: Business) {
        id = business.id
        name = business.name ?? ""
        address = business.address
        email = business.email
        website = business.website
        defaultTaxRate = business.defaultTaxRate
        defaultCurrency = business.defaultCurrency ?? "CZK"
        createdAt = business.createdAt
        updatedAt = business.updatedAt
    }
}
