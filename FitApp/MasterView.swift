//
//  ContentView.swift
//  FitApp
//
//  Created by Štěpán Pazderka on 01.10.2023.
//

import SwiftUI
import SwiftData

struct MasterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MasterViewModelImpl.self) var viewModel
    @Query private var pushupRecords: [PushupsRecord]
    
    @State private var showingAddPushupAlert = false
    @State private var pushupsInput: String = ""
        
    var body: some View {
        TabView {
            NavigationStack {
                VStack {
                    Spacer()
                    Text(viewModel.stepsToday)
                        .font(.system(size: 70))
                    Text("steps today")
                        .foregroundStyle(.secondary)
                        .fontWeight(.regular)
                        .font(.title)
                        .offset(CGSize(width: 00.0, height: -10.0))
                    Spacer()
                        .frame(height: 20)
                    Text(viewModel.stepsYesterday)
                        .font(.largeTitle)
                    Text("steps yesterday")
                        .foregroundStyle(.secondary)
                        .fontWeight(.regular)
                        .font(.caption)
                    Spacer()
                    Text(viewModel.ultimateWeight)
                        .font(.largeTitle)
                    Text("weight")
                        .foregroundStyle(.secondary)
                        .fontWeight(.regular)
                        .font(.caption)
                    Spacer()
                    Text(viewModel.penultimateWeight)
                        .font(.largeTitle)
                    Text("second to last weight")
                        .foregroundStyle(.secondary)
                        .fontWeight(.regular)
                        .font(.caption)
                    Spacer()
                        .font(.title3)
                    Text(viewModel.energyBured)
                        .font(.largeTitle)
                    Text("energy burned today")
                        .foregroundStyle(.secondary)
                        .fontWeight(.regular)
                        .font(.caption)
                    Spacer()
                }
            }
            .tabItem {
                Image(systemName: "figure.walk")
                Text("Daily steps")
            }
            .navigationTitle("Daily steps")
            
            NavigationView {
                List {
                    ForEach(pushupRecords.sorted(by: { $0.timestamp > $1.timestamp })) { item in
                        NavigationLink {
                            PushupSheetView(pushupRecord: item, callback: { number in })
                        } label: {
                            HStack {
                                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .none))
                                Spacer()
                                    .fontWeight(.light)
                                Text("\(item.pullupsNumber)")
                                    .fontWeight(.bold)
                                    .font(.headline)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: {
                            showingAddPushupAlert.toggle()
                        }) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddPushupAlert) {
                    PushupSheetView(pushupRecord: PushupsRecord(timestamp: Date(), noPushups: 0), shouldShowSaveButton: true) { pushupRecord in
                        addPushupRecord(newItem: pushupRecord)
                    }
                }
            }
            .tabItem {
                Image(systemName: "figure.barre")
                Text("Pushups")
            }
        }
        .onAppear() {
            viewModel.setupNotification()
            viewModel.requestHealthDataAccess()
        }
        .alert(isPresented: $showingAddPushupAlert, content: {
            Alert(title: Text(viewModel.errorLabel))
        })
    }
    
    private func addPushupRecord(newItem: PushupsRecord) {
        withAnimation {
            modelContext.insert(newItem)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(pushupRecords[index])
            }
        }
    }
}

#Preview {
    MasterView()
        .modelContainer(for: PushupsRecord.self, inMemory: true)
}
