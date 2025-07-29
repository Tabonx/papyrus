//
//  BusinessSettingsViewModel.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import Dependencies
import os.log
import SwiftUI

@MainActor
@Observable
class BusinessSettingsViewModel {
    @ObservationIgnored
    @Dependency(\.businessRepository) var businessRepository

    var businesses: [BusinessDTO] = []
    var isLoading = false
    var errorMessage: String?

    func loadBusinesses() async {
        Logger.business.info("Loading all businesses")
        isLoading = true
        defer { isLoading = false }

        do {
            businesses = try await businessRepository.fetchAllBusinesses()
                .sorted { $0.isActive && !$1.isActive }
            Logger.business.info("Loaded \(self.businesses.count) businesses")
        } catch {
            Logger.business.error("Failed to load businesses: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func createBusiness(with data: BusinessFormData) async {
        Logger.business.info("Creating new business: \(data.name)")

        do {
            let business = try await businessRepository.createBusiness(
                name: data.name,
                address: data.address.isEmpty ? nil : data.address,
                email: data.email.isEmpty ? nil : data.email,
                website: data.website.isEmpty ? nil : data.website,
                defaultTaxRate: data.taxRate / 100,
                defaultCurrency: data.currency
            )
            Logger.business.info("Successfully created business: \(business.name)")
            await loadBusinesses()
        } catch {
            Logger.business.error("Failed to create business '\(data.name)': \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func updateBusiness(_ id: UUID, with data: BusinessFormData) async {
        Logger.business.info("Updating business: \(data.name)")

        do {
            let business = try await businessRepository.updateBusiness(
                id,
                name: data.name,
                address: data.address.isEmpty ? nil : data.address,
                email: data.email.isEmpty ? nil : data.email,
                website: data.website.isEmpty ? nil : data.website,
                defaultTaxRate: data.taxRate / 100,
                defaultCurrency: data.currency
            )
            Logger.business.info("Successfully updated business: \(business.name)")
            await loadBusinesses()
        } catch {
            Logger.business.error("Failed to update business '\(data.name)': \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func setActiveBusiness(_ id: UUID) async {
        Logger.business.info("Setting active business: \(id)")

        do {
            let business = try await businessRepository.makeBusinessActive(id)
            if let business = business {
                Logger.business.info("Successfully set active business: \(business.name)")
            } else {
                Logger.business.info("Business activated successfully")
            }
            await loadBusinesses()
        } catch {
            Logger.business.error("Failed to set active business: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func deleteBusiness(_ id: UUID) async {
        Logger.business.info("Deleting business: \(id)")

        do {
            try await businessRepository.deleteBusiness(id)
            Logger.business.info("Successfully deleted business")
            await loadBusinesses()
        } catch {
            Logger.business.error("Failed to delete business: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        Logger.business.debug("Clearing error message")
        errorMessage = nil
    }
}
