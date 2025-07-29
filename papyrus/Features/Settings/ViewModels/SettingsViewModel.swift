//
//  SettingsViewModel.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import Dependencies
import SwiftUI

@MainActor
@Observable
class SettingsViewModel {
    @ObservationIgnored
    @Dependency(\.businessRepository) var businessRepository

    @ObservationIgnored
    @Dependency(\.issuerRepository) var issuerRepository

    var activeBusinessName: String?
    var activeIssuerName: String?
    var isLoading = false

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        async let business = try? await businessRepository.fetchActiveBusiness()
        async let issuer = try? await issuerRepository.fetchActiveIssuer()

        let (businessResult, issuerResult) = await (business, issuer)

        activeBusinessName = businessResult?.name
        activeIssuerName = issuerResult?.name
        
    }
}
