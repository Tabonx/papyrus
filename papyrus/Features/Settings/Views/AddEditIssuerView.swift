//
//  AddEditIssuerView.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import SwiftUI

struct AddEditIssuerView: View {
    let issuer: IssuerDTO?
    let onSave: (String) async -> Void

    @State private var name: String
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @FocusState private var isNameFocused: Bool

    init(issuer: IssuerDTO?, onSave: @escaping (String) async -> Void) {
        self.issuer = issuer
        self.onSave = onSave
        _name = State(initialValue: issuer?.name ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Issuer Name", text: $name)
                        .focused($isNameFocused)
                } footer: {
                    Text("The issuer name appears on printed receipts")
                }
            }
            .navigationTitle(issuer == nil ? "New Issuer" : "Edit Issuer")
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
                            await onSave(name.trimmingCharacters(in: .whitespacesAndNewlines))
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .onAppear {
                if issuer == nil {
                    isNameFocused = true
                }
            }
        }
    }
}
