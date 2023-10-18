//
//  PushupSheetView.swift
//  FitApp
//
//  Created by Štěpán Pazderka on 02.10.2023.
//

import SwiftUI

struct PushupSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var pushupRecord: PullupsRecord
    @State var shouldShowSaveButton = false
    var callback: ((_ newPushupRecord: PullupsRecord) -> Void)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("Date", selection: $pushupRecord.timestamp, displayedComponents: [.date])
                TextField("Number of pushups", value: $pushupRecord.pullupsNumber, format: .number).onTapGesture {
                    if pushupRecord.pullupsNumber == 0 {
                        pushupRecord.pullupsNumber = 0  // Clear the value
                    }
                }
                .keyboardType(.numberPad)
                .padding()
                .border(Color.gray, width: 0.5)
                .cornerRadius(15.0)
                
                if shouldShowSaveButton {
                    Button("Save") {
                        callback(pushupRecord)
                        dismiss.callAsFunction()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

#Preview {
    PushupSheetView(pushupRecord: PullupsRecord(timestamp: .now, noPushups: 4)) { newPushupRecord in }
}
