import Foundation

/// Types of notifications in the app
enum NotificationType {
    case dailyReminder
    case challengeStart
    case challengeComplete
    case streakMilestone(days: Int)
    case taskDue
} 