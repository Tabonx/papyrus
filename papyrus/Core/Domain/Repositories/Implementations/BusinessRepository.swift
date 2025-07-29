//
//  BusinessRepository.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Dependencies
import os.log

actor BusinessRepository: BusinessRepositoryProtocol {
    @Dependency(\.persistenceController) var persistenceController

    func fetchActiveBusiness() async throws -> BusinessDTO? {
        Logger.repositories.info("Fetching active business")
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Business.fetchActiveBusiness()
            let business = try context.fetch(request).first?.toDTO()

            if let business = business {
                Logger.repositories.info("Found active business: \(business.name)")
            } else {
                Logger.repositories.info("No active business found")
            }

            return business
        }
    }

    func fetchAllBusinesses() async throws -> [BusinessDTO] {
        Logger.repositories.info("Fetching all businesses")
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Business.fetchAllBusinesses()
            let businesses = try context.fetch(request).map { $0.toDTO() }
            Logger.repositories.info("Fetched \(businesses.count) businesses")
            return businesses
        }
    }

    func fetchBusiness(withId businessId: UUID) async throws -> BusinessDTO? {
        Logger.repositories.info("Fetching business with ID: \(businessId)")
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Business.fetchBusiness(withId: businessId)
            let business = try context.fetch(request).first?.toDTO()

            if let business = business {
                Logger.repositories.info("Found business: \(business.name)")
            } else {
                Logger.repositories.warning("Business not found with ID: \(businessId)")
            }

            return business
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
        Logger.repositories.info("Creating business: \(name)")
        let context = persistenceController.backgroundContext

        @Dependency(\.date) var date

        return try await context.perform {
            let business = Business(context: context)
            business.id = UUID()
            business.name = name
            business.address = address
            business.email = email
            business.website = website
            business.defaultTaxRate = defaultTaxRate
            business.defaultCurrency = defaultCurrency
            business.createdAt = date.now
            business.updatedAt = date.now

            try context.save()
            Logger.repositories.info("Successfully created business: \(name)")
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
        async throws -> BusinessDTO {
        Logger.repositories.info("Updating business with ID: \(businessID)")
        let context = persistenceController.backgroundContext

        @Dependency(\.date) var date

        return try await context.perform {
            let request = Business.fetchBusiness(withId: businessID)

            guard let contextBusiness = try context.fetch(request).first else {
                Logger.repositories.error("Business not found for update: \(businessID)")
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

            contextBusiness.updatedAt = date.now

            try context.save()
            Logger.repositories.info("Successfully updated business: \(contextBusiness.name ?? "Unknown")")
            return contextBusiness.toDTO()
        }
    }

    func deleteBusiness(_ businessID: UUID) async throws {
        Logger.repositories.info("Deleting business with ID: \(businessID)")
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = Business.fetchBusiness(withId: businessID)

            guard let contextBusiness = try context.fetch(request).first else {
                Logger.repositories.error("Business not found for deletion: \(businessID)")
                throw RepositoryError.businessNotFound
            }

            let businessName = contextBusiness.name ?? "Unknown"
            context.delete(contextBusiness)
            try context.save()
            Logger.repositories.info("Successfully deleted business: \(businessName)")
        }
    }

    func makeBusinessActive(_ businessID: UUID) async throws -> BusinessDTO? {
        Logger.repositories.info("Making business active with ID: \(businessID)")
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let targetRequest = Business.fetchBusiness(withId: businessID)
            guard let targetBusiness = try context.fetch(targetRequest).first else {
                Logger.repositories.error("Business not found for activation: \(businessID)")
                throw RepositoryError.businessNotFound
            }

            let allBusinessesRequest = Business.fetchAllBusinesses()
            let allBusinesses = try context.fetch(allBusinessesRequest)

            for business in allBusinesses {
                business.isActive = false
            }

            targetBusiness.isActive = true

            try context.save()
            Logger.repositories.info("Successfully activated business: \(targetBusiness.name ?? "Unknown")")

            return targetBusiness.toDTO()
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
