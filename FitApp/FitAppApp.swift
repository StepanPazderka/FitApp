//
//  FitAppApp.swift
//  FitApp
//
//  Created by Štěpán Pazderka on 01.10.2023.
//

import SwiftUI
import SwiftData

@main
struct FitAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PushupsRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
