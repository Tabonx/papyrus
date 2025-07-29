//
//  papyrusApp.swift
//  papyrus
//
//  Created by Pavel Kroupa on 19.06.2025.
//

import CoreData
import Dependencies
import SwiftUI

@main
struct papyrusApp: App {
    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.printerManager) private var printerManagerWrapper

    var body: some Scene {
        WindowGroup {
            TabView {
                Text("To Be Implemented")
                    .tabItem { Label("POS", systemImage: "creditcard") }

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
            .environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
            .environmentObject(printerManagerWrapper.value)
        }
    }
}
