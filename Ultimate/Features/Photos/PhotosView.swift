import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

/// Main view for the Photos feature
struct PhotosView: View {
    @Environment(\.modelContext) private var modelContext
    // Sort challenges primarily by status, then by start date
    @Query(sort: [SortDescriptor(\Challenge.startDate, order: .reverse)]) var challenges: [Challenge]
    @Query(sort: \ProgressPhoto.date, order: .reverse) var photos: [ProgressPhoto]

    // State for selected challenge instance (using ID for stability)
    @State private var selectedChallengeId: UUID?
    
    // Sheet presentation states
    @State private var showingCameraView = false // Consider if PhotoSessionView replaces this need
    @State private var showingPhotoLibrary = false
    @State private var showingPhotoSessionSheet = false
    @State private var showingComparisonView = false
    @State private var showingPhotoDetail: ProgressPhoto? // Use item presentation for detail
    
    // Temporary state for photo saving context
    @State private var selectedAngle: PhotoAngle = .front 
    
    // Service for managing photos
    private let photoService = ProgressPhotoService()
    
    // Refresh state for forcing UI updates
    @State private var refreshTrigger = UUID()
    
    // Computed property to get the Challenge object from the ID
    private var selectedChallenge: Challenge? {
        challenges.first { $0.id == selectedChallengeId }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        challengeSelectorDropDown
                        
                        // --- Main Content Area ---
                        Group {
                            if let challenge = selectedChallenge {
                                challengeSpecificContent(challenge: challenge)
                            } else {
                                allChallengesOverviewContent
                            }
                        }
                        .animation(.default, value: selectedChallengeId) // Animate content change
                        // --- End Main Content Area ---
                        
                    }
                    .padding(.vertical) // Padding for scroll view content
                }
            }
            .navigationTitle("Progress Photos")
            .navigationBarTitleDisplayMode(.inline)
            // --- Sheets ---
            // Consider replacing separate camera/library sheets with PhotoSessionView
            .sheet(isPresented: $showingCameraView) {
                OptimizedCameraView(
                    selectedChallenge: selectedChallenge,
                    selectedAngle: $selectedAngle,
                    onPhotoTaken: { image in
                        savePhoto(image: image)
                    }
                )
                .interactiveDismissDisabled(true)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                PhotoPicker(
                    selectedChallenge: selectedChallenge,
                    selectedAngle: $selectedAngle,
                    onPhotoSelected: { image in
                        savePhoto(image: image)
                    }
                )
            }
            .sheet(isPresented: $showingPhotoSessionSheet) {
                // Pass the currently selected challenge (or nil) to the session view
                PhotoSessionView(selectedChallenge: selectedChallenge)
            }
            .sheet(isPresented: $showingComparisonView) {
                // Comparison only makes sense within a selected challenge
                if let challenge = selectedChallenge {
                    EnhancedPhotoComparisonView(selectedChallenge: challenge)
                } else {
                    // Optional: Show an alert or message if compare is tapped in "All Challenges"
                    Text("Select a specific challenge to compare photos.")
                        .padding()
                }
            }
            .sheet(item: $showingPhotoDetail) { photo in // Use .sheet(item:...) for detail view
                PhotoDetailView(photo: photo, photoService: photoService)
            }
            // --- End Sheets ---
            .onAppear {
                Logger.info("PhotosView appeared. Selected challenge ID: \(selectedChallengeId?.uuidString ?? "None")", category: .photos)
                
                // Set default selection to current in-progress challenge if none selected
                if selectedChallengeId == nil {
                    let inProgressChallenges = challenges.filter { $0.status == .inProgress }
                    if let currentChallenge = inProgressChallenges.first {
                        selectedChallengeId = currentChallenge.id
                        Logger.info("Auto-selected current in-progress challenge: \(currentChallenge.name)", category: .photos)
                    } else {
                        // If no in-progress challenges, don't auto-select anything to prevent crashes
                        Logger.info("No in-progress challenges found, keeping selection as 'All Challenges'", category: .photos)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .photoUpdated)) { _ in
                // Force a refresh of the view when photos are updated
                Logger.info("Photo update notification received, refreshing PhotosView", category: .photos)
                refreshTrigger = UUID()
            }
        }
    }
    
    // MARK: - View Components

    /// Dropdown-style challenge selector
    private var challengeSelectorDropDown: some View {
        Menu {
            Button(action: { selectedChallengeId = nil }) {
                Label("All Challenges", systemImage: "list.bullet")
            }
            
            let active = challenges.filter { $0.status == .inProgress }
            let completed = challenges.filter { $0.status == .completed }
            let failed = challenges.filter { $0.status == .failed }

            if !active.isEmpty {
                Divider()
                Section("Active") {
                    ForEach(active) { challenge in
                        Button(action: { selectedChallengeId = challenge.id }) {
                            Label(challenge.name, systemImage: "figure.run")
                        }
                    }
                }
            }
            
            if !completed.isEmpty {
                 Divider()
                 Section("Completed") {
                    ForEach(completed) { challenge in
                        Button(action: { selectedChallengeId = challenge.id }) {
                            Label(challenge.name, systemImage: "checkmark.seal")
                        }
                    }
                }
            }
            
            if !failed.isEmpty {
                 Divider()
                 Section("Failed") {
                    ForEach(failed) { challenge in
                        Button(action: { selectedChallengeId = challenge.id }) {
                            Label(challenge.name, systemImage: "xmark.octagon")
                        }
                    }
                }
            }
            
        } label: {
            HStack {
                Text(selectedChallenge?.name ?? "All Challenges")
                    .font(DesignSystem.Typography.headline)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down.circle")
                    .imageScale(.large)
            }
            .padding(.vertical, DesignSystem.Spacing.s)
            .padding(.horizontal, DesignSystem.Spacing.m)
            .background(DesignSystem.Colors.cardBackground.opacity(0.8))
            .cornerRadius(DesignSystem.BorderRadius.medium)
            .foregroundColor(DesignSystem.Colors.primaryText)
        }
        .padding(.horizontal)
    }
    
    /// Content shown when "All Challenges" is selected
    private var allChallengesOverviewContent: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            // Button to start a session without pre-selecting a challenge
            photoSessionButton(title: "Start New Photo Session")
            
            let active = challenges.filter { $0.status == .inProgress }
            let completed = challenges.filter { $0.status == .completed }
            let failed = challenges.filter { $0.status == .failed } // Include failed to show their photos too
            let orphanedPhotos = photos.filter { $0.challenge == nil }

            if active.isEmpty && completed.isEmpty && failed.isEmpty && orphanedPhotos.isEmpty {
                emptyStateView(message: "No photos found. Start a challenge and take some progress pics!")
            } else {
                // Active Challenges Section
                if !active.isEmpty {
                    SectionBox(title: "Active Challenges") {
                        ForEach(active) { challenge in
                            challengeOverviewCard(challenge: challenge)
                        }
                    }
                }
                
                // Completed Challenges Section
                if !completed.isEmpty {
                    SectionBox(title: "Completed Challenges") {
                        ForEach(completed) { challenge in
                            challengeOverviewCard(challenge: challenge)
                        }
                    }
                }
                
                // Failed Challenges Section (Optional but good for history)
                if !failed.isEmpty {
                    SectionBox(title: "Failed Challenges") {
                        ForEach(failed) { challenge in
                            challengeOverviewCard(challenge: challenge)
                        }
                    }
                }
                
                // Orphaned Photos Section
                if !orphanedPhotos.isEmpty {
                    SectionBox(title: "Other Photos") {
                        photoGrid(photos: orphanedPhotos)
                    }
                }
            }
        }
    }
    
    /// Content shown when a specific challenge is selected
    private func challengeSpecificContent(challenge: Challenge) -> some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            photoCaptureSection(challenge: challenge)
            photoComparisonButton(challenge: challenge)
            challengePhotoGallery(challenge: challenge)
        }
    }
    
    /// Reusable button to start a photo session
    private func photoSessionButton(title: String = "Start Photo Session") -> some View {
        CTButton(
            title: title,
            icon: "camera.fill",
            style: .neon,
            size: .large,
            customNeonColor: Color.cyan.opacity(0.8)
        ) {
            Logger.info("Start photo session button tapped. Selected challenge ID: \(selectedChallengeId?.uuidString ?? "None")", category: .photos)
            // PhotoSessionView will use selectedChallenge if available
            showingPhotoSessionSheet = true
        }
        .padding(.horizontal)
    }
    
    /// Photo capture card tailored for a specific challenge
    private func photoCaptureSection(challenge: Challenge) -> some View {
        let hasPhotosForToday = hasAnyPhotosForTodayInChallenge(challenge)
        let buttonTitle = hasPhotosForToday ? "Update Photos" : "Take Photos"
        
        return CTCard(style: .glass) {
            VStack(spacing: 16) {
                Text("Capture Today's Progress for \"\(challenge.name)\"")
                    .font(DesignSystem.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Angle progress tracker for today and this specific challenge
                HStack(spacing: 12) {
                    ForEach(PhotoAngle.allCases, id: \.self) { angle in
                        AngleIndicator(angle: angle, isCompleted: hasPhotoForToday(angle: angle, challenge: challenge))
                    }
                }
                .padding(.vertical, 8)
                
                // Button specific to the selected challenge context with dynamic text
                CTButton(
                    title: buttonTitle,
                    icon: "camera.fill",
                    style: .neon,
                    size: .large,
                    customNeonColor: Color.cyan.opacity(0.8)
                ) {
                    Logger.info("Start photo session button tapped. Selected challenge ID: \(selectedChallengeId?.uuidString ?? "None")", category: .photos)
                    // PhotoSessionView will use selectedChallenge if available
                    showingPhotoSessionSheet = true
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    /// Comparison button enabled only if enough photos exist for the challenge
    private func photoComparisonButton(challenge: Challenge) -> some View {
        let challengePhotos = photos.filter { $0.challenge?.id == challenge.id }
        let canCompare = challengePhotos.count >= 2
        
        return Button {
            Logger.info("Compare photos button tapped for challenge \(challenge.name)", category: .photos)
            showingComparisonView = true
        } label: {
            Label("Compare Photos", systemImage: "arrow.left.arrow.right.circle")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .cornerRadius(8)
        }
        .disabled(!canCompare)
        .opacity(canCompare ? 1.0 : 0.5)
        .padding(.horizontal)
    }
    
    /// Gallery view for a specific challenge, grouped by date
    private func challengePhotoGallery(challenge: Challenge) -> some View {
        let challengePhotos = photos.filter { $0.challenge?.id == challenge.id }
        // Group photos by date (start of day) for sectioning
        let photosGroupedByDate = Dictionary(grouping: challengePhotos) { photo in
            Calendar.current.startOfDay(for: photo.date)
        }
        // Sort dates descending to show most recent first
        let sortedDates = photosGroupedByDate.keys.sorted(by: >)
        
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
            Text("Photo History")
                 .font(DesignSystem.Typography.headline)
                 .padding(.horizontal)
                 
            if challengePhotos.isEmpty {
                emptyStateView(message: "No photos yet for \(challenge.name). Start your photo session!")
            } else {
                ForEach(sortedDates, id: \.self) { date in
                    DateSection(date: date, photos: photosGroupedByDate[date] ?? [])
                }
            }
        }
    }
    
    /// Overview card for a challenge in the "All Challenges" list
    private func challengeOverviewCard(challenge: Challenge) -> some View {
        // Get the 4 most recent photos for this specific challenge instance
        let recentPhotos = photos
            .filter { $0.challenge?.id == challenge.id }
            .prefix(4)
        
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            HStack {
                Text(challenge.name)
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
                Text(challenge.status.displayString) // Use extension method
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(challenge.status.color.opacity(0.2))
                    .foregroundColor(challenge.status.color)
                    .cornerRadius(6)
            }
            
            // Display date range
            Text(challengeDateRangeString(challenge))
                .font(.caption)
                .foregroundColor(.secondary)
            
            if recentPhotos.isEmpty {
                 Text("No photos captured for this challenge yet.")
                     .font(.caption)
                     .foregroundColor(.secondary)
                     .padding(.vertical)
            } else {
                // Horizontal scroll for recent photo thumbnails
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.s) {
                        ForEach(Array(recentPhotos)) { photo in
                            PhotoThumbnail(photo: photo, photoService: photoService)
                                .frame(width: 100, height: 133) // Fixed aspect ratio 3:4
                                .onTapGesture {
                                    Logger.info("Tapped photo \(photo.id) from overview for challenge \(challenge.name)", category: .photos)
                                    showingPhotoDetail = photo // Use item presentation
                                }
                        }
                    }
                    .padding(.vertical, 4) // Add padding around scroll view
                }
            }
            
            // Button to navigate to the specific challenge's photos
            Button("View All Photos") {
                 Logger.info("Tapped 'View All Photos' for challenge \(challenge.name)", category: .photos)
                selectedChallengeId = challenge.id
            }
            .font(.caption)
            .padding(.top, 4)
            
        }
        .padding()
        .background(Material.regular) // Use material background
        .cornerRadius(DesignSystem.BorderRadius.medium)
        .padding(.horizontal)
    }
    
    /// A section container with a title
    private func SectionBox<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text(title)
                .font(DesignSystem.Typography.headline)
                .padding(.horizontal)
            content()
        }
    }
    
    /// Displays photos for a specific date
    private func DateSection(date: Date, photos: [ProgressPhoto]) -> some View {
        // Sort photos by the correct angle order: Front, Left, Right, Back
        let sortedPhotos = photos.sorted { photo1, photo2 in
            let angleOrder: [PhotoAngle] = [.front, .leftSide, .rightSide, .back]
            let index1 = angleOrder.firstIndex(of: photo1.angle) ?? angleOrder.count
            let index2 = angleOrder.firstIndex(of: photo2.angle) ?? angleOrder.count
            return index1 < index2
        }
        
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text(date, style: .date)
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .padding(.horizontal)
            
            photoGrid(photos: sortedPhotos)
        }
    }
    
    /// Reusable grid for displaying photo thumbnails
    private func photoGrid(photos: [ProgressPhoto]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 180))], spacing: DesignSystem.Spacing.s) { // Adjusted min/max
            ForEach(photos) { photo in
                PhotoThumbnail(photo: photo, photoService: photoService)
                    .aspectRatio(3/4, contentMode: .fill)
                    .onTapGesture {
                        Logger.info("Photo thumbnail tapped: \(photo.id)", category: .photos)
                        showingPhotoDetail = photo // Use item presentation
                    }
            }
        }
        .padding(.horizontal)
    }
    
    /// Empty state view
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.primaryAction.opacity(0.5))
            
            Text("No Photos Here")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    
    /// Formats the date range string for a challenge
    private func challengeDateRangeString(_ challenge: Challenge) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        
        let start = challenge.startDate != nil ? formatter.string(from: challenge.startDate!) : "N/A"
        let end: String
        if challenge.status == .inProgress {
            end = "Present"
        } else {
            end = challenge.endDate != nil ? formatter.string(from: challenge.endDate!) : "N/A"
        }
        return "\(start) - \(end)"
    }

    /// Saves a photo, associating it with the correct challenge and iteration
    private func savePhoto(image: UIImage) {
        // Use the explicitly selected challenge if available, otherwise infer from context (e.g., active challenge)
        let challengeContext = selectedChallenge ?? challenges.first { $0.status == .inProgress }
        let optionalChallengeId = challengeContext?.id
        
        Logger.info("Saving photo for angle \(selectedAngle). Context Challenge ID: \(optionalChallengeId?.uuidString ?? "None")", category: .photos)
        
        // All operations must be on main thread
        DispatchQueue.main.async {
            do {
                // Fix image orientation first
                let correctedImage = image.fixedOrientation()
                
                // Get today's date for comparison
                let todayStart = Calendar.current.startOfDay(for: Date())
                
                // Check for existing photo to update FIRST
                let allPhotos = try self.modelContext.fetch(FetchDescriptor<ProgressPhoto>())
                let existingPhoto = allPhotos.first { photo in
                    photo.angle == self.selectedAngle &&
                    photo.challenge?.id == optionalChallengeId &&
                    Calendar.current.isDate(photo.date, inSameDayAs: todayStart)
                }
                
                if let existing = existingPhoto {
                    // UPDATE EXISTING PHOTO - Don't create new one
                    Logger.info("Updating existing photo record for today/angle/challenge: \(existing.id)", category: .photos)
                    
                    // Delete old file first (if it exists)
                    if FileManager.default.fileExists(atPath: existing.fileURL.path) {
                        try? FileManager.default.removeItem(at: existing.fileURL)
                    }
                    
                    // Save new photo file
                    guard let newFileURL = self.photoService.savePhoto(
                        image: correctedImage,
                        challengeId: optionalChallengeId ?? UUID(),
                        angle: self.selectedAngle
                    ) else {
                        Logger.error("Error saving updated photo file.", category: .photos)
                        return
                    }
                    
                    // Update existing record's properties  
                    existing.fileURL = newFileURL
                    existing.date = Date()
                    existing.updatedAt = Date()
                    
                    // Save the updated record
                    try self.modelContext.save()
                    Logger.info("Successfully updated existing photo.", category: .photos)
                    
                    // Post notification to refresh UI
                    NotificationCenter.default.post(name: .photoUpdated, object: nil)
                    
                } else {
                    // CREATE NEW PHOTO - No existing photo found
                    Logger.info("Creating new ProgressPhoto record.", category: .photos)
                    
                    // Save photo file
                    guard let fileURL = self.photoService.savePhoto(
                        image: correctedImage,
                        challengeId: optionalChallengeId ?? UUID(),
                        angle: self.selectedAngle
                    ) else {
                        Logger.error("Error saving new photo file.", category: .photos)
                        return
                    }
                    
                    // Determine challenge iteration
                    var iteration = 1
                    if let currentChallenge = challengeContext, let currentStartDate = currentChallenge.startDate {
                        let previousInstancesCount = self.challenges.filter {
                            $0.type == currentChallenge.type &&
                            $0.id != currentChallenge.id &&
                            $0.startDate != nil &&
                            $0.startDate! < currentStartDate
                        }.count
                        iteration = previousInstancesCount + 1
                    }

                    // Create new photo record
                    let newPhoto = ProgressPhoto(
                        challenge: challengeContext,
                        date: Date(),
                        angle: self.selectedAngle,
                        fileURL: fileURL,
                        challengeIteration: iteration
                    )
                    
                    self.modelContext.insert(newPhoto)
                    try self.modelContext.save()
                    Logger.info("Successfully created new photo.", category: .photos)
                    
                    // Post notification to refresh UI
                    NotificationCenter.default.post(name: .photoUpdated, object: nil)
                }
                
                // Check task completion after successful save
                if let challenge = challengeContext {
                    self.checkAndCompletePhotoTasks(for: challenge)
                }
                
            } catch {
                Logger.error("Failed to save/update photo: \(error.localizedDescription)", category: .photos)
            }
        }
    }
    
    /// Checks if all photos for today are taken *for a specific challenge* and marks tasks as complete
    private func checkAndCompletePhotoTasks(for challenge: Challenge) {
        Logger.info("Checking photo task completion for challenge: \(challenge.name)", category: .photos)
        
        var hasAllAnglesToday = true
        for angle in PhotoAngle.allCases {
            if !hasPhotoForToday(angle: angle, challenge: challenge) {
                hasAllAnglesToday = false
                break
            }
        }
        
        if hasAllAnglesToday {
            Logger.info("All photo angles captured for today for \(challenge.name). Attempting to mark tasks.", category: .photos)
            
            // Use Swift concurrency to perform async operations
            DispatchQueue.global().async {
                self.markTodayPhotoTasksComplete(for: challenge.id)
            }
        } else {
             Logger.info("Not all photo angles captured today for \(challenge.name). Tasks not marked.", category: .photos)
        }
    }
    
    /// Marks today's photo tasks for a specific challenge as complete (async helper)
    private func markTodayPhotoTasksComplete(for challengeId: UUID) {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
        
        // Create a simplified fetch to avoid predicate errors
        let dailyTasks = try? modelContext.fetch(FetchDescriptor<DailyTask>())
        guard let dailyTasks = dailyTasks else {
            Logger.error("Failed to fetch daily tasks", category: .photos)
            return
        }
        
        // Filter manually instead of using complex predicates
        let tasksToComplete = dailyTasks.filter { task in
            let matchesChallenge = task.challenge?.id == challengeId
            let isPhotoTask = task.task?.type == .photo
            let isForToday = task.date >= todayStart && task.date < todayEnd
            let isNotCompleted = task.status != .completed
            
            return matchesChallenge && isPhotoTask && isForToday && isNotCompleted
        }
        
        if tasksToComplete.isEmpty {
            Logger.info("No pending photo tasks found for today for challenge \(challengeId.uuidString)", category: .photos)
            return
        }
        
        DispatchQueue.main.async {
            var completedCount = 0
            for task in tasksToComplete {
                task.complete(notes: "Automatically completed - all progress photos taken")
                completedCount += 1
            }
            
            do {
                try self.modelContext.save()
                Logger.info("Successfully marked \(completedCount) photo tasks as complete for challenge \(challengeId.uuidString)", category: .photos)
            } catch {
                Logger.error("Failed to save after marking photo tasks complete: \(error.localizedDescription)", category: .photos)
            }
        }
    }
    
    /// Checks if there's a photo for today for the given angle *and specific challenge*
    private func hasPhotoForToday(angle: PhotoAngle, challenge: Challenge) -> Bool {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        
        // Use the main photos query (@Query), filtering specifically
        return photos.contains { photo in
            photo.challenge?.id == challenge.id &&
            calendar.isDate(photo.date, inSameDayAs: todayStart) &&
            photo.angle == angle
        }
    }
    
    /// Checks if there are any photos for today in a specific challenge
    private func hasAnyPhotosForTodayInChallenge(_ challenge: Challenge) -> Bool {
        let todayStart = Calendar.current.startOfDay(for: Date())
        
        // Use the main photos query (@Query), filtering specifically
        return photos.contains { photo in
            photo.challenge?.id == challenge.id &&
            Calendar.current.isDate(photo.date, inSameDayAs: todayStart)
        }
    }
}

// MARK: - Supporting Views

/// Indicator for a single photo angle completion
struct AngleIndicator: View {
    let angle: PhotoAngle
    let isCompleted: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isCompleted ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.cardBackground.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(isCompleted ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.dividers.opacity(0.7), lineWidth: 1)
                    )
                
                Image(systemName: angle.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isCompleted ? .white : DesignSystem.Colors.secondaryText)
            }
            
            Text(angle.description)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(isCompleted ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Thumbnail view for a photo
struct PhotoThumbnail: View {
    let photo: ProgressPhoto 
    let photoService: ProgressPhotoService
    
    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = true
    @State private var loadError: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle() // Background placeholder
                .fill(Material.thin)
                .aspectRatio(3/4, contentMode: .fill)
                .cornerRadius(DesignSystem.BorderRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                        .stroke(DesignSystem.Colors.dividers.opacity(0.3), lineWidth: 1)
                )

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(DesignSystem.BorderRadius.small)
                    .clipped()
            } else if loadError {
                // Error state
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("Error")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Loading Indicator
            if isLoading {
                 ProgressView()
                     .tint(DesignSystem.Colors.secondaryText)
                     .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Angle indicator badge (show in all non-loading states)
            if !isLoading {
                Text(photo.angle.rawValue.prefix(1))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(DesignSystem.Colors.primaryAction.opacity(0.9))
                    .clipShape(Circle())
                    .padding(4)
            }
        }
        .aspectRatio(3/4, contentMode: .fill) 
        .cornerRadius(DesignSystem.BorderRadius.small)
        .clipped()
        .onAppear {
            loadImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .photoUpdated)) { _ in
            // Reload image when photo updates are received
            loadImage()
        }
    }
    
    private func loadImage() {
        isLoading = true
        loadError = false
        
        Logger.debug("Starting to load image for photo thumbnail: \(photo.id)", category: .photos)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = photoService.loadPhoto(from: photo.fileURL)
            
            // Update state on the main thread
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let loadedImage = loadedImage {
                    withAnimation(.easeIn(duration: 0.2)) {
                        self.image = photo.isBlurred ? photoService.blurPhoto(image: loadedImage) : loadedImage
                    }
                    Logger.debug("Image loaded successfully for photo: \(photo.id)", category: .photos)
                } else {
                    self.loadError = true
                    Logger.error("Failed to load image for photo: \(photo.id)", category: .photos)
                }
            }
        }
    }
}

// MARK: - Extensions for Model data

extension ChallengeStatus {
    var displayString: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "Active"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .inProgress: return .green
        case .completed: return .blue
        case .failed: return .red
        }
    }
}

// Preview section intentionally removed to avoid initialization issues.
// This will need to be fixed in a future update. 