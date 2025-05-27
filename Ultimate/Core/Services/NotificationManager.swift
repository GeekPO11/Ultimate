import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var currentBadgeCount: Int = 0
    
    private init() {
        print("NotificationManager: Initializing...")
        checkAuthorizationStatus()
        updateCurrentBadgeCount()
    }
    
    /// Updates the current badge count from the notification center
    private func updateCurrentBadgeCount() {
        // Get the current badge count using notification settings
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // We can't directly get the badge count from UNUserNotificationCenter
            // We'll keep track of it internally in our app
            // No action needed here as we'll update currentBadgeCount when we set it
        }
    }
    
    /// Resets the notification badge count
    func resetBadgeCount() {
        print("NotificationManager: Resetting badge count")
        // Use the recommended UNUserNotificationCenter method instead of deprecated UIApplication property
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("NotificationManager: Error resetting badge count: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.currentBadgeCount = 0
                    print("NotificationManager: Badge count reset successfully")
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        print("NotificationManager: Checking authorization status")
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
                print("NotificationManager: Authorization status - \(self.isAuthorized)")
            }
        }
    }
    
    func requestAuthorization() {
        print("NotificationManager: Requesting authorization")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                print("NotificationManager: Authorization granted - \(success)")
                if let error = error {
                    print("NotificationManager: Error requesting authorization - \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Challenge Notifications
    
    /// Schedule notifications for a challenge based on its type and tasks
    func scheduleNotificationsForChallenge(_ challenge: Challenge) {
        guard isAuthorized else {
            print("NotificationManager: Not authorized to send notifications")
            return
        }
        
        // First remove any existing notifications for this challenge
        removeNotificationsForChallenge(challenge)
        
        // Schedule notifications based on challenge type
        switch challenge.type {
        case .seventyFiveHard:
            scheduleSeventyFiveHardNotifications(challenge)
        case .waterFasting:
            scheduleWaterFastingNotifications(challenge)
        case .thirtyOneModified:
            scheduleHabitBuilderNotifications(challenge)
        case .custom:
            scheduleCustomChallengeNotifications(challenge)
        }
        
        Logger.info("Scheduled notifications for challenge: \(challenge.name)", category: .notification)
    }
    
    /// Remove all notifications for a specific challenge
    func removeNotificationsForChallenge(_ challenge: Challenge) {
        let identifierPrefix = "challenge_\(challenge.id.uuidString)"
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests.filter { 
                $0.identifier.hasPrefix(identifierPrefix) || 
                ($0.content.userInfo["challengeId"] as? String == challenge.id.uuidString)
            }.map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            Logger.info("Removed \(identifiers.count) notifications for challenge: \(challenge.name)", category: .notification)
        }
    }
    
    /// Removes all pending notifications and resets badge count
    func removeAllPendingNotifications() {
        print("NotificationManager: Removing all pending notifications")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        resetBadgeCount()
    }
    
    /// Enables all notification types and schedules daily reminders
    func enableAllNotifications(userSettings: UserSettings? = nil) {
        print("NotificationManager: Enabling all notifications")
        
        // Make sure we have authorization
        guard isAuthorized else {
            print("NotificationManager: Cannot enable notifications - not authorized")
            return
        }
        
        // Enable all notification types in UserSettings
        DispatchQueue.main.async {
            if let userSettings = userSettings {
                userSettings.notifyWorkouts = true
                userSettings.notifyNutrition = true
                userSettings.notifyWater = true
                userSettings.notifyReading = true
                userSettings.notifyPhotos = true
                
                print("NotificationManager: All notification types enabled in UserSettings")
            } else {
                print("NotificationManager: No UserSettings provided, skipping preference updates")
            }
        }
        
        // Setup notification categories and actions
        setupNotificationCategories()
        
        // Register for remote notifications
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        print("NotificationManager: All notifications enabled")
    }
    
    /// Sets up notification categories and actions for the app
    private func setupNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        
        // Define actions
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Mark as Complete",
            options: .foreground
        )
        
        let laterAction = UNNotificationAction(
            identifier: "LATER_ACTION",
            title: "Remind Me Later",
            options: .foreground
        )
        
        // Create the category
        let taskCategory = UNNotificationCategory(
            identifier: "TASK_CATEGORY",
            actions: [completeAction, laterAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register the category
        center.setNotificationCategories([taskCategory])
        
        print("NotificationManager: Notification categories and actions set up")
    }
    
    // MARK: - Challenge-Specific Notification Scheduling
    
    private func scheduleSeventyFiveHardNotifications(_ challenge: Challenge) {
        // 75 Hard has specific requirements that need reminders at specific times
        
        // Morning workout reminder (6:00 AM)
        scheduleRepeatingNotification(
            title: "Morning Workout",
            body: "Time for your first workout of the day! 💪",
            hour: 6,
            minute: 0,
            challengeId: challenge.id,
            taskType: .workout,
            identifier: "\(challenge.id)-morning-workout"
        )
        
        // Water reminders (every 2 hours from 8 AM to 8 PM)
        for hour in stride(from: 8, to: 21, by: 2) {
            scheduleRepeatingNotification(
                title: "Hydration Check",
                body: "Remember to drink water! Stay on track with your gallon.",
                hour: hour,
                minute: 0,
                challengeId: challenge.id,
                taskType: .water,
                identifier: "\(challenge.id)-water-\(hour)"
            )
        }
        
        // Reading reminder (9:00 PM)
        scheduleRepeatingNotification(
            title: "Daily Reading",
            body: "Time to read your 10 pages for the day! 📚",
            hour: 21,
            minute: 0,
            challengeId: challenge.id,
            taskType: .reading,
            identifier: "\(challenge.id)-reading"
        )
        
        // Evening workout reminder (5:00 PM)
        scheduleRepeatingNotification(
            title: "Evening Workout",
            body: "Time for your second workout of the day! 💪",
            hour: 17,
            minute: 0,
            challengeId: challenge.id,
            taskType: .workout,
            identifier: "\(challenge.id)-evening-workout"
        )
        
        // Progress photo reminder (8:00 PM)
        scheduleRepeatingNotification(
            title: "Daily Progress Photo",
            body: "Don't forget to take your daily progress photo!",
            hour: 20,
            minute: 0,
            challengeId: challenge.id,
            taskType: .photo,
            identifier: "\(challenge.id)-progress-photo"
        )
    }
    
    private func scheduleWaterFastingNotifications(_ challenge: Challenge) {
        // Water fasting needs frequent hydration reminders and fasting milestone notifications
        
        // Hydration reminders every hour from 8 AM to 8 PM
        for hour in 8...20 {
            scheduleRepeatingNotification(
                title: "Hydration Reminder",
                body: "Remember to drink water during your fast! Stay hydrated.",
                hour: hour,
                minute: 0,
                challengeId: challenge.id,
                taskType: .water,
                identifier: "\(challenge.id)-water-\(hour)"
            )
        }
        
        // Fasting milestone reminders
        let milestones = [12, 16, 20, 24, 36, 48, 60, 72]
        for (_, hours) in milestones.enumerated() {
            // Calculate when this milestone will be hit based on challenge start date
            if let startDate = challenge.startDate {
                let milestoneDate = Calendar.current.date(byAdding: .hour, value: hours, to: startDate)
                if let milestoneDate = milestoneDate, milestoneDate > Date() {
                    scheduleOneTimeNotification(
                        title: "Fasting Milestone! 🎉",
                        body: "You've been fasting for \(hours) hours! Keep going!",
                        date: milestoneDate,
                        challengeId: challenge.id,
                        taskType: .fasting,
                        identifier: "\(challenge.id)-milestone-\(hours)"
                    )
                }
            }
        }
        
        // Weight tracking reminder (morning)
        scheduleRepeatingNotification(
            title: "Weight Tracking",
            body: "Time to record your weight for the day!",
            hour: 7,
            minute: 0,
            challengeId: challenge.id,
            taskType: .weight,
            identifier: "\(challenge.id)-weight-tracking"
        )
    }
    
    private func scheduleHabitBuilderNotifications(_ challenge: Challenge) {
        // Habit builder needs consistent reminders throughout the day
        
        // Morning habit reminder
        scheduleRepeatingNotification(
            title: "Morning Habits",
            body: "Time to complete your morning habits! Start your day right.",
            hour: 7,
            minute: 30,
            challengeId: challenge.id,
            taskType: .habit,
            identifier: "\(challenge.id)-morning-habits"
        )
        
        // Midday check-in
        scheduleRepeatingNotification(
            title: "Midday Habit Check",
            body: "How are your habits going today? Take a moment to check in.",
            hour: 12,
            minute: 30,
            challengeId: challenge.id,
            taskType: .habit,
            identifier: "\(challenge.id)-midday-habits"
        )
        
        // Evening habit reminder
        scheduleRepeatingNotification(
            title: "Evening Habits",
            body: "Don't forget to complete your evening habits!",
            hour: 19,
            minute: 0,
            challengeId: challenge.id,
            taskType: .habit,
            identifier: "\(challenge.id)-evening-habits"
        )
        
        // Reflection reminder
        scheduleRepeatingNotification(
            title: "Daily Reflection",
            body: "Take a moment to reflect on your habits today. What went well? What can improve?",
            hour: 21,
            minute: 0,
            challengeId: challenge.id,
            taskType: .habit,
            identifier: "\(challenge.id)-reflection"
        )
    }
    
    private func scheduleCustomChallengeNotifications(_ challenge: Challenge) {
        // For custom challenges, schedule based on the task types
        
        // Group tasks by type
        var tasksByType: [TaskType?: [Task]] = [:]
        for task in challenge.tasks {
            if let type = task.type {
                if tasksByType[type] == nil {
                    tasksByType[type] = []
                }
                tasksByType[type]?.append(task)
            }
        }
        
        // Schedule notifications for each task type
        for (type, tasks) in tasksByType {
            guard let type = type else { continue }
            
            // Schedule based on task type
            switch type {
            case .workout:
                scheduleWorkoutNotifications(tasks, challenge: challenge)
            case .water:
                scheduleWaterNotifications(tasks, challenge: challenge)
            case .reading:
                scheduleReadingNotifications(tasks, challenge: challenge)
            case .nutrition:
                scheduleNutritionNotifications(tasks, challenge: challenge)
            case .fasting:
                scheduleFastingNotifications(tasks, challenge: challenge)
            case .habit:
                scheduleHabitNotifications(tasks, challenge: challenge)
            case .weight:
                scheduleWeightNotifications(tasks, challenge: challenge)
            case .photo:
                schedulePhotoNotifications(tasks, challenge: challenge)
            case .mindfulness:
                scheduleMeditationNotifications(tasks, challenge: challenge)
            case .journal:
                scheduleJournalNotifications(tasks, challenge: challenge)
            case .custom:
                scheduleCustomTaskNotifications(tasks, challenge: challenge)
            }
        }
    }
    
    // MARK: - Task-Specific Notification Scheduling
    
    private func scheduleWorkoutNotifications(_ tasks: [Task], challenge: Challenge) {
        for (index, task) in tasks.enumerated() {
            if let scheduledTime = task.scheduledTime {
                // Use the scheduled time if available
                let hour = Calendar.current.component(.hour, from: scheduledTime)
                let minute = Calendar.current.component(.minute, from: scheduledTime)
                
                scheduleRepeatingNotification(
                    title: "Workout Time",
                    body: task.name,
                    hour: hour,
                    minute: minute,
                    challengeId: challenge.id,
                    taskType: .workout,
                    identifier: "\(challenge.id)-workout-\(index)"
                )
            } else {
                // Default times if no scheduled time
                let defaultHours = [6, 17] // 6 AM and 5 PM
                let hour = index < defaultHours.count ? defaultHours[index] : 12
                
                scheduleRepeatingNotification(
                    title: "Workout Reminder",
                    body: task.name,
                    hour: hour,
                    minute: 0,
                    challengeId: challenge.id,
                    taskType: .workout,
                    identifier: "\(challenge.id)-workout-\(index)"
                )
            }
        }
    }
    
    private func scheduleWaterNotifications(_ tasks: [Task], challenge: Challenge) {
        // Schedule water reminders every 2 hours from 8 AM to 8 PM
        for hour in stride(from: 8, to: 21, by: 2) {
            scheduleRepeatingNotification(
                title: "Hydration Reminder",
                body: "Remember to drink water! Stay hydrated.",
                hour: hour,
                minute: 0,
                challengeId: challenge.id,
                taskType: .water,
                identifier: "\(challenge.id)-water-\(hour)"
            )
        }
    }
    
    private func scheduleReadingNotifications(_ tasks: [Task], challenge: Challenge) {
        // Schedule reading reminder in the evening
        scheduleRepeatingNotification(
            title: "Reading Time",
            body: "Time for your daily reading! 📚",
            hour: 21,
            minute: 0,
            challengeId: challenge.id,
            taskType: .reading,
            identifier: "\(challenge.id)-reading"
        )
    }
    
    private func scheduleNutritionNotifications(_ tasks: [Task], challenge: Challenge) {
        // Schedule meal reminders
        let mealTimes = [(7, 0, "Breakfast"), (12, 0, "Lunch"), (18, 0, "Dinner")]
        
        for (index, mealTime) in mealTimes.enumerated() {
            scheduleRepeatingNotification(
                title: "\(mealTime.2) Time",
                body: "Remember to follow your nutrition plan for \(mealTime.2.lowercased())!",
                hour: mealTime.0,
                minute: mealTime.1,
                challengeId: challenge.id,
                taskType: .nutrition,
                identifier: "\(challenge.id)-meal-\(index)"
            )
        }
    }
    
    private func scheduleFastingNotifications(_ tasks: [Task], challenge: Challenge) {
        // Schedule fasting start and end reminders
        if let startTime = tasks.first?.scheduledTime {
            let startHour = Calendar.current.component(.hour, from: startTime)
            let startMinute = Calendar.current.component(.minute, from: startTime)
            
            scheduleRepeatingNotification(
                title: "Fasting Start",
                body: "Time to start your fasting window!",
                hour: startHour,
                minute: startMinute,
                challengeId: challenge.id,
                taskType: .fasting,
                identifier: "\(challenge.id)-fasting-start"
            )
            
            // Calculate end time based on fasting duration (default to 16 hours if not specified)
            let fastingHours = tasks.first?.durationMinutes ?? (16 * 60)
            let endTime = Calendar.current.date(byAdding: .minute, value: fastingHours, to: startTime) ?? Date()
            let endHour = Calendar.current.component(.hour, from: endTime)
            let endMinute = Calendar.current.component(.minute, from: endTime)
            
            scheduleRepeatingNotification(
                title: "Fasting End",
                body: "Your fasting window is complete! You can eat now.",
                hour: endHour,
                minute: endMinute,
                challengeId: challenge.id,
                taskType: .fasting,
                identifier: "\(challenge.id)-fasting-end"
            )
        }
    }
    
    private func scheduleHabitNotifications(_ tasks: [Task], challenge: Challenge) {
        // Schedule habit reminders at appropriate times
        let defaultTimes = [(7, 30, "Morning"), (12, 30, "Midday"), (19, 0, "Evening")]
        
        for (index, task) in tasks.enumerated() {
            if let scheduledTime = task.scheduledTime {
                // Use the scheduled time if available
                let hour = Calendar.current.component(.hour, from: scheduledTime)
                let minute = Calendar.current.component(.minute, from: scheduledTime)
                
                scheduleRepeatingNotification(
                    title: "Habit Reminder",
                    body: task.name,
                    hour: hour,
                    minute: minute,
                    challengeId: challenge.id,
                    taskType: .habit,
                    identifier: "\(challenge.id)-habit-\(index)"
                )
            } else {
                // Use default times if no scheduled time
                let timeIndex = min(index, defaultTimes.count - 1)
                let (hour, minute, timeOfDay) = defaultTimes[timeIndex]
                
                scheduleRepeatingNotification(
                    title: "\(timeOfDay) Habit",
                    body: task.name,
                    hour: hour,
                    minute: minute,
                    challengeId: challenge.id,
                    taskType: .habit,
                    identifier: "\(challenge.id)-habit-\(index)"
                )
            }
        }
    }
    
    private func scheduleWeightNotifications(_ tasks: [Task], challenge: Challenge) {
        // Schedule weight tracking reminder in the morning
        scheduleRepeatingNotification(
            title: "Weight Tracking",
            body: "Time to record your weight for the day!",
            hour: 7,
            minute: 0,
            challengeId: challenge.id,
            taskType: .weight,
            identifier: "\(challenge.id)-weight"
        )
    }
    
    private func schedulePhotoNotifications(_ tasks: [Task], challenge: Challenge) {
        // Schedule progress photo reminder in the evening
        scheduleRepeatingNotification(
            title: "Progress Photo",
            body: "Don't forget to take your progress photo today!",
            hour: 20,
            minute: 0,
            challengeId: challenge.id,
            taskType: .photo,
            identifier: "\(challenge.id)-photo"
        )
    }
    
    private func scheduleMeditationNotifications(_ tasks: [Task], challenge: Challenge) {
        // Schedule meditation reminder
        for (index, task) in tasks.enumerated() {
            if let scheduledTime = task.scheduledTime {
                // Use the scheduled time if available
                let hour = Calendar.current.component(.hour, from: scheduledTime)
                let minute = Calendar.current.component(.minute, from: scheduledTime)
                
                scheduleRepeatingNotification(
                    title: "Meditation Time",
                    body: task.name,
                    hour: hour,
                    minute: minute,
                    challengeId: challenge.id,
                    taskType: .mindfulness,
                    identifier: "\(challenge.id)-meditation-\(index)"
                )
            } else {
                // Default to morning meditation
                scheduleRepeatingNotification(
                    title: "Meditation Time",
                    body: task.name,
                    hour: 7,
                    minute: 0,
                    challengeId: challenge.id,
                    taskType: .mindfulness,
                    identifier: "\(challenge.id)-meditation-\(index)"
                )
            }
        }
    }
    
    private func scheduleCustomTaskNotifications(_ tasks: [Task], challenge: Challenge) {
        for (index, task) in tasks.enumerated() {
            if let scheduledTime = task.scheduledTime {
                // Use the scheduled time if available
                let hour = Calendar.current.component(.hour, from: scheduledTime)
                let minute = Calendar.current.component(.minute, from: scheduledTime)
                
                scheduleRepeatingNotification(
                    title: "Time for your \(task.name)",
                    body: "Keep up with your \(challenge.name) challenge!",
                    hour: hour,
                    minute: minute,
                    challengeId: challenge.id,
                    taskType: .custom,
                    identifier: "custom-\(challenge.id)-\(index)"
                )
            } else {
                // Default time if no scheduled time
                scheduleRepeatingNotification(
                    title: "Time for your \(task.name)",
                    body: "Keep up with your \(challenge.name) challenge!",
                    hour: 9,
                    minute: 0,
                    challengeId: challenge.id,
                    taskType: .custom,
                    identifier: "custom-\(challenge.id)-\(index)"
                )
            }
        }
    }
    
    private func scheduleJournalNotifications(_ tasks: [Task], challenge: Challenge) {
        for (index, task) in tasks.enumerated() {
            if let scheduledTime = task.scheduledTime {
                // Use the scheduled time if available
                let hour = Calendar.current.component(.hour, from: scheduledTime)
                let minute = Calendar.current.component(.minute, from: scheduledTime)
                
                scheduleRepeatingNotification(
                    title: "Time to journal",
                    body: "Take a moment to reflect on your \(challenge.name) challenge",
                    hour: hour,
                    minute: minute,
                    challengeId: challenge.id,
                    taskType: .journal,
                    identifier: "journal-\(challenge.id)-\(index)"
                )
            } else {
                // Default time if no scheduled time
                scheduleRepeatingNotification(
                    title: "Time to journal",
                    body: "Take a moment to reflect on your \(challenge.name) challenge",
                    hour: 20,
                    minute: 0,
                    challengeId: challenge.id,
                    taskType: .journal,
                    identifier: "journal-\(challenge.id)-\(index)"
                )
            }
        }
    }
    
    // MARK: - Notification Response Handling
    
    /// Handles notification responses
    func handleNotificationResponse(_ response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Check if this is a challenge notification
        if let challengeIdString = userInfo["challengeId"] as? String,
           let challengeId = UUID(uuidString: challengeIdString) {
            
            // Handle different action types
            switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                // Default action (user tapped the notification)
                Logger.info("User tapped notification for challenge ID: \(challengeId)", category: .notification)
                
                // Post notification to switch to Today tab
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("SwitchToTodayTab"), object: nil)
                }
                
            case "COMPLETE_ACTION":
                // User tapped "Mark as Complete"
                if let taskIdString = userInfo["taskId"] as? String,
                   let taskId = UUID(uuidString: taskIdString) {
                    Logger.info("User marked task \(taskId) as complete from notification", category: .notification)
                    
                    // Post notification to mark task as complete
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: Notification.Name("CompleteTaskFromNotification"),
                            object: nil,
                            userInfo: ["taskId": taskId]
                        )
                    }
                }
                
            case "LATER_ACTION":
                // User tapped "Remind Me Later"
                if let taskIdString = userInfo["taskId"] as? String,
                   let taskId = UUID(uuidString: taskIdString) {
                    Logger.info("User requested reminder for task \(taskId)", category: .notification)
                    
                    // Schedule a reminder for 30 minutes later
                    let content = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
                    content.title = "Reminder: \(content.title)"
                    
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "reminder_\(taskId.uuidString)_\(Date().timeIntervalSince1970)",
                        content: content,
                        trigger: trigger
                    )
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            Logger.error("Error scheduling reminder: \(error.localizedDescription)", category: .notification)
                        }
                    }
                }
                
            default:
                Logger.info("Unknown action identifier: \(response.actionIdentifier)", category: .notification)
            }
        }
        
        // Call completion handler
        completionHandler()
    }
    
    // MARK: - Helper Methods
    
    /// Schedule a notification that repeats daily at a specific time
    private func scheduleRepeatingNotification(title: String, body: String, hour: Int, minute: Int, challengeId: UUID, taskType: TaskType, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [
            "challengeId": challengeId.uuidString,
            "taskType": taskType.rawValue
        ]
        
        // Create date components for the specified time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Create the trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("Error scheduling notification: \(error.localizedDescription)", category: .notification)
            } else {
                Logger.debug("Scheduled repeating notification: \(title) at \(hour):\(minute)", category: .notification)
            }
        }
    }
    
    /// Schedule a one-time notification at a specific date
    private func scheduleOneTimeNotification(title: String, body: String, date: Date, challengeId: UUID, taskType: TaskType, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [
            "challengeId": challengeId.uuidString,
            "taskType": taskType.rawValue
        ]
        
        // Create the trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: date.timeIntervalSinceNow,
            repeats: false
        )
        
        // Create the request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("Error scheduling one-time notification: \(error.localizedDescription)", category: .notification)
            } else {
                Logger.debug("Scheduled one-time notification: \(title) at \(date)", category: .notification)
            }
        }
    }
    
    /// Schedules a test notification
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from the Challenge Tracker app."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling test notification: \(error)")
            }
        }
    }
    
    /// Schedule a notification for automatic workout completion
    func scheduleWorkoutCompletionNotification(taskTitle: String, timeOfDay: TimeOfDay) {
        guard isAuthorized else {
            Logger.warning("Cannot schedule workout completion notification because authorization is not granted", category: .notification)
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Workout Completed! 💪"
        content.body = "\(taskTitle) was automatically marked as complete based on your Apple Fitness data."
        content.sound = .default
        content.badge = 1
        
        // Add category and user info
        content.categoryIdentifier = "WORKOUT_COMPLETION"
        content.userInfo = [
            "type": "workoutCompletion",
            "taskTitle": taskTitle,
            "timeOfDay": timeOfDay.rawValue
        ]
        
        // Create a time-based trigger (deliver immediately)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create the notification request
        let request = UNNotificationRequest(
            identifier: "workout-completion-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("Failed to schedule workout completion notification: \(error.localizedDescription)", category: .notification)
            } else {
                Logger.info("Scheduled workout completion notification for \(taskTitle)", category: .notification)
            }
        }
    }
} 