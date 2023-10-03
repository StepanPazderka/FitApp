//
//  MasterViewModel.swift
//  FitApp
//
//  Created by Štěpán Pazderka on 01.10.2023.
//

import Foundation
import Combine
import HealthKit
import UIKit

protocol MasterViewModelProtocol {
    var stepsToday: String { get }
    var stepsYesterday: String { get }
    
    func fetchData()
}

class MasterViewModel: MasterViewModelProtocol, ObservableObject {
    
    let healthStore = HKHealthStore()
    
    var activeEnergyBurned: Double?
    var pasiveEnergyBurned: Double?
    
    @Published var energyBured: String = ""
    @Published var stepsToday: String = ""
    @Published var stepsYesterday: String = ""
    @Published var weight: String = ""
    
    @Published var showingAlertNoHealthDataAcces = false
    
    func setupNotification() {
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            self.requestHealthDataAccess()
        }
    }
    
    func requestHealthDataAccess() {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        
        guard let activeEnergyBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return
        }
        
        guard let pasiveEnergyBurned = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
            return
        }
        
        guard let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return
        }
        
        guard let stepsCount = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("Step Count Type is no longer available in HealthKit")
            return
        }
        
        healthStore.requestAuthorization(toShare: [], read: [stepsCount, activeEnergyBurned, pasiveEnergyBurned, weight]) { success, error in
            if success {
                self.fetchData()
            } else if let error = error {
                print("Error requesting HealthKit authorization: \(error)")
            }
        }
    }
    
    func fetchData() {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        guard let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return
        }
        
        guard let pasiveEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
            return
        }
        
        guard let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        
        fetchData(from: startOfToday, to: now, for: stepCountType) { [weak self] steps in
            self?.stepsToday = self?.formattedSteps(steps) ?? "0"
        }
        
        fetchData(from: startOfYesterday, to: startOfToday, for: stepCountType) { [weak self] steps in
            self?.stepsYesterday = self?.formattedSteps(steps) ?? "0"
        }
        
        fetchData(from: startOfToday, to: now, for: activeEnergyBurnedType, completion: { [weak self] activeEnergy in
            self?.activeEnergyBurned = activeEnergy
        })
        
        fetchData(from: startOfToday, to: now, for: pasiveEnergyBurnedType, completion: { [weak self] pasiveEnergy in
            self?.pasiveEnergyBurned = pasiveEnergy
            
            if let activeEnergyBurned = self?.activeEnergyBurned {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let summedNumber = activeEnergyBurned + pasiveEnergy
                self?.energyBured = "\(numberFormatter.string(from: NSNumber(value: summedNumber.rounded())) ?? "0")"
            }
        })
        
        fetchBodyMass(from: startOfYesterday, to: now, for: weight, completion: { [weak self] weight in
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            if let number = formatter.string(from: NSNumber(value: (weight/1000))) {
                self?.weight = "\(number) kg"
            }
            print(weight)
        })
    }

    private func fetchData(from startDate: Date, to endDate: Date, for type: HKQuantityType, completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch steps: \(error?.localizedDescription ?? "N/A")")
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            DispatchQueue.main.async {
                if type == HKQuantityType.quantityType(forIdentifier: .stepCount) {
                    completion(sum.doubleValue(for: HKUnit.count()))
                } else if type == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                    completion(sum.doubleValue(for: HKUnit.kilocalorie()))
                } else if type == HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) {
                    completion(sum.doubleValue(for: HKUnit.kilocalorie()))
                }  else if type == HKQuantityType.quantityType(forIdentifier: .bodyMass) {
                    completion(sum.doubleValue(for: HKUnit.gram()))
                } else {
                    completion(0.0)
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchBodyMass(from startDate: Date, to endDate: Date, for type: HKQuantityType, completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .mostRecent) { _, result, error in
            guard let result = result else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            DispatchQueue.main.async {
                if type == HKQuantityType.quantityType(forIdentifier: .bodyMass) {
                    let quantity = result.mostRecentQuantity()
                    
                    completion(quantity?.doubleValue(for: HKUnit.gram()) ?? 0.0)
                }
            }
        }
        healthStore.execute(query)
    }

    private func formattedSteps(_ steps: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "0"
    }
}
