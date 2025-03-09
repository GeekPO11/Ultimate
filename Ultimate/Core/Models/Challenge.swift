import Foundation
import SwiftData

/// Represents a challenge type
enum ChallengeType: String, Codable {
    case seventyFiveHard = "75Hard"
    case waterFasting = "WaterFasting"
    case thirtyOneModified = "31Modified"
    case custom = "Custom"
}

/// Represents the status of a challenge
enum ChallengeStatus: String, Codable {
    case notStarted = "NotStarted"
    case inProgress = "InProgress"
    case completed = "Completed"
    case failed = "Failed"
}

/// Represents a challenge in the app
@Model
final class Challenge {
    // MARK: - Properties
    
    /// Unique identifier for the challenge
    var id: UUID
    
    /// The type of challenge
    var type: ChallengeType
    
    /// The name of the challenge
    var name: String
    
    /// The challenge description
    var challengeDescription: String
    
    /// Alias for challengeDescription for backward compatibility
    var description: String {
        get { return challengeDescription }
        set { challengeDescription = newValue }
    }
    
    /// The start date of the challenge
    var startDate: Date?
    
    /// The end date of the challenge
    var endDate: Date?
    
    /// The duration of the challenge in days
    var durationInDays: Int
    
    /// The current status of the challenge
    var status: ChallengeStatus
    
    /// The tasks associated with this challenge
    @Relationship(inverse: \Task.challenge)
    var tasks: [Task] = []
    
    /// The image name for the challenge
    var imageName: String?
    
    /// The creation date of the challenge
    var createdAt: Date
    
    /// The last update date of the challenge
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// The progress of the challenge (0.0 to 1.0)
    var progress: Double {
        get {
            guard status == .inProgress || status == .completed, let startDate = startDate else {
                return 0.0
            }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            if status == .completed {
                return 1.0
            }
            
            if let endDate = endDate, endDate < today {
                // Challenge has ended but not marked as completed
                return 0.0
            }
            
            // Calculate days elapsed
            let startDay = calendar.startOfDay(for: startDate)
            let daysElapsed = calendar.dateComponents([.day], from: startDay, to: today).day ?? 0
            
            // Calculate progress as a percentage of days elapsed
            let progress = Double(daysElapsed) / Double(durationInDays)
            
            // Ensure progress is between 0 and 1
            return min(max(progress, 0.0), 1.0)
        }
    }
    
    /// The current day of the challenge
    var currentDay: Int {
        get {
            guard let startDate = startDate else {
                return 0
            }
            
            let calendar = Calendar.current
            let startDay = calendar.startOfDay(for: startDate)
            let today = calendar.startOfDay(for: Date())
            
            let daysElapsed = calendar.dateComponents([.day], from: startDay, to: today).day ?? 0
            
            // Ensure current day is between 1 and durationInDays
            return min(max(daysElapsed + 1, 1), durationInDays)
        }
    }
    
    /// Returns the number of days remaining in the challenge
    var daysRemaining: Int {
        get {
            guard let endDate = endDate else {
                return durationInDays
            }
            
            let now = Date()
            let calendar = Calendar.current
            
            // If challenge is already completed
            if now >= endDate {
                return 0
            }
            
            return calendar.dateComponents([.day], from: now, to: endDate).day ?? 0
        }
    }
    
    /// Returns the number of days completed in the challenge
    var completedDays: Int {
        get {
            guard let startDate = startDate else {
                return 0
            }
            
            let calendar = Calendar.current
            let startDay = calendar.startOfDay(for: startDate)
            let today = calendar.startOfDay(for: Date())
            
            let daysElapsed = calendar.dateComponents([.day], from: startDay, to: today).day ?? 0
            
            // Ensure completed days is between 0 and durationInDays
            return min(max(daysElapsed, 0), durationInDays)
        }
    }
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        type: ChallengeType,
        name: String,
        challengeDescription: String,
        startDate: Date? = nil,
        durationInDays: Int,
        status: ChallengeStatus = .notStarted,
        imageName: String? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.challengeDescription = challengeDescription
        self.startDate = startDate
        self.durationInDays = durationInDays
        self.status = status
        self.imageName = imageName
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Calculate end date if start date is set
        if let startDate = startDate {
            self.endDate = Calendar.current.date(byAdding: .day, value: durationInDays, to: startDate)
        }
    }
    
    // MARK: - Methods
    
    /// Starts the challenge
    func startChallenge() {
        guard status == .notStarted else { return }
        
        self.startDate = Date()
        self.endDate = Calendar.current.date(byAdding: .day, value: durationInDays, to: startDate!)
        self.status = .inProgress
        self.updatedAt = Date()
        
        // Schedule notifications for the challenge
        NotificationManager.shared.scheduleNotificationsForChallenge(self)
    }
    
    /// Completes the challenge
    func completeChallenge() {
        guard status == .inProgress else { return }
        
        self.status = .completed
        self.updatedAt = Date()
        
        // If the challenge is completed early, set the end date to today
        if let endDate = self.endDate, endDate > Date() {
            self.endDate = Date()
        }
        
        // Remove notifications for the challenge
        NotificationManager.shared.removeNotificationsForChallenge(self)
    }
    
    /// Fails the challenge
    func failChallenge() {
        guard status == .inProgress else { return }
        
        self.status = .failed
        self.updatedAt = Date()
        
        // If the challenge is failed early, set the end date to today
        if let endDate = self.endDate, endDate > Date() {
            self.endDate = Date()
        }
        
        // Remove notifications for the challenge
        NotificationManager.shared.removeNotificationsForChallenge(self)
    }
    
    // MARK: - Factory Methods
    
    /// Creates a 75 Hard challenge
    static func createSeventyFiveHardChallenge() -> Challenge {
        let challenge = Challenge(
            type: .seventyFiveHard,
            name: "75 Hard Challenge",
            challengeDescription: "Transform your life with this intense 75-day mental toughness program.",
            durationInDays: 75,
            imageName: "75hard"
        )
        
        // Create tasks for the challenge
        let workoutTask1 = Task(
            name: "First 45-Minute Workout",
            description: "Complete your first 45-minute workout of the day.",
            type: .workout,
            frequency: .daily
        )
        
        let workoutTask2 = Task(
            name: "Second 45-Minute Workout (Outdoors)",
            description: "Complete your second 45-minute workout of the day outdoors.",
            type: .workout,
            frequency: .daily
        )
        
        let dietTask = Task(
            name: "Follow Diet Plan",
            description: "Stick to your chosen diet plan with zero cheating.",
            type: .nutrition,
            frequency: .daily
        )
        
        let waterTask = Task(
            name: "Drink 1 Gallon of Water",
            description: "Drink 1 gallon (3.8 liters) of water throughout the day.",
            type: .water,
            frequency: .daily,
            targetValue: 1.0,
            targetUnit: "gallon"
        )
        
        let readingTask = Task(
            name: "Read 10 Pages",
            description: "Read 10 pages of a non-fiction book.",
            type: .reading,
            frequency: .daily
        )
        
        let photoTask = Task(
            name: "Take Progress Photo",
            description: "Take a daily progress photo.",
            type: .photo,
            frequency: .daily
        )
        
        challenge.tasks = [workoutTask1, workoutTask2, dietTask, waterTask, readingTask, photoTask]
        
        return challenge
    }
    
    /// Creates a Water Fasting challenge
    static func createWaterFastingChallenge(durationInDays: Int = 7) -> Challenge {
        let challenge = Challenge(
            type: .waterFasting,
            name: "7 Day Water Fast",
            challengeDescription: "Cleanse your body and reset your system with a water fast.",
            durationInDays: durationInDays,
            imageName: "waterfasting"
        )
        
        // Create tasks for the challenge
        let fastingTask = Task(
            name: "Maintain Fast",
            description: "Consume only water throughout the day.",
            type: .nutrition,
            frequency: .daily
        )
        
        let waterTask = Task(
            name: "Drink Water",
            description: "Drink at least 2 liters of water throughout the day.",
            type: .water,
            frequency: .daily,
            targetValue: 2.0,
            targetUnit: "liters"
        )
        
        let journalTask = Task(
            name: "Journal Entry",
            description: "Record your experiences, feelings, and any physical changes.",
            type: .journal,
            frequency: .daily
        )
        
        challenge.tasks = [fastingTask, waterTask, journalTask]
        
        return challenge
    }
    
    /// Creates a 31 Modified challenge
    static func createThirtyOneModifiedChallenge() -> Challenge {
        let challenge = Challenge(
            type: .thirtyOneModified,
            name: "31 Modified Challenge",
            challengeDescription: "A more balanced approach to the 75 Hard challenge, designed for sustainable progress.",
            durationInDays: 31,
            imageName: "31modified"
        )
        
        // Create tasks for the challenge
        let workoutTask = Task(
            name: "30-Minute Workout",
            description: "Complete a 30-minute workout of your choice.",
            type: .workout,
            frequency: .daily
        )
        
        let nutritionTask = Task(
            name: "Follow Nutrition Plan",
            description: "Stick to your nutrition plan with one cheat meal allowed per week.",
            type: .nutrition,
            frequency: .daily
        )
        
        let waterTask = Task(
            name: "Drink 2 Liters of Water",
            description: "Drink at least 2 liters of water throughout the day.",
            type: .water,
            frequency: .daily
        )
        
        let progressTask = Task(
            name: "Track Progress",
            description: "Record your progress for the day.",
            type: .journal,
            frequency: .daily
        )
        
        challenge.tasks = [workoutTask, nutritionTask, waterTask, progressTask]
        
        return challenge
    }
} 