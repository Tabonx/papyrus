//
//  ESCPOSCommands.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import Foundation

// MARK: - ESC/POS Commands
enum ESCPOSCommands {
    static let initialize: [UInt8] = [0x1B, 0x40] // ESC @
    static let cutPaper: [UInt8] = [0x1D, 0x56, 0x42, 0x00] // GS V B 0
    static let lineFeed: [UInt8] = [0x0A] // LF
    static let carriageReturn: [UInt8] = [0x0D] // CR
    static let selectFontA: [UInt8] = [0x1B, 0x4D, 0x00] // ESC M 0
    static let selectFontB: [UInt8] = [0x1B, 0x4D, 0x01] // ESC M 1
    static let boldOn: [UInt8] = [0x1B, 0x45, 0x01] // ESC E 1
    static let boldOff: [UInt8] = [0x1B, 0x45, 0x00] // ESC E 0
    static let alignLeft: [UInt8] = [0x1B, 0x61, 0x00] // ESC a 0
    static let alignCenter: [UInt8] = [0x1B, 0x61, 0x01] // ESC a 1
    static let alignRight: [UInt8] = [0x1B, 0x61, 0x02] // ESC a 2
    static let doubleWidth: [UInt8] = [0x1B, 0x21, 0x20] // ESC ! 32
    static let doubleHeight: [UInt8] = [0x1B, 0x21, 0x10] // ESC ! 16
    static let normalSize: [UInt8] = [0x1B, 0x21, 0x00] // ESC ! 0
    static let underlineOn: [UInt8] = [0x1B, 0x2D, 0x01] // ESC - 1
    static let underlineOff: [UInt8] = [0x1B, 0x2D, 0x00] // ESC - 0

    static func setLineSpacing(_ spacing: UInt8) -> [UInt8] {
        return [0x1B, 0x33, spacing] // ESC 3 n
    }

    static func feedLines(_ lines: UInt8) -> [UInt8] {
        return [0x1B, 0x64, lines] // ESC d n
    }
}
enum TextSize: Codable {
    case normal
    case doubleWidth
    case doubleHeight
    case both

    var escCommand: [UInt8] {
        switch self {
        case .normal: return ESCPOSCommands.normalSize
        case .doubleWidth: return ESCPOSCommands.doubleWidth
        case .doubleHeight: return ESCPOSCommands.doubleHeight
        case .both: return [0x1B, 0x21, 0x30] // ESC ! 48 (both)
        }
    }
}

extension Data {
    func chunked(into size: Int) -> [Data] {
        return stride(from: 0, to: count, by: size).map {
            Data(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
