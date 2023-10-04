//
//  SwiftDataSchema.swift
//  FitApp
//
//  Created by Štěpán Pazderka on 03.10.2023.
//

import Foundation
import SwiftData

enum FitAppSchemaV1: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [PushupsRecord.self]
    }
    
    static var versionIdentifier: Schema.Version = .init(1, 0, 0)
}

extension FitAppSchemaV1 {
    @Model
    final class PushupsRecord {
        var timestamp: Date
        var pushupsNumber: Int
        
        init(timestamp: Date, noPushups: Int) {
            self.timestamp = timestamp
            self.pushupsNumber = noPushups
        }
    }
}

enum FitAppSchemaV2: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [PullupsRecord.self]
    }
    
    static var versionIdentifier: Schema.Version = .init(1, 1, 0)
}

extension FitAppSchemaV2 {
    @Model
    @Attribute(originalName: "PushupsRecord")
    final class PullupsRecord {
        var timestamp: Date
        @Attribute(originalName: "pushupsNumber")
        var pullupsNumber: Int
        
        init(timestamp: Date, noPushups: Int) {
            self.timestamp = timestamp
            self.pullupsNumber = noPushups
        }
    }
}
