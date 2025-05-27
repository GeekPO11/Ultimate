import SwiftUI
import SwiftData
import UIKit

/// Enhanced view for comparing progress photos with improved fitness tracking features
struct EnhancedPhotoComparisonView: View {
    // MARK: - Properties
    
    var selectedChallenge: Challenge?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var photos: [ProgressPhoto]
    
    @State private var selectedAngle: PhotoAngle = .front
    @State private var comparisonMode: ComparisonMode = .sideBySide
    @State private var firstDate: Date?
    @State private var secondDate: Date?
    @State private var sliderPosition: Double = 0.5
    @State private var showingTimeline = false
    @State private var showingAnalytics = false
    
    // Service for managing photos
    private let photoService = ProgressPhotoService()
    
    // MARK: - Comparison Mode
    
    enum ComparisonMode: String, CaseIterable, Identifiable {
        case sideBySide = "Side by Side"
        case slider = "Slider"
        case timeline = "Timeline"
        
        var id: Self { self }
        
        var icon: String {
            switch self {
            case .sideBySide: return "rectangle.split.2x1"
            case .slider: return "slider.horizontal.below.rectangle"
            case .timeline: return "timeline.selection"
            }
        }
    }
    
    // MARK: - Initialization
    
    init(selectedChallenge: Challenge? = nil) {
        self.selectedChallenge = selectedChallenge
        
        var descriptor = FetchDescriptor<ProgressPhoto>()
        if let challengeId = selectedChallenge?.id {
            descriptor.predicate = #Predicate<ProgressPhoto> { photo in
                photo.challenge?.id == challengeId
            }
        }
        descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]
        
        _photos = Query(descriptor)
    }
    
    // MARK: - Computed Properties
    
    private var availableDates: [Date] {
        getAvailableDates(for: selectedAngle)
    }
    
    private var daysBetweenPhotos: Int? {
        guard let firstDate = firstDate, let secondDate = secondDate else { return nil }
        return Calendar.current.dateComponents([.day], from: firstDate, to: secondDate).day
    }
    
    private var progressAnalytics: PhotoProgressAnalytics? {
        guard let firstPhoto = getPhoto(for: firstDate, angle: selectedAngle),
              let secondPhoto = getPhoto(for: secondDate, angle: selectedAngle),
              let firstImage = photoService.loadPhoto(from: firstPhoto.fileURL),
              let secondImage = photoService.loadPhoto(from: secondPhoto.fileURL) else {
            return nil
        }
        
        return PhotoProgressAnalytics(
            firstPhoto: firstPhoto,
            secondPhoto: secondPhoto,
            firstImage: firstImage,
            secondImage: secondImage,
            daysBetween: daysBetweenPhotos ?? 0
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        // Quick comparison selector
                        quickComparisonSelector
                        
                        // Angle and mode selectors
                        CTCard(style: .glass) {
                            VStack(spacing: DesignSystem.Spacing.m) {
                                angleSelector
                                Divider()
                                comparisonModeSelector
                            }
                            .padding()
                        }
                        
                        // Enhanced date selectors with day difference
                        CTCard(style: .glass) {
                            enhancedDateSelectors
                        }
                        
                        // Progress analytics summary
                        if let analytics = progressAnalytics {
                            CTCard(style: .glass) {
                                progressAnalyticsView(analytics)
                            }
                        }
                        
                        // Enhanced photo comparison view
                        if let firstDate = firstDate, let secondDate = secondDate,
                           let firstPhoto = getPhoto(for: firstDate, angle: selectedAngle),
                           let secondPhoto = getPhoto(for: secondDate, angle: selectedAngle),
                           let firstImage = photoService.loadPhoto(from: firstPhoto.fileURL),
                           let secondImage = photoService.loadPhoto(from: secondPhoto.fileURL) {
                            
                            CTCard(style: .glass) {
                                enhancedComparisonView(
                                    firstImage: firstImage,
                                    secondImage: secondImage,
                                    firstDate: firstDate,
                                    secondDate: secondDate
                                )
                            }
                        } else {
                            CTCard(style: .glass) {
                                placeholderView
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Enhanced Photo Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAnalytics = true
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                }
            }
            .sheet(isPresented: $showingAnalytics) {
                if let analytics = progressAnalytics {
                    PhotoAnalyticsDetailView(analytics: analytics, challenge: selectedChallenge)
                }
            }
            .onAppear {
                setupDefaultDates()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Quick comparison selector for common comparisons
    private var quickComparisonSelector: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                Text("Quick Comparisons")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.s) {
                        QuickComparisonButton(title: "Latest vs First", systemImage: "arrow.right.to.line") {
                            setLatestVsFirst()
                        }
                        
                        QuickComparisonButton(title: "Last 7 Days", systemImage: "calendar.circle") {
                            setLastSevenDays()
                        }
                        
                        QuickComparisonButton(title: "Last 30 Days", systemImage: "calendar.circle.fill") {
                            setLastThirtyDays()
                        }
                        
                        QuickComparisonButton(title: "Challenge Start", systemImage: "flag") {
                            setChallengeStartComparison()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }
    
    /// Enhanced angle selector with photo counts
    private var angleSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Select Angle:")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PhotoAngle.allCases, id: \.self) { angle in
                    let photoCount = getPhotoCount(for: angle)
                    
                    Button {
                        selectedAngle = angle
                    } label: {
                        VStack(spacing: 4) {
                            HStack {
                                Image(systemName: angle.icon)
                                    .font(.system(size: 16))
                                
                                Text(angle.description)
                                    .font(DesignSystem.Typography.body)
                                
                                Spacer()
                                
                                Text("\(photoCount)")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(DesignSystem.Colors.cardBackground)
                                    .cornerRadius(8)
                            }
                        }
                        .fontWeight(selectedAngle == angle ? .semibold : .regular)
                        .foregroundColor(selectedAngle == angle ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(selectedAngle == angle ? DesignSystem.Colors.primaryAction.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedAngle == angle ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.dividers, lineWidth: selectedAngle == angle ? 2 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(photoCount == 0)
                    .opacity(photoCount == 0 ? 0.5 : 1.0)
                }
            }
            .onChange(of: selectedAngle) { _, _ in
                setupDefaultDates()
            }
        }
    }
    
    /// Enhanced date selectors with additional context
    private var enhancedDateSelectors: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            Text("Select Dates to Compare")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: DesignSystem.Spacing.m) {
                // First date selector
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                    Text("First Date:")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    dateSelectionMenu(
                        selectedDate: $firstDate,
                        placeholder: "Select first date"
                    )
                }
                
                // Arrow indicator
                Image(systemName: "arrow.right")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.top, 20)
                
                // Second date selector
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                    Text("Second Date:")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    dateSelectionMenu(
                        selectedDate: $secondDate,
                        placeholder: "Select second date"
                    )
                }
            }
            
            // Days difference indicator
            if let daysDiff = daysBetweenPhotos {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                    
                    Text("\(abs(daysDiff)) days between photos")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Spacer()
                }
                .padding(.top, DesignSystem.Spacing.s)
            }
        }
        .padding()
    }
    
    /// Progress analytics view
    private func progressAnalyticsView(_ analytics: PhotoProgressAnalytics) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("Progress Insights")
                .font(DesignSystem.Typography.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.m) {
                AnalyticsCard(
                    title: "Time Span",
                    value: "\(analytics.daysBetween)",
                    subtitle: analytics.daysBetween == 1 ? "day" : "days",
                    icon: "calendar",
                    color: .blue
                )
                
                AnalyticsCard(
                    title: "Challenge Day",
                    value: challengeDayText(for: analytics.secondPhoto),
                    subtitle: "of challenge",
                    icon: "flag",
                    color: .orange
                )
            }
            
            Button {
                showingAnalytics = true
            } label: {
                Label("View Detailed Analytics", systemImage: "chart.bar.xaxis")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DesignSystem.Colors.primaryAction.opacity(0.1))
                    .foregroundColor(DesignSystem.Colors.primaryAction)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    /// Enhanced comparison view with better controls
    private func enhancedComparisonView(firstImage: UIImage, secondImage: UIImage, firstDate: Date, secondDate: Date) -> some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            // Header with dates
            HStack {
                VStack(alignment: .leading) {
                    Text(formatDate(firstDate))
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("Starting Point")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(formatDate(secondDate))
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("Current Progress")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                }
            }
            .padding(.horizontal)
            
            // Comparison view based on mode
            switch comparisonMode {
            case .sideBySide:
                enhancedSideBySideView(firstImage: firstImage, secondImage: secondImage)
            case .slider:
                enhancedSliderView(firstImage: firstImage, secondImage: secondImage)
            case .timeline:
                timelineView(firstImage: firstImage, secondImage: secondImage)
            }
        }
        .padding()
    }
    
    /// Enhanced side by side view with zoom capability
    private func enhancedSideBySideView(firstImage: UIImage, secondImage: UIImage) -> some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            VStack {
                Text("Before")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(DesignSystem.Colors.primaryAction.opacity(0.2))
                    .cornerRadius(DesignSystem.BorderRadius.small)
                
                ZoomableImageView(image: firstImage)
                    .aspectRatio(3/4, contentMode: .fit)
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                            .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                    )
            }
            
            VStack {
                Text("After")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(DesignSystem.Colors.primaryAction.opacity(0.2))
                    .cornerRadius(DesignSystem.BorderRadius.small)
                
                ZoomableImageView(image: secondImage)
                    .aspectRatio(3/4, contentMode: .fit)
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                            .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                    )
            }
        }
        .frame(maxHeight: 500)
    }
    
    /// Enhanced slider view with better controls
    private func enhancedSliderView(firstImage: UIImage, secondImage: UIImage) -> some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            GeometryReader { geometry in
                ZStack {
                    // Background image (first)
                    Image(uiImage: firstImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                    
                    // Overlay image (second) with mask
                    Image(uiImage: secondImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                        .mask(
                            Rectangle()
                                .frame(width: geometry.size.width * sliderPosition)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                    
                    // Enhanced divider line with gradient
                    LinearGradient(
                        colors: [.clear, .white, .white, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: 3)
                    .frame(height: geometry.size.height)
                    .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 0)
                    
                    // Enhanced slider handle
                    VStack {
                        Circle()
                            .fill(DesignSystem.Colors.primaryAction)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .overlay(
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
                    
                    // Full-width drag area
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let newPosition = value.location.x / geometry.size.width
                                    sliderPosition = min(max(newPosition, 0), 1)
                                }
                        )
                    
                    // Progress indicator
                    VStack {
                        HStack {
                            Text("Before")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(DesignSystem.BorderRadius.small)
                                .opacity(sliderPosition > 0.1 ? 1 : 0)
                            
                            Spacer()
                            
                            Text("After")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(DesignSystem.BorderRadius.small)
                                .opacity(sliderPosition < 0.9 ? 1 : 0)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Progress percentage
                        Text("\(Int(sliderPosition * 100))%")
                            .font(DesignSystem.Typography.caption1)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(DesignSystem.BorderRadius.small)
                            .padding(.bottom)
                    }
                }
                .frame(height: geometry.size.height)
                .cornerRadius(DesignSystem.BorderRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                        .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                )
            }
            .frame(height: 400)
            .onAppear {
                sliderPosition = 0.5
            }
            
            // Slider controls
            VStack(spacing: DesignSystem.Spacing.s) {
                Text("Drag to compare")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                HStack {
                    Button("Reset") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            sliderPosition = 0.5
                        }
                    }
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.primaryAction)
                    
                    Spacer()
                    
                    Button("Before") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            sliderPosition = 0.0
                        }
                    }
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.primaryAction)
                    
                    Spacer()
                    
                    Button("After") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            sliderPosition = 1.0
                        }
                    }
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.primaryAction)
                }
            }
        }
    }
    
    /// Timeline view for progression visualization
    private func timelineView(firstImage: UIImage, secondImage: UIImage) -> some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            Text("Progress Timeline")
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 0) {
                // First image
                VStack {
                    Image(uiImage: firstImage)
                        .resizable()
                        .aspectRatio(3/4, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                .stroke(DesignSystem.Colors.primaryAction, lineWidth: 2)
                        )
                    
                    Text(formatDate(firstDate!))
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // Progress arrow
                VStack {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                        .padding(.horizontal, DesignSystem.Spacing.m)
                    
                    if let daysDiff = daysBetweenPhotos {
                        Text("\(abs(daysDiff))d")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                // Second image
                VStack {
                    Image(uiImage: secondImage)
                        .resizable()
                        .aspectRatio(3/4, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                .stroke(DesignSystem.Colors.primaryAction, lineWidth: 2)
                        )
                    
                    Text(formatDate(secondDate!))
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .frame(maxHeight: 300)
        }
    }
    
    /// Comparison mode selector
    private var comparisonModeSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Comparison Mode:")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Picker("Comparison Mode", selection: $comparisonMode) {
                ForEach(ComparisonMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    /// Placeholder view for when no photos are selected
    private var placeholderView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.primaryAction.opacity(0.7))
            
            Text("Select Two Dates")
                .font(DesignSystem.Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("Choose two dates with photos to compare your fitness progress")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Helper Methods
    
    private func setupDefaultDates() {
        let availableDates = getAvailableDates(for: selectedAngle)
        if availableDates.count >= 2 {
            secondDate = availableDates[0]  // Most recent
            firstDate = availableDates[1]   // Second most recent
        } else if availableDates.count == 1 {
            secondDate = availableDates[0]
            firstDate = nil
        } else {
            firstDate = nil
            secondDate = nil
        }
    }
    
    private func setLatestVsFirst() {
        let dates = getAvailableDates(for: selectedAngle)
        if dates.count >= 2 {
            secondDate = dates.first  // Latest
            firstDate = dates.last    // First
        }
    }
    
    private func setLastSevenDays() {
        let dates = getAvailableDates(for: selectedAngle)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let recentDates = dates.filter { $0 >= sevenDaysAgo }
        if recentDates.count >= 2 {
            secondDate = recentDates.first
            firstDate = recentDates.last
        }
    }
    
    private func setLastThirtyDays() {
        let dates = getAvailableDates(for: selectedAngle)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let recentDates = dates.filter { $0 >= thirtyDaysAgo }
        if recentDates.count >= 2 {
            secondDate = recentDates.first
            firstDate = recentDates.last
        }
    }
    
    private func setChallengeStartComparison() {
        guard let challenge = selectedChallenge, let startDate = challenge.startDate else { return }
        
        let dates = getAvailableDates(for: selectedAngle)
        let challengeStartDay = Calendar.current.startOfDay(for: startDate)
        
        // Find the earliest photo on or after challenge start
        let challengePhotos = dates.filter { $0 >= challengeStartDay }
        
        if let firstChallengePhoto = challengePhotos.last, // Earliest
           let latestPhoto = dates.first { // Latest
            firstDate = firstChallengePhoto
            secondDate = latestPhoto
        }
    }
    
    private func getAvailableDates(for angle: PhotoAngle) -> [Date] {
        let filteredPhotos = photos.filter { photo in
            photo.angle == angle &&
            (selectedChallenge == nil || photo.challenge?.id == selectedChallenge?.id)
        }
        
        let dates = filteredPhotos.map { Calendar.current.startOfDay(for: $0.date) }
        return Array(Set(dates)).sorted(by: >)
    }
    
    private func getPhotoCount(for angle: PhotoAngle) -> Int {
        return photos.filter { photo in
            photo.angle == angle &&
            (selectedChallenge == nil || photo.challenge?.id == selectedChallenge?.id)
        }.count
    }
    
    private func getPhoto(for date: Date?, angle: PhotoAngle) -> ProgressPhoto? {
        guard let date = date else { return nil }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return photos.first { photo in
            photo.angle == angle &&
            photo.date >= startOfDay &&
            photo.date < endOfDay &&
            (selectedChallenge == nil || photo.challenge?.id == selectedChallenge?.id)
        }
    }
    
    private func dateSelectionMenu(selectedDate: Binding<Date?>, placeholder: String) -> some View {
        Menu {
            ForEach(availableDates, id: \.self) { date in
                Button(formatDate(date)) {
                    selectedDate.wrappedValue = date
                }
            }
        } label: {
            HStack {
                Text(selectedDate.wrappedValue != nil ? formatDate(selectedDate.wrappedValue!) : placeholder)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(selectedDate.wrappedValue != nil ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func challengeDayText(for photo: ProgressPhoto) -> String {
        guard let challenge = photo.challenge ?? selectedChallenge,
              let startDate = challenge.startDate else {
            return "N/A"
        }
        
        let dayNumber = Calendar.current.dateComponents([.day], from: startDate, to: photo.date).day ?? 0
        return "Day \(dayNumber + 1)"
    }
}

// MARK: - Supporting Views

struct QuickComparisonButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                Text(title)
                    .font(DesignSystem.Typography.caption1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(DesignSystem.Colors.primaryAction.opacity(0.1))
            .foregroundColor(DesignSystem.Colors.primaryAction)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Text(title)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .cornerRadius(8)
    }
}

struct ZoomableImageView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newScale = lastScale * value
                        scale = min(max(newScale, 1.0), 4.0)
                    }
                    .onEnded { _ in
                        lastScale = scale
                        if scale == 1.0 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                offset = .zero
                            }
                            lastOffset = .zero
                        }
                    }
                    .simultaneously(with:
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
            )
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if scale > 1.0 {
                        scale = 1.0
                        offset = .zero
                    } else {
                        scale = 2.0
                    }
                }
                lastScale = scale
                lastOffset = offset
            }
    }
}

// MARK: - Data Models

struct PhotoProgressAnalytics {
    let firstPhoto: ProgressPhoto
    let secondPhoto: ProgressPhoto
    let firstImage: UIImage
    let secondImage: UIImage
    let daysBetween: Int
    
    var timeSpanDescription: String {
        if daysBetween == 0 {
            return "Same day"
        } else if daysBetween == 1 {
            return "1 day apart"
        } else if daysBetween < 7 {
            return "\(daysBetween) days apart"
        } else if daysBetween < 30 {
            let weeks = daysBetween / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s") apart"
        } else {
            let months = daysBetween / 30
            return "\(months) month\(months == 1 ? "" : "s") apart"
        }
    }
}

// MARK: - Preview

#Preview {
    EnhancedPhotoComparisonView()
        .modelContainer(for: [User.self, Challenge.self, Task.self, DailyTask.self, ProgressPhoto.self], inMemory: true)
} 