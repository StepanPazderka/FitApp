//
//  FitAppApp.swift
//  FitApp
//
//  Created by Štěpán Pazderka on 01.10.2023.
//

import SwiftUI
import SwiftData

typealias PushupsRecord = FitAppSchemaV2.PullupsRecord

enum FitAppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [FitAppSchemaV1.self,
         FitAppSchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.lightweight(fromVersion: FitAppSchemaV1.self, toVersion: FitAppSchemaV2.self)
}

@main
struct FitAppApp: App {
    @ObservedObject var masterViewModel = MasterViewModelImpl()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PushupsRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, migrationPlan: FitAppMigrationPlan.self, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MasterView()
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(masterViewModel)
    }
}
