//
//  AppConstants.swift
//  papyrus
//
//  Created by Pavel Kroupa on 16.07.2025.
//

import UIKit

enum AppConstants {
    enum App {
        static let name = "Papyrus"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Business Rules
    enum Business {
        static let maxReceiptNumber = 9_999_999
        static let receiptNumberFormat = "%d%07d" // Year + 7-digit sequence
    }

    // MARK: - Date Formatting
    enum DateFormats {
        static let receiptDate = "dd.MM.yyyy"
        static let receiptTime = "HH:mm:ss"
        static let receiptDateTime = "dd.MM.yyyy HH:mm:ss"
        static let receiptNumber = "yyyy"
        static let reportMonth = "MMMM yyyy"
        static let reportYear = "yyyy"
        static let fileTimestamp = "yyyyMMdd_HHmmss"
    }

    // MARK: - Validation Rules
    enum Validation {
        static let minPrice: Decimal = 0
        static let maxPrice: Decimal = 999_999.99
        static let minQuantity = 1
        static let maxQuantity = 9999
        static let minTaxRate: Double = 0
        static let maxTaxRate: Double = 100
    }
}
