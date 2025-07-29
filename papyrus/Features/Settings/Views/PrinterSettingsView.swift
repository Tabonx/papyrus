//
//  PrinterSettingsView.swift
//  papyrus
//
//  Created by Pavel Kroupa on 29.07.2025.
//

import Dependencies
import SwiftUI

struct PrinterSettingsView: View {
    @AppStorage("printerEnabled") private var printerEnabled = false
    @AppStorage("paperWidth") private var paperWidth = 58
    @AppStorage("charactersPerLine") private var charactersPerLine = 32
    @AppStorage("printLogo") private var printLogo = false
    @AppStorage("autoPrintReceipts") private var autoPrintReceipts = false

    @EnvironmentObject var printerManager: PrinterManager

    @State private var showingTestResult = false
    @State private var testResultMessage = ""
    @State private var alertType: AlertType?

    enum AlertType: Identifiable {
        case testSuccess
        case testError(String)
        case connectionError(String)

        var id: String {
            switch self {
            case .testSuccess: return "testSuccess"
            case .testError: return "testError"
            case .connectionError: return "connectionError"
            }
        }
    }

    var body: some View {
        Form {
            Section {
                Toggle("Enable Printing", isOn: $printerEnabled)

                if printerEnabled {
                    connectionStatusRow

                    if !printerManager.connectionState.isOperational {
                        scanningSection
                    }

                    if !printerManager.discoveredPrinters.isEmpty {
                        printersSection
                    }
                }
            } header: {
                Text("Printer Connection")
            } footer: {
                Text("Connect to thermal printers via Bluetooth")
            }

            if printerEnabled {
                printSettingsSection

                if printerManager.connectionState.isOperational {
                    testPrintingSection
                }
            }
        }
        .navigationTitle("Printer")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $alertType) { alertType in
            switch alertType {
            case .testSuccess:
                return Alert(
                    title: Text("Test Successful"),
                    message: Text("Test print sent successfully!"),
                    dismissButton: .default(Text("OK"))
                )

            case let .testError(message):
                return Alert(
                    title: Text("Test Failed"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )

            case let .connectionError(message):
                return Alert(
                    title: Text("Connection Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    @ViewBuilder
    private var connectionStatusRow: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Status")
                    Text(printerManager.connectionState.displayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
            }

            Spacer()

            if case .connecting = printerManager.connectionState {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }

        if let connectedPrinter = printerManager.connectedPrinter {
            HStack {
                Text("Connected Printer")
                Spacer()
                Text(connectedPrinter.name)
                    .foregroundStyle(.secondary)
            }

            Button("Disconnect") {
                Task {
                    await printerManager.disconnect()
                }
            }
            .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var scanningSection: some View {
        Button {
            Task {
                await printerManager.startScanning()
            }
        } label: {
            HStack {
                if case .scanning = printerManager.connectionState {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning...")
                } else {
                    Image(systemName: "magnifyingglass")
                    Text("Scan for Printers")
                }
            }
        }
        .disabled(printerManager.connectionState == .scanning)
    }

    @ViewBuilder
    private var printersSection: some View {
        Section("Available Printers") {
            ForEach(printerManager.discoveredPrinters) { printer in
                Button {
                    Task {
                        do {
                            try await printerManager.connect(to: printer)
                        } catch {
                            alertType = .connectionError(error.localizedDescription)
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(printer.name)
                                .foregroundStyle(.primary)
                            Text("Signal: \(printer.rssi) dBm")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if printerManager.connectedPrinter?.id == printer.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if case .connecting = printerManager.connectionState {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .disabled(printerManager.connectionState == .connecting)
            }
        }
    }

    @ViewBuilder
    private var printSettingsSection: some View {
        Section {
            Picker("Paper Width", selection: $paperWidth) {
                Text("58mm").tag(58)
                Text("80mm").tag(80)
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Characters Per Line")
                Spacer()
                Stepper("\(charactersPerLine)", value: $charactersPerLine, in: 20 ... 48)
            }

            Toggle("Print Business Logo", isOn: $printLogo)
            Toggle("Auto-Print Receipts", isOn: $autoPrintReceipts)
        } header: {
            Text("Print Settings")
        } footer: {
            Text("Characters per line depends on paper width and font size. Standard: 32 for 58mm, 42 for 80mm")
        }
    }

    @ViewBuilder
    private var testPrintingSection: some View {
        Section {
            Button("Print Test Page") {
                Task {
                    do {
                        try await printerManager.printTestReceipt()
                        alertType = .testSuccess
                    } catch {
                        alertType = .testError(error.localizedDescription)
                    }
                }
            }
            .disabled(!printerManager.connectionState.isOperational)

            if case .printing = printerManager.connectionState {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Printing...")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Test Printing")
        } footer: {
            Text("Send a test receipt to verify your printer connection and formatting")
        }
    }

    // MARK: - Helper Properties

    private var statusIcon: String {
        switch printerManager.connectionState {
        case .disconnected:
            return "printer.slash"
        case .scanning:
            return "magnifyingglass"
        case .connecting:
            return "printer.dotmatrix"
        case .connected:
            return "printer"
        case .printing:
            return "printer.filled"
        case .error:
            return "exclamationmark.triangle"
        }
    }

    private var statusColor: Color {
        switch printerManager.connectionState {
        case .disconnected:
            return .secondary
        case .scanning:
            return .blue
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .printing:
            return .blue
        case .error:
            return .red
        }
    }
}
