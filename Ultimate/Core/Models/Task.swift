import Foundation
import SwiftData
import SwiftUI

/// Represents a task type
enum TaskType: String, Codable, CaseIterable {
    case workout = "Workout"
    case nutrition = "Nutrition"
    case water = "Water"
    case reading = "Reading"
    case photo = "Photo"
    case journal = "Journal"
    case mindfulness = "Meditation"
    case custom = "Custom"
    case fasting = "Fasting"
    case weight = "Weight"
    case habit = "Habit"
    
    var icon: String {
        switch self {
        case .workout:
            return "figure.run"
        case .nutrition:
            return "fork.knife"
        case .water:
            return "drop.fill"
        case .reading:
            return "book.fill"
        case .photo:
            return "camera.fill"
        case .journal:
            return "note.text"
        case .mindfulness:
            return "brain.head.profile"
        case .custom:
            return "checklist"
        case .fasting:
            return "timer"
        case .weight:
            return "scalemass"
        case .habit:
            return "checkmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .workout:
            return DesignSystem.Colors.primaryAction
        case .nutrition:
            return Color(hex: "FF9500") // Orange
        case .water:
            return Color(hex: "00C7BE") // Teal
        case .reading:
            return Color(hex: "AF52DE") // Purple
        case .photo:
            return Color(hex: "FF2D55") // Pink
        case .journal:
            return Color(hex: "5856D6") // Indigo
        case .mindfulness:
            return Color(hex: "007AFF") // Blue
        case .custom:
            return DesignSystem.Colors.secondaryAction
        case .fasting:
            return Color(hex: "FF3B30") // Red
        case .weight:
            return Color(hex: "34C759") // Green
        case .habit:
            return Color(hex: "FFCC00") // Yellow
        }
    }
}

/// Represents the time of day for a task
enum TimeOfDay: String, Codable {
    case morning = "Morning"
    case evening = "Evening"
    case anytime = "Anytime"
}

/// Represents a task completion status
enum TaskCompletionStatus: String, Codable {
    case notStarted = "NotStarted"
    case inProgress = "InProgress"
    case completed = "Completed"
    case missed = "Missed"
    case failed = "Failed"
}

/// Represents a task in the app
@Model
final class Task: Identifiable {
    // MARK: - Properties
    
    /// Unique identifier for the task
    @Attribute(.unique) var id: UUID = UUID()
    
    /// The name of the task
    var name: String = ""
    
    /// The description of the task
    var taskDescription: String = ""
    
    /// The type of task
    var type: TaskType? = nil
    
    /// The frequency of the task
    var frequency: TaskFrequency = TaskFrequency.daily
    
    /// The challenge this task belongs to
    @Relationship
    var challenge: Challenge? = nil
    
    /// The time of day for the task (morning, evening, or anytime)
    var timeOfDay: TimeOfDay = TimeOfDay.anytime
    
    /// The time of day for the task (in minutes from midnight)
    var timeOfDayMinutes: Int? = nil
    
    /// The duration of the task in minutes (if applicable)
    var durationMinutes: Int? = nil
    
    /// The target value for the task (e.g., pages to read, water to drink)
    var targetValue: Double? = nil
    
    /// The unit for the target value (e.g., pages, liters)
    var targetUnit: String? = nil
    
    /// The scheduled time for the task
    // Instead of using a Date? with nil, use a non-optional Date with a far past date
    // This helps avoid nil handling issues with SwiftData
    private var _scheduledTime: Date = Date(timeIntervalSince1970: 0)
    
    /// Public getter/setter for scheduledTime that handles the internal storage correctly
    var scheduledTime: Date? {
        get {
            // If the date is the "null date", return nil
            return _scheduledTime == Date(timeIntervalSince1970: 0) ? nil : _scheduledTime
        }
        set {
            // Store the new value or a "null date" if nil
            _scheduledTime = newValue ?? Date(timeIntervalSince1970: 0)
        }
    }
    
    /// The creation date of the task
    var createdAt: Date = Date()
    
    /// The last update date of the task
    var updatedAt: Date = Date()
    
    /// Indicates whether the task is completed
    var isCompleted: Bool = false
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        type: TaskType? = nil,
        frequency: TaskFrequency = TaskFrequency.daily,
        challenge: Challenge? = nil,
        timeOfDay: TimeOfDay = TimeOfDay.anytime,
        timeOfDayComponents: DateComponents? = nil,
        durationMinutes: Int? = nil,
        targetValue: Double? = nil,
        targetUnit: String? = nil,
        scheduledTime: Date? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.taskDescription = description
        self.type = type
        self.frequency = frequency
        self.challenge = challenge
        self.timeOfDay = timeOfDay
        
        // Convert DateComponents to minutes from midnight if provided
        if let timeComponents = timeOfDayComponents {
            let hours = timeComponents.hour ?? 0
            let minutes = timeComponents.minute ?? 0
            self.timeOfDayMinutes = hours * 60 + minutes
        } else {
            self.timeOfDayMinutes = nil
        }
        
        self.durationMinutes = durationMinutes
        self.targetValue = targetValue
        self.targetUnit = targetUnit
        
        // Use the property setter to handle the nil case correctly
        self.scheduledTime = scheduledTime
        
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isCompleted = isCompleted
    }
    
    // Helper computed property to get DateComponents
    var timeOfDayComponents: DateComponents? {
        get {
            guard let minutes = timeOfDayMinutes else { return nil }
            var components = DateComponents()
            components.hour = minutes / 60
            components.minute = minutes % 60
            return components
        }
    }
    
    // Determine if task is a morning or evening workout based on time components
    func inferTimeOfDay() -> TimeOfDay {
        guard let components = timeOfDayComponents else {
            return TimeOfDay.anytime
        }
        
        let hour = components.hour ?? 0
        
        if hour < 12 {
            return TimeOfDay.morning
        } else {
            return TimeOfDay.evening
        }
    }
}

// Removing the duplicate DailyTask class that's causing ambiguity
// The proper DailyTask class should be in DailyTask.swift 