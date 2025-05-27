import Foundation
import SwiftData
import SwiftUI
import Combine

/// Service responsible for handling data migration between app updates
class DataMigrationService: ObservableObject {
    static let shared = DataMigrationService()
    
    // Published property to trigger UI updates when migration status changes
    @Published var isMigrationComplete = false
    
    private let userDefaults = UserDefaults.standard
    private let lastVersionKey = "lastAppVersion"
    private let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    private init() {}
    
    /// Checks if migration is needed and performs it if necessary
    func checkAndPerformMigration(modelContext: ModelContext) {
        // Get the current app version
        let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        // Get the last app version from UserDefaults
        let userDefaults = UserDefaults.standard
        let lastAppVersion = userDefaults.string(forKey: lastVersionKey) ?? "0.0"
        
        Logger.info("Current app version: \(currentAppVersion), Last app version: \(lastAppVersion)", category: .database)
        
        // Check if this is a new installation or an update
        if lastAppVersion != currentAppVersion {
            Logger.info("App version changed. Performing migration...", category: .database)
            
            // Perform migration steps
            migratePhotos(modelContext: modelContext)
            migrateProgressPhotoAttributes(modelContext: modelContext)
            migrateTaskScheduledTime(modelContext: modelContext)
            
            // Update the stored version
            userDefaults.set(currentAppVersion, forKey: lastVersionKey)
        } else {
            // Even if it's not a version update, we should verify photo integrity
            verifyPhotoIntegrity(modelContext: modelContext)
            migrateProgressPhotoAttributes(modelContext: modelContext)
        }
        
        // Mark migration as complete
        isMigrationComplete = true
    }
    
    /// Verifies that all photos in the database have corresponding files on disk
    private func verifyPhotoIntegrity(modelContext: ModelContext) {
        Logger.info("Verifying photo integrity...", category: .database)
        
        // Get all photos in the database
        let descriptor = FetchDescriptor<ProgressPhoto>()
        guard let existingPhotos = try? modelContext.fetch(descriptor) else {
            Logger.error("Failed to fetch existing photos", category: .database)
            return
        }
        
        // Create a photo service to use its photoExists method
        let photoService = ProgressPhotoService()
        var photosToRemove: [ProgressPhoto] = []
        
        // Check each photo to see if the file exists using the service's method
        for photo in existingPhotos {
            if !photoService.photoExists(at: photo.fileURL) {
                Logger.warning("Photo file missing: \(photo.fileURL.lastPathComponent)", category: .database)
                photosToRemove.append(photo)
            }
        }
        
        // Remove photos with missing files
        if !photosToRemove.isEmpty {
            Logger.info("Removing \(photosToRemove.count) photo records with missing files", category: .database)
            for photo in photosToRemove {
                modelContext.delete(photo)
            }
            
            // Save changes
            do {
                try modelContext.save()
                Logger.info("Successfully removed orphaned photo records", category: .database)
            } catch {
                Logger.error("Failed to save changes after removing orphaned photos: \(error.localizedDescription)", category: .database)
            }
        }
    }
    
    /// Migrates photos to ensure they're preserved between app updates
    private func migratePhotos(modelContext: ModelContext) {
        Logger.info("Migrating photos...", category: .database)
        
        // First verify and clean up existing photos
        verifyPhotoIntegrity(modelContext: modelContext)
        
        // Get the photo directory
        let photoService = ProgressPhotoService()
        let photoDirectory = photoService.getPhotoDirectory()
        
        // Get all photo files in the directory
        do {
            let fileManager = FileManager.default
            let photoFiles = try fileManager.contentsOfDirectory(at: photoDirectory, includingPropertiesForKeys: nil)
            
            // Get all photos in the database
            let descriptor = FetchDescriptor<ProgressPhoto>()
            guard let existingPhotos = try? modelContext.fetch(descriptor) else {
                Logger.error("Failed to fetch existing photos", category: .database)
                return
            }
            
            // Create a set of existing file URLs for quick lookup
            let existingFileURLs = Set(existingPhotos.map { $0.fileURL.lastPathComponent })
            
            // Find photos that exist on disk but not in the database
            let orphanedPhotos = photoFiles.filter { 
                let filename = $0.lastPathComponent
                // Skip non-photo files like .nomedia
                return filename.hasPrefix("photo_") && !existingFileURLs.contains(filename)
            }
            
            if !orphanedPhotos.isEmpty {
                Logger.info("Found \(orphanedPhotos.count) orphaned photos. Restoring references.", category: .database)
                
                // Try to restore orphaned photos
                for photoURL in orphanedPhotos {
                    // Parse the filename to extract metadata
                    // Format: photo_challengeId_angle_timestamp.jpg
                    let filename = photoURL.lastPathComponent
                    let components = filename.components(separatedBy: "_")
                    
                    if components.count >= 4, 
                       let challengeIdString = components[safe: 1],
                       let challengeId = UUID(uuidString: challengeIdString),
                       let angleRawValue = components[safe: 2],
                       let angle = PhotoAngle(rawValue: angleRawValue) {
                        
                        // Create a new photo record
                        let photo = ProgressPhoto(
                            challenge: nil, // We'll try to find the challenge later
                            date: Date(),
                            angle: angle,
                            fileURL: photoURL,
                            isBlurred: false
                        )
                        
                        // Try to find the associated challenge
                        let challengeDescriptor = FetchDescriptor<Challenge>(predicate: #Predicate { $0.id == challengeId })
                        if let challenges = try? modelContext.fetch(challengeDescriptor), let challenge = challenges.first {
                            photo.challenge = challenge
                        }
                        
                        modelContext.insert(photo)
                        Logger.info("Restored photo reference: \(photoURL.lastPathComponent)", category: .database)
                    }
                }
                
                // Save changes
                do {
                    try modelContext.save()
                    Logger.info("Successfully restored orphaned photo references", category: .database)
                } catch {
                    Logger.error("Failed to save restored photo references: \(error.localizedDescription)", category: .database)
                }
            }
        } catch {
            Logger.error("Failed to read photo directory: \(error.localizedDescription)", category: .database)
        }
    }
    
    /// Migrates ProgressPhoto records to ensure they have valid attributes
    private func migrateProgressPhotoAttributes(modelContext: ModelContext) {
        Logger.info("Migrating ProgressPhoto attributes...", category: .database)
        
        // Get all photos in the database
        let descriptor = FetchDescriptor<ProgressPhoto>()
        guard let existingPhotos = try? modelContext.fetch(descriptor) else {
            Logger.error("Failed to fetch existing photos", category: .database)
            return
        }
        
        var updatedCount = 0
        
        // Update each photo to ensure it has a valid challengeIteration value
        for photo in existingPhotos {
            if photo.challengeIteration == 0 {
                photo.challengeIteration = 1
                updatedCount += 1
            }
        }
        
        if updatedCount > 0 {
            Logger.info("Updated challengeIteration for \(updatedCount) photos", category: .database)
            
            // Save changes
            do {
                try modelContext.save()
                Logger.info("Successfully migrated ProgressPhoto attributes", category: .database)
            } catch {
                Logger.error("Failed to save changes after migrating ProgressPhoto attributes: \(error.localizedDescription)", category: .database)
            }
        }
    }
    
    /// Migrates Task records to ensure scheduledTime property works correctly
    private func migrateTaskScheduledTime(modelContext: ModelContext) {
        Logger.info("Migrating Task scheduledTime property...", category: .database)
        
        // Get all tasks in the database
        let descriptor = FetchDescriptor<Task>()
        guard let existingTasks = try? modelContext.fetch(descriptor) else {
            Logger.error("Failed to fetch existing tasks", category: .database)
            return
        }
        
        var updatedCount = 0
        
        // Due to how we've implemented the scheduledTime property with a private backing field,
        // we need to ensure all Task objects are loaded and have their properties accessed
        // to trigger SwiftData to properly update the schema
        for task in existingTasks {
            // Ensure timeOfDay has a valid value by accessing it and setting it explicitly
            // This helps "materialize" the property for SwiftData
            let currentTimeOfDay = task.timeOfDay
            task.timeOfDay = currentTimeOfDay 
            
            // Access the scheduledTime property to ensure it's properly loaded
            // For tasks that might have corrupt data, reset the property
            let currentScheduledTime = task.scheduledTime
            task.scheduledTime = currentScheduledTime
            
            // This forces any task with a problematic scheduledTime to be updated
            modelContext.processPendingChanges()
            updatedCount += 1
        }
        
        if updatedCount > 0 {
            Logger.info("Updated scheduledTime and timeOfDay for \(updatedCount) tasks", category: .database)
            
            // Save changes
            do {
                try modelContext.save()
                Logger.info("Successfully migrated Task scheduledTime and timeOfDay properties", category: .database)
            } catch {
                Logger.error("Failed to save changes after migrating Task properties: \(error.localizedDescription)", category: .database)
            }
        } else {
            Logger.info("No Task properties needed migration", category: .database)
        }
    }
}

// Extension to safely access array elements
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 