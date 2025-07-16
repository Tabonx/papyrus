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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                             persistenceController.persistentContainer.viewContext)
        }
    }
}
