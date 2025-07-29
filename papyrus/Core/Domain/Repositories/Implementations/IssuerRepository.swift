//
//  IssuerRepository.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Dependencies
import os.log

actor IssuerRepository: IssuerRepositoryProtocol {
    @Dependency(\.date) var date
    @Dependency(\.persistenceController) var persistenceController

    func fetchActiveIssuer() async throws -> IssuerDTO? {
        Logger.repositories.info("Fetching active issuer")
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Issuer.fetchActiveIssuer()
            let issuer = try context.fetch(request).first?.toDTO()

            if let issuer = issuer {
                Logger.repositories.info("Found active issuer: \(issuer.name)")
            } else {
                Logger.repositories.info("No active issuer found")
            }

            return issuer
        }
    }

    func fetchAllIssuers() async throws -> [IssuerDTO] {
        Logger.repositories.info("Fetching all issuers")
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Issuer.fetchAllIssuers()
            let issuers = try context.fetch(request).map { $0.toDTO() }
            Logger.repositories.info("Fetched \(issuers.count) issuers")
            return issuers
        }
    }

    func fetchIssuer(withId issuerId: UUID) async throws -> IssuerDTO? {
        Logger.repositories.info("Fetching issuer with ID: \(issuerId)")
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Issuer.fetchIssuer(withId: issuerId)
            let issuer = try context.fetch(request).first?.toDTO()

            if let issuer = issuer {
                Logger.repositories.info("Found issuer: \(issuer.name)")
            } else {
                Logger.repositories.warning("Issuer not found with ID: \(issuerId)")
            }

            return issuer
        }
    }

    func createIssuer(name: String) async throws -> IssuerDTO {
        Logger.repositories.info("Creating issuer: \(name)")
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let issuer = Issuer(context: context)
            issuer.id = UUID()
            issuer.name = name

            try context.save()
            Logger.repositories.info("Successfully created issuer: \(name)")
            return issuer.toDTO()
        }
    }

    func updateIssuer(_ issuerId: UUID, name: String) async throws -> IssuerDTO {
        Logger.repositories.info("Updating issuer with ID: \(issuerId)")
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Issuer.fetchIssuer(withId: issuerId)
            guard let issuer = try context.fetch(request).first else {
                Logger.repositories.error("Issuer not found for update: \(issuerId)")
                throw RepositoryError.issuerNotFound
            }

            issuer.name = name
            try context.save()

            Logger.repositories.info("Successfully updated issuer: \(name)")
            return issuer.toDTO()
        }
    }

    func deleteIssuer(_ issuerId: UUID) async throws {
        Logger.repositories.info("Deleting issuer with ID: \(issuerId)")
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = Issuer.fetchIssuer(withId: issuerId)
            guard let issuer = try context.fetch(request).first else {
                Logger.repositories.error("Issuer not found for deletion: \(issuerId)")
                throw RepositoryError.issuerNotFound
            }

            let issuerName = issuer.name
            context.delete(issuer)
            try context.save()
            Logger.repositories.info("Successfully deleted issuer: \(issuerName)")
        }
    }

    func makeIssuerActive(_ issuerID: UUID) async throws -> IssuerDTO? {
        Logger.repositories.info("Making issuer active with ID: \(issuerID)")
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let targetRequest = Issuer.fetchIssuer(withId: issuerID)
            guard let targetIssuer = try context.fetch(targetRequest).first else {
                Logger.repositories.error("Issuer not found for activation: \(issuerID)")
                throw RepositoryError.issuerNotFound
            }

            let allIssuersRequest = Issuer.fetchAllIssuers()
            let allIssuers = try context.fetch(allIssuersRequest)

            for issuer in allIssuers {
                issuer.isActive = false
            }

            targetIssuer.isActive = true

            try context.save()
            Logger.repositories.info("Successfully activated issuer: \(targetIssuer.name)")

            return targetIssuer.toDTO()
        }
    }
}

extension DependencyValues {
    var issuerRepository: IssuerRepositoryProtocol {
        get { self[IssuerRepositoryKey.self] }
        set { self[IssuerRepositoryKey.self] = newValue }
    }
}

private enum IssuerRepositoryKey: DependencyKey {
    static let liveValue: any IssuerRepositoryProtocol = IssuerRepository()
}
