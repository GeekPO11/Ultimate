import Foundation
import SwiftData

@Model
final class DailyTask: Identifiable {
    var id: UUID
    var title: String
    var date: Date
    var isCompleted: Bool
    @Relationship
    var challenge: Challenge?
    @Relationship
    var task: Task?
    var status: TaskCompletionStatus
    var notes: String?
    var actualValue: Double?
    var completionTime: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), title: String, date: Date = Date(), isCompleted: Bool = false, challenge: Challenge? = nil, task: Task? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
        self.challenge = challenge
        self.task = task
        self.status = .notStarted
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Marks the task as completed
    /// - Parameters:
    ///   - actualValue: The actual value achieved (optional)
    ///   - notes: Notes for the completion (optional)
    func complete(actualValue: Double? = nil, notes: String? = nil) {
        self.status = .completed
        self.isCompleted = true
        self.actualValue = actualValue
        self.notes = notes
        self.completionTime = Date()
        self.updatedAt = Date()
    }
    
    /// Marks the task as in progress
    /// - Parameters:
    ///   - notes: Notes for the status change (optional)
    func markInProgress(notes: String? = nil) {
        self.status = .inProgress
        self.isCompleted = false
        self.notes = notes
        self.updatedAt = Date()
    }
    
    /// Marks the task as missed
    /// - Parameter notes: Notes for the missed task (optional)
    func markMissed(notes: String? = nil) {
        self.status = .missed
        self.isCompleted = false
        self.notes = notes
        self.completionTime = Date()
        self.updatedAt = Date()
    }
    
    /// Marks the task as failed
    /// - Parameter notes: Notes for the failure (optional)
    func markFailed(notes: String? = nil) {
        self.status = .failed
        self.isCompleted = false
        self.notes = notes
        self.completionTime = Date()
        self.updatedAt = Date()
    }
    
    /// Resets the task to not started
    func reset() {
        self.status = .notStarted
        self.isCompleted = false
        self.completionTime = nil
        self.actualValue = nil
        self.updatedAt = Date()
    }
} 