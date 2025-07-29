//
//  BusinessFormData.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

struct BusinessFormData {
    var name = ""
    var address = ""
    var email = ""
    var website = ""
    var taxRate: Double = 21.0
    var currency = "CZK"

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            taxRate >= 0 && taxRate <= 100
    }

    init() {}

    init(from business: BusinessDTO) {
        name = business.name
        address = business.address ?? ""
        email = business.email ?? ""
        website = business.website ?? ""
        taxRate = business.defaultTaxRate * 100
        currency = business.defaultCurrency
    }
}
