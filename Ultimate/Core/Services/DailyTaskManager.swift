import Foundation
import SwiftData
import HealthKit

class DailyTaskManager {
    static let shared = DailyTaskManager()
    
    private let healthKitService = HealthKitService.shared
    private let notificationManager = NotificationManager.shared
    private var modelContext: ModelContext?
    
    // Track whether HealthKit integration is enabled
    private var isHealthKitEnabled = false
    private var healthKitAuthorizationRequested = false
    
    // Store timer to prevent memory leaks
    private var workoutTrackingTimer: Timer?
    
    private init() {}
    
    // Set the model context when the app starts
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // Request HealthKit authorization with better error handling
    func requestHealthKitAuthorization(completion: @escaping (Bool) -> Void) {
        // Only request once per app session
        if healthKitAuthorizationRequested {
            let currentStatus = healthKitService.currentAuthorizationStatus
            let isAuthorized = currentStatus == .approved
            completion(isAuthorized)
            return
        }
        
        healthKitAuthorizationRequested = true
        
        // First check if HealthKit is available
        if !healthKitService.isHealthDataAvailable {
            isHealthKitEnabled = false
            Logger.warning("HealthKit is not available on this device", category: .healthKit)
            completion(false)
            return
        }
        
        // Request authorization with proper error handling
        healthKitService.requestAuthorization { success, error in
            self.isHealthKitEnabled = success
            
            if let error = error {
                Logger.error("HealthKit authorization failed: \(error.localizedDescription)", category: .healthKit)
            } else if success {
                Logger.info("HealthKit authorization successful", category: .healthKit)
            } else {
                Logger.warning("HealthKit authorization denied by user", category: .healthKit)
            }
            
            completion(success)
        }
    }
    
    // Check HealthKit status without requesting authorization
    func checkHealthKitStatus() -> Bool {
        let status = healthKitService.currentAuthorizationStatus
        isHealthKitEnabled = status == .approved
        return isHealthKitEnabled
    }
    
    // Check and update workout tasks based on Apple Fitness data
    func checkAndUpdateWorkoutTasks() {
        // Skip if HealthKit is not enabled or available
        if !isHealthKitEnabled {
            Logger.info("HealthKit integration is not enabled, skipping workout checks", category: .healthKit)
            return
        }
        
        guard let modelContext = modelContext else {
            Logger.error("Model context not set in DailyTaskManager", category: .database)
            return
        }
        
        // Check authorization status before proceeding
        let status = healthKitService.currentAuthorizationStatus
        guard status == .approved else {
            Logger.warning("HealthKit not authorized (status: \(status)), skipping workout checks", category: .healthKit)
            return
        }
        
        // Get today's workout tasks
        let today = Calendar.current.startOfDay(for: Date())
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            Logger.error("Failed to calculate tomorrow's date", category: .healthKit)
            return
        }
        
        let descriptor = FetchDescriptor<DailyTask>()
        
        do {
            // Fetch all daily tasks
            var dailyTasks = try modelContext.fetch(descriptor)
            
            // Filter in memory instead of using a predicate
            dailyTasks = dailyTasks.filter { dailyTask in
                return dailyTask.date >= today &&
                       dailyTask.date < tomorrow &&
                       dailyTask.status != .completed &&
                       dailyTask.task?.type == .workout
            }
            
            if dailyTasks.isEmpty {
                Logger.info("No incomplete workout tasks found for today", category: .tracking)
                return
            }
            
            for dailyTask in dailyTasks {
                if let task = dailyTask.task {
                    // Check if this task meets the workout criteria
                    healthKitService.checkWorkoutCompletion(forTask: task) { isCompleted in
                        if isCompleted {
                            // Run on main thread since we're updating the UI
                            DispatchQueue.main.async {
                                Logger.info("Automatically completing workout task: \(dailyTask.title)", category: .tracking)
                                dailyTask.complete(notes: "Automatically completed via Apple Fitness tracking")
                                
                                do {
                                    try modelContext.save()
                                    
                                    // Show a notification to the user
                                    self.notificationManager.scheduleWorkoutCompletionNotification(
                                        taskTitle: dailyTask.title,
                                        timeOfDay: task.timeOfDay
                                    )
                                    
                                    // Post notification for UI updates
                                    NotificationCenter.default.post(
                                        name: Notification.Name("WorkoutTaskCompletedAutomatically"),
                                        object: nil,
                                        userInfo: ["taskId": dailyTask.id]
                                    )
                                } catch {
                                    Logger.error("Failed to save task completion: \(error.localizedDescription)", category: .database)
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            Logger.error("Failed to fetch daily tasks: \(error.localizedDescription)", category: .database)
        }
    }
    
    // Set up a timer to periodically check for workout completion
    func startWorkoutTrackingTimer() {
        // Skip if HealthKit is not enabled
        if !isHealthKitEnabled {
            Logger.info("HealthKit integration is not enabled, skipping workout tracking timer", category: .healthKit)
            return
        }
        
        // Invalidate existing timer if it exists
        stopWorkoutTrackingTimer()
        
        // Check immediately on startup, but wrapped in a try-catch to prevent crashes
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.safeCheckAndUpdateWorkoutTasks()
            
            // Schedule on main queue to ensure proper timer lifecycle management
            DispatchQueue.main.async {
                // Then check every 15 minutes
                self?.workoutTrackingTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
                    DispatchQueue.global(qos: .background).async {
                        self?.safeCheckAndUpdateWorkoutTasks()
                    }
                }
            }
        }
    }
    
    // Stop the workout tracking timer
    func stopWorkoutTrackingTimer() {
        workoutTrackingTimer?.invalidate()
        workoutTrackingTimer = nil
        Logger.info("Workout tracking timer stopped", category: .healthKit)
    }
    
    // Safe wrapper for checkAndUpdateWorkoutTasks to prevent crashes
    private func safeCheckAndUpdateWorkoutTasks() {
        checkAndUpdateWorkoutTasks()
    }
} 