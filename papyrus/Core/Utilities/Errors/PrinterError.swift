//
//  PrinterError.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import Foundation

enum PrinterError: LocalizedError, Sendable {
    case bluetoothNotAvailable
    case connectionTimeout
    case connectionFailed
    case printerNotReady
    case printTimeout
    case noServicesFound

    var errorDescription: String? {
        switch self {
        case .bluetoothNotAvailable:
            return "Bluetooth is not available"
        case .connectionTimeout:
            return "Connection timed out"
        case .connectionFailed:
            return "Failed to connect to printer"
        case .printerNotReady:
            return "Printer is not ready"
        case .printTimeout:
            return "Print job timed out"
        case .noServicesFound:
            return "No printer services found"
        }
    }
}
