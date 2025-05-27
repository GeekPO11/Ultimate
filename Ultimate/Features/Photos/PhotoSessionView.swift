import SwiftUI
import SwiftData
import _Concurrency

/// Enhanced view for capturing a set of progress photos with improved UI and user flow
struct PhotoSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let selectedChallenge: Challenge?
    
    @State private var currentAngleIndex = 0
    @State private var capturedImages: [PhotoAngle: UIImage] = [:]
    @State private var savedPhotoAngles: Set<PhotoAngle> = []
    @State private var showingCameraView = false
    @State private var showingPhotoLibrary = false
    @State private var sessionComplete = false
    @State private var isProcessing = false
    
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
            ZStack {
                PremiumBackground()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        // Session header with challenge info
                        sessionHeaderView
                        
                        // Action buttons at the top - now dynamic
                        dynamicActionButtonsSection
                        
                        // Compact angle selection
                        compactAngleSelector
                        
                        // Current angle preview
                        currentAnglePreview
                        
                        // Progress overview at bottom
                        progressOverview
                        
                        // Add some bottom padding for better scrolling
                        Color.clear.frame(height: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Photo Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primaryAction)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if capturedImages.count == angles.count && !isProcessing {
                        Button("Complete") {
                            completeSession()
                        }
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                        .fontWeight(.semibold)
                    } else if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                }
            }
            .sheet(isPresented: $showingCameraView) {
                OptimizedCameraView(
                    selectedChallenge: selectedChallenge,
                    selectedAngle: currentAngleBinding,
                    onPhotoTaken: { image in
                        handlePhotoCapture(image: image)
                    }
                )
                .interactiveDismissDisabled(true)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                PhotoPicker(
                    selectedChallenge: selectedChallenge,
                    selectedAngle: currentAngleBinding,
                    onPhotoSelected: { image in
                        capturedImages[currentAngle] = image
                        updateProgress()
                    }
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var sessionHeaderView: some View {
        CTCard(style: .glass) {
            VStack(spacing: DesignSystem.Spacing.l) {
                // Main header row
                HStack(alignment: .center, spacing: DesignSystem.Spacing.m) {
                    // Session icon
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primaryAction.opacity(0.1))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.primaryAction)
                    }
                    
                    // Title and info
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Progress Photo Session")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .lineLimit(1)
                        
                        if let challenge = selectedChallenge {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "target")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.primaryAction)
                                
                                Text(challenge.name)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .lineLimit(1)
                            }
                        } else {
                            Text("General Progress Photos")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        // Date
                        Text(Date(), style: .date)
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Progress counter
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        ZStack {
                            Circle()
                                .stroke(DesignSystem.Colors.primaryAction.opacity(0.2), lineWidth: 4)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(capturedImages.count) / CGFloat(angles.count))
                                .stroke(DesignSystem.Colors.primaryAction, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.3), value: capturedImages.count)
                            
                            VStack(spacing: 0) {
                                Text("\(capturedImages.count)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(DesignSystem.Colors.primaryAction)
                                
                                Text("/\(angles.count)")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        
                        Text("Photos")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                }
                
                // Progress bar section (separated for better layout)
                VStack(spacing: DesignSystem.Spacing.s) {
                    HStack {
                        Text("Session Progress")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Text("\(Int(Double(capturedImages.count) / Double(angles.count) * 100))% Complete")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.primaryAction)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(DesignSystem.Colors.primaryAction.opacity(0.1))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(DesignSystem.Colors.primaryAction)
                                .frame(
                                    width: geometry.size.width * (Double(capturedImages.count) / Double(angles.count)),
                                    height: 6
                                )
                                .animation(.easeInOut(duration: 0.3), value: capturedImages.count)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(DesignSystem.Spacing.l)
        }
    }
    
    private var dynamicActionButtonsSection: some View {
        let hasPhotosForToday = hasAnyPhotosForToday()
        let buttonTitle = hasPhotosForToday ? "Update Photos" : "Take Photos"
        let libraryTitle = hasPhotosForToday ? "Update Library" : "Photo Library"
        
        return HStack(spacing: DesignSystem.Spacing.m) {
            // Camera button - primary action
            CTButton(
                title: buttonTitle,
                icon: "camera.fill",
                style: .primary,
                size: .large,
                action: {
                    showingCameraView = true
                }
            )
            
            // Library button - secondary action  
            CTButton(
                title: libraryTitle,
                icon: "photo.on.rectangle",
                style: .secondary,
                size: .large,
                action: {
                    showingPhotoLibrary = true
                }
            )
        }
    }
    
    private var compactAngleSelector: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                HStack {
                    Text("Select Angle")
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text("\(currentAngle.description)")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.primaryAction.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Center-aligned horizontal scrolling angle selection
                HStack {
                    Spacer()
                    
                    HStack(spacing: DesignSystem.Spacing.l) {
                        ForEach(0..<angles.count, id: \.self) { index in
                            CompactAngleButton(
                                angle: angles[index],
                                isSelected: currentAngleIndex == index,
                                isCaptured: capturedImages[angles[index]] != nil,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentAngleIndex = index
                                    }
                                }
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
            }
            .padding(DesignSystem.Spacing.l)
        }
    }
    
    private var currentAnglePreview: some View {
        let existingPhoto = getExistingPhotoForAngle(currentAngle)
        let hasExistingPhoto = existingPhoto != nil
        
        return CTCard(style: .glass) {
            VStack(spacing: DesignSystem.Spacing.m) {
                // Angle info header
                HStack {
                    Image(systemName: currentAngle.icon)
                        .font(.system(size: 18))
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentAngle.description)
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(getInstructionsForAngle(currentAngle))
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    if capturedImages[currentAngle] != nil {
                        // New photo captured in session
                        VStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                            
                            Text("New")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                        }
                    } else if hasExistingPhoto {
                        // Existing photo from today
                        VStack(spacing: 2) {
                            Image(systemName: "photo.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text("Today")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
                
                // Image preview - show session capture, existing photo, or placeholder
                if let sessionImage = capturedImages[currentAngle] {
                    // Show newly captured image from this session
                    Image(uiImage: sessionImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                .stroke(DesignSystem.Colors.primaryAction, lineWidth: 2)
                        )
                        .overlay(
                            VStack {
                                HStack {
                                    Spacer()
                                    Text("NEW")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(DesignSystem.Colors.primaryAction)
                                        .cornerRadius(4)
                                        .padding(8)
                                }
                                Spacer()
                            }
                        )
                } else if let existingPhoto = existingPhoto {
                    // Show existing photo from today with option to update
                    AsyncImage(url: existingPhoto.fileURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(DesignSystem.BorderRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                    .stroke(DesignSystem.Colors.secondaryText, lineWidth: 1)
                            )
                            .overlay(
                                VStack {
                                    HStack {
                                        Spacer()
                                        Text("TODAY")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(DesignSystem.Colors.secondaryText)
                                            .cornerRadius(4)
                                            .padding(8)
                                    }
                                    Spacer()
                                }
                            )
                    } placeholder: {
                        Rectangle()
                            .fill(DesignSystem.Colors.cardBackground.opacity(0.3))
                            .frame(height: 200)
                            .cornerRadius(DesignSystem.BorderRadius.medium)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                } else {
                    // Compact placeholder for new photo
                    ZStack {
                        Rectangle()
                            .fill(DesignSystem.Colors.cardBackground.opacity(0.3))
                            .frame(height: 200)
                            .cornerRadius(DesignSystem.BorderRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                    .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                            )
                        
                        VStack(spacing: DesignSystem.Spacing.s) {
                            Image(systemName: currentAngle.icon)
                                .font(.system(size: 32))
                                .foregroundColor(DesignSystem.Colors.primaryAction.opacity(0.6))
                            
                            Text("Ready to capture")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var progressOverview: some View {
        CTCard(style: .glass) {
            VStack(spacing: DesignSystem.Spacing.s) {
                // Progress bar
                HStack {
                    Text("Progress")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(Double(capturedImages.count) / Double(angles.count) * 100))%")
                        .font(DesignSystem.Typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(DesignSystem.Colors.cardBackground)
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(DesignSystem.Colors.primaryAction)
                            .frame(
                                width: geometry.size.width * (Double(capturedImages.count) / Double(angles.count)),
                                height: 4
                            )
                            .cornerRadius(2)
                            .animation(.easeInOut(duration: 0.3), value: capturedImages.count)
                    }
                }
                .frame(height: 4)
                
                // Navigation controls
                HStack(spacing: DesignSystem.Spacing.s) {
                    Button(action: previousAngle) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Previous")
                                .font(DesignSystem.Typography.caption1)
                        }
                        .foregroundColor(currentAngleIndex > 0 ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            currentAngleIndex > 0 ?
                            DesignSystem.Colors.primaryAction.opacity(0.1) :
                            Color.clear
                        )
                        .cornerRadius(8)
                    }
                    .disabled(currentAngleIndex == 0)
                    
                    Spacer()
                    
                    Button(action: nextAngle) {
                        HStack(spacing: 4) {
                            Text("Next")
                                .font(DesignSystem.Typography.caption1)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(currentAngleIndex < angles.count - 1 ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            currentAngleIndex < angles.count - 1 ?
                            DesignSystem.Colors.primaryAction.opacity(0.1) :
                            Color.clear
                        )
                        .cornerRadius(8)
                    }
                    .disabled(currentAngleIndex >= angles.count - 1)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.s)
            .padding(.horizontal, DesignSystem.Spacing.m)
        }
    }
    
    // MARK: - Helper Methods
    
    private func previousAngle() {
        guard currentAngleIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentAngleIndex -= 1
        }
    }
    
    private func nextAngle() {
        guard currentAngleIndex < angles.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentAngleIndex += 1
        }
    }
    
    private func handlePhotoCapture(image: UIImage) {
        // Save captured image for current angle
        capturedImages[currentAngle] = image
        
        // Save photo immediately 
        savePhoto(image: image, angle: currentAngle)
        
        // Update progress
        updateProgress()
        
        // Check if we've completed all angles
        if capturedImages.count == angles.count {
            // All photos captured - show completion
            withAnimation(.easeInOut(duration: 0.5)) {
                sessionComplete = true
            }
            
            // Auto-dismiss after showing completion briefly
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } else {
            // Find next uncaptured angle
            var nextAngleIndex = (currentAngleIndex + 1) % angles.count
            while capturedImages[angles[nextAngleIndex]] != nil && nextAngleIndex != currentAngleIndex {
                nextAngleIndex = (nextAngleIndex + 1) % angles.count
            }
            
            // Smoothly transition to next angle
            withAnimation(.easeInOut(duration: 0.3)) {
                currentAngleIndex = nextAngleIndex
            }
            
            // Keep camera view open for continuous flow
            // Don't dismiss - let user continue with next photo
        }
    }
    
    private func completeSession() {
        guard !isProcessing else { return }
        isProcessing = true
        
        // Use main thread for all SwiftData operations
        DispatchQueue.main.async {
            // Save any remaining photos synchronously on main thread
            for (angle, image) in capturedImages {
                if !savedPhotoAngles.contains(angle) {
                    self.savePhotoSync(angle: angle, image: image)
                    savedPhotoAngles.insert(angle)
                }
            }
            
            // Complete photo tasks if all angles captured
            if capturedImages.count == PhotoAngle.allCases.count {
                self.markPhotoTasksComplete()
            }
            
            sessionComplete = true
            isProcessing = false
            dismiss()
        }
    }
    
    private func updateProgress() {
        // Progress indicators update automatically via @State bindings
        // No manual update needed
    }
    
    /// Gets instructions for the current angle
    private func getInstructionsForAngle(_ angle: PhotoAngle) -> String {
        switch angle {
        case .front:
            return "Face camera with arms slightly away from body"
        case .leftSide:
            return "Left side facing camera for profile view"
        case .rightSide:
            return "Right side facing camera for profile view"
        case .back:
            return "Back to camera, arms slightly away from body"
        }
    }
    
    /// Thread-safe async photo saving with proper challenge association
    @MainActor
    private func saveProgressPhotoAsync(angle: PhotoAngle, image: UIImage) async {
        Logger.info("Saving progress photo for angle: \(angle.rawValue) with challenge: \(selectedChallenge?.name ?? "No Challenge")", category: .photos)
        
        // Save photo file
        let fileURL = photoService.savePhoto(
            image: image,
            challengeId: selectedChallenge?.id ?? UUID(),
            angle: angle
        )
        
        guard let fileURL = fileURL else {
            Logger.error("Failed to save photo - fileURL is nil", category: .photos)
            return
        }
        
        // All SwiftData operations on main thread with proper challenge association
        do {
            let descriptor = FetchDescriptor<ProgressPhoto>()
            let allPhotos = try modelContext.fetch(descriptor)
            let today = Calendar.current.startOfDay(for: Date())
            
            // Find and remove existing photos for today with the same angle and challenge
            let sameDayPhotos = allPhotos.filter { photo in
                photo.angle == angle &&
                Calendar.current.isDate(photo.date, inSameDayAs: today) &&
                photo.challenge?.id == selectedChallenge?.id  // Fixed challenge association
            }
            
            // Replace existing photos for today with the same angle
            for photo in sameDayPhotos {
                if FileManager.default.fileExists(atPath: photo.fileURL.path) {
                    try? FileManager.default.removeItem(at: photo.fileURL)
                }
                modelContext.delete(photo)
            }
            
            // Create new photo with proper challenge association
            let newPhoto = ProgressPhoto(
                challenge: selectedChallenge,  // This ensures proper challenge tagging
                date: Date(),
                angle: angle,
                fileURL: fileURL,
                isBlurred: false
            )
            
            modelContext.insert(newPhoto)
            try modelContext.save()
            Logger.info("Successfully saved photo to model context with challenge: \(selectedChallenge?.name ?? "No Challenge")", category: .photos)
        } catch {
            Logger.error("Error saving photo: \(error.localizedDescription)", category: .photos)
        }
    }
    
    /// Thread-safe async task completion
    @MainActor
    private func checkAndCompletePhotoTasksAsync() async {
        Logger.info("Photo session complete with all angles, marking photo tasks as complete", category: .photos)
        
        do {
            let today = Calendar.current.startOfDay(for: Date())
            let fetchDescriptor = FetchDescriptor<DailyTask>()
            
            let allDailyTasks = try modelContext.fetch(fetchDescriptor)
            let todayPhotoTasks = allDailyTasks.filter { task in
                Calendar.current.isDate(task.date, inSameDayAs: today) &&
                task.task?.type == .photo &&
                !task.isCompleted
            }
            
            for task in todayPhotoTasks {
                Logger.info("Marking photo task as complete: \(task.title)", category: .photos)
                task.complete(notes: "Automatically completed - all progress photos taken in session")
            }
            
            try modelContext.save()
            Logger.info("Successfully marked \(todayPhotoTasks.count) photo tasks as complete", category: .photos)
        } catch {
            Logger.error("Failed to mark photo tasks as complete: \(error.localizedDescription)", category: .photos)
        }
    }
    
    private func savePhoto(image: UIImage, angle: PhotoAngle) {
        // All SwiftData operations must happen on main thread
        DispatchQueue.main.async {
            do {
                // Fix image orientation to maintain original orientation
                let correctedImage = image.fixedOrientation()
                
                // Check if there's an existing photo for this angle today FIRST
                let existingPhoto = self.getExistingPhotoForAngle(angle)
                
                if let existingPhoto = existingPhoto {
                    // UPDATE existing photo
                    Logger.info("Updating existing photo for angle: \(angle.rawValue)", category: .photos)
                    
                    // Delete old photo file
                    if FileManager.default.fileExists(atPath: existingPhoto.fileURL.path) {
                        try? FileManager.default.removeItem(at: existingPhoto.fileURL)
                    }
                    
                    // Save new photo file
                    guard let newPhotoURL = photoService.savePhoto(
                        image: correctedImage,
                        challengeId: selectedChallenge?.id ?? UUID(),
                        angle: angle
                    ) else {
                        print("Failed to save updated photo file")
                        return
                    }
                    
                    // Update existing record
                    existingPhoto.fileURL = newPhotoURL
                    existingPhoto.date = Date()
                    existingPhoto.updatedAt = Date()
                    
                } else {
                    // CREATE new photo
                    Logger.info("Creating new photo for angle: \(angle.rawValue)", category: .photos)
                    
                    // Save photo to file system using the service
                    guard let photoURL = photoService.savePhoto(
                        image: correctedImage,
                        challengeId: selectedChallenge?.id ?? UUID(),
                        angle: angle
                    ) else {
                        print("Failed to save new photo file")
                        return
                    }
                    
                    // Calculate challenge iteration
                    let iteration = 1 // Simplified for now
                    
                    // Create photo record on main thread
                    let progressPhoto = ProgressPhoto(
                        challenge: selectedChallenge,
                        date: Date(),
                        angle: angle,
                        fileURL: photoURL,
                        challengeIteration: iteration
                    )
                    
                    modelContext.insert(progressPhoto)
                }
            
                try modelContext.save()
                savedPhotoAngles.insert(angle)
                
                Logger.info("Successfully saved/updated photo for angle: \(angle.rawValue)", category: .photos)
                
            } catch {
                print("Failed to save/update photo: \(error)")
            }
        }
    }
    
    private func savePhotoSync(angle: PhotoAngle, image: UIImage) {
        // All SwiftData operations must happen on main thread
        DispatchQueue.main.async {
            do {
                // Fix image orientation to maintain original orientation
                let correctedImage = image.fixedOrientation()
                
                // Save photo to file system using the service
                guard let photoURL = photoService.savePhoto(
                    image: correctedImage,
                    challengeId: selectedChallenge?.id ?? UUID(),
                    angle: angle
                ) else {
                    print("Failed to save photo file")
                    return
                }
                
                // Calculate challenge iteration
                let iteration = 1 // Simplified for now
                
                // Create photo record on main thread
                let progressPhoto = ProgressPhoto(
                    challenge: selectedChallenge,
                    date: Date(),
                    angle: angle,
                    fileURL: photoURL,
                    challengeIteration: iteration
                )
                
                modelContext.insert(progressPhoto)
                try modelContext.save()
                
                savedPhotoAngles.insert(angle)
                
            } catch {
                print("Failed to save photo: \(error)")
            }
        }
    }
    
    private func markPhotoTasksComplete() {
        // All SwiftData operations must happen on main thread
        DispatchQueue.main.async {
            do {
                let today = Calendar.current.startOfDay(for: Date())
                let fetchDescriptor = FetchDescriptor<DailyTask>()
                
                let allDailyTasks = try modelContext.fetch(fetchDescriptor)
                let todayPhotoTasks = allDailyTasks.filter { task in
                    Calendar.current.isDate(task.date, inSameDayAs: today) &&
                    task.task?.type == .photo &&
                    !task.isCompleted
                }
                
                for task in todayPhotoTasks {
                    Logger.info("Marking photo task as complete: \(task.title)", category: .photos)
                    task.complete(notes: "Automatically completed - all progress photos taken in session")
                }
                
                try modelContext.save()
                Logger.info("Successfully marked \(todayPhotoTasks.count) photo tasks as complete", category: .photos)
            } catch {
                Logger.error("Failed to mark photo tasks as complete: \(error.localizedDescription)", category: .photos)
            }
        }
    }
    
    private func hasAnyPhotosForToday() -> Bool {
        // Check if there are any photos for today for this challenge
        let todayPhotos = getTodayPhotos()
        return !todayPhotos.isEmpty
    }
    
    private func getTodayPhotos() -> [ProgressPhoto] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get photos from the parent view's @Query or fetch them
        // For now, we'll use a simple approach - this should be passed from parent
        do {
            let descriptor = FetchDescriptor<ProgressPhoto>()
            let allPhotos = try modelContext.fetch(descriptor)
            
            return allPhotos.filter { photo in
                calendar.isDate(photo.date, inSameDayAs: today) &&
                photo.challenge?.id == selectedChallenge?.id
            }
        } catch {
            print("Error fetching today's photos: \(error)")
            return []
        }
    }
    
    private func getExistingPhotoForAngle(_ angle: PhotoAngle) -> ProgressPhoto? {
        let todayPhotos = getTodayPhotos()
        return todayPhotos.first { $0.angle == angle }
    }
}

// MARK: - Supporting Views

/// Compact angle selection button (smaller size)
struct CompactAngleButton: View {
    let angle: PhotoAngle
    let isSelected: Bool
    let isCaptured: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(
                            isCaptured ? DesignSystem.Colors.primaryAction :
                            isSelected ? DesignSystem.Colors.primaryAction.opacity(0.2) :
                            DesignSystem.Colors.cardBackground
                        )
                        .frame(width: 36, height: 36)  // Smaller size
                        .overlay(
                            Circle()
                                .stroke(
                                    isCaptured || isSelected ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.dividers,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                    
                    if isCaptured {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: angle.icon)
                            .font(.system(size: 14))
                            .foregroundColor(
                                isSelected ? DesignSystem.Colors.primaryAction :
                                DesignSystem.Colors.secondaryText
                            )
                    }
                }
                
                Text(angle.shortDescription)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(
                        isCaptured || isSelected ? DesignSystem.Colors.primaryAction :
                        DesignSystem.Colors.secondaryText
                    )
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

// MARK: - Extensions

extension PhotoAngle {
    var shortDescription: String {
        switch self {
        case .front: return "Front"
        case .leftSide: return "Left"
        case .rightSide: return "Right"
        case .back: return "Back"
        }
    }
}

// MARK: - UIImage Extension for Orientation Fix

extension UIImage {
    func fixedOrientation() -> UIImage {
        // If the image orientation is already correct, return as is
        if imageOrientation == .up {
            return self
        }
        
        // Calculate the transform needed to correct the orientation
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Create a new context with the correct dimensions
        guard let cgImage = cgImage else { return self }
        
        let ctx = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: cgImage.colorSpace!,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let correctedCGImage = ctx.makeImage() else { return self }
        return UIImage(cgImage: correctedCGImage)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let photoUpdated = Notification.Name("photoUpdated")
}

#Preview {
    PhotoSessionView(selectedChallenge: nil)
        .modelContainer(for: [User.self, Challenge.self, Task.self, DailyTask.self, ProgressPhoto.self], inMemory: true)
} 



