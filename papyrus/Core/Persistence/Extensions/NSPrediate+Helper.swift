//
//  NSPredicate+Helpers.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import Foundation

extension NSPredicate {
    nonisolated(unsafe) static let all = NSPredicate(format: "TRUEPREDICATE")
    nonisolated(unsafe) static let none = NSPredicate(format: "FALSEPREDICATE")
}
