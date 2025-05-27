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
final class Challenge: ValidatableModel, TimestampedModel, SoftDeletableModel, VersionedModel {
    // MARK: - Properties
    
    /// Unique identifier for the challenge
    @Attribute(.unique) var id: UUID = UUID()
    
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
    var createdAt: Date = Date()
    
    /// The last update date of the challenge
    var updatedAt: Date = Date()
    
    /// The current progress value (0.0 to 1.0)
    var progressValue: Double = 0.0
    
    /// Model version for migration support
    var version: Int = 1
    
    /// Soft delete flag
    var isDeleted: Bool = false
    
    /// Soft delete timestamp
    var deletedAt: Date?
    
    // MARK: - Computed Properties
    
    /// The progress of the challenge (0.0 to 1.0)
    var progress: Double {
        guard status == .inProgress || status == .completed else { return 0.0 }
        
        let totalDays = durationInDays
        guard totalDays > 0 else { return 0.0 }
        
        let completedDays = self.completedDays
        return min(1.0, Double(completedDays) / Double(totalDays))
    }
    
    /// The number of completed days
    var completedDays: Int {
        guard let startDate = startDate else { return 0 }
        
        let today = Date()
        let endDate = self.endDate ?? today
        let actualEndDate = min(today, endDate)
        
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: actualEndDate).day ?? 0
        
        return max(0, daysDifference)
    }
    
    /// The total days in the challenge
    var totalDays: Int {
        return durationInDays
    }
    
    /// Days remaining in the challenge
    var daysRemaining: Int {
        guard status == .inProgress, let endDate = endDate else { return 0 }
        
        let today = Date()
        guard endDate > today else { return 0 }
        
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: today, to: endDate).day ?? 0
        
        return max(0, daysDifference)
    }
    
    /// Whether the challenge is active
    var isActive: Bool {
        return status == .inProgress
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
        self.version = 1
        self.isDeleted = false
        
        // Calculate end date if start date is set
        if let startDate = startDate {
            self.endDate = Calendar.current.date(byAdding: .day, value: durationInDays, to: startDate)
        }
    }
    
    // MARK: - Validation Implementation
    
    func fieldValidators() -> [FieldValidator] {
        return [
            FieldValidator("name", rules: ValidationRule.challengeName()),
            FieldValidator("challengeDescription", rules: ValidationRule.challengeDescription()),
            FieldValidator("durationInDays", rules: ValidationRule.challengeDuration())
        ]
    }
    
    func validateBusinessRules() throws {
        // Challenge name uniqueness (would need service layer for global check)
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.required(field: "name")
        }
        
        // Duration validation
        if durationInDays <= 0 {
            throw ValidationError.invalidRange(field: "durationInDays", min: 1, max: 365)
        }
        
        if durationInDays > 365 {
            throw ValidationError.invalidRange(field: "durationInDays", min: 1, max: 365)
        }
        
        // Status validation
        if status == .inProgress && startDate == nil {
            throw ValidationError.businessRuleViolation("Cannot start challenge without a start date")
        }
        
        if status == .completed && startDate == nil {
            throw ValidationError.businessRuleViolation("Cannot complete challenge without a start date")
        }
        
        // Task validation for specific challenge types
        if type == .seventyFiveHard && tasks.count > 0 && tasks.count != 5 {
            throw ValidationError.businessRuleViolation("75 Hard challenge must have exactly 5 tasks")
        }
        
        if type == .waterFasting && tasks.count > 0 && !tasks.contains(where: { $0.type == .water }) {
            throw ValidationError.businessRuleViolation("Water fasting challenge must include a water task")
        }
    }
    
    func validateCrossFields() throws {
        // Date range validation
        if let startDate = startDate, let endDate = endDate {
            if endDate <= startDate {
                throw ValidationError.invalidDate(field: "endDate", reason: "End date must be after start date")
            }
            
            let calendar = Calendar.current
            let daysDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            
            if daysDifference != durationInDays {
                throw ValidationError.businessRuleViolation("End date must be exactly \(durationInDays) days after start date")
            }
        }
        
        // Progress validation
        if progressValue < 0.0 || progressValue > 1.0 {
            throw ValidationError.invalidRange(field: "progressValue", min: 0.0, max: 1.0)
        }
        
        // Status transition validation
        if status == .completed && progress < 1.0 && daysRemaining > 0 {
            throw ValidationError.businessRuleViolation("Cannot mark challenge as completed before it's finished")
        }
    }
    
    // MARK: - Methods
    
    /// Starts the challenge
    func startChallenge() throws {
        guard status == .notStarted else {
            throw ValidationError.businessRuleViolation("Challenge is already started")
        }
        
        // Validate before starting
        try validate()
        
        self.startDate = Date()
        self.endDate = Calendar.current.date(byAdding: .day, value: durationInDays, to: startDate!)
        self.status = .inProgress
        self.updatedAt = Date()
        
        // Schedule notifications for the challenge
        NotificationManager.shared.scheduleNotificationsForChallenge(self)
    }
    
    /// Completes the challenge
    func completeChallenge() throws {
        guard status == .inProgress else {
            throw ValidationError.businessRuleViolation("Cannot complete a challenge that is not in progress")
        }
        
        self.status = .completed
        self.progressValue = 1.0
        self.updatedAt = Date()
        
        // If the challenge is completed early, set the end date to today
        if let endDate = self.endDate, endDate > Date() {
            self.endDate = Date()
        }
        
        // Remove notifications for the challenge
        NotificationManager.shared.removeNotificationsForChallenge(self)
    }
    
    /// Fails the challenge
    func failChallenge() throws {
        guard status == .inProgress else {
            throw ValidationError.businessRuleViolation("Cannot fail a challenge that is not in progress")
        }
        
        self.status = .failed
        self.updatedAt = Date()
        
        // If the challenge is failed early, set the end date to today
        if let endDate = self.endDate, endDate > Date() {
            self.endDate = Date()
        }
        
        // Remove notifications for the challenge
        NotificationManager.shared.removeNotificationsForChallenge(self)
    }
    
    /// Pauses the challenge (if supported)
    func pauseChallenge() throws {
        guard status == .inProgress else {
            throw ValidationError.businessRuleViolation("Cannot pause a challenge that is not in progress")
        }
        
        // For now, we don't support pausing, but this is where the logic would go
        throw ValidationError.businessRuleViolation("Challenge pausing is not currently supported")
    }
    
    /// Resumes the challenge (if supported)
    func resumeChallenge() throws {
        // For now, we don't support resuming, but this is where the logic would go
        throw ValidationError.businessRuleViolation("Challenge resuming is not currently supported")
    }
    
    /// Updates the challenge progress
    func updateProgress() {
        guard status == .inProgress else { return }
        
        let calculatedProgress = self.progress
        self.progressValue = calculatedProgress
        self.updatedAt = Date()
    }
    
    /// Adds a task to the challenge
    func addTask(_ task: Task) throws {
        // Validate the task first
        try task.validate()
        
        // Check if task is already in the challenge
        if tasks.contains(where: { $0.id == task.id }) {
            throw ValidationError.businessRuleViolation("Task is already part of this challenge")
        }
        
        // Set the relationship
        task.challenge = self
        tasks.append(task)
        
        // Validate business rules after adding task
        try validateBusinessRules()
        
        self.updatedAt = Date()
    }
    
    /// Removes a task from the challenge
    func removeTask(_ task: Task) throws {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            throw ValidationError.businessRuleViolation("Task is not part of this challenge")
        }
        
        tasks.remove(at: index)
        task.challenge = nil
        
        // Validate business rules after removing task
        try validateBusinessRules()
        
        self.updatedAt = Date()
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
        
        return challenge
    }
    
    /// Creates a Water Fasting challenge
    static func createWaterFastingChallenge(durationInDays: Int = 3) -> Challenge {
        let challenge = Challenge(
            type: .waterFasting,
            name: "Water Fasting Challenge",
            challengeDescription: "A focused water fasting program for health and mindfulness.",
            durationInDays: durationInDays,
            imageName: "water_fasting"
        )
        
        return challenge
    }
    
    /// Creates a 31 Modified challenge
    static func createThirtyOneModifiedChallenge() -> Challenge {
        let challenge = Challenge(
            type: .thirtyOneModified,
            name: "31 Modified Challenge",
            challengeDescription: "A balanced 31-day program for sustainable lifestyle changes.",
            durationInDays: 31,
            imageName: "31modified"
        )
        
        return challenge
    }
    
    /// Creates a custom challenge
    static func createCustomChallenge(
        name: String,
        description: String,
        durationInDays: Int
    ) -> Challenge {
        return Challenge(
            type: .custom,
            name: name,
            challengeDescription: description,
            durationInDays: durationInDays,
            imageName: "custom"
        )
    }
}

// MARK: - Challenge Extensions

extension Challenge: Identifiable {}

extension Challenge: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Challenge: Equatable {
    static func == (lhs: Challenge, rhs: Challenge) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Challenge Analytics Extension

extension Challenge {
    /// Analytics data for the challenge
    var analyticsData: [String: Any]? {
        get {
            // This would be implemented when we add analytics storage
            return nil
        }
        set {
            // This would be implemented when we add analytics storage
        }
    }
    
    /// Calculate consistency score for the challenge
    func calculateConsistencyScore() -> Double {
        guard status == .inProgress || status == .completed else { return 0.0 }
        guard let startDate = startDate else { return 0.0 }
        
        let calendar = Calendar.current
        let today = Date()
        let endDate = self.endDate ?? today
        let actualEndDate = min(today, endDate)
        
        let totalDays = calendar.dateComponents([.day], from: startDate, to: actualEndDate).day ?? 0
        guard totalDays > 0 else { return 0.0 }
        
        // This is a simplified calculation
        // In a real implementation, you'd calculate based on actual daily task completion
        let completionRate = Double(completedDays) / Double(totalDays)
        return min(100.0, completionRate * 100.0)
    }
} 