//
//  AddEditBusinessView.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import SwiftUI

struct AddEditBusinessView: View {
    let business: BusinessDTO?
    let onSave: (BusinessFormData) async -> Void

    @State private var formData: BusinessFormData
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name
        case address
        case email
        case website
    }

    init(business: BusinessDTO?, onSave: @escaping (BusinessFormData) async -> Void) {
        self.business = business
        self.onSave = onSave
        _formData = State(initialValue: business != nil ? BusinessFormData(from: business!) : BusinessFormData())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Information") {
                    TextField("Business Name", text: $formData.name)
                        .focused($focusedField, equals: .name)

                    TextField("Address", text: $formData.address, axis: .vertical)
                        .lineLimit(2 ... 4)
                        .focused($focusedField, equals: .address)

                    TextField("Email", text: $formData.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .email)

                    TextField("Website", text: $formData.website)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .website)
                }

                Section("Defaults") {
                    HStack {
                        Text("Tax Rate")
                        Spacer()
                        TextField("Tax Rate", value: $formData.taxRate, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }

                    Picker("Currency", selection: $formData.currency) {
                        Text("CZK").tag("CZK")
                        Text("EUR").tag("EUR")
                        Text("USD").tag("USD")
                    }
                }
            }
            .navigationTitle(business == nil ? "New Business" : "Edit Business")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            await onSave(formData)
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(!formData.isValid || isSaving)
                }
            }
            .onAppear {
                if business == nil {
                    focusedField = .name
                }
            }
        }
    }
}
