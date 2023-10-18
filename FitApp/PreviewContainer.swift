//
//  PreviewContainer.swift
//  FitApp
//
//  Created by Štěpán Pazderka on 18.10.2023.
//

import Foundation
import SwiftData

@MainActor let PreviewContainer: ModelContainer = {
    do {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        let previewPullupsRecord1 = PullupsRecord(timestamp: Date(), noPushups: 5)
        let previewPullupsRecord2 = PullupsRecord(timestamp: Date(), noPushups: 15)

        let container = try ModelContainer(for: PullupsRecord.self, configurations: modelConfiguration)
        let context = container.mainContext
        context.insert(previewPullupsRecord1)
        context.insert(previewPullupsRecord2)
        return container
    } catch {
        fatalError("Could not create preview ModelContainer: \(error)")
    }
}()
