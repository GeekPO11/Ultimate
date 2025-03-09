import SwiftUI

/// Appearance options for the app
enum AppearancePreference: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

/// Class for managing user settings
@MainActor
final class UserSettings: ObservableObject {
    // Use constant keys to avoid string literals
    private enum Keys {
        static let appearance: String = "selectedAppearance"
        static let onboarding: String = "hasCompletedOnboarding"
        
        // Notification preferences
        static let notifyWorkouts: String = "notifyWorkouts"
        static let notifyNutrition: String = "notifyNutrition"
        static let notifyWater: String = "notifyWater"
        static let notifyReading: String = "notifyReading"
        static let notifyPhotos: String = "notifyPhotos"
        
        // Quiet hours
        static let quietHoursEnabled: String = "quietHoursEnabled"
        static let quietHoursStart: String = "quietHoursStart"
        static let quietHoursEnd: String = "quietHoursEnd"
    }
    
    // Static UserDefaults instance to avoid repeated lookups
    private static let defaults: UserDefaults = UserDefaults.standard
    
    // Cache for appearance values
    private static var cachedAppearances: [String: AppearancePreference] = [:]
    
    // Published property with explicit type annotation
    @Published var selectedAppearance: AppearancePreference
    
    // Notification preferences
    @Published var notifyWorkouts: Bool {
        didSet {
            Self.defaults.set(notifyWorkouts, forKey: Keys.notifyWorkouts)
        }
    }
    
    @Published var notifyNutrition: Bool {
        didSet {
            Self.defaults.set(notifyNutrition, forKey: Keys.notifyNutrition)
        }
    }
    
    @Published var notifyWater: Bool {
        didSet {
            Self.defaults.set(notifyWater, forKey: Keys.notifyWater)
        }
    }
    
    @Published var notifyReading: Bool {
        didSet {
            Self.defaults.set(notifyReading, forKey: Keys.notifyReading)
        }
    }
    
    @Published var notifyPhotos: Bool {
        didSet {
            Self.defaults.set(notifyPhotos, forKey: Keys.notifyPhotos)
        }
    }
    
    // Quiet hours
    @Published var quietHoursEnabled: Bool {
        didSet {
            Self.defaults.set(quietHoursEnabled, forKey: Keys.quietHoursEnabled)
        }
    }
    
    @Published var quietHoursStart: Date {
        didSet {
            Self.defaults.set(quietHoursStart, forKey: Keys.quietHoursStart)
        }
    }
    
    @Published var quietHoursEnd: Date {
        didSet {
            Self.defaults.set(quietHoursEnd, forKey: Keys.quietHoursEnd)
        }
    }
    
    init() {
        // Load settings from UserDefaults with caching
        let appearanceString: String? = Self.defaults.string(forKey: Keys.appearance)
        
        if let appearanceString: String = appearanceString,
           let appearance: AppearancePreference = Self.getCachedAppearance(for: appearanceString) {
            self.selectedAppearance = appearance
        } else {
            self.selectedAppearance = .system
        }
        
        // Load notification preferences
        self.notifyWorkouts = Self.defaults.bool(forKey: Keys.notifyWorkouts)
        self.notifyNutrition = Self.defaults.bool(forKey: Keys.notifyNutrition)
        self.notifyWater = Self.defaults.bool(forKey: Keys.notifyWater)
        self.notifyReading = Self.defaults.bool(forKey: Keys.notifyReading)
        self.notifyPhotos = Self.defaults.bool(forKey: Keys.notifyPhotos)
        
        // Load quiet hours settings
        self.quietHoursEnabled = Self.defaults.bool(forKey: Keys.quietHoursEnabled)
        
        // Default quiet hours: 10 PM to 7 AM
        let calendar = Calendar.current
        let defaultStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        let defaultEnd = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        
        self.quietHoursStart = Self.defaults.object(forKey: Keys.quietHoursStart) as? Date ?? defaultStart
        self.quietHoursEnd = Self.defaults.object(forKey: Keys.quietHoursEnd) as? Date ?? defaultEnd
    }
    
    private static func getCachedAppearance(for key: String) -> AppearancePreference? {
        if let cached: AppearancePreference = cachedAppearances[key] {
            return cached
        }
        
        if let appearance: AppearancePreference = AppearancePreference(rawValue: key) {
            cachedAppearances[key] = appearance
            return appearance
        }
        
        return nil
    }
    
    func setAppearance(_ appearance: AppearancePreference) {
        self.selectedAppearance = appearance
        Self.defaults.set(appearance.rawValue, forKey: Keys.appearance)
    }
    
    func resetOnboarding() {
        print("UserSettings: Resetting onboarding completion state to false")
        Self.defaults.set(false, forKey: Keys.onboarding)
        Self.defaults.synchronize() // Force immediate save
        print("UserDefaults value after resetting: \(Self.defaults.bool(forKey: Keys.onboarding))")
    }
    
    func completeOnboarding() {
        print("UserSettings: Setting onboarding completed to true")
        Self.defaults.set(true, forKey: Keys.onboarding)
        Self.defaults.synchronize() // Force immediate save
        print("UserDefaults value after setting: \(Self.defaults.bool(forKey: Keys.onboarding))")
    }
    
    static func hasCompletedOnboarding() -> Bool {
        let completed = defaults.bool(forKey: Keys.onboarding)
        print("UserSettings: Checking if onboarding is completed: \(completed)")
        return completed
    }
    
    /// Resets all notification preferences to default values
    func resetNotificationPreferences() {
        notifyWorkouts = true
        notifyNutrition = true
        notifyWater = true
        notifyReading = true
        notifyPhotos = true
        
        quietHoursEnabled = false
        
        let calendar = Calendar.current
        quietHoursStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        quietHoursEnd = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }
    
    /// Checks if notifications should be sent for a specific task type
    func shouldNotify(for taskType: TaskType) -> Bool {
        if quietHoursEnabled {
            // Check if current time is within quiet hours
            let now = Date()
            let calendar = Calendar.current
            
            let startComponents = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
            let endComponents = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
            let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
            
            let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
            let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
            let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
            
            // Check if current time is within quiet hours
            let isQuietHours: Bool
            if startMinutes < endMinutes {
                // Normal case (e.g., 22:00 to 07:00)
                isQuietHours = nowMinutes >= startMinutes && nowMinutes < endMinutes
            } else {
                // Overnight case (e.g., 22:00 to 07:00)
                isQuietHours = nowMinutes >= startMinutes || nowMinutes < endMinutes
            }
            
            if isQuietHours {
                return false
            }
        }
        
        // Check task type preferences
        switch taskType {
        case .workout:
            return notifyWorkouts
        case .nutrition:
            return notifyNutrition
        case .water:
            return notifyWater
        case .reading:
            return notifyReading
        case .photo:
            return notifyPhotos
        case .journal:
            return true // Always notify for journal tasks
        case .mindfulness:
            return true // Always notify for mindfulness tasks
        case .custom:
            return true // Always notify for custom tasks
        case .fasting:
            return true // Always notify for fasting tasks
        case .weight:
            return true // Always notify for weight tracking tasks
        case .habit:
            return true // Always notify for habit tasks
        }
    }
} 