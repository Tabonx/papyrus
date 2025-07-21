//
//  RepositoryError.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import Foundation

enum RepositoryError: LocalizedError {
    case itemNotFound
    case receiptNotFound
    case businessNotFound
    case issuerNotFound
    case duplicateItem(String)
    case invalidData(String)
    case coreDataError(Error)
    case networkError(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found"
        case .receiptNotFound:
            return "Receipt not found"
        case .businessNotFound:
            return "Business not found"
        case .issuerNotFound:
            return "Issuer not found"
        case let .duplicateItem(name):
            return "Item with name '\(name)' already exists"
        case let .invalidData(description):
            return "Invalid data: \(description)"
        case let .coreDataError(error):
            return "Database error: \(error.localizedDescription)"
        case let .networkError(error):
            return "Network error: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }

    var failureReason: String? {
        switch self {
        case .itemNotFound:
            return "The requested item could not be found in the database"
        case .receiptNotFound:
            return "The requested receipt could not be found in the database"
        case .businessNotFound:
            return "The business information could not be found"
        case .issuerNotFound:
            return "The issuer information could not be found"
        case .duplicateItem:
            return "An item with this name already exists"
        case .invalidData:
            return "The provided data is invalid or incomplete"
        case .coreDataError:
            return "There was a problem accessing the database"
        case .networkError:
            return "There was a problem with the network connection"
        case .unknownError:
            return "An unexpected error occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .businessNotFound, .issuerNotFound, .itemNotFound, .receiptNotFound:
            return "Please refresh and try again"
        case .duplicateItem:
            return "Please choose a different name"
        case .invalidData:
            return "Please check your input and try again"
        case .coreDataError:
            return "Please restart the app and try again"
        case .networkError:
            return "Please check your internet connection and try again"
        case .unknownError:
            return "Please try again or contact support"
        }
    }
}
