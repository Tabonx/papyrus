//
//  IssuerRepositoryProtocol.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import Foundation

protocol IssuerRepositoryProtocol: Sendable {
    func fetchAllIssuers() async throws -> [IssuerDTO]

    func fetchActiveIssuer() async throws -> IssuerDTO?

    func fetchIssuer(withId issuerId: UUID) async throws -> IssuerDTO?

    func createIssuer(name: String) async throws -> IssuerDTO

    func updateIssuer(_ issuerId: UUID, name: String) async throws -> IssuerDTO

    func deleteIssuer(_ issuerId: UUID) async throws

    func makeIssuerActive(_ issuerID: UUID) async throws -> IssuerDTO?
}
