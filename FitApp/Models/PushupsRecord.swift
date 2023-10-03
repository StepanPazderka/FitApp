//
//  Item.swift
//  FitApp
//
//  Created by Štěpán Pazderka on 01.10.2023.
//

import Foundation
import SwiftData

@Model
final class PushupsRecord {
    var timestamp: Date
    var pushupsNumber: Int
    
    init(timestamp: Date, noPushups: Int) {
        self.timestamp = timestamp
        self.pushupsNumber = noPushups
    }
}
