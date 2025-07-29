//
//  IssuerSettingsViewModel.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import Dependencies
import os.log
import SwiftUI

@MainActor
@Observable
class IssuerSettingsViewModel {
    @ObservationIgnored
    @Dependency(\.issuerRepository) var issuerRepository

    var issuers: [IssuerDTO] = []
    var isLoading = false
    var errorMessage: String?

    func loadIssuers() async {
        Logger.issuer.info("Loading all issuers")
        isLoading = true
        defer { isLoading = false }

        do {
            issuers = try await issuerRepository.fetchAllIssuers()
                .sorted { $0.isActive && !$1.isActive }
            Logger.issuer.info("Loaded \(self.issuers.count) issuers")
        } catch {
            Logger.issuer.error("Failed to load issuers: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func createIssuer(name: String) async {
        Logger.issuer.info("Creating new issuer: \(name)")

        do {
            let issuer = try await issuerRepository.createIssuer(name: name)
            Logger.issuer.info("Successfully created issuer: \(issuer.name)")
            await loadIssuers()
        } catch {
            Logger.issuer.error("Failed to create issuer '\(name)': \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func updateIssuer(_ id: UUID, name: String) async {
        Logger.issuer.info("Updating issuer: \(name)")

        do {
            let issuer = try await issuerRepository.updateIssuer(id, name: name)
            Logger.issuer.info("Successfully updated issuer: \(issuer.name)")
            await loadIssuers()
        } catch {
            Logger.issuer.error("Failed to update issuer '\(name)': \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func setActiveIssuer(_ id: UUID) async {
        Logger.issuer.info("Setting active issuer: \(id)")

        do {
            let issuer = try await issuerRepository.makeIssuerActive(id)
            if let issuer = issuer {
                Logger.issuer.info("Successfully set active issuer: \(issuer.name)")
            } else {
                Logger.issuer.info("Issuer activated successfully")
            }
            await loadIssuers()
        } catch {
            Logger.issuer.error("Failed to set active issuer: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func deleteIssuer(_ id: UUID) async {
        Logger.issuer.info("Deleting issuer: \(id)")

        do {
            try await issuerRepository.deleteIssuer(id)
            Logger.issuer.info("Successfully deleted issuer")
            await loadIssuers()
        } catch {
            Logger.issuer.error("Failed to delete issuer: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        Logger.issuer.debug("Clearing error message")
        errorMessage = nil
    }
}
