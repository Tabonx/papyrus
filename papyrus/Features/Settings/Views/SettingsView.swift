//
//  SettingsView.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import Dependencies
import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        BusinessSettingsView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Business")
                                if let businessName = viewModel.activeBusinessName {
                                    Text(businessName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Not configured")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: "building.2")
                                .foregroundStyle(.blue)
                        }
                    }

                    NavigationLink {
                        IssuerSettingsView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Issuer")
                                if let issuerName = viewModel.activeIssuerName {
                                    Text(issuerName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Not configured")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: "person.text.rectangle")
                                .foregroundStyle(.green)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        ReceiptSettingsView()
                    } label: {
                        Label("Receipt Defaults", systemImage: "doc.text")
                            .foregroundStyle(.primary, .orange)
                    }

                    NavigationLink {
                        PrinterSettingsView()
                    } label: {
                        Label("Printer", systemImage: "printer")
                            .foregroundStyle(.primary, .purple)
                    }
                } header: {
                    Text("Configuration")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                Task {
                    await viewModel.loadData()
                }
            }
        }
    }
}
