import Foundation
import HealthKit

class HealthKitService {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    // Track authorization status explicitly
    private var authorizationStatus: AuthorizationStatus = .unknown
    
    // Define possible authorization states for clearer handling
    enum AuthorizationStatus {
        case unknown      // Initial state, haven't checked
        case notAvailable // HealthKit not available on this device
        case notDetermined // Permission not yet requested
        case approved     // User granted permission
        case denied       // User denied permission
    }
    
    private init() {
        // Check initial status during initialization
        checkAuthorizationStatus()
    }
    
    // Check if HealthKit is available on this device
    var isHealthDataAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // Get the current authorization status
    var currentAuthorizationStatus: AuthorizationStatus {
        return authorizationStatus
    }
    
    // Check the current authorization status without prompting the user
    func checkAuthorizationStatus() {
        guard isHealthDataAvailable else {
            authorizationStatus = .notAvailable
            return
        }
        
        // Get the types we need to check permission for - with safe unwrapping
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
              let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            Logger.error("Failed to create HealthKit quantity types", category: .healthKit)
            authorizationStatus = .notAvailable
            return
        }
        
        let typesToCheck: [HKObjectType] = [
            HKObjectType.workoutType(),
            activeEnergyType,
            distanceType,
            exerciseTimeType
        ]
        
        // Check each type's authorization status
        var allApproved = true
        var anyDetermined = false
        
        for type in typesToCheck {
            let status = healthStore.authorizationStatus(for: type)
            if status == .sharingDenied {
                allApproved = false
            }
            if status != .notDetermined {
                anyDetermined = true
            }
        }
        
        if !anyDetermined {
            authorizationStatus = .notDetermined
        } else if allApproved {
            authorizationStatus = .approved
        } else {
            authorizationStatus = .denied
        }
        
        Logger.info("HealthKit authorization status: \(authorizationStatus)", category: .healthKit)
    }
    
    // Request authorization to access HealthKit data
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // First check if HealthKit is available
        guard isHealthDataAvailable else {
            authorizationStatus = .notAvailable
            completion(false, nil)
            return
        }
        
        // Check current status first
        checkAuthorizationStatus()
        
        // If we're already authorized, return success immediately
        if authorizationStatus == .approved {
            completion(true, nil)
            return
        }
        
        // If permission was previously denied, direct user to settings
        if authorizationStatus == .denied {
            let error = NSError(
                domain: "com.ultimate.healthkit",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit access denied. Please enable in Settings."]
            )
            completion(false, error)
            return
        }
        
        // Define the types of data we want to read - with safe unwrapping
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
              let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            Logger.error("Failed to create HealthKit quantity types for authorization", category: .healthKit)
            let error = NSError(
                domain: "com.ultimate.healthkit",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit types unavailable on this device."]
            )
            completion(false, error)
            return
        }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            activeEnergyType,
            distanceType,
            exerciseTimeType
        ]
        
        // Request authorization
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { (success, error) in
            self.authorizationStatus = success ? .approved : .denied
            completion(success, error)
        }
    }
    
    // Fetch today's exercise minutes
    func fetchTodayExerciseMinutes(completion: @escaping (Double?, Error?) -> Void) {
        // Check if we can access HealthKit
        guard checkAndEnsureAccess(completion: { success, error in 
            if !success {
                completion(nil, error)
            }
        }) else {
            return
        }
        
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            Logger.error("Failed to create exercise time quantity type", category: .healthKit)
            let error = NSError(
                domain: "com.ultimate.healthkit",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Exercise time type unavailable."]
            )
            completion(nil, error)
            return
        }
        
        // Get today's start and end dates
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            Logger.error("Failed to calculate end of day", category: .healthKit)
            let error = NSError(
                domain: "com.ultimate.healthkit",
                code: 501,
                userInfo: [NSLocalizedDescriptionKey: "Date calculation failed."]
            )
            completion(nil, error)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, error)
                return
            }
            
            let minutes = sum.doubleValue(for: HKUnit.minute())
            completion(minutes, nil)
        }
        
        healthStore.execute(query)
    }
    
    // Fetch exercise minutes for a specific time range (morning or evening)
    func fetchExerciseMinutes(forTimeOfDay timeOfDay: TimeOfDay, completion: @escaping (Double?, Error?) -> Void) {
        // Check if we can access HealthKit
        guard checkAndEnsureAccess(completion: { success, error in 
            if !success {
                completion(nil, error)
            }
        }) else {
            return
        }
        
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            Logger.error("Failed to create exercise time quantity type", category: .healthKit)
            let error = NSError(
                domain: "com.ultimate.healthkit",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Exercise time type unavailable."]
            )
            completion(nil, error)
            return
        }
        
        // Get today's date
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        
        // Define time ranges for morning and evening
        let startTime: Date
        let endTime: Date
        
        switch timeOfDay {
        case .morning:
            // Morning: 12:00 AM - 11:59 AM
            startTime = startOfDay
            guard let calculatedEndTime = calendar.date(bySettingHour: 11, minute: 59, second: 59, of: startOfDay) else {
                Logger.error("Failed to calculate morning end time", category: .healthKit)
                let error = NSError(domain: "com.ultimate.healthkit", code: 501, userInfo: [NSLocalizedDescriptionKey: "Date calculation failed."])
                completion(nil, error)
                return
            }
            endTime = calculatedEndTime
        case .evening:
            // Evening: 12:00 PM - 11:59 PM
            guard let calculatedStartTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startOfDay),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                Logger.error("Failed to calculate evening time range", category: .healthKit)
                let error = NSError(domain: "com.ultimate.healthkit", code: 501, userInfo: [NSLocalizedDescriptionKey: "Date calculation failed."])
                completion(nil, error)
                return
            }
            startTime = calculatedStartTime
            endTime = nextDay.addingTimeInterval(-1)
        case .anytime:
            // Anytime: Full day
            startTime = startOfDay
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                Logger.error("Failed to calculate anytime end time", category: .healthKit)
                let error = NSError(domain: "com.ultimate.healthkit", code: 501, userInfo: [NSLocalizedDescriptionKey: "Date calculation failed."])
                completion(nil, error)
                return
            }
            endTime = nextDay.addingTimeInterval(-1)
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startTime, end: endTime, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, error)
                return
            }
            
            let minutes = sum.doubleValue(for: HKUnit.minute())
            completion(minutes, nil)
        }
        
        healthStore.execute(query)
    }
    
    // Check if workout requirements are met
    func checkWorkoutCompletion(forTask task: Task, completion: @escaping (Bool) -> Void) {
        // Check if we can access HealthKit
        guard checkAndEnsureAccess(completion: { success, _ in 
            if !success {
                completion(false)
            }
        }) else {
            completion(false)
            return
        }
        
        guard let minimumExerciseMinutes = getMinimumExerciseMinutes(forTask: task) else {
            completion(false)
            return
        }
        
        fetchExerciseMinutes(forTimeOfDay: task.timeOfDay) { minutes, error in
            guard let minutes = minutes, error == nil else {
                completion(false)
                return
            }
            
            // Check if user has exercised for at least the minimum required minutes
            completion(minutes >= minimumExerciseMinutes)
        }
    }
    
    // Helper method to check access and ensure we have authorization
    private func checkAndEnsureAccess(completion: @escaping (Bool, Error?) -> Void) -> Bool {
        // If HealthKit is not available, return false
        guard isHealthDataAvailable else {
            let error = NSError(
                domain: "com.ultimate.healthkit",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]
            )
            completion(false, error)
            return false
        }
        
        // Check current status
        checkAuthorizationStatus()
        
        // If we're approved, return true
        if authorizationStatus == .approved {
            return true
        }
        
        // If not determined, request authorization
        if authorizationStatus == .notDetermined {
            requestAuthorization { success, error in
                completion(success, error)
            }
            return false
        }
        
        // If denied, return false
        if authorizationStatus == .denied {
            let error = NSError(
                domain: "com.ultimate.healthkit",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit access denied. Please enable in Settings."]
            )
            completion(false, error)
            return false
        }
        
        return false
    }
    
    // Helper to determine the minimum exercise minutes required for a specific task
    private func getMinimumExerciseMinutes(forTask task: Task) -> Double? {
        // For 75 Hard, workouts are typically 45 minutes
        if task.type == .workout {
            // Default to 45 minutes for 75 Hard workouts
            return 45.0
        }
        
        // Parse from the task description if needed
        // This could be enhanced to extract exercise duration from task name or description
        let durationString = task.name.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        if !durationString.isEmpty, let duration = Double(durationString) {
            return duration
        }
        
        // Default duration (could be customized based on challenge type)
        return 30.0
    }
} 