//
//  BusinessSettingsView.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import SwiftUI

struct BusinessSettingsView: View {
    @State private var viewModel = BusinessSettingsViewModel()
    @State private var businessToEdit: BusinessDTO?
    @State private var isPresentingNewBusiness = false

    var body: some View {
        List {
            ForEach(viewModel.businesses) { business in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(business.name)
                                .font(.headline)

                            if let address = business.address, !address.isEmpty {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            HStack {
                                Text(business.formattedDefaultTaxRate)
                                Text("•")
                                Text(business.defaultCurrency)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if business.isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    if !business.contactInfo.isEmpty {
                        Text(business.contactInfo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if !business.isActive {
                        Task {
                            await viewModel.setActiveBusiness(business.id)
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        Task {
                            await viewModel.deleteBusiness(business.id)
                        }
                    }

                    Button("Edit", systemImage: "pencil") {
                        businessToEdit = business
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .leading) {
                    if !business.isActive {
                        Button("Set Active", systemImage: "checkmark.circle") {
                            Task {
                                await viewModel.setActiveBusiness(business.id)
                            }
                        }
                        .tint(.green)
                    }
                }
            }
        }
        .navigationTitle("Business")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    isPresentingNewBusiness = true
                }
            }
        }
        .sheet(item: $businessToEdit) { business in
            AddEditBusinessView(business: business) { businessData in
                await viewModel.updateBusiness(business.id, with: businessData)
            }
        }
        .sheet(isPresented: $isPresentingNewBusiness) {
            AddEditBusinessView(business: nil) { businessData in
                await viewModel.createBusiness(with: businessData)
            }
        }
        .task {
            await viewModel.loadBusinesses()
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
