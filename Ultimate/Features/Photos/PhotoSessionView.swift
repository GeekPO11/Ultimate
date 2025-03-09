import SwiftUI
import SwiftData

/// View for capturing a set of progress photos
struct PhotoSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let selectedChallenge: Challenge?
    
    @State private var currentAngleIndex = 0
    @State private var capturedImages: [PhotoAngle: UIImage] = [:]
    @State private var savedPhotoAngles: Set<PhotoAngle> = []
    @State private var showingCameraView = false
    @State private var showingPhotoLibrary = false
    
    private let photoService = ProgressPhotoService()
    private var angles: [PhotoAngle] { PhotoAngle.allCases }
    private var currentAngle: PhotoAngle { angles[currentAngleIndex] }
    
    // Create a binding for currentAngle
    private var currentAngleBinding: Binding<PhotoAngle> {
        Binding(
            get: { self.currentAngle },
            set: { newValue in
                if let index = angles.firstIndex(of: newValue) {
                    self.currentAngleIndex = index
                }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Progress indicator
                ProgressIndicatorView(
                    angles: angles,
                    currentAngleIndex: currentAngleIndex,
                    capturedImages: capturedImages
                )
                
                // Current angle instructions
                AngleInstructionsView(currentAngle: currentAngle)
                
                // Preview of captured image
                ImagePreviewView(
                    currentAngle: currentAngle,
                    capturedImage: capturedImages[currentAngle]
                )
                
                // Capture buttons
                CaptureButtonsView(
                    showingCameraView: $showingCameraView,
                    showingPhotoLibrary: $showingPhotoLibrary
                )
                
                // Navigation buttons
                NavigationButtonsView(
                    currentAngleIndex: $currentAngleIndex,
                    angles: angles,
                    currentAngle: currentAngle,
                    capturedImages: capturedImages,
                    onFinish: saveAllPhotos
                )
            }
            .navigationTitle("Photo Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCameraView) {
                CameraView(
                    selectedChallenge: selectedChallenge,
                    selectedAngle: currentAngleBinding,
                    onPhotoTaken: { image in
                        capturedImages[currentAngle] = image
                        // Save the image to the model after capturing
                        saveProgressPhoto(angle: currentAngle, image: image)
                        // Mark this angle as saved
                        savedPhotoAngles.insert(currentAngle)
                    }
                )
                .interactiveDismissDisabled(true) // Prevent accidental dismissal during photo capture
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                PhotoPicker(
                    selectedChallenge: selectedChallenge,
                    selectedAngle: currentAngleBinding,
                    onPhotoSelected: { image in
                        capturedImages[currentAngle] = image
                        // Don't save immediately when selecting from library
                    }
                )
            }
        }
    }
    
    /// Gets instructions for the current angle
    private func getInstructionsForAngle(_ angle: PhotoAngle) -> String {
        switch angle {
        case .front:
            return "Stand straight facing the camera with arms slightly away from your body"
        case .leftSide:
            return "Stand with your left side facing the camera to capture your profile"
        case .rightSide:
            return "Stand with your right side facing the camera to capture your profile"
        case .back:
            return "Stand with your back to the camera, arms slightly away from your body"
        }
    }
    
    /// Saves all captured photos
    private func saveAllPhotos() {
        for (angle, image) in capturedImages {
            // Skip angles that have already been saved
            if savedPhotoAngles.contains(angle) {
                Logger.debug("Skipping already saved photo for angle: \(angle.rawValue)", category: .photos)
                continue
            }
            
            guard let fileURL = photoService.savePhoto(
                image: image,
                challengeId: selectedChallenge?.id ?? UUID(),
                angle: angle
            ) else {
                continue
            }
            
            let newPhoto = ProgressPhoto(
                challenge: selectedChallenge,
                date: Date(),
                angle: angle,
                fileURL: fileURL,
                isBlurred: false
            )
            
            modelContext.insert(newPhoto)
            Logger.info("Saved photo for angle: \(angle.rawValue) during session completion", category: .photos)
        }
        
        try? modelContext.save()
        
        // Check if all angles have photos and mark tasks as complete
        if capturedImages.count == PhotoAngle.allCases.count {
            checkAndCompletePhotoTasks()
        }
        
        dismiss()
    }
    
    /// Checks if all photos for today are taken and marks photo tasks as complete
    private func checkAndCompletePhotoTasks() {
        Logger.info("Photo session complete with all angles, marking photo tasks as complete", category: .photos)
        
        // Get today's date
        let today = Calendar.current.startOfDay(for: Date())
        
        // Fetch all daily tasks for today
        let fetchDescriptor = FetchDescriptor<DailyTask>()
        do {
            let allDailyTasks = try modelContext.fetch(fetchDescriptor)
            
            // Filter for today's photo tasks
            let todayPhotoTasks = allDailyTasks.filter { task in
                Calendar.current.isDate(task.date, inSameDayAs: today) &&
                task.task?.type == .photo &&
                !task.isCompleted
            }
            
            // Mark each photo task as complete
            for task in todayPhotoTasks {
                Logger.info("Marking photo task as complete: \(task.title)", category: .photos)
                task.complete(notes: "Automatically completed - all progress photos taken in session")
            }
            
            // Save the changes
            try modelContext.save()
            Logger.info("Successfully marked \(todayPhotoTasks.count) photo tasks as complete", category: .photos)
        } catch {
            Logger.error("Failed to mark photo tasks as complete: \(error.localizedDescription)", category: .photos)
        }
    }
    
    /// Saves a progress photo to the model
    private func saveProgressPhoto(angle: PhotoAngle, image: UIImage) {
        print("PhotoSessionView: Saving progress photo for angle: \(angle)")
        
        guard let fileURL = photoService.savePhoto(
            image: image,
            challengeId: selectedChallenge?.id ?? UUID(),
            angle: angle
        ) else {
            print("PhotoSessionView: Error saving photo - fileURL is nil")
            return
        }
        
        // Query for existing photos to prevent duplicates
        let descriptor = FetchDescriptor<ProgressPhoto>()
        do {
            let allPhotos = try modelContext.fetch(descriptor)
            
            // Check if a photo with this URL already exists
            let existingPhotos = allPhotos.filter { 
                $0.fileURL.lastPathComponent == fileURL.lastPathComponent 
            }
            
            if !existingPhotos.isEmpty {
                print("PhotoSessionView: Duplicate photo detected, not saving again")
                return
            }
            
            print("PhotoSessionView: Creating new ProgressPhoto object")
            let newPhoto = ProgressPhoto(
                challenge: selectedChallenge,
                date: Date(),
                angle: angle,
                fileURL: fileURL,
                isBlurred: false
            )
            
            print("PhotoSessionView: Inserting photo into model context")
            modelContext.insert(newPhoto)
            
            do {
                try modelContext.save()
                print("PhotoSessionView: Successfully saved photo to model context")
            } catch {
                print("PhotoSessionView: Error saving photo to model context: \(error.localizedDescription)")
            }
        } catch {
            print("PhotoSessionView: Error fetching existing photos: \(error.localizedDescription)")
        }
    }
}

// MARK: - Subviews

/// Progress indicator view showing the status of each angle
struct ProgressIndicatorView: View {
    let angles: [PhotoAngle]
    let currentAngleIndex: Int
    let capturedImages: [PhotoAngle: UIImage]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(Array(angles.enumerated()), id: \.element) { index, angle in
                let isCurrent = index == currentAngleIndex
                let isCompleted = capturedImages[angle] != nil
                
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? DesignSystem.Colors.primaryAction : (isCurrent ? DesignSystem.Colors.primaryAction.opacity(0.3) : DesignSystem.Colors.cardBackground))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(isCompleted || isCurrent ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.dividers, lineWidth: 1)
                            )
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(isCurrent ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Text(angle.description)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(isCompleted || isCurrent ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

/// View showing instructions for the current angle
struct AngleInstructionsView: View {
    let currentAngle: PhotoAngle
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Capture \(currentAngle.description)")
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
            
            Text(getInstructionsForAngle(currentAngle))
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private func getInstructionsForAngle(_ angle: PhotoAngle) -> String {
        switch angle {
        case .front:
            return "Stand straight facing the camera with arms slightly away from your body"
        case .leftSide:
            return "Stand with your left side facing the camera to capture your profile"
        case .rightSide:
            return "Stand with your right side facing the camera to capture your profile"
        case .back:
            return "Stand with your back to the camera, arms slightly away from your body"
        }
    }
}

/// View showing the preview of the captured image or a placeholder
struct ImagePreviewView: View {
    let currentAngle: PhotoAngle
    let capturedImage: UIImage?
    
    var body: some View {
        if let image = capturedImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 300)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                )
                .padding(.horizontal)
        } else {
            // Placeholder
            ZStack {
                Rectangle()
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                    )
                
                VStack(spacing: 16) {
                    Image(systemName: currentAngle.icon)
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.primaryAction.opacity(0.7))
                    
                    Text("No photo captured yet")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .padding(.horizontal)
        }
    }
}

/// View with buttons for capturing photos
struct CaptureButtonsView: View {
    @Binding var showingCameraView: Bool
    @Binding var showingPhotoLibrary: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Take Photo button with neon style
            Button {
                showingCameraView = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Take Photo")
                }
                .font(DesignSystem.Typography.body)
                .fontWeight(.medium)
                .foregroundColor(Color.cyan.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.cyan.opacity(0.8), lineWidth: 1.5)
                        .shadow(color: Color.cyan.opacity(0.8), radius: 4, x: 0, y: 0)
                        .shadow(color: Color.cyan.opacity(0.6), radius: 8, x: 0, y: 0)
                )
            }
            
            // From Library button with neon style
            Button {
                showingPhotoLibrary = true
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("From Library")
                }
                .font(DesignSystem.Typography.body)
                .fontWeight(.medium)
                .foregroundColor(Color.purple.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.purple.opacity(0.8), lineWidth: 1.5)
                        .shadow(color: Color.purple.opacity(0.8), radius: 4, x: 0, y: 0)
                        .shadow(color: Color.purple.opacity(0.6), radius: 8, x: 0, y: 0)
                )
            }
        }
        .padding(.horizontal)
    }
}

/// View with navigation buttons
struct NavigationButtonsView: View {
    @Binding var currentAngleIndex: Int
    let angles: [PhotoAngle]
    let currentAngle: PhotoAngle
    let capturedImages: [PhotoAngle: UIImage]
    let onFinish: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Back button with neon style
            Button(action: {
                if currentAngleIndex > 0 {
                    currentAngleIndex -= 1
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(DesignSystem.Typography.body)
                .foregroundColor(currentAngleIndex > 0 ? Color.blue.opacity(0.8) : Color.gray.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(currentAngleIndex > 0 ? Color.blue.opacity(0.8) : Color.gray.opacity(0.3), lineWidth: 1.5)
                        .shadow(color: currentAngleIndex > 0 ? Color.blue.opacity(0.6) : Color.clear, radius: 4, x: 0, y: 0)
                )
            }
            .disabled(currentAngleIndex == 0)
            
            // Next/Finish button with neon style
            Button(action: {
                if currentAngleIndex < angles.count - 1 {
                    currentAngleIndex += 1
                } else {
                    onFinish()
                }
            }) {
                HStack {
                    Text(currentAngleIndex < angles.count - 1 ? "Next" : "Finish")
                    Image(systemName: currentAngleIndex < angles.count - 1 ? "chevron.right" : "checkmark")
                }
                .font(DesignSystem.Typography.body)
                .foregroundColor(capturedImages[currentAngle] != nil ? Color.green.opacity(0.8) : Color.gray.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(capturedImages[currentAngle] != nil ? Color.green.opacity(0.8) : Color.gray.opacity(0.3), lineWidth: 1.5)
                        .shadow(color: capturedImages[currentAngle] != nil ? Color.green.opacity(0.6) : Color.clear, radius: 4, x: 0, y: 0)
                )
            }
            .disabled(capturedImages[currentAngle] == nil)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

#Preview {
    PhotoSessionView(selectedChallenge: nil)
        .modelContainer(for: [User.self, Challenge.self, Task.self, DailyTask.self, ProgressPhoto.self], inMemory: true)
} 