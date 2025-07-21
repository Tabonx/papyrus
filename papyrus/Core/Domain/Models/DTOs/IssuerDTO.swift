//
//  IssuerDTO.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Foundation

struct IssuerDTO: Identifiable, Hashable {
    let id: UUID
    let name: String
}

extension IssuerDTO {
    init(from issuer: Issuer) {
        id = issuer.id
        name = issuer.name
    }
}
