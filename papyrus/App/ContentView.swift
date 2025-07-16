//
//  ContentView.swift
//  papyrus
//
//  Created by Pavel Kroupa on 19.06.2025.
//

import CoreBluetooth
import SwiftUI

struct ReceiptElementEditor: View {
    @Binding var element: ReceiptElement
    @Environment(\.dismiss) private var dismiss
    let onDelete: (() -> Void)?

    init(element: Binding<ReceiptElement>, onDelete: (() -> Void)? = nil) {
        _element = element
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Element Type") {
                    Picker("Type", selection: $element.type) {
                        Text("Text").tag(ReceiptElementType.text)
                        Text("Separator Line").tag(ReceiptElementType.separator)
                        Text("Blank Space").tag(ReceiptElementType.spacer)
                    }
                    .pickerStyle(.segmented)
                }

                if element.type == .text {
                    Section("Text Content") {
                        TextField("Enter text", text: $element.text, axis: .vertical)
                            .lineLimit(1 ... 5)
                    }

                    Section("Formatting") {
                        Toggle("Bold", isOn: $element.isBold)
                        Toggle("Underlined", isOn: $element.isUnderlined)

                        Picker("Alignment", selection: $element.alignment) {
                            Text("Left").tag(ReceiptTextAlignment.left)
                            Text("Center").tag(ReceiptTextAlignment.center)
                            Text("Right").tag(ReceiptTextAlignment.right)
                        }
                        .pickerStyle(.segmented)

                        Picker("Size", selection: $element.size) {
                            Text("Normal").tag(TextSize.normal)
                            Text("Wide").tag(TextSize.doubleWidth)
                            Text("Tall").tag(TextSize.doubleHeight)
                            Text("Large").tag(TextSize.both)
                        }
                        .pickerStyle(.menu)
                    }
                } else if element.type == .spacer {
                    Section("Spacing") {
                        Stepper("Lines: \(element.lineCount)", value: $element.lineCount, in: 1 ... 10)
                    }
                }

                Section("Preview") {
                    ReceiptElementPreview(element: element)
                }

                if onDelete != nil {
                    Section {
                        Button("Delete Element", role: .destructive) {
                            onDelete?()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Edit Element")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct ReceiptElementPreview: View {
    let element: ReceiptElement

    var body: some View {
        VStack {
            switch element.type {
            case .text:
                HStack {
                    if element.alignment == .center || element.alignment == .right {
                        Spacer()
                    }

                    Text(element.text.isEmpty ? "Sample Text" : element.text)
                        .font(fontForSize(element.size))
                        .fontWeight(element.isBold ? .bold : .regular)
                        .underline(element.isUnderlined)
                        .multilineTextAlignment(element.alignment.ui)

                    if element.alignment == .center || element.alignment == .left {
                        Spacer()
                    }
                }

            case .separator:
                Text(String(repeating: "-", count: 32))
                    .font(.system(.caption, design: .monospaced))

            case .spacer:
                ForEach(0 ..< element.lineCount, id: \.self) { _ in
                    Text(" ")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private func fontForSize(_ size: TextSize) -> Font {
        switch size {
        case .normal:
            return .system(.body, design: .monospaced)
        case .doubleWidth:
            return .system(.body, design: .monospaced).width(.expanded)
        case .doubleHeight:
            return .system(.title2, design: .monospaced)
        case .both:
            return .system(.title, design: .monospaced).width(.expanded)
        }
    }
}

struct ReceiptEditor: View {
    @State private var template = ReceiptTemplate()
    @State private var showingElementEditor = false
    @State private var editingElement = ReceiptElement()
    @State private var editingIndex: Int?
    @State private var showingDeleteAlert = false
    @State private var elementToDelete: Int?

    let printerManager: AsyncPrinterManager

    var body: some View {
        NavigationView {
            VStack {
                // Receipt Preview
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(template.elements.enumerated()), id: \.element.id) { index, element in
                            ReceiptElementRow(element: element) {
                                editElement(at: index)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    deleteElement(at: index)
                                }
                            }
                        }
                        .onDelete(perform: deleteElements)

                        if template.elements.isEmpty {
                            Text("No elements added yet")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 100)
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding()

                // Controls
                VStack(spacing: 12) {
                    HStack {
                        Button("Add Text") {
                            addElement(.text)
                        }
                        .buttonStyle(.bordered)

                        Button("Add Separator") {
                            addElement(.separator)
                        }
                        .buttonStyle(.bordered)

                        Button("Add Space") {
                            addElement(.spacer)
                        }
                        .buttonStyle(.bordered)
                    }

                    if printerManager.state.isConnected {
                        Button("Print Receipt") {
                            Task {
                                do {
                                    try await printerManager.printReceipt(template)
                                } catch {
                                    print("Print error: \(error)")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(printerManager.state.isPrinting || template.elements.isEmpty)
                    } else {
                        Text("Connect to printer to print")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Receipt Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !template.elements.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        showingDeleteAlert = true
                    }
                    .disabled(template.elements.isEmpty)
                }
            }
            .alert("Clear All Elements", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    template.elements.removeAll()
                }
            } message: {
                Text("Are you sure you want to remove all elements from the receipt?")
            }
        }
        .sheet(isPresented: $showingElementEditor) {
            ReceiptElementEditor(element: $editingElement, onDelete: editingIndex != nil ? {
                if let index = editingIndex {
                    withAnimation {
                        template.removeElement(at: index)
                    }
                    showingElementEditor = false
                    editingIndex = nil
                }
            } : nil)
                .onDisappear {
                    if let index = editingIndex, index < template.elements.count {
                        template.elements[index] = editingElement
                    } else if editingIndex == nil {
                        template.addElement(editingElement)
                    }
                    editingIndex = nil
                }
        }
    }

    private func addElement(_ type: ReceiptElementType) {
        editingElement = ReceiptElement(type: type)
        editingIndex = nil
        showingElementEditor = true
    }

    private func editElement(at index: Int) {
        editingElement = template.elements[index]
        editingIndex = index
        showingElementEditor = true
    }

    private func deleteElement(at index: Int) {
        withAnimation {
            template.removeElement(at: index)
        }
    }

    private func deleteElements(offsets: IndexSet) {
        withAnimation {
            for index in offsets.sorted(by: >) {
                template.removeElement(at: index)
            }
        }
        showingElementEditor = false
        editingIndex = nil
    }
}

struct ReceiptElementRow: View {
    let element: ReceiptElement
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    switch element.type {
                    case .text:
                        HStack {
                            if element.alignment == .center || element.alignment == .right {
                                Spacer()
                            }

                            Text(element.text.isEmpty ? "Empty Text" : element.text)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(element.isBold ? .bold : .regular)
                                .underline(element.isUnderlined)
                                .foregroundColor(element.text.isEmpty ? .secondary : .primary)

                            if element.alignment == .center || element.alignment == .left {
                                Spacer()
                            }
                        }

                    case .separator:
                        Text(String(repeating: "-", count: 32))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)

                    case .spacer:
                        Text("⏷ \(element.lineCount) line\(element.lineCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var printerManager = AsyncPrinterManager()
    @State private var isScanning = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        TabView {
            // Printer Connection Tab
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
                                    Button(action: {
                                        Task {
                                            await connectToPrinter(printer)
                                        }
                                    }) {
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
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Printer Connected")
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)

                            Button("Disconnect") {
                                Task {
                                    await printerManager.disconnect()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }

                    Spacer()
                }
                .padding()
                .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "printer")
                Text("Printer")
            }

            // Receipt Editor Tab
            ReceiptEditor(printerManager: printerManager)
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Editor")
                }

            // Quick Templates Tab
            QuickTemplatesView(printerManager: printerManager)
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Templates")
                }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
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
}

// MARK: - Quick Templates View

struct QuickTemplatesView: View {
    let printerManager: AsyncPrinterManager

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Quick Templates")
                    .font(.title2)
                    .fontWeight(.bold)

                if printerManager.state.isConnected {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 16) {
                        TemplateCard(title: "Simple Receipt", icon: "receipt") {
                            printSimpleReceipt()
                        }

                        TemplateCard(title: "Store Header", icon: "building.2") {
                            printStoreHeader()
                        }

                        TemplateCard(title: "Menu Item", icon: "list.bullet.rectangle") {
                            printMenuItem()
                        }

                        TemplateCard(title: "Thank You", icon: "heart") {
                            printThankYou()
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "printer.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("Connect to printer first")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Go to the Printer tab to connect your Rongta RPP200")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }

    private func printSimpleReceipt() {
        Task {
            let template = createSimpleReceiptTemplate()
            try? await printerManager.printReceipt(template)
        }
    }

    private func printStoreHeader() {
        Task {
            let template = createStoreHeaderTemplate()
            try? await printerManager.printReceipt(template)
        }
    }

    private func printMenuItem() {
        Task {
            let template = createMenuItemTemplate()
            try? await printerManager.printReceipt(template)
        }
    }

    private func printThankYou() {
        Task {
            let template = createThankYouTemplate()
            try? await printerManager.printReceipt(template)
        }
    }

    private func createSimpleReceiptTemplate() -> ReceiptTemplate {
        let template = ReceiptTemplate()
        template.name = "Simple Receipt"

        template.addElement(ReceiptElement(type: .text, text: "RECEIPT", isBold: true, alignment: .center, size: .doubleWidth))
        template.addElement(ReceiptElement(type: .spacer, lineCount: 1))
        template.addElement(ReceiptElement(type: .text, text: "My Store", alignment: .center))
        template.addElement(ReceiptElement(type: .text, text: "123 Main St", alignment: .center))
        template.addElement(ReceiptElement(type: .spacer, lineCount: 1))
        template.addElement(ReceiptElement(type: .separator))
        template.addElement(ReceiptElement(type: .text, text: "Item A               $5.00"))
        template.addElement(ReceiptElement(type: .text, text: "Item B               $3.50"))
        template.addElement(ReceiptElement(type: .separator))
        template.addElement(ReceiptElement(type: .text, text: "TOTAL:              $8.50", isBold: true))
        template.addElement(ReceiptElement(type: .spacer, lineCount: 2))
        template.addElement(ReceiptElement(type: .text, text: "Thank you!", alignment: .center))

        return template
    }

    private func createStoreHeaderTemplate() -> ReceiptTemplate {
        let template = ReceiptTemplate()
        template.name = "Store Header"

        template.addElement(ReceiptElement(type: .text, text: "MY AWESOME STORE", isBold: true, alignment: .center, size: .both))
        template.addElement(ReceiptElement(type: .spacer, lineCount: 1))
        template.addElement(ReceiptElement(type: .text, text: "123 Business Street", alignment: .center))
        template.addElement(ReceiptElement(type: .text, text: "City, State 12345", alignment: .center))
        template.addElement(ReceiptElement(type: .text, text: "Phone: (555) 123-4567", alignment: .center))
        template.addElement(ReceiptElement(type: .text, text: "www.mystore.com", alignment: .center))
        template.addElement(ReceiptElement(type: .spacer, lineCount: 2))

        return template
    }

    private func createMenuItemTemplate() -> ReceiptTemplate {
        let template = ReceiptTemplate()
        template.name = "Menu Item"

        template.addElement(ReceiptElement(type: .text, text: "TODAY'S SPECIAL", isBold: true, alignment: .center, size: .doubleWidth))
        template.addElement(ReceiptElement(type: .spacer, lineCount: 1))
        template.addElement(ReceiptElement(type: .text, text: "Deluxe Burger", isBold: true, alignment: .center))
        template.addElement(ReceiptElement(type: .text, text: "with fries & drink", alignment: .center))
        template.addElement(ReceiptElement(type: .spacer, lineCount: 1))
        template.addElement(ReceiptElement(type: .text, text: "$12.99", isBold: true, alignment: .center, size: .doubleHeight))
        template.addElement(ReceiptElement(type: .spacer, lineCount: 2))

        return template
    }

    private func createThankYouTemplate() -> ReceiptTemplate {
        let template = ReceiptTemplate()
        template.name = "Thank You"

        template.addElement(ReceiptElement(type: .spacer, lineCount: 2))
        template.addElement(ReceiptElement(type: .text, text: "Thank You!", isBold: true, alignment: .center, size: .both))
        template.addElement(ReceiptElement(type: .spacer, lineCount: 1))
        template.addElement(ReceiptElement(type: .text, text: "for your business", alignment: .center))
        template.addElement(ReceiptElement(type: .spacer, lineCount: 1))
        template.addElement(ReceiptElement(type: .text, text: "Please come again!", alignment: .center))
        template.addElement(ReceiptElement(type: .spacer, lineCount: 3))

        return template
    }
}

struct TemplateCard: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
