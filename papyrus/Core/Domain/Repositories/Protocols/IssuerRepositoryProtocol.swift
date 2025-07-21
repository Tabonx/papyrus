//
//  IssuerRepositoryProtocol.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import Foundation

protocol IssuerRepositoryProtocol {
    func fetchAllIssuers() async throws -> [IssuerDTO]

    func fetchIssuer(withId issuerId: UUID) async throws -> IssuerDTO?

    func createIssuer(name: String) async throws -> IssuerDTO

    func updateIssuer(_ issuerId: UUID, name: String) async throws

    func deleteIssuer(_ issuerId: UUID) async throws
}
