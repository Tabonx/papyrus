//
//  IssuerSettingsView.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import SwiftUI

struct IssuerSettingsView: View {
    @State private var viewModel = IssuerSettingsViewModel()
    @State private var issuerToEdit: IssuerDTO?
    @State private var isPresentingNewIssuer = false

    var body: some View {
        List {
            ForEach(viewModel.issuers) { issuer in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(issuer.name)
                            .font(.headline)
                        Text("Issuer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if issuer.isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if !issuer.isActive {
                        Task {
                            await viewModel.setActiveIssuer(issuer.id)
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        Task {
                            await viewModel.deleteIssuer(issuer.id)
                        }
                    }

                    Button("Edit", systemImage: "pencil") {
                        issuerToEdit = issuer
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .leading) {
                    if !issuer.isActive {
                        Button("Set Active", systemImage: "checkmark.circle") {
                            Task {
                                await viewModel.setActiveIssuer(issuer.id)
                            }
                        }
                        .tint(.green)
                    }
                }
            }
        }
        .navigationTitle("Issuer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    isPresentingNewIssuer = true
                }
            }
        }
        .sheet(item: $issuerToEdit) { issuer in
            AddEditIssuerView(issuer: issuer) { name in
                await viewModel.updateIssuer(issuer.id, name: name)
            }
        }
        .sheet(isPresented: $isPresentingNewIssuer) {
            AddEditIssuerView(issuer: nil) { name in
                await viewModel.createIssuer(name: name)
            }
        }
        .task {
            await viewModel.loadIssuers()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}
