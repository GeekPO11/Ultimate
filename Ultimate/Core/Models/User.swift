import Foundation
import SwiftData
import SwiftUI

/// Represents a user in the app
@Model
final class User {
    // MARK: - Properties
    
    /// Unique identifier for the user
    var id: UUID
    
    /// The user's name
    var name: String
    
    /// The user's email
    var email: String?
    
    /// The user's profile image URL
    var profileImageURL: URL?
    
    /// The user's height in centimeters
    var heightCm: Double?
    
    /// The user's weight in kilograms
    var weightKg: Double?
    
    /// The user's preferred notification times
    @Attribute(.externalStorage)
    var notificationPreferences: NotificationPreferences
    
    /// The user's preferred units
    @Attribute(.externalStorage)
    var unitPreferences: UnitPreferences
    
    /// The user's preferred app appearance
    var appearancePreference: String
    
    /// The user's preferred language
    var languageCode: String?
    
    /// Whether the user has completed onboarding
    var hasCompletedOnboarding: Bool
    
    /// The creation date of the user
    var createdAt: Date
    
    /// The last update date of the user
    var updatedAt: Date
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        profileImageURL: URL? = nil,
        heightCm: Double? = nil,
        weightKg: Double? = nil,
        notificationPreferences: NotificationPreferences = NotificationPreferences(),
        unitPreferences: UnitPreferences = UnitPreferences(),
        appearancePreference: String = "System",
        languageCode: String? = nil,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.notificationPreferences = notificationPreferences
        self.unitPreferences = unitPreferences
        self.appearancePreference = appearancePreference
        self.languageCode = languageCode
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Methods
    
    /// Updates the user's profile information
    func updateProfile(
        name: String? = nil,
        email: String? = nil,
        profileImageURL: URL? = nil,
        heightCm: Double? = nil,
        weightKg: Double? = nil
    ) {
        if let name = name {
            self.name = name
        }
        
        self.email = email
        
        if let profileImageURL = profileImageURL {
            self.profileImageURL = profileImageURL
        }
        
        if let heightCm = heightCm {
            self.heightCm = heightCm
        }
        
        if let weightKg = weightKg {
            self.weightKg = weightKg
        }
        
        self.updatedAt = Date()
    }
    
    /// Updates the user's notification preferences
    func updateNotificationPreferences(_ preferences: NotificationPreferences) {
        self.notificationPreferences = preferences
        self.updatedAt = Date()
    }
    
    /// Updates the user's unit preferences
    func updateUnitPreferences(_ preferences: UnitPreferences) {
        self.unitPreferences = preferences
        self.updatedAt = Date()
    }
    
    /// Updates the user's appearance preference
    func updateAppearancePreference(_ preference: String) {
        self.appearancePreference = preference
        self.updatedAt = Date()
    }
    
    /// Completes the onboarding process
    func completeOnboarding() {
        self.hasCompletedOnboarding = true
        self.updatedAt = Date()
    }
}

/// Represents notification preferences
struct NotificationPreferences: Codable {
    /// Whether notifications are enabled
    var isEnabled: Bool = true
    
    /// Whether quiet hours are enabled
    var quietHoursEnabled: Bool = false
    
    /// The start time for quiet hours (in minutes from midnight)
    var quietHoursStart: Int = 22 * 60 // 10:00 PM
    
    /// The end time for quiet hours (in minutes from midnight)
    var quietHoursEnd: Int = 8 * 60 // 8:00 AM
    
    /// Notification preferences for different task types
    var taskTypePreferences: [TaskType: TaskNotificationPreference] = [
        .workout: TaskNotificationPreference(reminderTime: 8 * 60), // 8:00 AM
        .nutrition: TaskNotificationPreference(
            reminderTimes: [7 * 60, 12 * 60, 18 * 60] // 7:00 AM, 12:00 PM, 6:00 PM
        ),
        .water: TaskNotificationPreference(
            reminderTimes: [8 * 60, 11 * 60, 14 * 60, 17 * 60] // 8:00 AM, 11:00 AM, 2:00 PM, 5:00 PM
        ),
        .reading: TaskNotificationPreference(reminderTime: 20 * 60), // 8:00 PM
        .photo: TaskNotificationPreference(reminderTime: 19 * 60), // 7:00 PM
        .journal: TaskNotificationPreference(reminderTime: 21 * 60), // 9:00 PM
        .mindfulness: TaskNotificationPreference(reminderTime: 7 * 60), // 7:00 AM
        .custom: TaskNotificationPreference(reminderTime: 9 * 60) // 9:00 AM
    ]
}

/// Represents notification preferences for a specific task type
struct TaskNotificationPreference: Codable {
    /// Whether notifications are enabled for this task type
    var isEnabled: Bool = true
    
    /// The reminder times for this task type (in minutes from midnight)
    var reminderTimes: [Int] = []
    
    /// Initializer with a single reminder time
    init(reminderTime: Int) {
        self.reminderTimes = [reminderTime]
    }
    
    /// Initializer with multiple reminder times
    init(reminderTimes: [Int]) {
        self.reminderTimes = reminderTimes
    }
}

/// Represents unit preferences
struct UnitPreferences: Codable {
    /// The preferred weight unit
    var weightUnit: WeightUnit = .kg
    
    /// The preferred height unit
    var heightUnit: HeightUnit = .cm
    
    /// The preferred volume unit
    var volumeUnit: VolumeUnit = .liter
    
    /// The preferred distance unit
    var distanceUnit: DistanceUnit = .km
}

/// Represents weight units
enum WeightUnit: String, Codable, CaseIterable {
    case kg = "kg"
    case lb = "lb"
    
    var displayName: String {
        switch self {
        case .kg:
            return "Kilograms (kg)"
        case .lb:
            return "Pounds (lb)"
        }
    }
}

/// Represents height units
enum HeightUnit: String, Codable, CaseIterable {
    case cm = "cm"
    case feet = "ft"
    
    var displayName: String {
        switch self {
        case .cm:
            return "Centimeters (cm)"
        case .feet:
            return "Feet and inches (ft)"
        }
    }
}

/// Represents volume units
enum VolumeUnit: String, Codable, CaseIterable {
    case liter = "L"
    case flOz = "fl oz"
    
    var displayName: String {
        switch self {
        case .liter:
            return "Liters (L)"
        case .flOz:
            return "Fluid Ounces (fl oz)"
        }
    }
}

/// Represents distance units
enum DistanceUnit: String, Codable, CaseIterable {
    case km = "km"
    case mile = "mi"
    
    var displayName: String {
        switch self {
        case .km:
            return "Kilometers (km)"
        case .mile:
            return "Miles (mi)"
        }
    }
} 