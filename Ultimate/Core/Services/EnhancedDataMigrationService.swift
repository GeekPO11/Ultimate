import Foundation
import SwiftData
import SwiftUI
import Combine

/// Enhanced service responsible for handling robust data migration between app updates
final class EnhancedDataMigrationService: ObservableObject {
    static let shared = EnhancedDataMigrationService()
    
    // Published properties for UI updates
    @Published var migrationState: MigrationState = .idle
    @Published var migrationProgress: Double = 0.0
    @Published var currentMigrationStep: String = ""
    
    // Migration tracking
    private let userDefaults = UserDefaults.standard
    private let migrationVersionKey = "lastMigrationVersion"
    private let backupVersionKey = "backupVersion"
    private let currentMigrationVersion = "2.0.0" // Update this with each migration
    
    // Migration state enum
    enum MigrationState: Equatable {
        case idle
        case inProgress(step: String)
        case completed
        case failed(error: MigrationError)
        
        static func == (lhs: MigrationState, rhs: MigrationState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.completed, .completed):
                return true
            case (.inProgress(let step1), .inProgress(let step2)):
                return step1 == step2
            case (.failed(let error1), .failed(let error2)):
                return error1.localizedDescription == error2.localizedDescription
            default:
                return false
            }
        }
    }
    
    // Migration error types
    enum MigrationError: LocalizedError, Equatable {
        case backupFailed
        case migrationStepFailed(step: String, underlying: String)
        case rollbackFailed
        case dataCorruption
        case insufficientStorage
        
        var errorDescription: String? {
            switch self {
            case .backupFailed:
                return "Failed to create data backup"
            case .migrationStepFailed(let step, let error):
                return "Migration failed at step '\(step)': \(error)"
            case .rollbackFailed:
                return "Failed to rollback migration changes"
            case .dataCorruption:
                return "Data corruption detected during migration"
            case .insufficientStorage:
                return "Insufficient storage space for migration"
            }
        }
        
        static func == (lhs: MigrationError, rhs: MigrationError) -> Bool {
            switch (lhs, rhs) {
            case (.backupFailed, .backupFailed),
                 (.rollbackFailed, .rollbackFailed),
                 (.dataCorruption, .dataCorruption),
                 (.insufficientStorage, .insufficientStorage):
                return true
            case (.migrationStepFailed(let step1, let error1), .migrationStepFailed(let step2, let error2)):
                return step1 == step2 && error1 == error2
            default:
                return false
            }
        }
    }
    
    // Migration step protocol
    protocol MigrationStep {
        var version: String { get }
        var description: String { get }
        var isReversible: Bool { get }
        
        func execute(context: ModelContext) async throws
        func rollback(context: ModelContext) async throws
        func validate(context: ModelContext) throws -> Bool
    }
    
    // Available migration steps
    private lazy var migrationSteps: [MigrationStep] = [
        PhotoAttributesMigration(),
        TaskSchedulingMigration(),
        ProgressPhotoMigration(),
        AnalyticsDataMigration()
    ]
    
    private init() {}
    
    // MARK: - Main Migration Interface
    
    /// Performs comprehensive migration check and execution
    func performMigration(modelContext: ModelContext) async {
        let lastMigrationVersion = userDefaults.string(forKey: migrationVersionKey) ?? "0.0.0"
        
        Logger.info("Starting migration check. Last version: \(lastMigrationVersion), Current: \(currentMigrationVersion)", category: .database)
        
        // Check if migration is needed
        guard lastMigrationVersion != currentMigrationVersion else {
            Logger.info("No migration needed", category: .database)
            await MainActor.run {
                migrationState = .completed
            }
            return
        }
        
        do {
            await MainActor.run {
                migrationState = .inProgress(step: "Preparing migration")
                migrationProgress = 0.0
            }
            
            // Pre-migration checks
            try await performPreMigrationChecks()
            
            // Create backup
            try await createDataBackup(context: modelContext)
            
            // Execute migration steps
            try await executeMigrationSteps(context: modelContext, fromVersion: lastMigrationVersion)
            
            // Post-migration validation
            try await performPostMigrationValidation(context: modelContext)
            
            // Update version
            userDefaults.set(currentMigrationVersion, forKey: migrationVersionKey)
            
            await MainActor.run {
                migrationState = .completed
                migrationProgress = 1.0
                currentMigrationStep = "Migration completed successfully"
            }
            
            Logger.info("Migration completed successfully", category: .database)
            
        } catch {
            Logger.error("Migration failed: \(error.localizedDescription)", category: .database)
            
            // Attempt rollback
            await attemptRollback(context: modelContext, error: error)
        }
    }
    
    // MARK: - Pre-Migration Checks
    
    private func performPreMigrationChecks() async throws {
        await updateProgress(0.1, step: "Performing pre-migration checks")
        
        // Check available storage
        try checkAvailableStorage()
        
        // Verify data integrity
        try await verifyDataIntegrity()
        
        // Check app permissions
        try checkAppPermissions()
    }
    
    private func checkAvailableStorage() throws {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: documentsPath.path)
            let freeSpace = attributes[.systemFreeSize] as? NSNumber
            let requiredSpace: Int64 = 100_000_000 // 100MB minimum
            
            if let available = freeSpace?.int64Value, available < requiredSpace {
                throw MigrationError.insufficientStorage
            }
        } catch {
            throw MigrationError.insufficientStorage
        }
    }
    
    private func verifyDataIntegrity() async throws {
        await updateProgress(0.15, step: "Verifying data integrity")
        // Add data integrity checks here
    }
    
    private func checkAppPermissions() throws {
        // Check photo library permissions, notifications, etc.
        // Add permission checks here
    }
    
    // MARK: - Backup Creation
    
    private func createDataBackup(context: ModelContext) async throws {
        await updateProgress(0.2, step: "Creating data backup")
        
        let backupManager = DataBackupManager()
        
        do {
            try await backupManager.createBackup(
                context: context,
                version: currentMigrationVersion
            )
            
            userDefaults.set(currentMigrationVersion, forKey: backupVersionKey)
            Logger.info("Data backup created successfully", category: .database)
            
        } catch {
            Logger.error("Failed to create backup: \(error.localizedDescription)", category: .database)
            throw MigrationError.backupFailed
        }
    }
    
    // MARK: - Migration Execution
    
    private func executeMigrationSteps(context: ModelContext, fromVersion: String) async throws {
        let applicableSteps = migrationSteps.filter { step in
            shouldExecuteStep(step, fromVersion: fromVersion)
        }
        
        Logger.info("Executing \(applicableSteps.count) migration steps", category: .database)
        
        for (index, step) in applicableSteps.enumerated() {
            let progressValue = 0.3 + (Double(index) / Double(applicableSteps.count)) * 0.5
            await updateProgress(progressValue, step: "Executing: \(step.description)")
            
            do {
                try await step.execute(context: context)
                
                // Validate step completion
                let isValid = try step.validate(context: context)
                if !isValid {
                    throw MigrationError.dataCorruption
                }
                
                Logger.info("Migration step '\(step.description)' completed successfully", category: .database)
                
            } catch {
                Logger.error("Migration step '\(step.description)' failed: \(error.localizedDescription)", category: .database)
                throw MigrationError.migrationStepFailed(step: step.description, underlying: error.localizedDescription)
            }
        }
    }
    
    private func shouldExecuteStep(_ step: MigrationStep, fromVersion: String) -> Bool {
        // Implement version comparison logic
        return compareVersions(step.version, isGreaterThan: fromVersion)
    }
    
    private func compareVersions(_ version1: String, isGreaterThan version2: String) -> Bool {
        let components1 = version1.split(separator: ".").compactMap { Int($0) }
        let components2 = version2.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(components1.count, components2.count) {
            let v1 = i < components1.count ? components1[i] : 0
            let v2 = i < components2.count ? components2[i] : 0
            
            if v1 > v2 { return true }
            if v1 < v2 { return false }
        }
        
        return false
    }
    
    // MARK: - Post-Migration Validation
    
    private func performPostMigrationValidation(context: ModelContext) async throws {
        await updateProgress(0.9, step: "Validating migration results")
        
        // Validate data integrity
        try await validateDataIntegrity(context: context)
        
        // Verify relationships
        try await validateRelationships(context: context)
        
        // Check for orphaned data
        try await cleanupOrphanedData(context: context)
    }
    
    private func validateDataIntegrity(context: ModelContext) async throws {
        // Check that all required models exist and have valid data
        let challengeDescriptor = FetchDescriptor<Challenge>()
        let challenges = try context.fetch(challengeDescriptor)
        
        for challenge in challenges {
            if challenge.name.isEmpty || challenge.durationInDays <= 0 {
                throw MigrationError.dataCorruption
            }
        }
        
        let photoDescriptor = FetchDescriptor<ProgressPhoto>()
        let photos = try context.fetch(photoDescriptor)
        
        for photo in photos {
            let photoService = ProgressPhotoService()
            if !photoService.photoExists(at: photo.fileURL) {
                Logger.warning("Photo file missing after migration: \(photo.fileURL.lastPathComponent)", category: .database)
            }
        }
    }
    
    private func validateRelationships(context: ModelContext) async throws {
        // Validate that all relationships are properly connected
        let taskDescriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(taskDescriptor)
        
        for task in tasks {
            if task.challenge == nil {
                Logger.warning("Found task without challenge relationship: \(task.name)", category: .database)
            }
        }
    }
    
    private func cleanupOrphanedData(context: ModelContext) async throws {
        // Remove any orphaned data that might have been created during migration
        let photoDescriptor = FetchDescriptor<ProgressPhoto>()
        let photos = try context.fetch(photoDescriptor)
        
        let photoService = ProgressPhotoService()
        var orphanedPhotos: [ProgressPhoto] = []
        
        for photo in photos {
            if !photoService.photoExists(at: photo.fileURL) {
                orphanedPhotos.append(photo)
            }
        }
        
        for photo in orphanedPhotos {
            context.delete(photo)
        }
        
        if !orphanedPhotos.isEmpty {
            try context.save()
            Logger.info("Cleaned up \(orphanedPhotos.count) orphaned photo records", category: .database)
        }
    }
    
    // MARK: - Rollback Handling
    
    private func attemptRollback(context: ModelContext, error: Error) async {
        Logger.warning("Attempting to rollback migration due to error: \(error.localizedDescription)", category: .database)
        
        await MainActor.run {
            migrationState = .inProgress(step: "Rolling back changes")
        }
        
        do {
            let backupManager = DataBackupManager()
            try await backupManager.restoreBackup(context: context)
            
            let migrationError = MigrationError.migrationStepFailed(step: "Migration", underlying: error.localizedDescription)
            await MainActor.run {
                migrationState = .failed(error: migrationError)
            }
            
            Logger.info("Successfully rolled back migration", category: .database)
            
        } catch {
            Logger.error("Rollback failed: \(error.localizedDescription)", category: .database)
            
            await MainActor.run {
                migrationState = .failed(error: MigrationError.rollbackFailed)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func updateProgress(_ progress: Double, step: String) {
        migrationProgress = progress
        currentMigrationStep = step
    }
    
    // MARK: - Migration Recovery
    
    func recoverFromFailedMigration(context: ModelContext) async {
        Logger.info("Attempting recovery from failed migration", category: .database)
        
        do {
            let backupManager = DataBackupManager()
            try await backupManager.restoreBackup(context: context)
            
            await MainActor.run {
                migrationState = .completed
            }
            
            Logger.info("Successfully recovered from failed migration", category: .database)
            
        } catch {
            Logger.error("Migration recovery failed: \(error.localizedDescription)", category: .database)
            
            await MainActor.run {
                migrationState = .failed(error: MigrationError.rollbackFailed)
            }
        }
    }
}

// MARK: - Migration Steps Implementation

struct PhotoAttributesMigration: EnhancedDataMigrationService.MigrationStep {
    let version = "1.1.0"
    let description = "Migrate photo attributes and metadata"
    let isReversible = true
    
    func execute(context: ModelContext) async throws {
        let descriptor = FetchDescriptor<ProgressPhoto>()
        let photos = try context.fetch(descriptor)
        
        for photo in photos {
            // Ensure all photos have valid challenge iteration
            if photo.challengeIteration == 0 {
                photo.challengeIteration = 1
            }
            
            // Ensure createdAt and updatedAt are set if they weren't before
            if photo.createdAt == Date(timeIntervalSince1970: 0) {
                photo.createdAt = photo.date
                photo.updatedAt = photo.date
            }
        }
        
        try context.save()
    }
    
    func rollback(context: ModelContext) async throws {
        // Implement rollback logic if needed
    }
    
    func validate(context: ModelContext) throws -> Bool {
        let descriptor = FetchDescriptor<ProgressPhoto>()
        let photos = try context.fetch(descriptor)
        
        return photos.allSatisfy { $0.challengeIteration > 0 }
    }
}

struct TaskSchedulingMigration: EnhancedDataMigrationService.MigrationStep {
    let version = "1.2.0"
    let description = "Migrate task scheduling data"
    let isReversible = true
    
    func execute(context: ModelContext) async throws {
        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)
        
        for task in tasks {
            // Ensure all tasks have valid scheduling information
            if task.timeOfDay == .anytime && task.scheduledTime != nil {
                // Set proper time of day based on scheduled time
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: task.scheduledTime!)
                
                if hour < 12 {
                    task.timeOfDay = .morning
                } else {
                    task.timeOfDay = .evening
                }
            }
            
            // Ensure all tasks have valid duration if they are workout tasks
            if task.type == .workout && task.durationMinutes == nil {
                task.durationMinutes = 30 // Default 30 minutes for workouts
            }
        }
        
        try context.save()
    }
    
    func rollback(context: ModelContext) async throws {
        // Implement rollback logic
    }
    
    func validate(context: ModelContext) throws -> Bool {
        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)
        
        // Check that workout tasks have duration
        let workoutTasks = tasks.filter { $0.type == .workout }
        return workoutTasks.allSatisfy { $0.durationMinutes != nil }
    }
}

struct ProgressPhotoMigration: EnhancedDataMigrationService.MigrationStep {
    let version = "1.3.0"
    let description = "Migrate progress photo organization"
    let isReversible = true
    
    func execute(context: ModelContext) async throws {
        let descriptor = FetchDescriptor<ProgressPhoto>()
        let photos = try context.fetch(descriptor)
        
        // Group photos by challenge and organize them
        let groupedPhotos = Dictionary(grouping: photos) { $0.challenge?.id }
        
        for (challengeId, challengePhotos) in groupedPhotos {
            if challengeId != nil {
                // Sort photos by date to ensure proper order
                let sortedPhotos = challengePhotos.sorted { $0.date < $1.date }
                
                // Update the updatedAt field to reflect this organization
                for photo in sortedPhotos {
                    photo.updatedAt = Date()
                }
            }
        }
        
        try context.save()
    }
    
    func rollback(context: ModelContext) async throws {
        // Implement rollback logic
    }
    
    func validate(context: ModelContext) throws -> Bool {
        let descriptor = FetchDescriptor<ProgressPhoto>()
        let photos = try context.fetch(descriptor)
        
        // Validate that all photos have proper updatedAt timestamps
        return photos.allSatisfy { $0.updatedAt > Date(timeIntervalSince1970: 0) }
    }
}

struct AnalyticsDataMigration: EnhancedDataMigrationService.MigrationStep {
    let version = "2.0.0"
    let description = "Migrate analytics and progress data"
    let isReversible = false // Analytics migration is not reversible
    
    func execute(context: ModelContext) async throws {
        // Calculate and store analytics data for existing challenges
        let challengeDescriptor = FetchDescriptor<Challenge>()
        let challenges = try context.fetch(challengeDescriptor)
        
        for challenge in challenges {
            // Calculate and store progress metrics
            challenge.analyticsData = await calculateAnalyticsData(for: challenge, context: context)
        }
        
        try context.save()
    }
    
    func rollback(context: ModelContext) async throws {
        throw EnhancedDataMigrationService.MigrationError.rollbackFailed // Not reversible
    }
    
    func validate(context: ModelContext) throws -> Bool {
        let descriptor = FetchDescriptor<Challenge>()
        let challenges = try context.fetch(descriptor)
        
        return challenges.allSatisfy { $0.analyticsData != nil }
    }
    
    private func calculateAnalyticsData(for challenge: Challenge, context: ModelContext) async -> [String: Any] {
        // Calculate comprehensive analytics data
        return [
            "totalDays": challenge.durationInDays,
            "completedDays": challenge.completedDays,
            "consistencyScore": 0.85, // Calculate actual score
            "lastUpdated": Date()
        ]
    }
}

// MARK: - Data Backup Manager

class DataBackupManager {
    private let backupDirectory: URL
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        backupDirectory = documentsPath.appendingPathComponent("Backups")
        
        try? FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
    }
    
    func createBackup(context: ModelContext, version: String) async throws {
        let backupPath = backupDirectory.appendingPathComponent("backup_\(version).sqlite")
        
        // Export data to backup file
        // This is a simplified implementation - you would implement actual backup logic here
        let backupData = try await exportData(context: context)
        try backupData.write(to: backupPath)
        
        Logger.info("Backup created at: \(backupPath.path)", category: .database)
    }
    
    func restoreBackup(context: ModelContext) async throws {
        // Find the most recent backup
        let backupFiles = try FileManager.default.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
        
        guard let latestBackup = backupFiles.first(where: { $0.pathExtension == "sqlite" }) else {
            throw EnhancedDataMigrationService.MigrationError.rollbackFailed
        }
        
        // Restore data from backup
        let backupData = try Data(contentsOf: latestBackup)
        try await importData(backupData, context: context)
        
        Logger.info("Data restored from backup: \(latestBackup.path)", category: .database)
    }
    
    private func exportData(context: ModelContext) async throws -> Data {
        // Implement actual data export logic
        return Data()
    }
    
    private func importData(_ data: Data, context: ModelContext) async throws {
        // Implement actual data import logic
    }
}

// MARK: - Extension for Challenge

extension Challenge {
    var analyticsData: [String: Any]? {
        get {
            // Parse from stored analytics string
            return nil
        }
        set {
            // Store as analytics string
        }
    }
}

// MARK: - Supporting Types

struct PhotoMetadata {
    let deviceModel: String
    let createdAt: Date
    let fileSize: Int64
} 