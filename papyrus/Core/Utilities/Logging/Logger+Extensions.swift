//
//  Logger+Extensions.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import Foundation
import os.log

extension Logger {
    static let business = Logger(subsystem: AppConstants.bundleID, category: "Business")
    static let items = Logger(subsystem: AppConstants.bundleID, category: "Items")
    static let receipts = Logger(subsystem: AppConstants.bundleID, category: "Receipts")
    static let cart = Logger(subsystem: AppConstants.bundleID, category: "Cart")
    static let issuer = Logger(subsystem: AppConstants.bundleID, category: "Issuer")

    
    static let persistence = Logger(subsystem: AppConstants.bundleID, category: "Persistence")
    static let repositories = Logger(subsystem: AppConstants.bundleID, category: "Repositories")
    static let services = Logger(subsystem: AppConstants.bundleID, category: "Services")
    static let useCases = Logger(subsystem: AppConstants.bundleID, category: "UseCases")

    static let printer = Logger(subsystem: AppConstants.bundleID, category: "Printer")
    static let bluetooth = Logger(subsystem: AppConstants.bundleID, category: "Bluetooth")
    static let settings = Logger(subsystem: AppConstants.bundleID, category: "Settings")

    static let backup = Logger(subsystem: AppConstants.bundleID, category: "Backup")
    static let export = Logger(subsystem: AppConstants.bundleID, category: "Export")

    static let performance = Logger(subsystem: AppConstants.bundleID, category: "Performance")
    static let memory = Logger(subsystem: AppConstants.bundleID, category: "Memory")
    static let general = Logger(subsystem: AppConstants.bundleID, category: "General")
    static let errors = Logger(subsystem: AppConstants.bundleID, category: "Errors")
    static let analytics = Logger(subsystem: AppConstants.bundleID, category: "Analytics")
}

// MARK: - Performance Logging
extension Logger {
    /// Measure and log execution time of a closure
    func measureTime<T>(
        operation: String,
        metadata: [String: Any]? = nil,
        _ closure: () throws -> T
    )
        rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try closure()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        var finalMetadata = metadata ?? [:]
        finalMetadata["duration"] = String(format: "%.4f seconds", timeElapsed)

        info("Performance: \(operation)")

        return result
    }

    /// Async version of measureTime
    func measureTime<T>(
        operation: String,
        metadata: [String: Any]? = nil,
        _ closure: () async throws -> T
    )
        async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await closure()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        var finalMetadata = metadata ?? [:]
        finalMetadata["duration"] = String(format: "%.4f seconds", timeElapsed)

        info("Performance: \(operation)")
        return result
    }
}
