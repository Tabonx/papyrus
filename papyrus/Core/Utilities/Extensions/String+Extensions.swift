//
//  String+Extensions.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
