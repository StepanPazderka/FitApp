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
    var passiveEnergyBurned: Double?
    
    var energyBurned: String = "Not Available"
    var stepsToday: String = "Not Available"
    var stepsYesterday: String = "Not Available"
    var ultimateWeight: String = ""
    var penultimateWeight: String = ""
    
    var showingAlert = false
    var alertLabelDescription = ""
    
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
        
        guard let passiveEnergyBurned = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
            return
        }
        
        guard let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return
        }
        
        guard let stepsCount = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("Step Count Type is no longer available in HealthKit")
            return
        }
        
        healthStore.requestAuthorization(toShare: [], read: [stepsCount, activeEnergyBurned, passiveEnergyBurned, weight]) { success, error in
            if success {
                self.fetchData()
            } else if let error = error {
                self.alertLabelDescription = error.localizedDescription
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
        
        fetchCumulativeData(from: startOfToday, to: now, for: stepCountType, typeOfStartDay: .strictStartDate) { [weak self] result in
            switch result {
            case .success(let data) :
                self?.stepsToday = self?.formatSteps(data) ?? "0"
            case .failure(let error) :
                self?.alertLabelDescription = error.localizedDescription
                self?.showingAlert = true
            }
        }
        
        fetchCumulativeData(from: startOfYesterday, to: startOfToday, for: stepCountType, typeOfStartDay: .strictStartDate) { [weak self] result in
            switch result {
            case .success(let data) :
                self?.stepsYesterday = self?.formatSteps(data) ?? "0"
            case .failure(let error) :
                self?.alertLabelDescription = "Couldnt load steps: \(error.localizedDescription)"
                self?.showingAlert = true
            }
        }
        
        fetchCumulativeData(from: startOfToday, to: now, for: activeEnergyBurnedType, typeOfStartDay: .strictStartDate, completion: { [weak self] result in
            switch result {
            case .success(let data) :
                self?.activeEnergyBurned = data
            case .failure(let error) :
                self?.alertLabelDescription = "Couldnt load active energy: \(error.localizedDescription)"
                self?.showingAlert = true
            }
        })
        
        fetchCumulativeData(from: startOfToday, to: now, for: pasiveEnergyBurnedType, typeOfStartDay: .strictStartDate, completion: { [weak self] result in
            switch result {
            case .success(let data) :
                self?.passiveEnergyBurned = data
                
                if let activeEnergyBurned = self?.activeEnergyBurned {
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    let summedNumber = activeEnergyBurned + data
                    self?.energyBurned = "\(numberFormatter.string(from: NSNumber(value: summedNumber.rounded())) ?? "0")"
                }
            case .failure(let error) :
                self?.alertLabelDescription = "Couldn't load passive energy: \(error.localizedDescription)"
                self?.showingAlert = true
            }
        })
        
        fetchStrictData(from: Calendar.current.date(byAdding: .year, value: -10, to: now)!, to: now, for: weight, options: .mostRecent) { [weak self] weightData in
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
        
        fetchUltimateWeight() { [weak self] result in
            if let result {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 2
                if let number = formatter.string(from: NSNumber(value: (result))) {
                    self?.ultimateWeight = "\(number) kg"
                }
                print(result)
            }
        }
    }
    
    private func fetchCumulativeData(from startDate: Date, to endDate: Date, for type: HKQuantityType, typeOfStartDay: HKQueryOptions, completion: @escaping (Result<Double, Error>) -> Void) {
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
    
    private func fetchStrictData(from startDate: Date, to endDate: Date, for type: HKQuantityType, options: HKStatisticsOptions, completion: @escaping (Result<Double, Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { query, result, error in
            guard let result = result else {
                DispatchQueue.main.async {
                    completion(.failure(error ?? HealthDataFetchError.noDataFound))
                }
                return
            }
            DispatchQueue.main.async {
                if type == HKQuantityType.quantityType(forIdentifier: .bodyMass) {
                    let fetchedData = result.mostRecentQuantity()
                    if let fetchedData {
                        let result = fetchedData.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                        completion(.success(result))
                    }
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchUltimateWeight(completion: @escaping (Double?) -> Void) {
        guard let weightSampleType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }
        
        let query = HKSampleQuery(sampleType: weightSampleType, predicate: nil, limit: 2, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { (query, samples, error) in

            guard let samples = samples as? [HKQuantitySample], samples.count > 1 else {
                print("Unable to fetch weight samples or less than 2 samples returned.")
                return
            }

            let penultimateWeight = samples[0].quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            completion(penultimateWeight)
        }
        healthStore.execute(query)
    }
    
    private func fetchPenultimateWeight(completion: @escaping (Double?) -> Void) {
        guard let weightSampleType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }
        
        let query = HKSampleQuery(sampleType: weightSampleType, predicate: nil, limit: 2, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { (query, samples, error) in

            guard let samples = samples as? [HKQuantitySample], samples.count > 1 else {
                print("Unable to fetch weight samples or less than 2 samples returned.")
                return
            }

            let penultimateWeight = samples[1].quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            completion(penultimateWeight)
        }
        healthStore.execute(query)
    }
    
    private func formatSteps(_ steps: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "0"
    }
}
