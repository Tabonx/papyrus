//
//  BusinessRepositoryProtocol.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import Foundation

protocol BusinessRepositoryProtocol: Sendable {
    func fetchActiveBusiness() async throws -> BusinessDTO?

    func fetchAllBusinesses() async throws -> [BusinessDTO]

    func fetchBusiness(withId businessId: UUID) async throws -> BusinessDTO?

    func createBusiness(
        name: String,
        address: String?,
        email: String?,
        website: String?,
        defaultTaxRate: Double,
        defaultCurrency: String
    )
        async throws -> BusinessDTO

    func updateBusiness(
        _ businessID: UUID,
        name: String?,
        address: String?,
        email: String?,
        website: String?,
        defaultTaxRate: Double?,
        defaultCurrency: String?
    )
        async throws -> BusinessDTO

    func deleteBusiness(_ businessID: UUID) async throws

    func makeBusinessActive(_ businessID: UUID) async throws -> BusinessDTO?
}
