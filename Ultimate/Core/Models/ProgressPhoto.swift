import Foundation
import SwiftData
import SwiftUI
import Photos

/// Represents a photo angle
enum PhotoAngle: String, Codable, CaseIterable {
    case front = "Front"
    case leftSide = "Left Side"
    case rightSide = "Right Side"
    case back = "Back"
    
    var description: String {
        switch self {
        case .front:
            return "Front Profile"
        case .leftSide:
            return "Left Profile"
        case .rightSide:
            return "Right Profile"
        case .back:
            return "Back Profile"
        }
    }
    
    var icon: String {
        // Use a consistent icon for all angles
        return "person.bust"
    }
}

/// Represents a progress photo in the app
@Model
final class ProgressPhoto {
    // MARK: - Properties
    
    /// Unique identifier for the photo
    var id: UUID
    
    /// The challenge this photo belongs to
    @Relationship
    var challenge: Challenge?
    
    /// The date the photo was taken
    var date: Date
    
    /// The angle of the photo
    var angle: PhotoAngle
    
    /// The file URL for the photo
    var fileURL: URL
    
    /// Notes for this photo
    var notes: String?
    
    /// Whether the photo is blurred for privacy
    var isBlurred: Bool
    
    /// The iteration of the challenge this photo belongs to (for repeated challenges)
    var challengeIteration: Int = 1
    
    /// The creation date of the photo record
    var createdAt: Date
    
    /// The last update date of the photo record
    var updatedAt: Date
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        challenge: Challenge? = nil,
        date: Date = Date(),
        angle: PhotoAngle,
        fileURL: URL,
        notes: String? = nil,
        isBlurred: Bool = false,
        challengeIteration: Int = 1
    ) {
        self.id = id
        self.challenge = challenge
        self.date = date
        self.angle = angle
        self.fileURL = fileURL
        self.notes = notes
        self.isBlurred = isBlurred
        self.challengeIteration = challengeIteration
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Service for managing progress photos
class ProgressPhotoService {
    /// The directory where photos are stored
    private let photoDirectory: URL
    
    init() {
        // Create a directory for storing photos in the app's documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        photoDirectory = documentsDirectory.appendingPathComponent("ProgressPhotos", isDirectory: true)
        
        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: photoDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: photoDirectory, withIntermediateDirectories: true)
                
                // Add a .nomedia file to prevent media scanners from indexing this directory
                let noMediaFile = photoDirectory.appendingPathComponent(".nomedia")
                try Data().write(to: noMediaFile)
                
                Logger.info("Created photo directory at \(photoDirectory.path)", category: .photos)
            } catch {
                Logger.error("Error creating photo directory: \(error)", category: .photos)
            }
        }
        
        // Ensure the directory has proper attributes to persist
        do {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false
            var directoryURL = photoDirectory
            try directoryURL.setResourceValues(resourceValues)
            Logger.info("Set photo directory to be included in backups", category: .photos)
        } catch {
            Logger.error("Error setting directory attributes: \(error)", category: .photos)
        }
    }
    
    /// Returns the directory where photos are stored
    func getPhotoDirectory() -> URL {
        return photoDirectory
    }
    
    /// Saves a photo to the file system and returns the file URL
    func savePhoto(image: UIImage, challengeId: UUID, angle: PhotoAngle) -> URL? {
        // Create a unique filename with a consistent format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        // Use a consistent naming convention: photo_challengeId_angle_timestamp.jpg
        let filename = "photo_\(challengeId.uuidString)_\(angle.rawValue)_\(timestamp).jpg"
        let fileURL = photoDirectory.appendingPathComponent(filename)
        
        // Compress the image and save it
        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)
                
                // Set file attributes to ensure persistence
                try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: fileURL.path)
                
                Logger.info("Saved photo to \(fileURL.lastPathComponent)", category: .photos)
                return fileURL
            } catch {
                Logger.error("Error saving photo: \(error)", category: .photos)
                return nil
            }
        }
        
        return nil
    }
    
    /// Checks if a photo file exists at the given URL
    func photoExists(at url: URL) -> Bool {
        // First check if the file exists at the exact path
        let exists = FileManager.default.fileExists(atPath: url.path)
        
        // If the file doesn't exist at the exact path, try to find it by filename in the photo directory
        if !exists {
            Logger.warning("Photo not found at exact path: \(url.path)", category: .photos)
            
            // Try to find the file by its filename in the photo directory
            let filename = url.lastPathComponent
            let newURL = photoDirectory.appendingPathComponent(filename)
            
            // Check if the file exists in the photo directory
            let existsInPhotoDir = FileManager.default.fileExists(atPath: newURL.path)
            if existsInPhotoDir {
                Logger.info("Found photo at alternative location: \(newURL.path)", category: .photos)
                return true
            }
            
            // If still not found, try to find any file with the same challenge ID and angle
            do {
                let files = try FileManager.default.contentsOfDirectory(at: photoDirectory, includingPropertiesForKeys: nil)
                
                // Parse the filename to extract components
                let filenameComponents = filename.components(separatedBy: "_")
                
                // Check if we have enough components to extract challenge ID and angle
                // Format could be either:
                // - photo_challengeId_angle_timestamp.jpg (new format)
                // - challengeId_angle_timestamp.jpg (old format)
                
                var challengeIdComponent: String?
                var angleComponent: String?
                
                if filenameComponents.count >= 4 && filenameComponents[0] == "photo" {
                    // New format: photo_challengeId_angle_timestamp.jpg
                    challengeIdComponent = filenameComponents[1]
                    angleComponent = filenameComponents[2]
                } else if filenameComponents.count >= 3 {
                    // Old format: challengeId_angle_timestamp.jpg
                    challengeIdComponent = filenameComponents[0]
                    angleComponent = filenameComponents[1]
                }
                
                if let challengeIdComponent = challengeIdComponent, let angleComponent = angleComponent {
                    for file in files {
                        let fileComponents = file.lastPathComponent.components(separatedBy: "_")
                        
                        // Check for both old and new format
                        if fileComponents.count >= 4 && fileComponents[0] == "photo" {
                            // New format
                            if fileComponents[1] == challengeIdComponent && fileComponents[2] == angleComponent {
                                Logger.info("Found similar photo (new format): \(file.lastPathComponent)", category: .photos)
                                return true
                            }
                        } else if fileComponents.count >= 3 {
                            // Old format
                            if fileComponents[0] == challengeIdComponent && fileComponents[1] == angleComponent {
                                Logger.info("Found similar photo (old format): \(file.lastPathComponent)", category: .photos)
                                return true
                            }
                        }
                    }
                }
            } catch {
                Logger.error("Error searching for alternative photos: \(error)", category: .photos)
            }
        }
        
        return exists
    }
    
    /// Loads a photo from the file system
    func loadPhoto(from url: URL) -> UIImage? {
        // First check if the file exists at the exact path
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                guard let image = UIImage(data: data) else {
                    Logger.error("Failed to create image from data for photo: \(url.lastPathComponent)", category: .photos)
                    return nil
                }
                Logger.info("Successfully loaded photo: \(url.lastPathComponent)", category: .photos)
                return image
            } catch {
                Logger.error("Error loading photo: \(error.localizedDescription)", category: .photos)
            }
        }
        
        // If the file doesn't exist at the exact path, try to find it by filename in the photo directory
        let filename = url.lastPathComponent
        let newURL = photoDirectory.appendingPathComponent(filename)
        
        if url.path != newURL.path && FileManager.default.fileExists(atPath: newURL.path) {
            do {
                let data = try Data(contentsOf: newURL)
                guard let image = UIImage(data: data) else {
                    Logger.error("Failed to create image from data for photo at alternative location: \(newURL.lastPathComponent)", category: .photos)
                    return nil
                }
                Logger.info("Successfully loaded photo from alternative location: \(newURL.lastPathComponent)", category: .photos)
                return image
            } catch {
                Logger.error("Error loading photo from alternative location: \(error.localizedDescription)", category: .photos)
            }
        }
        
        // If still not found, try to find any file with the same challenge ID and angle
        let filenameComponents = filename.components(separatedBy: "_")
        
        var challengeIdComponent: String?
        var angleComponent: String?
        
        if filenameComponents.count >= 4 && filenameComponents[0] == "photo" {
            // New format: photo_challengeId_angle_timestamp.jpg
            challengeIdComponent = filenameComponents[1]
            angleComponent = filenameComponents[2]
        } else if filenameComponents.count >= 3 {
            // Old format: challengeId_angle_timestamp.jpg
            challengeIdComponent = filenameComponents[0]
            angleComponent = filenameComponents[1]
        }
        
        if let challengeIdComponent = challengeIdComponent, let angleComponent = angleComponent {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: photoDirectory, includingPropertiesForKeys: nil)
                
                for file in files {
                    let fileComponents = file.lastPathComponent.components(separatedBy: "_")
                    
                    var isMatch = false
                    
                    // Check for both old and new format
                    if fileComponents.count >= 4 && fileComponents[0] == "photo" {
                        // New format
                        isMatch = fileComponents[1] == challengeIdComponent && fileComponents[2] == angleComponent
                    } else if fileComponents.count >= 3 {
                        // Old format
                        isMatch = fileComponents[0] == challengeIdComponent && fileComponents[1] == angleComponent
                    }
                    
                    if isMatch {
                        do {
                            let data = try Data(contentsOf: file)
                            guard let image = UIImage(data: data) else { continue }
                            Logger.info("Successfully loaded similar photo: \(file.lastPathComponent)", category: .photos)
                            return image
                        } catch {
                            continue
                        }
                    }
                }
            } catch {
                Logger.error("Error searching for alternative photos: \(error)", category: .photos)
            }
        }
        
        Logger.error("Failed to load image for photo: \(url.lastPathComponent) - File not found", category: .photos)
        return nil
    }
    
    /// Deletes a photo from the file system
    func deletePhoto(at url: URL) -> Bool {
        // Check if the file exists at the exact path
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                Logger.info("Successfully deleted photo: \(url.lastPathComponent)", category: .photos)
                return true
            } catch {
                Logger.error("Error deleting photo: \(error.localizedDescription)", category: .photos)
                return false
            }
        }
        
        // If the file doesn't exist at the exact path, try to find it by filename in the photo directory
        let filename = url.lastPathComponent
        let newURL = photoDirectory.appendingPathComponent(filename)
        
        if url.path != newURL.path && FileManager.default.fileExists(atPath: newURL.path) {
            do {
                try FileManager.default.removeItem(at: newURL)
                Logger.info("Successfully deleted photo from alternative location: \(newURL.lastPathComponent)", category: .photos)
                return true
            } catch {
                Logger.error("Error deleting photo from alternative location: \(error.localizedDescription)", category: .photos)
                return false
            }
        }
        
        // If we couldn't find the file, consider the deletion "successful"
        Logger.warning("Photo not found for deletion: \(url.lastPathComponent)", category: .photos)
        return true
    }
    
    /// Applies a blur effect to a photo for privacy
    func blurPhoto(image: UIImage, radius: CGFloat = 10) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let outputCIImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return nil }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    /// Saves a photo to the user's photo library
    func savePhotoToLibrary(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Since UIImageWriteToSavedPhotosAlbum doesn't provide a completion handler,
        // we'll assume success unless there's a permissions issue
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch authStatus {
        case .authorized, .limited:
            completion(true, nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        completion(true, nil)
                    } else {
                        completion(false, NSError(domain: "com.ultimate.photos", code: 403, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"]))
                    }
                }
            }
        case .denied, .restricted:
            completion(false, NSError(domain: "com.ultimate.photos", code: 403, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"]))
        @unknown default:
            completion(false, NSError(domain: "com.ultimate.photos", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unknown authorization status"]))
        }
    }
} 