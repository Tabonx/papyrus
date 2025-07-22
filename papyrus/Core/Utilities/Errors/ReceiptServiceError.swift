//
//  ReceiptServiceError.swift
//  papyrus
//
//  Created by Pavel Kroupa on 23.07.2025.
//

import Foundation

enum ReceiptServiceError: LocalizedError {
    case emptyCart
    case businessNotFound
    case issuerNotFound
    case receiptNotFound
    case invalidData(String)

    var errorDescription: String? {
        switch self {
        case .emptyCart:
            return "Cannot create receipt from empty cart"
        case .businessNotFound:
            return "Business not found"
        case .issuerNotFound:
            return "Issuer not found"
        case .receiptNotFound:
            return "Receipt not found"
        case let .invalidData(message):
            return "Invalid data: \(message)"
        }
    }
}
