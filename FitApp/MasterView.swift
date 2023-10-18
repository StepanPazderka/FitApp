//
//  ContentView.swift
//  FitApp
//
//  Created by Štěpán Pazderka on 01.10.2023.
//

import SwiftUI
import SwiftData

struct MasterView: View {
    // MARK: - View Model
    @Environment(MasterViewModelImpl.self) var viewModel
    
    // MARK: - Swift Data
    @Environment(\.modelContext) private var modelContext
    @Query private var pushupRecords: [PullupsRecord]
    
    @State private var showingAddPushupSheet = false
    @State private var pushupsInput: String = ""
    
    var showingAlert: Binding<Bool> {
        Binding(
            get: { viewModel.showingAlert },
            set: { viewModel.showingAlert = $0 }
        )
    }
    
    var body: some View {
        TabView {
            GeometryReader { geometry in
                NavigationStack {
                    VStack {
                        Spacer()
                        Text(viewModel.stepsToday)
                            .font(.system(size: 60))
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
                        Text("last weight")
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
                        Text(viewModel.energyBurned)
                            .font(.largeTitle)
                        Text("energy burned today")
                            .foregroundStyle(.secondary)
                            .fontWeight(.regular)
                            .font(.caption)
                        Spacer()
                    }
                }
                .overlay {
                    if viewModel.showingAlert {
                        VStack(alignment: .leading) {
                            Rectangle()
                                .fill(.red)
                                .frame(height: 250)
                                .overlay(
                                    Text(viewModel.alertLabelDescription)
                                        .foregroundColor(.white)
                                        .bold()
                                        .padding(EdgeInsets(top: 150, leading: 0, bottom: 0, trailing: 0))
                                )
                                .frame(height: geometry.safeAreaInsets.top)
                                .ignoresSafeArea(.all)
                            Spacer()
                        }
                    }
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
                            showingAddPushupSheet.toggle()
                        }) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddPushupSheet) {
                    PushupSheetView(pushupRecord: PullupsRecord(timestamp: Date(), noPushups: 0), shouldShowSaveButton: true) { pushupRecord in
                        addPushupRecord(newItem: pushupRecord)
                    }
                }
            }
            .tabItem {
                Image(systemName: "figure.play")
                Text("Pullups")
            }
        }
        .onAppear() {
            viewModel.setupNotification()
            viewModel.requestHealthDataAccess()
        }
    }
    
    private func addPushupRecord(newItem: PullupsRecord) {
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
    do {
        return MasterView()
            .environment(MasterViewModelImpl())
            .modelContainer(PreviewContainer)
    } catch {
        fatalError("Could not create preview ModelContainer: \(error)")
    }
}
