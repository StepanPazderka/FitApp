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
import Observation

protocol MasterViewModel {
    var stepsToday: String { get }
    var stepsYesterday: String { get }
    
    func fetchData()
}

@Observable class MasterViewModelImpl: MasterViewModel {
    
    enum HealthDataFetchError: Error {
        case noDataFound
    }
    
    let healthStore = HKHealthStore()
    
    var activeEnergyBurned: Double?
    var pasiveEnergyBurned: Double?
    
    var energyBured: String = "Not Available"
    var stepsToday: String = "Not Available"
    var stepsYesterday: String = "Not Available"
    var ultimateWeight: String = ""
    var penultimateWeight: String = ""
    
    var showingAlertNoHealthDataAcces = false
    var errorLabel = ""
    
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
        
        fetchData(from: startOfToday, to: now, for: stepCountType, typeOfStartDay: .strictStartDate) { [weak self] result in
            switch result {
            case .success(let data) :
                self?.stepsToday = self?.formattedSteps(data) ?? "0"
            case .failure(let error) :
                self?.errorLabel = error.localizedDescription
                self?.showingAlertNoHealthDataAcces = false
            }
        }
        
        fetchData(from: startOfYesterday, to: startOfToday, for: stepCountType, typeOfStartDay: .strictStartDate) { [weak self] result in
            switch result {
            case .success(let data) :
                self?.stepsYesterday = self?.formattedSteps(data) ?? "0"
            case .failure(let error) :
                self?.errorLabel = error.localizedDescription
                self?.showingAlertNoHealthDataAcces = false
            }
        }
        
        fetchData(from: startOfToday, to: now, for: activeEnergyBurnedType, typeOfStartDay: .strictStartDate, completion: { [weak self] result in
            switch result {
            case .success(let data) :
                self?.activeEnergyBurned = data
            case .failure(let error) :
                self?.errorLabel = error.localizedDescription
                self?.showingAlertNoHealthDataAcces = false
            }
        })
        
        fetchData(from: startOfToday, to: now, for: pasiveEnergyBurnedType, typeOfStartDay: .strictStartDate, completion: { [weak self] result in
            switch result {
            case .success(let data) :
                self?.pasiveEnergyBurned = data
                
                if let activeEnergyBurned = self?.activeEnergyBurned {
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    let summedNumber = activeEnergyBurned + data
                    self?.energyBured = "\(numberFormatter.string(from: NSNumber(value: summedNumber.rounded())) ?? "0")"
                }
            case .failure(let error) :
                self?.errorLabel = error.localizedDescription
                self?.showingAlertNoHealthDataAcces = false
            }
        })
        
        
        fetchBodyMass(from: startOfYesterday, to: now, for: weight, options: .mostRecent, completion: { [weak self] weight in
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            if let number = formatter.string(from: NSNumber(value: (weight/1000))) {
                self?.ultimateWeight = "\(number) kg"
            }
            print(weight)
        })
        
        fetchBodyMass(from: Calendar.current.date(byAdding: .year, value: -10, to: now)!, to: now, for: weight, options: .mostRecent) { [weak self] weightData in
            print(weightData)
        }
        
        fetchPenultimateWeight() { [weak self] result in
            if let result {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 2
                if let number = formatter.string(from: NSNumber(value: (result))) {
                    self?.penultimateWeight = "\(number) kg"
                }
                print(result)
            }
        }
    }
    
    private func fetchData(from startDate: Date, to endDate: Date, for type: HKQuantityType, typeOfStartDay: HKQueryOptions, completion: @escaping (Result<Double, Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: typeOfStartDay)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { query, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                if let error {
                    completion(.failure(error))
                }
                completion(.failure(HealthDataFetchError.noDataFound))
                return
            }
            DispatchQueue.main.async {
                if type == HKQuantityType.quantityType(forIdentifier: .stepCount) {
                    completion(.success(sum.doubleValue(for: HKUnit.count())))
                } else if type == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) || type == HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) {
                    completion(.success(sum.doubleValue(for: HKUnit.kilocalorie())))
                }  else if type == HKQuantityType.quantityType(forIdentifier: .bodyMass) {
                    completion(.success(sum.doubleValue(for: HKUnit.gram())))
                } else {
                    completion(.failure(HealthDataFetchError.noDataFound))
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchBodyMass(from startDate: Date, to endDate: Date, for type: HKQuantityType, options: HKStatisticsOptions, completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { _, result, error in
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
    
    func fetchPenultimateWeight(completion: @escaping (Double?) -> Void) {
        // Check if weight type is available
        guard let weightSampleType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            print("Weight Sample Type is unavailable")
            completion(nil)
            return
        }
        
        // Create a query to fetch the most recent 2 samples
        let query = HKSampleQuery(sampleType: weightSampleType, predicate: nil, limit: 2, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { (query, samples, error) in

            guard let samples = samples as? [HKQuantitySample], samples.count > 1 else {
                print("Unable to fetch weight samples or less than 2 samples returned.")
                return
            }

            let penultimateWeight = samples[1].quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))  // or whatever unit you prefer
            print("Penultimate weight: \(penultimateWeight)")
            completion(penultimateWeight)
        }
        healthStore.execute(query)
    }
    
    private func formattedSteps(_ steps: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "0"
    }
}
