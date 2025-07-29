//
//  ReceiptSettingsView.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import SwiftUI

struct ReceiptSettingsView: View {
    @AppStorage("defaultFooterText") private var defaultFooterText = "Thank you for your business!"
    @AppStorage("defaultPaymentMethod") private var defaultPaymentMethod = PaymentMethod.cash.rawValue
    @AppStorage("receiptNumberPrefix") private var receiptNumberPrefix = ""
    @AppStorage("autoGenerateReceiptNumbers") private var autoGenerateReceiptNumbers = true
    @AppStorage("showTaxBreakdown") private var showTaxBreakdown = true
    @AppStorage("printAfterCreation") private var printAfterCreation = false

    var body: some View {
        Form {
            Section {
                TextField("Footer Text", text: $defaultFooterText, axis: .vertical)
                    .lineLimit(2 ... 4)

                Picker("Payment Method", selection: $defaultPaymentMethod) {
                    ForEach(PaymentMethod.allCases, id: \.rawValue) { method in
                        Text(method.displayName)
                            .tag(method.rawValue)
                    }
                }
            } header: {
                Text("Receipt Content")
            } footer: {
                Text("Default values for new receipts")
            }

            Section {
                Toggle("Auto-Generate Numbers", isOn: $autoGenerateReceiptNumbers)

                if autoGenerateReceiptNumbers {
                    TextField("Number Prefix", text: $receiptNumberPrefix)
                        .textInputAutocapitalization(.characters)
                }
            } header: {
                Text("Receipt Numbering")
            } footer: {
                if autoGenerateReceiptNumbers {
                    Text("Format: \(receiptNumberPrefix.isEmpty ? "" : receiptNumberPrefix + "-")YYYYNNNNN")
                } else {
                    Text("You'll enter receipt numbers manually")
                }
            }

            Section {
                Toggle("Show Tax Breakdown", isOn: $showTaxBreakdown)
                Toggle("Print After Creation", isOn: $printAfterCreation)
            } header: {
                Text("Display Options")
            }
        }
        .navigationTitle("Receipt Defaults")
        .navigationBarTitleDisplayMode(.inline)
    }
}
