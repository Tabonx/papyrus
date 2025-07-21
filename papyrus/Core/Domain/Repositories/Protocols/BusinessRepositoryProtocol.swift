//
//  BusinessRepositoryProtocol.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import Foundation

protocol BusinessRepositoryProtocol {
    func fetchPrimaryBusiness() async throws -> BusinessDTO?

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
        async throws

    func deleteBusiness(_ businessID: UUID) async throws
}
