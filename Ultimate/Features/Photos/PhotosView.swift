import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

/// Main view for the Photos feature
struct PhotosView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var challenges: [Challenge]
    @Query private var photos: [ProgressPhoto]
    
    @State private var selectedChallenge: Challenge?
    @State private var showingCameraView = false
    @State private var showingPhotoLibrary = false
    @State private var selectedAngle: PhotoAngle = .front
    @State private var selectedPhoto: ProgressPhoto?
    @State private var showingComparisonView = false
    @State private var showingPhotoDetail = false
    @State private var showingPhotoSessionSheet = false
    
    // Service for managing photos
    private let photoService = ProgressPhotoService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium animated background
                PremiumBackground()
                
            ScrollView {
                VStack(spacing: 24) {
                    // Challenge selector
                    challengeSelector
                    
                    // Photo capture section
                    photoCaptureSection
                    
                    // Comparison button
                    Button {
                            Logger.info("Compare photos button tapped", category: .photos)
                        showingComparisonView = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 18))
                            Text("Compare Photos")
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                            .background(Color.clear)
                            .foregroundColor(Color.purple.opacity(0.8))
                        .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.purple.opacity(0.8), lineWidth: 1.5)
                                    .shadow(color: Color.purple.opacity(0.8), radius: 4, x: 0, y: 0)
                                    .shadow(color: Color.purple.opacity(0.6), radius: 8, x: 0, y: 0)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Photo gallery
                    photoGallerySection
                    }
                }
            }
            .navigationTitle("Progress Photos")
            .sheet(isPresented: $showingCameraView) {
                CameraView(
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
            .sheet(isPresented: $showingComparisonView) {
                PhotoComparisonView(selectedChallenge: selectedChallenge)
            }
            .sheet(item: $selectedPhoto) { photo in
                PhotoDetailView(photo: photo, photoService: photoService)
            }
            .sheet(isPresented: $showingPhotoSessionSheet) {
                PhotoSessionView(selectedChallenge: selectedChallenge)
            }
            .onAppear {
                Logger.info("PhotosView appeared", category: .photos)
                
                // Set an active challenge as default if none is selected
                if selectedChallenge == nil {
                    let activeChallenge = challenges.filter { $0.status == .inProgress }
                    if let firstActiveChallenge = activeChallenge.first {
                        Logger.info("Setting default active challenge: \(firstActiveChallenge.name)", category: .photos)
                        selectedChallenge = firstActiveChallenge
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Photos filtered by the selected challenge
    private var filteredPhotos: [ProgressPhoto] {
        guard let selectedChallenge = selectedChallenge else {
            return photos.sorted { $0.date > $1.date }
        }
        
        return photos
            .filter { $0.challenge?.id == selectedChallenge.id }
            .sorted { $0.date > $1.date }
    }
    
    /// Photos grouped by date
    private var groupedPhotos: [Date: [ProgressPhoto]] {
        Dictionary(grouping: filteredPhotos) { photo in
            Calendar.current.startOfDay(for: photo.date)
        }
    }
    
    /// Photos grouped by challenge iteration
    private var groupedByIteration: [Int: [ProgressPhoto]] {
        Dictionary(grouping: filteredPhotos) { photo in
            photo.challengeIteration
        }
    }
    
    /// Get the date range for a specific iteration
    private func dateRangeForIteration(_ iteration: Int) -> String {
        let iterationPhotos = groupedByIteration[iteration] ?? []
        guard !iterationPhotos.isEmpty else { return "Unknown date range" }
        
        let dates = iterationPhotos.map { $0.date }
        if let minDate = dates.min(), let maxDate = dates.max() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            
            return "\(dateFormatter.string(from: minDate)) - \(dateFormatter.string(from: maxDate))"
        }
        
        return "Unknown date range"
    }
    
    // MARK: - View Components
    
    /// Challenge selector view
    private var challengeSelector: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.s) {
                    // Active challenges first
                    let activeChallenge = challenges.filter { $0.status == .inProgress }
                    let completedChallenges = challenges.filter { $0.status == .completed }
                    
                    // All photos option
                    Button(action: {
                        Logger.info("All photos option selected", category: .photos)
                        selectedChallenge = nil
                    }) {
                        Text("All Photos")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, DesignSystem.Spacing.m)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(selectedChallenge == nil ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.cardBackground)
                            .foregroundColor(selectedChallenge == nil ? .white : DesignSystem.Colors.primaryText)
                            .cornerRadius(DesignSystem.BorderRadius.pill)
                    }
                    
                    // Active challenges
                    ForEach(activeChallenge) { challenge in
                        Button(action: {
                            Logger.info("Challenge selected: \(challenge.name)", category: .photos)
                            selectedChallenge = challenge
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                
                                Text(challenge.name)
                                    .font(DesignSystem.Typography.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.m)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(selectedChallenge?.id == challenge.id ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.cardBackground)
                            .foregroundColor(selectedChallenge?.id == challenge.id ? .white : DesignSystem.Colors.primaryText)
                            .cornerRadius(DesignSystem.BorderRadius.pill)
                        }
                    }
                    
                    // Completed challenges
                    ForEach(completedChallenges) { challenge in
                        Button(action: {
                            Logger.info("Completed challenge selected: \(challenge.name)", category: .photos)
                            selectedChallenge = challenge
                        }) {
                            Text(challenge.name)
                                .font(DesignSystem.Typography.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, DesignSystem.Spacing.m)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(selectedChallenge?.id == challenge.id ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.cardBackground)
                                .foregroundColor(selectedChallenge?.id == challenge.id ? .white : DesignSystem.Colors.primaryText)
                                .cornerRadius(DesignSystem.BorderRadius.pill)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, DesignSystem.Spacing.s)
            }
            
            Divider()
        }
        .background(DesignSystem.Colors.cardBackground)
    }
    
    /// Photo capture section
    private var photoCaptureSection: some View {
        CTCard(style: .glass) {
            VStack(spacing: 16) {
                Text("Capture Your Progress")
                    .font(DesignSystem.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Take photos from all 4 angles to track your progress effectively.")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Angle progress tracker
                HStack(spacing: 12) {
                    ForEach(PhotoAngle.allCases, id: \.self) { angle in
                        let hasPhoto = hasPhotoForToday(angle: angle)
                        
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(hasPhoto ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.cardBackground)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(hasPhoto ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.dividers, lineWidth: 1)
                                    )
                                
                                Image(systemName: angle.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(hasPhoto ? .white : DesignSystem.Colors.secondaryText)
                            }
                            
                            Text(angle.description)
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(hasPhoto ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.secondaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
                
                // Start session button
                CTButton(
                    title: "Start Photo Session",
                    icon: "camera.fill",
                    style: .neon,
                    size: .large,
                    customNeonColor: Color.cyan.opacity(0.8)
                ) {
                    Logger.info("Start photo session button tapped", category: .photos)
                    showingPhotoSessionSheet = true
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    /// Photo gallery section
    private var photoGallerySection: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            if selectedChallenge == nil {
                // All photos view with completed challenges list
                allPhotosView
            } else {
                // Challenge-specific photos
                challengePhotosView
            }
        }
    }
    
    // Challenge-specific photos view
    private var challengePhotosView: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            Text("\(selectedChallenge?.name ?? "") Photos")
                .font(DesignSystem.Typography.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            if filteredPhotos.isEmpty {
                emptyStateView
            } else {
                // Check if we have multiple iterations
                let iterations = groupedByIteration.keys.sorted(by: >)
                
                if iterations.count > 1 {
                    // Photos grouped by iteration
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.l) {
                            ForEach(iterations, id: \.self) { iteration in
                                VStack(spacing: DesignSystem.Spacing.s) {
                                    HStack {
                                        Text("Iteration \(iteration)")
                                            .font(DesignSystem.Typography.title3)
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                        
                                        Spacer()
                                        
                                        Text(dateRangeForIteration(iteration))
                                            .font(DesignSystem.Typography.caption1)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                    .padding(.horizontal)
                                    
                                    // Group photos by date within each iteration
                                    let iterationPhotos = groupedByIteration[iteration] ?? []
                                    let groupedByDate = Dictionary(grouping: iterationPhotos) { photo in
                                        Calendar.current.startOfDay(for: photo.date)
                                    }
                                    
                                    ForEach(groupedByDate.keys.sorted(by: >), id: \.self) { date in
                                        VStack(spacing: DesignSystem.Spacing.s) {
                                            Text(date, style: .date)
                                                .font(DesignSystem.Typography.subheadline)
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.horizontal)
                                            
                                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 180))], spacing: DesignSystem.Spacing.s) {
                                                ForEach(groupedByDate[date] ?? [], id: \.id) { photo in
                                                    PhotoThumbnail(photo: photo, photoService: photoService)
                                                        .aspectRatio(3/4, contentMode: .fill)
                                                        .onTapGesture {
                                                            Logger.info("Photo thumbnail tapped: \(photo.id)", category: .photos)
                                                            selectedPhoto = photo
                                                            showingPhotoDetail = true
                                                        }
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                    
                                    Divider()
                                        .padding(.vertical, DesignSystem.Spacing.s)
                                }
                            }
                        }
                        .padding(.bottom, 16)
                    }
                } else {
                    // Standard view - photos grouped by date
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.m) {
                ForEach(groupedPhotos.keys.sorted(by: >), id: \.self) { date in
                    VStack(spacing: DesignSystem.Spacing.s) {
                        Text(date, style: .date)
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 180))], spacing: DesignSystem.Spacing.s) {
                            ForEach(groupedPhotos[date] ?? [], id: \.id) { photo in
                                PhotoThumbnail(photo: photo, photoService: photoService)
                                                .aspectRatio(3/4, contentMode: .fill)
                                    .onTapGesture {
                                                    Logger.info("Photo thumbnail tapped: \(photo.id)", category: .photos)
                                        selectedPhoto = photo
                                        showingPhotoDetail = true
                                    }
                            }
                        }
                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
        }
    }
    
    // All photos view with completed challenges list
    private var allPhotosView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Text("All Photos")
                .font(DesignSystem.Typography.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            if photos.isEmpty {
                emptyStateView
            } else {
                // Group photos by challenge
                let challengeGroups = Dictionary(grouping: photos) { photo in
                    photo.challenge?.id
                }
                
                // Active challenges first
                let activeChallenge = challenges.filter { $0.status == .inProgress }
                let completedChallenges = challenges.filter { $0.status == .completed }
                
                // Photos from active challenges
                ForEach(activeChallenge) { challenge in
                    if let challengePhotos = challengeGroups[challenge.id]?.sorted(by: { $0.date > $1.date }), !challengePhotos.isEmpty {
                        challengePhotoSection(challenge: challenge, photos: challengePhotos)
                    }
                }
                
                // Photos from completed challenges
                ForEach(completedChallenges) { challenge in
                    if let challengePhotos = challengeGroups[challenge.id]?.sorted(by: { $0.date > $1.date }), !challengePhotos.isEmpty {
                        challengePhotoSection(challenge: challenge, photos: challengePhotos)
                    }
                }
                
                // Photos with no challenge
                if let noChallenge = challengeGroups[nil]?.sorted(by: { $0.date > $1.date }), !noChallenge.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.s) {
                        Text("Other Photos")
                            .font(DesignSystem.Typography.title3)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.s) {
                            ForEach(noChallenge) { photo in
                                PhotoThumbnail(photo: photo, photoService: photoService)
                                    .onTapGesture {
                                        Logger.info("Photo thumbnail tapped (no challenge): \(photo.id)", category: .photos)
                                        selectedPhoto = photo
                                        showingPhotoDetail = true
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    // Helper function to create a challenge photo section
    private func challengePhotoSection(challenge: Challenge, photos: [ProgressPhoto]) -> some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            HStack {
                Text(challenge.name)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                if challenge.status == .inProgress {
                    Text("Active")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(8)
                } else if challenge.status == .completed {
                    Text("Completed")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    Logger.info("View all photos button tapped for challenge: \(challenge.name)", category: .photos)
                    selectedChallenge = challenge
                }) {
                    Text("View All")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                }
            }
            .padding(.horizontal)
            
            // Show the most recent 4 photos
            let recentPhotos = Array(photos.prefix(4))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.s) {
                ForEach(recentPhotos) { photo in
                    PhotoThumbnail(photo: photo, photoService: photoService)
                        .onTapGesture {
                            Logger.info("Photo thumbnail tapped for challenge \(challenge.name): \(photo.id)", category: .photos)
                            selectedPhoto = photo
                            showingPhotoDetail = true
                        }
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical, DesignSystem.Spacing.s)
        }
    }
    
    /// Empty state view
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Image(systemName: "photo.fill")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.primaryAction.opacity(0.7))
            
            Text("No Photos Yet")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("Start capturing your progress to see your transformation journey.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Saves a photo to the database
    private func savePhoto(image: UIImage) {
        Logger.info("Saving photo", category: .photos)
        
        guard let fileURL = photoService.savePhoto(
            image: image,
            challengeId: selectedChallenge?.id ?? UUID(),
            angle: selectedAngle
        ) else {
            Logger.error("Error saving photo - fileURL is nil", category: .photos)
            return
        }
        
        // Check if a photo with this angle and date already exists to prevent duplicates
        let today = Calendar.current.startOfDay(for: Date())
        let existingPhotos = photos.filter { photo in
            photo.angle == selectedAngle && 
            Calendar.current.isDate(photo.date, inSameDayAs: today) &&
            photo.challenge?.id == selectedChallenge?.id
        }
        
        if !existingPhotos.isEmpty {
            Logger.warning("Duplicate photo detected for today with same angle, updating instead of creating new", category: .photos)
            
            // Update the existing photo instead of creating a new one
            if let existingPhoto = existingPhotos.first {
                // Delete the old file to avoid orphaned files
                if FileManager.default.fileExists(atPath: existingPhoto.fileURL.path) {
                    try? FileManager.default.removeItem(at: existingPhoto.fileURL)
                }
                
                existingPhoto.fileURL = fileURL
                existingPhoto.date = Date()
                
                do {
                    try modelContext.save()
                    Logger.info("Updated existing photo", category: .photos)
                    
                    // Check if all photos are taken and mark tasks as complete
                    checkAndCompletePhotoTasks()
                } catch {
                    Logger.error("Failed to update existing photo: \(error.localizedDescription)", category: .photos)
                }
            }
            return
        }
        
        // Also check by filename to prevent duplicates from PhotoSessionView
        let allPhotos = photos.filter { photo in
            photo.fileURL.lastPathComponent == fileURL.lastPathComponent
        }
        
        if !allPhotos.isEmpty {
            Logger.warning("Duplicate photo detected by filename, not creating new", category: .photos)
            return
        }
        
        // Determine the challenge iteration
        var challengeIteration = 1
        if let selectedChallenge = selectedChallenge {
            // Find the highest iteration number for this challenge
            let challengePhotos = photos.filter { $0.challenge?.id == selectedChallenge.id }
            if !challengePhotos.isEmpty {
                // Check if this is a repeated challenge
                let previousEndDate = selectedChallenge.startDate?.addingTimeInterval(Double(selectedChallenge.durationInDays) * 24 * 60 * 60)
                let isRepeatedChallenge = previousEndDate != nil && previousEndDate! < Date()
                
                if isRepeatedChallenge {
                    // Find the highest iteration number
                    challengeIteration = challengePhotos.map { $0.challengeIteration }.max() ?? 0
                    challengeIteration += 1
                    Logger.info("This appears to be a repeated challenge. Using iteration: \(challengeIteration)", category: .photos)
                }
            }
        }
        
        Logger.debug("Creating new ProgressPhoto object with iteration: \(challengeIteration)", category: .photos)
        let newPhoto = ProgressPhoto(
            challenge: selectedChallenge,
            date: Date(),
            angle: selectedAngle,
            fileURL: fileURL,
            challengeIteration: challengeIteration
        )
        
        modelContext.insert(newPhoto)
        
        do {
            try modelContext.save()
            Logger.info("Photo saved successfully", category: .photos)
            
            // Check if all photos are taken and mark tasks as complete
            checkAndCompletePhotoTasks()
        } catch {
            Logger.error("Failed to save photo: \(error.localizedDescription)", category: .photos)
        }
    }
    
    /// Checks if all photos for today are taken and marks photo tasks as complete
    private func checkAndCompletePhotoTasks() {
        Logger.info("Checking if all photos are taken for today", category: .photos)
        
        // Get today's date
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if we have photos for all angles today
        var hasAllPhotos = true
        for angle in PhotoAngle.allCases {
            let hasPhoto = hasPhotoForToday(angle: angle)
            if !hasPhoto {
                hasAllPhotos = false
                break
            }
        }
        
        // If we have all photos, mark photo tasks as complete
        if hasAllPhotos {
            Logger.info("All photos taken for today, marking photo tasks as complete", category: .photos)
            
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
                    task.complete(notes: "Automatically completed - all progress photos taken")
                }
                
                // Save the changes
                try modelContext.save()
                Logger.info("Successfully marked \(todayPhotoTasks.count) photo tasks as complete", category: .photos)
            } catch {
                Logger.error("Failed to mark photo tasks as complete: \(error.localizedDescription)", category: .photos)
            }
        }
    }
    
    /// Checks if there's a photo for today for the given angle
    private func hasPhotoForToday(angle: PhotoAngle) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return filteredPhotos.contains { photo in
            calendar.isDate(photo.date, inSameDayAs: today) && photo.angle == angle
        }
    }
}

// MARK: - Supporting Views

/// Thumbnail view for a photo
struct PhotoThumbnail: View {
    let photo: ProgressPhoto
    let photoService: ProgressPhotoService
    
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(DesignSystem.BorderRadius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                            .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                    )
            } else {
                Rectangle()
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(height: 150)
                    .cornerRadius(DesignSystem.BorderRadius.small)
                    .overlay(
                        ProgressView()
                    )
            }
            
            // Angle indicator
            VStack {
                Spacer()
                HStack {
                    Text(photo.angle.rawValue)
                        .font(DesignSystem.Typography.caption1)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.primaryAction)
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.BorderRadius.small)
                    
                    Spacer()
                }
                .padding(DesignSystem.Spacing.xs)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        Logger.debug("Loading image for photo: \(photo.id)", category: .photos)
        DispatchQueue.global().async {
            let loadedImage = photoService.loadPhoto(from: photo.fileURL)
            DispatchQueue.main.async {
                if let loadedImage = loadedImage {
                    self.image = photo.isBlurred ? photoService.blurPhoto(image: loadedImage) : loadedImage
                    Logger.debug("Image loaded successfully for photo: \(self.photo.id)", category: .photos)
                } else {
                    Logger.error("Failed to load image for photo: \(self.photo.id)", category: .photos)
                }
            }
        }
    }
}

// Preview
#Preview {
    PhotosView()
        .environmentObject(UserSettings())
        .modelContainer(for: [User.self, Challenge.self, Task.self, DailyTask.self, ProgressPhoto.self], inMemory: true)
} 