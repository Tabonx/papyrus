//
//  PrinterManager.swift
//  papyrus
//
//  Created by Pavel Kroupa on 19.06.2025.
//

@preconcurrency import CoreBluetooth
import Dependencies
import SwiftUI

// MARK: - Receipt Formatting Service
@MainActor
class ReceiptFormattingService {
    private let paperWidth: Int
    private let charactersPerLine: Int

    init(paperWidth: Int = 58, charactersPerLine: Int = 32) {
        self.paperWidth = paperWidth
        self.charactersPerLine = charactersPerLine
    }

    func formatReceiptData(from receipt: ReceiptDTO, business: BusinessDTO?, issuer: IssuerDTO?) -> Data {
        var printData = Data()

        // Initialize printer
        printData.append(Data(ESCPOSCommands.initialize))
        printData.append(Data([0x1B, 0x74, 0x10])) // UTF-8 encoding

        // Header - Business Info
        if let business = business {
            printData.append(formatCenteredText(business.name, bold: true, size: .doubleWidth))

            if let address = business.address, !address.isEmpty {
                printData.append(formatCenteredText(address))
            }

            if let email = business.email, !email.isEmpty {
                printData.append(formatCenteredText(email))
            }

            if let website = business.website, !website.isEmpty {
                printData.append(formatCenteredText(website))
            }

            printData.append(formatSeparator())
        }

        // Receipt Info
        printData.append(formatLeftRightText("Receipt #:", receipt.receiptNumber, bold: true))
        printData.append(formatLeftRightText("Date:", receipt.formattedIssuedDate))

        if let issuer = issuer {
            printData.append(formatLeftRightText("Issued by:", issuer.name))
        }

        printData.append(formatLeftRightText("Payment:", receipt.paymentMethodDisplayName))
        printData.append(formatSeparator())

        // Items
        for item in receipt.items.sorted(by: { $0.order < $1.order }) {
            // Item name
            printData.append(formatLeftText(item.itemName))

            // Quantity x Price = Total
            let qtyPriceText = "\(item.quantity) x \(item.formattedUnitPrice)"
            printData.append(formatLeftRightText(qtyPriceText, item.formattedSubtotal))

            // Tax info if applicable
            if item.taxRate > 0 {
                let taxText = "  Tax (\(item.formattedTaxRate))"
                printData.append(formatLeftRightText(taxText, item.formattedTaxAmount))
            }
        }

        printData.append(formatSeparator())

        // Totals
        printData.append(formatLeftRightText("Subtotal:", receipt.formattedSubtotal))
        if receipt.totalTax > 0 {
            printData.append(formatLeftRightText("Total Tax:", receipt.formattedTotalTax))
        }
        printData.append(formatLeftRightText("TOTAL:", receipt.formattedTotal, bold: true, size: .doubleWidth))

        // Footer
        if let footerText = receipt.footerText, !footerText.isEmpty {
            printData.append(formatSeparator())
            printData.append(formatCenteredText(footerText))
        }

        // Legal info
        if let legalDate = receipt.legalPerformanceDate {
            printData.append(Data(ESCPOSCommands.feedLines(1)))
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            printData.append(formatCenteredText("Performance Date: \(dateFormatter.string(from: legalDate))", size: .normal))
        }

        // Cut paper
        printData.append(Data(ESCPOSCommands.feedLines(3)))
        printData.append(Data(ESCPOSCommands.cutPaper))

        return printData
    }

    // MARK: - Formatting Helpers

    private func formatCenteredText(_ text: String, bold: Bool = false, size: TextSize = .normal) -> Data {
        var data = Data()
        data.append(Data(ESCPOSCommands.alignCenter))
        data.append(Data(size.escCommand))

        if bold {
            data.append(Data(ESCPOSCommands.boldOn))
        }

        data.append((text + "\n").data(using: .utf8) ?? Data())

        if bold {
            data.append(Data(ESCPOSCommands.boldOff))
        }

        data.append(Data(ESCPOSCommands.normalSize))
        return data
    }

    private func formatLeftText(_ text: String, bold: Bool = false) -> Data {
        var data = Data()
        data.append(Data(ESCPOSCommands.alignLeft))

        if bold {
            data.append(Data(ESCPOSCommands.boldOn))
        }

        data.append((text + "\n").data(using: .utf8) ?? Data())

        if bold {
            data.append(Data(ESCPOSCommands.boldOff))
        }

        return data
    }

    private func formatLeftRightText(_ left: String, _ right: String, bold: Bool = false, size: TextSize = .normal) -> Data {
        var data = Data()
        data.append(Data(ESCPOSCommands.alignLeft))
        data.append(Data(size.escCommand))

        if bold {
            data.append(Data(ESCPOSCommands.boldOn))
        }

        let maxWidth = size == .normal ? charactersPerLine : charactersPerLine / 2
        let spacing = maxWidth - left.count - right.count
        let line = left + String(repeating: " ", count: max(1, spacing)) + right

        data.append((line + "\n").data(using: .utf8) ?? Data())

        if bold {
            data.append(Data(ESCPOSCommands.boldOff))
        }

        data.append(Data(ESCPOSCommands.normalSize))
        return data
    }

    private func formatSeparator() -> Data {
        var data = Data()
        data.append(Data(ESCPOSCommands.alignLeft))
        let separator = String(repeating: "-", count: charactersPerLine)
        data.append((separator + "\n").data(using: .utf8) ?? Data())
        return data
    }
}

// MARK: - Discovered Printer Model
struct DiscoveredPrinter: Identifiable, Hashable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    let rssi: Int
    let discoveredAt: Date

    init(peripheral: CBPeripheral, rssi: NSNumber) {
        id = peripheral.identifier
        self.peripheral = peripheral
        name = peripheral.name ?? "Unknown Printer"
        self.rssi = rssi.intValue
        discoveredAt = Date()
    }

    static func == (lhs: DiscoveredPrinter, rhs: DiscoveredPrinter) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Printer Connection State
enum PrinterConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case connected
    case printing
    case error(String)

    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .scanning: return "Scanning..."
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .printing: return "Printing..."
        case let .error(message): return "Error: \(message)"
        }
    }

    var isOperational: Bool {
        switch self {
        case .connected: return true
        default: return false
        }
    }
}

// MARK: - Enhanced Printer Manager
@MainActor
class PrinterManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var connectionState: PrinterConnectionState = .disconnected
    @Published var discoveredPrinters: [DiscoveredPrinter] = []
    @Published var connectedPrinter: DiscoveredPrinter?

    private var centralManager: CBCentralManager?
    private var printerPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?

    private let bluetoothQueue = DispatchQueue(label: "bluetooth.queue", qos: .userInitiated)
    private let printerQueue = DispatchQueue(label: "printer.queue", qos: .utility)

    private var connectionContinuation: CheckedContinuation<Void, Error>?
    private var printContinuation: CheckedContinuation<Void, Error>?

    // Dependencies
    @ObservationIgnored
    @Dependency(\.businessRepository) var businessRepository

    @ObservationIgnored
    @Dependency(\.issuerRepository) var issuerRepository

    private lazy var formattingService = ReceiptFormattingService()

    override nonisolated init() {
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

    // MARK: - Public API

    func startScanning() async {
        guard let centralManager = centralManager, centralManager.state == .poweredOn else {
            connectionState = .error("Bluetooth not available")
            return
        }

        connectionState = .scanning
        discoveredPrinters.removeAll()

        bluetoothQueue.async {
            centralManager.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false,
            ])
        }

        // Auto-stop after 10 seconds
        try? await Task.sleep(for: .seconds(10))
        await stopScanning()
    }

    func stopScanning() async {
        guard let centralManager = centralManager else { return }

        bluetoothQueue.async {
            centralManager.stopScan()
        }

        if connectionState == .scanning {
            connectionState = discoveredPrinters.isEmpty ? .disconnected : .disconnected
        }
    }

    func connect(to printer: DiscoveredPrinter) async throws {
        guard let centralManager = centralManager, centralManager.state == .poweredOn else {
            throw PrinterError.bluetoothNotAvailable
        }

        connectionState = .connecting

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connectionContinuation = continuation
            printerPeripheral = printer.peripheral
            printerPeripheral?.delegate = self

            bluetoothQueue.async {
                centralManager.connect(printer.peripheral, options: nil)
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

        connectedPrinter = printer
    }

    func disconnect() async {
        guard let peripheral = printerPeripheral, let centralManager = centralManager else { return }

        bluetoothQueue.async {
            centralManager.cancelPeripheralConnection(peripheral)
        }

        resetConnection()
    }

    func printReceipt(_ receipt: ReceiptDTO) async throws {
        guard connectionState.isOperational,
              let peripheral = printerPeripheral,
              let characteristic = writeCharacteristic else {
            throw PrinterError.printerNotReady
        }

        connectionState = .printing

        // Get business and issuer data
        let business = try? await businessRepository.fetchBusiness(withId: receipt.businessId)
        let issuer = receipt.issuerId != nil ? try? await issuerRepository.fetchIssuer(withId: receipt.issuerId!) : nil

        let printData = formattingService.formatReceiptData(from: receipt, business: business, issuer: issuer)

        defer {
            if connectionState == .printing {
                connectionState = .connected
            }
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

    func printTestReceipt() async throws {
        // Create a test receipt
        let testReceipt = ReceiptDTO(
            id: UUID(),
            receiptNumber: "TEST-001",
            createdAt: Date(),
            issuedDate: Date(),
            legalPerformanceDate: Date(),
            paymentMethod: PaymentMethod.cash.rawValue,
            footerText: "Test Receipt - Thank you!",
            issuedBy: "Test User",
            businessId: UUID(),
            issuerId: nil,
            items: [
                ReceiptItemDTO(
                    id: UUID(),
                    itemName: "Test Item 1",
                    unitPrice: 100.00,
                    quantity: 1,
                    taxRate: 0.21,
                    order: 0,
                    itemId: nil
                ),
                ReceiptItemDTO(
                    id: UUID(),
                    itemName: "Test Item 2",
                    unitPrice: 50.00,
                    quantity: 2,
                    taxRate: 0.21,
                    order: 1,
                    itemId: nil
                ),
            ]
        )

        try await printReceipt(testReceipt)
    }

    // MARK: - Private Methods

    private func resetConnection() {
        connectionState = .disconnected
        connectedPrinter = nil
        printerPeripheral = nil
        writeCharacteristic = nil
        notifyCharacteristic = nil
    }

    private nonisolated func sendDataToPrinter(_ data: Data, peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        let chunkSize = 20
        let chunks = data.chunked(into: chunkSize)

        sendChunksRecursively(chunks, to: peripheral, characteristic: characteristic, index: 0)
    }

    private nonisolated func sendChunksRecursively(_ chunks: [Data], to peripheral: CBPeripheral,
                                                   characteristic: CBCharacteristic, index: Int) {
        guard index < chunks.count else {
            Task { @MainActor in
                self.printContinuation?.resume()
                self.printContinuation = nil
            }
            return
        }

        let chunk = chunks[index]
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse

        peripheral.writeValue(chunk, for: characteristic, type: writeType)

        // Small delay between chunks
        printerQueue.asyncAfter(deadline: .now() + 0.05) {
            self.sendChunksRecursively(chunks, to: peripheral, characteristic: characteristic, index: index + 1)
        }
    }

    // MARK: - CBCentralManagerDelegate

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                if self.connectionState == .error("Bluetooth not available") {
                    self.connectionState = .disconnected
                }

            case .poweredOff:
                self.connectionState = .error("Bluetooth is turned off")

            case .unauthorized:
                self.connectionState = .error("Bluetooth access denied")

            case .unsupported:
                self.connectionState = .error("Bluetooth not supported")

            default:
                self.connectionState = .error("Bluetooth unavailable")
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }

        let isRongta = name.uppercased().contains("RPP") ||
            name.uppercased().contains("RONGTA") ||
            name.uppercased().contains("PRINTER")

        if isRongta {
            let printer = DiscoveredPrinter(peripheral: peripheral, rssi: RSSI)
            Task { @MainActor in
                if !self.discoveredPrinters.contains(printer) {
                    self.discoveredPrinters.append(printer)
                }
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.connectionState = .connecting
        }
        peripheral.discoverServices(nil)
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            let errorMessage = error?.localizedDescription ?? "Unknown error"
            self.connectionState = .error("Connection failed: \(errorMessage)")
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
                self.connectionState = .error("No services found")
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
                self.connectionState = .connected
                self.connectionContinuation?.resume()
                self.connectionContinuation = nil
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            Task { @MainActor in
                self.connectionState = .error("Write failed: \(error.localizedDescription)")
                self.printContinuation?.resume(throwing: error)
                self.printContinuation = nil
            }
        }
    }
}

// MARK: - Dependency Registration
private enum PrinterManagerKey: DependencyKey {
    static let liveValue: MainActorIsolated<PrinterManager> = .init {
        PrinterManager()
    }
}

extension DependencyValues {
    var printerManager: MainActorIsolated<PrinterManager> {
        get { self[PrinterManagerKey.self] }
        set { self[PrinterManagerKey.self] = newValue }
    }
}
