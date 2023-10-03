//
//  PushupSheetView.swift
//  FitApp
//
//  Created by Štěpán Pazderka on 02.10.2023.
//

import SwiftUI

struct PushupSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var pushupRecord: PushupsRecord
    @State var shouldShowSaveButton = false
    var callback: ((_ newPushupRecord: PushupsRecord) -> Void)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("Date", selection: $pushupRecord.timestamp, displayedComponents: [.date])
                TextField("Number of pushups", value: $pushupRecord.pushupsNumber, format: .number)
                    .keyboardType(.numberPad)
                    .padding()
                    .border(Color.gray, width: 0.5)
                
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
//
//#Preview {
//    PushupSheetView()
//}
