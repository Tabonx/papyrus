//
//  IssuerRepository.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import CoreData
import Dependencies

actor IssuerRepository: IssuerRepositoryProtocol {
    @Dependency(\.date) var date
    @Dependency(\.persistenceController) var persistenceController

    func fetchAllIssuers() async throws -> [IssuerDTO] {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Issuer.fetchAllIssuers()
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func fetchIssuer(withId issuerId: UUID) async throws -> IssuerDTO? {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let request = Issuer.fetchIssuer(withId: issuerId)
            return try context.fetch(request).first?.toDTO()
        }
    }

    func createIssuer(name: String) async throws -> IssuerDTO {
        let context = persistenceController.backgroundContext

        return try await context.perform {
            let issuer = Issuer(context: context)
            issuer.id = UUID()
            issuer.name = name

            try context.save()
            return issuer.toDTO()
        }
    }

    func updateIssuer(_ issuerId: UUID, name: String) async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = Issuer.fetchIssuer(withId: issuerId)
            guard let issuer = try context.fetch(request).first else {
                throw RepositoryError.issuerNotFound
            }

            issuer.name = name
            try context.save()
        }
    }

    func deleteIssuer(_ issuerId: UUID) async throws {
        let context = persistenceController.backgroundContext

        try await context.perform {
            let request = Issuer.fetchIssuer(withId: issuerId)
            guard let issuer = try context.fetch(request).first else {
                throw RepositoryError.issuerNotFound
            }

            context.delete(issuer)
            try context.save()
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
