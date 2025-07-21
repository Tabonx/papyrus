//
//  BusinessRepository.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Dependencies

actor BusinessRepository: BusinessRepositoryProtocol {
    @Dependency(\.date) var date
    @Dependency(\.persistenceController) var persistenceController

    func fetchPrimaryBusiness() async throws -> BusinessDTO? {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Business.fetchPrimaryBusiness()
            return try context.fetch(request).first?.toDTO()
        }
    }

    func fetchAllBusinesses() async throws -> [BusinessDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Business.fetchAllBusinesses()
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func fetchBusiness(withId businessId: UUID) async throws -> BusinessDTO? {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Business.fetchBusiness(withId: businessId)
            return try context.fetch(request).first?.toDTO()
        }
    }

    func createBusiness(
        name: String,
        address: String?,
        email: String?,
        website: String?,
        defaultTaxRate: Double,
        defaultCurrency: String
    )
        async throws -> BusinessDTO {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let business = Business(context: context)
            business.id = UUID()
            business.name = name
            business.address = address
            business.email = email
            business.website = website
            business.defaultTaxRate = defaultTaxRate
            business.defaultCurrency = defaultCurrency
            business.createdAt = self.date.now
            business.updatedAt = self.date.now

            try context.save()
            return business.toDTO()
        }
    }

    func updateBusiness(
        _ businessID: UUID,
        name: String?,
        address: String?,
        email: String?,
        website: String?,
        defaultTaxRate: Double?,
        defaultCurrency: String?
    )
        async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = Business.fetchBusiness(withId: businessID)

            guard let contextBusiness = try context.fetch(request).first else {
                throw RepositoryError.businessNotFound
            }

            // Update properties if provided
            if let name = name {
                contextBusiness.name = name
            }
            if let address = address {
                contextBusiness.address = address
            }
            if let email = email {
                contextBusiness.email = email
            }
            if let website = website {
                contextBusiness.website = website
            }
            if let defaultTaxRate = defaultTaxRate {
                contextBusiness.defaultTaxRate = defaultTaxRate
            }
            if let defaultCurrency = defaultCurrency {
                contextBusiness.defaultCurrency = defaultCurrency
            }

            contextBusiness.updatedAt = self.date.now

            try context.save()
        }
    }

    func deleteBusiness(_ businessID: UUID) async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = Business.fetchBusiness(withId: businessID)

            guard let contextBusiness = try context.fetch(request).first else {
                throw RepositoryError.businessNotFound
            }

            context.delete(contextBusiness)
            try context.save()
        }
    }
}

extension DependencyValues {
    var businessRepository: BusinessRepositoryProtocol {
        get { self[BusinessRepositoryKey.self] }
        set { self[BusinessRepositoryKey.self] = newValue }
    }
}

private enum BusinessRepositoryKey: DependencyKey {
    static let liveValue: any BusinessRepositoryProtocol = BusinessRepository()
}
