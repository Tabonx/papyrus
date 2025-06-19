//
//  PrinterManager.swift
//  papyrus
//
//  Created by Pavel Kroupa on 19.06.2025.
//

@preconcurrency import CoreBluetooth
import SwiftUI

// MARK: - ESC/POS Commands 
enum ESCPOSCommands {
    static let initialize: [UInt8] = [0x1B, 0x40] // ESC @
    static let cutPaper: [UInt8] = [0x1D, 0x56, 0x42, 0x00] // GS V B 0
    static let lineFeed: [UInt8] = [0x0A] // LF
    static let carriageReturn: [UInt8] = [0x0D] // CR
    static let selectFontA: [UInt8] = [0x1B, 0x4D, 0x00] // ESC M 0
    static let selectFontB: [UInt8] = [0x1B, 0x4D, 0x01] // ESC M 1
    static let boldOn: [UInt8] = [0x1B, 0x45, 0x01] // ESC E 1
    static let boldOff: [UInt8] = [0x1B, 0x45, 0x00] // ESC E 0
    static let alignLeft: [UInt8] = [0x1B, 0x61, 0x00] // ESC a 0
    static let alignCenter: [UInt8] = [0x1B, 0x61, 0x01] // ESC a 1
    static let alignRight: [UInt8] = [0x1B, 0x61, 0x02] // ESC a 2
    static let doubleWidth: [UInt8] = [0x1B, 0x21, 0x20] // ESC ! 32
    static let doubleHeight: [UInt8] = [0x1B, 0x21, 0x10] // ESC ! 16
    static let normalSize: [UInt8] = [0x1B, 0x21, 0x00] // ESC ! 0

    static func setLineSpacing(_ spacing: UInt8) -> [UInt8] {
        return [0x1B, 0x33, spacing] // ESC 3 n
    }

    static func feedLines(_ lines: UInt8) -> [UInt8] {
        return [0x1B, 0x64, lines] // ESC d n
    }
}

@MainActor
@Observable
class PrinterState {
    var statusMessage: String = "Ready to scan"
    var isConnected: Bool = false
    var isScanning: Bool = false
    var discoveredPrinters: [CBPeripheral] = []
    var isPrinting: Bool = false

    func updateStatus(_ message: String) {
        statusMessage = message
    }

    func setConnected(_ connected: Bool) {
        isConnected = connected
    }

    func setScanning(_ scanning: Bool) {
        isScanning = scanning
    }

    func addDiscoveredPrinter(_ printer: CBPeripheral) {
        if !discoveredPrinters.contains(where: { $0.identifier == printer.identifier }) {
            discoveredPrinters.append(printer)
        }
    }

    func clearDiscoveredPrinters() {
        discoveredPrinters.removeAll()
    }

    func setPrinting(_ printing: Bool) {
        isPrinting = printing
    }
}

// MARK: - Error Types
enum PrinterError: LocalizedError, Sendable {
    case bluetoothNotAvailable
    case connectionTimeout
    case connectionFailed
    case printerNotReady
    case printTimeout
    case noServicesFound

    var errorDescription: String? {
        switch self {
        case .bluetoothNotAvailable:
            return "Bluetooth is not available"
        case .connectionTimeout:
            return "Connection timed out"
        case .connectionFailed:
            return "Failed to connect to printer"
        case .printerNotReady:
            return "Printer is not ready"
        case .printTimeout:
            return "Print job timed out"
        case .noServicesFound:
            return "No printer services found"
        }
    }
}

// MARK: - Async Printer Manager
@MainActor
class AsyncPrinterManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager?
    private var printerPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?

    private let bluetoothQueue = DispatchQueue(label: "bluetooth.queue", qos: .userInitiated)
    private let printerQueue = DispatchQueue(label: "printer.queue", qos: .utility)

    let state = PrinterState()

    // Connection and scan continuations for async operations
    private var scanContinuation: CheckedContinuation<[CBPeripheral], Never>?
    private var connectionContinuation: CheckedContinuation<Void, Error>?
    private var printContinuation: CheckedContinuation<Void, Error>?

    // Common service UUIDs for thermal printers
    private let printerServiceUUIDs: [CBUUID] = [
        CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455"),
        CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2"),
        CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"),
    ]

    private let writeCharacteristicUUIDs: [CBUUID] = [
        CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3"),
        CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"),
    ]

    override init() {
        super.init()
        initializeBluetooth()
    }

    private nonisolated func initializeBluetooth() {
        bluetoothQueue.async {
            let manager = CBCentralManager(delegate: self, queue: self.bluetoothQueue)
            Task { @MainActor in
                self.centralManager = manager
            }
        }
    }

    // MARK: - Public Async Methods

    func scanForPrinters(timeout: TimeInterval = 10.0) async -> [CBPeripheral] {
        guard let centralManager = centralManager, centralManager.state == .poweredOn else {
            state.updateStatus("Bluetooth not powered on")
            return []
        }

        return await withCheckedContinuation { continuation in
            scanContinuation = continuation

            state.clearDiscoveredPrinters()
            state.updateStatus("Scanning for Rongta printers...")
            state.setScanning(true)

            bluetoothQueue.async {
                centralManager.scanForPeripherals(withServices: nil, options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey: false,
                ])
            }

            // Stop scanning after timeout
            Task {
                try? await Task.sleep(for: .seconds(timeout))
                await self.stopScanInternal()
            }
        }
    }

    private func stopScanInternal() async {
        guard let centralManager = centralManager else { return }

        bluetoothQueue.async {
            centralManager.stopScan()
        }

        state.setScanning(false)
        let count = state.discoveredPrinters.count
        if count == 0 {
            state.updateStatus("No Rongta printers found")
        } else {
            state.updateStatus("Found \(count) printer(s)")
        }

        scanContinuation?.resume(returning: state.discoveredPrinters)
        scanContinuation = nil
    }

    func connectToPrinter(_ peripheral: CBPeripheral) async throws {
        guard let centralManager = centralManager, centralManager.state == .poweredOn else {
            throw PrinterError.bluetoothNotAvailable
        }

        state.updateStatus("Connecting to \(peripheral.name ?? "Unknown")...")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connectionContinuation = continuation

            printerPeripheral = peripheral
            printerPeripheral?.delegate = self

            bluetoothQueue.async {
                centralManager.connect(peripheral, options: nil)
            }

            // Timeout after 15 seconds
            Task {
                try? await Task.sleep(for: .seconds(15))
                if self.connectionContinuation != nil {
                    self.connectionContinuation?.resume(throwing: PrinterError.connectionTimeout)
                    self.connectionContinuation = nil
                }
            }
        }
    }

    func disconnect() async {
        guard let peripheral = printerPeripheral, let centralManager = centralManager else { return }

        state.updateStatus("Disconnecting...")

        bluetoothQueue.async {
            centralManager.cancelPeripheralConnection(peripheral)
        }

        resetConnection()
    }

    private func resetConnection() {
        state.setConnected(false)
        printerPeripheral = nil
        writeCharacteristic = nil
        notifyCharacteristic = nil
        state.updateStatus("Disconnected")
    }

    func printTestReceipt() async throws {
        guard state.isConnected,
              let peripheral = printerPeripheral,
              let characteristic = writeCharacteristic else {
            throw PrinterError.printerNotReady
        }

        state.setPrinting(true)
        state.updateStatus("Preparing print job...")

        let printData = await createTestReceiptData()

        defer {
            state.setPrinting(false)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            printContinuation = continuation

            printerQueue.async {
                self.sendDataToPrinter(printData, peripheral: peripheral, characteristic: characteristic)
            }

            // Timeout after 30 seconds
            Task {
                try? await Task.sleep(for: .seconds(30))
                if self.printContinuation != nil {
                    self.printContinuation?.resume(throwing: PrinterError.printTimeout)
                    self.printContinuation = nil
                }
            }
        }
    }

    private func createTestReceiptData() async -> Data {
        return await withCheckedContinuation { continuation in
            Task.detached {
                var printData = Data()

                // Initialize printer
                printData.append(Data(ESCPOSCommands.initialize))

                // Set character set to UTF-8
                printData.append(Data([0x1B, 0x74, 0x10])) // ESC t 16

              
                printData.append(Data(ESCPOSCommands.alignCenter))
                printData.append(Data(ESCPOSCommands.doubleWidth))
                printData.append(Data(ESCPOSCommands.boldOn))
                printData.append("RECEIPT\n".data(using: .ascii) ?? Data())
                printData.append(Data(ESCPOSCommands.normalSize))
                printData.append(Data(ESCPOSCommands.boldOff))

                // Store info
                printData.append("My Store Name\n".data(using: .ascii) ?? Data())
                printData.append("123 Main Street\n".data(using: .ascii) ?? Data())
                printData.append("City, State 12345\n".data(using: .ascii) ?? Data())
                printData.append("Tel: (555) 123-4567\n".data(using: .ascii) ?? Data())

                // Separator line
                printData.append(Data(ESCPOSCommands.alignLeft))
                printData.append("--------------------------------\n".data(using: .ascii) ?? Data())

                // Items
                printData.append("Item A               $5.00\n".data(using: .ascii) ?? Data())
                printData.append("Item B               $3.50\n".data(using: .ascii) ?? Data())
                printData.append("Item C               $2.25\n".data(using: .ascii) ?? Data())

                // Separator
                printData.append("--------------------------------\n".data(using: .ascii) ?? Data())

                // Total
                printData.append(Data(ESCPOSCommands.boldOn))
                printData.append("TOTAL:              $10.75\n".data(using: .ascii) ?? Data())
                printData.append(Data(ESCPOSCommands.boldOff))

                // Footer
                printData.append(Data(ESCPOSCommands.alignCenter))
                printData.append("\nThank you for your business!\n".data(using: .ascii) ?? Data())

                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                printData.append("\(dateFormatter.string(from: Date()))\n".data(using: .ascii) ?? Data())

                // Feed paper and cut
                printData.append(Data(ESCPOSCommands.feedLines(3)))
                printData.append(Data(ESCPOSCommands.cutPaper))

                continuation.resume(returning: printData)
            }
        }
    }

    private nonisolated func sendDataToPrinter(_ data: Data, peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        let chunkSize = 20
        let chunks = data.chunked(into: chunkSize)

        Task { @MainActor in
            self.state.updateStatus("Sending print job... (0/\(chunks.count))")
        }

        sendChunksRecursively(chunks, to: peripheral, characteristic: characteristic, index: 0)
    }

    private nonisolated func sendChunksRecursively(_ chunks: [Data], to peripheral: CBPeripheral,
                                                   characteristic: CBCharacteristic, index: Int) {
        guard index < chunks.count else {
            Task { @MainActor in
                self.state.updateStatus("Print job completed!")
                self.printContinuation?.resume()
                self.printContinuation = nil
            }
            return
        }

        let chunk = chunks[index]
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse

        peripheral.writeValue(chunk, for: characteristic, type: writeType)

        Task { @MainActor in
            self.state.updateStatus("Sending print job... (\(index + 1)/\(chunks.count))")
        }

        // Small delay between chunks to avoid overwhelming the printer
        printerQueue.asyncAfter(deadline: .now() + 0.05) {
            self.sendChunksRecursively(chunks, to: peripheral, characteristic: characteristic, index: index + 1)
        }
    }

    // MARK: - CBCentralManagerDelegate

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let message: String
        switch central.state {
        case .poweredOn:
            message = "Bluetooth ready"
        case .poweredOff:
            message = "Bluetooth is turned off"
        case .resetting:
            message = "Bluetooth is resetting"
        case .unauthorized:
            message = "Bluetooth access denied"
        case .unsupported:
            message = "Bluetooth not supported"
        case .unknown:
            message = "Bluetooth state unknown"
        @unknown default:
            message = "Unknown Bluetooth state"
        }

        Task { @MainActor in
            self.state.updateStatus(message)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }

        let isRongta = name.uppercased().contains("RPP") ||
            name.uppercased().contains("RONGTA") ||
            name.uppercased().contains("PRINTER")

        if isRongta {
            Task { @MainActor in
                self.state.addDiscoveredPrinter(peripheral)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.state.updateStatus("Connected! Discovering services...")
            self.state.setConnected(true)
        }

        peripheral.discoverServices(nil)
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"

        Task { @MainActor in
            self.state.updateStatus("Failed to connect: \(errorMessage)")
            self.connectionContinuation?.resume(throwing: error ?? PrinterError.connectionFailed)
            self.connectionContinuation = nil
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.resetConnection()
        }
    }

    // MARK: - CBPeripheralDelegate

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            Task { @MainActor in
                self.state.updateStatus("No services found")
                self.connectionContinuation?.resume(throwing: PrinterError.noServicesFound)
                self.connectionContinuation = nil
            }
            return
        }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        Task { @MainActor in
            for characteristic in characteristics {
                if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                    self.writeCharacteristic = characteristic
                }

                if characteristic.properties.contains(.notify) {
                    self.notifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }

            if self.writeCharacteristic != nil {
                self.state.updateStatus("Ready to print!")
                self.connectionContinuation?.resume()
                self.connectionContinuation = nil
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            Task { @MainActor in
                self.state.updateStatus("Write error: \(error.localizedDescription)")
                self.printContinuation?.resume(throwing: error)
                self.printContinuation = nil
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Notification error: \(error.localizedDescription)")
            return
        }

        if let data = characteristic.value {
            print("Received data: \(data.map { String(format: "%02x", $0) }.joined(separator: " "))")
        }
    }
}

extension Data {
    func chunked(into size: Int) -> [Data] {
        return stride(from: 0, to: count, by: size).map {
            Data(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
