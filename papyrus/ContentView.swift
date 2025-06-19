//
//  ContentView.swift
//  papyrus
//
//  Created by Pavel Kroupa on 19.06.2025.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @State private var printerManager = AsyncPrinterManager()
    @State private var isScanning = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Rongta RPP200 Printer")
                    .font(.title)
                    .fontWeight(.bold)

                Text(printerManager.state.statusMessage)
                    .foregroundColor(printerManager.state.isConnected ? .green : .primary)
                    .multilineTextAlignment(.center)
                    .padding()

                if !printerManager.state.isConnected {
                    VStack {
                        Button(action: {
                            Task {
                                await scanForPrinters()
                            }
                        }) {
                            HStack {
                                if isScanning {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                }
                                Text(isScanning ? "Scanning..." : "Scan for Printers")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isScanning ? Color.orange : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isScanning)

                        if !printerManager.state.discoveredPrinters.isEmpty {
                            List(printerManager.state.discoveredPrinters, id: \.identifier) { printer in
                                Button {
                                    Task {
                                        await connectToPrinter(printer)
                                    }
                                }
                                label: {
                                    VStack(alignment: .leading) {
                                        Text(printer.name ?? "Unknown Printer")
                                            .fontWeight(.medium)
                                        Text("UUID: \(printer.identifier.uuidString)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .foregroundColor(.primary)
                            }
                            .frame(maxHeight: 200)
                        }
                    }
                } else {
                    VStack(spacing: 15) {
                        Button {
                            Task {
                                await printTestReceipt()
                            }
                        } label: {
                            Text("Print Test Receipt")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(printerManager.state.isPrinting ? Color.orange : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        .disabled(printerManager.state.isPrinting)

                        Button {
                            Task {
                                await printerManager.disconnect()
                            }
                        } label: {
                            Text("Disconnect")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func scanForPrinters() async {
        isScanning = true
        let _ = await printerManager.scanForPrinters()
        isScanning = false
    }

    private func connectToPrinter(_ printer: CBPeripheral) async {
        do {
            try await printerManager.connectToPrinter(printer)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func printTestReceipt() async {
        do {
            try await printerManager.printTestReceipt()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
