import SwiftUI
import SwiftData
import Charts

/// Detailed analytics view for photo progress analysis
struct PhotoAnalyticsDetailView: View {
    let analytics: PhotoProgressAnalytics
    let challenge: Challenge?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allPhotos: [ProgressPhoto]
    
    @State private var selectedMetric: AnalyticsMetric = .frequency
    @State private var showingExportOptions = false
    
    enum AnalyticsMetric: String, CaseIterable, Identifiable {
        case frequency = "Photo Frequency"
        case consistency = "Consistency"
        case progress = "Progress Timeline"
        case insights = "Insights"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .frequency: return "calendar.badge.clock"
            case .consistency: return "chart.line.uptrend.xyaxis"
            case .progress: return "timeline.selection"
            case .insights: return "lightbulb"
            }
        }
    }
    
    init(analytics: PhotoProgressAnalytics, challenge: Challenge?) {
        self.analytics = analytics
        self.challenge = challenge
        
        var descriptor = FetchDescriptor<ProgressPhoto>()
        if let challengeId = challenge?.id {
            descriptor.predicate = #Predicate<ProgressPhoto> { photo in
                photo.challenge?.id == challengeId
            }
        }
        descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]
        
        _allPhotos = Query(descriptor)
    }
    
    // MARK: - Computed Properties
    
    private var challengePhotos: [ProgressPhoto] {
        if let challenge = challenge {
            return allPhotos.filter { $0.challenge?.id == challenge.id }
        }
        return allPhotos
    }
    
    private var photoFrequencyData: [PhotoFrequencyData] {
        calculatePhotoFrequency()
    }
    
    private var consistencyScore: Double {
        calculateConsistencyScore()
    }
    
    private var progressInsights: [ProgressInsight] {
        generateProgressInsights()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        // Summary header
                        summaryHeader
                        
                        // Metric selector
                        metricSelector
                        
                        // Analytics content based on selected metric
                        switch selectedMetric {
                        case .frequency:
                            frequencyAnalytics
                        case .consistency:
                            consistencyAnalytics
                        case .progress:
                            progressTimeline
                        case .insights:
                            insightsView
                        }
                        
                        // Export options
                        exportSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Photo Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingExportOptions = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                PhotoAnalyticsExportView(
                    analytics: analytics,
                    challenge: challenge,
                    frequencyData: photoFrequencyData,
                    consistencyScore: consistencyScore
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var summaryHeader: some View {
        CTCard(style: .glass) {
            VStack(spacing: DesignSystem.Spacing.m) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Analysis Period")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text(analytics.timeSpanDescription)
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Total Photos")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("\(challengePhotos.count)")
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.primaryAction)
                    }
                }
                
                if let challenge = challenge {
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Challenge")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text(challenge.name)
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Day")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text("\(challenge.currentDay) of \(challenge.durationInDays)")
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var metricSelector: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                Text("Analytics")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(AnalyticsMetric.allCases) { metric in
                        Button {
                            selectedMetric = metric
                        } label: {
                            HStack {
                                Image(systemName: metric.icon)
                                    .font(.system(size: 16))
                                
                                Text(metric.rawValue)
                                    .font(DesignSystem.Typography.body)
                                
                                Spacer()
                            }
                            .fontWeight(selectedMetric == metric ? .semibold : .regular)
                            .foregroundColor(selectedMetric == metric ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(selectedMetric == metric ? DesignSystem.Colors.primaryAction.opacity(0.15) : Color.clear)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedMetric == metric ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.dividers, lineWidth: selectedMetric == metric ? 2 : 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
    }
    
    private var frequencyAnalytics: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            CTCard(style: .glass) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    Text("Photo Frequency Analysis")
                        .font(DesignSystem.Typography.headline)
                    
                    if !photoFrequencyData.isEmpty {
                        Chart(photoFrequencyData) { data in
                            BarMark(
                                x: .value("Date", data.date),
                                y: .value("Photos", data.photoCount)
                            )
                            .foregroundStyle(DesignSystem.Colors.primaryAction.gradient)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: max(1, photoFrequencyData.count / 7))) { value in
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisValueLabel()
                            }
                        }
                    } else {
                        Text("No data available for frequency analysis")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    }
                }
                .padding()
            }
            
            CTCard(style: .glass) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    Text("Frequency Statistics")
                        .font(DesignSystem.Typography.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.m) {
                        FrequencyStatCard(
                            title: "Average per Week",
                            value: String(format: "%.1f", averagePhotosPerWeek),
                            icon: "calendar.circle",
                            color: .blue
                        )
                        
                        FrequencyStatCard(
                            title: "Most Active Day",
                            value: mostActiveDay,
                            icon: "star.fill",
                            color: .orange
                        )
                        
                        FrequencyStatCard(
                            title: "Longest Streak",
                            value: "\(longestPhotoStreak) days",
                            icon: "flame.fill",
                            color: .red
                        )
                        
                        FrequencyStatCard(
                            title: "Current Streak",
                            value: "\(currentPhotoStreak) days",
                            icon: "bolt.fill",
                            color: .green
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    private var consistencyAnalytics: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            CTCard(style: .glass) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    Text("Consistency Score")
                        .font(DesignSystem.Typography.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Overall Consistency")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(consistencyScore * 100))")
                                    .font(DesignSystem.Typography.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(consistencyColor)
                                
                                Text("%")
                                    .font(DesignSystem.Typography.title2)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            
                            Text(consistencyDescription)
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        // Consistency ring chart
                        ZStack {
                            Circle()
                                .stroke(DesignSystem.Colors.cardBackground, lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: consistencyScore)
                                .stroke(consistencyColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1), value: consistencyScore)
                        }
                    }
                }
                .padding()
            }
            
            CTCard(style: .glass) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    Text("Consistency Breakdown")
                        .font(DesignSystem.Typography.headline)
                    
                    ForEach(PhotoAngle.allCases, id: \.self) { angle in
                        consistencyBreakdownRow(for: angle)
                    }
                }
                .padding()
            }
        }
    }
    
    private var progressTimeline: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Progress Timeline")
                    .font(DesignSystem.Typography.headline)
                
                if challengePhotos.count >= 2 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.m) {
                            ForEach(Array(challengePhotos.enumerated()), id: \.offset) { index, photo in
                                TimelinePhotoView(
                                    photo: photo,
                                    index: index,
                                    isFirst: index == 0,
                                    isLast: index == challengePhotos.count - 1,
                                    challenge: challenge
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    Text("Need at least 2 photos to show timeline")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                }
            }
            .padding()
        }
    }
    
    private var insightsView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            ForEach(progressInsights, id: \.id) { insight in
                CTCard(style: .glass) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        HStack {
                            Image(systemName: insight.icon)
                                .foregroundColor(insight.color)
                                .font(.system(size: 20))
                            
                            Text(insight.title)
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Spacer()
                        }
                        
                        Text(insight.description)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let recommendation = insight.recommendation {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 14))
                                
                                Text(recommendation)
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.primaryAction)
                                    .fontWeight(.medium)
                            }
                            .padding(.top, DesignSystem.Spacing.s)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var exportSection: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Export & Share")
                    .font(DesignSystem.Typography.headline)
                
                Text("Share your progress analytics and insights")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Button {
                    showingExportOptions = true
                } label: {
                    Label("Export Analytics", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(DesignSystem.Colors.primaryAction)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Views
    
    private func consistencyBreakdownRow(for angle: PhotoAngle) -> some View {
        let anglePhotos = challengePhotos.filter { $0.angle == angle }
        let angleConsistency = calculateConsistencyScore(for: angle)
        
        return HStack {
            Image(systemName: angle.icon)
                .foregroundColor(DesignSystem.Colors.primaryAction)
                .font(.system(size: 16))
                .frame(width: 24)
            
            Text(angle.description)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Spacer()
            
            Text("\(anglePhotos.count)")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(width: 30)
            
            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignSystem.Colors.cardBackground)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(consistencyColor)
                        .frame(width: geometry.size.width * angleConsistency, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut, value: angleConsistency)
                }
            }
            .frame(height: 4)
            .frame(width: 60)
            
            Text("\(Int(angleConsistency * 100))%")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(width: 35)
        }
    }
    
    // MARK: - Computed Values
    
    private var averagePhotosPerWeek: Double {
        guard !challengePhotos.isEmpty,
              let firstPhoto = challengePhotos.first,
              let lastPhoto = challengePhotos.last else {
            return 0
        }
        
        let daysDifference = Calendar.current.dateComponents([.day], from: firstPhoto.date, to: lastPhoto.date).day ?? 1
        let weeks = max(1, daysDifference / 7)
        return Double(challengePhotos.count) / Double(weeks)
    }
    
    private var mostActiveDay: String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        let dayGroups = Dictionary(grouping: challengePhotos) { photo in
            Calendar.current.component(.weekday, from: photo.date)
        }
        
        let mostActiveWeekday = dayGroups.max { $0.value.count < $1.value.count }?.key ?? 1
        let date = Calendar.current.date(from: DateComponents(weekday: mostActiveWeekday)) ?? Date()
        
        return dayFormatter.string(from: date)
    }
    
    private var longestPhotoStreak: Int {
        calculatePhotoStreak(type: .longest)
    }
    
    private var currentPhotoStreak: Int {
        calculatePhotoStreak(type: .current)
    }
    
    private var consistencyColor: Color {
        switch consistencyScore {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var consistencyDescription: String {
        switch consistencyScore {
        case 0.9...1.0:
            return "Excellent consistency!"
        case 0.8..<0.9:
            return "Very good consistency"
        case 0.6..<0.8:
            return "Good consistency"
        case 0.4..<0.6:
            return "Fair consistency"
        default:
            return "Needs improvement"
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculatePhotoFrequency() -> [PhotoFrequencyData] {
        guard !challengePhotos.isEmpty else { return [] }
        
        let calendar = Calendar.current
        let dateGroups = Dictionary(grouping: challengePhotos) { photo in
            calendar.startOfDay(for: photo.date)
        }
        
        return dateGroups.map { date, photos in
            PhotoFrequencyData(date: date, photoCount: photos.count)
        }.sorted { $0.date < $1.date }
    }
    
    private func calculateConsistencyScore() -> Double {
        guard let challenge = challenge,
              let startDate = challenge.startDate else {
            return 0
        }
        
        let calendar = Calendar.current
        let today = Date()
        let challengeDays = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        
        if challengeDays == 0 { return 0 }
        
        let photoDays = Set(challengePhotos.map { calendar.startOfDay(for: $0.date) })
        return Double(photoDays.count) / Double(challengeDays)
    }
    
    private func calculateConsistencyScore(for angle: PhotoAngle) -> Double {
        let anglePhotos = challengePhotos.filter { $0.angle == angle }
        
        guard let challenge = challenge,
              let startDate = challenge.startDate else {
            return 0
        }
        
        let calendar = Calendar.current
        let today = Date()
        let challengeDays = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        
        if challengeDays == 0 { return 0 }
        
        let photoDays = Set(anglePhotos.map { calendar.startOfDay(for: $0.date) })
        return Double(photoDays.count) / Double(challengeDays)
    }
    
    private func calculatePhotoStreak(type: StreakType) -> Int {
        guard !challengePhotos.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let photoDays = Set(challengePhotos.map { calendar.startOfDay(for: $0.date) }).sorted()
        
        switch type {
        case .current:
            return calculateCurrentStreak(photoDays: photoDays, calendar: calendar)
        case .longest:
            return calculateLongestStreak(photoDays: photoDays, calendar: calendar)
        }
    }
    
    private func calculateCurrentStreak(photoDays: [Date], calendar: Calendar) -> Int {
        guard !photoDays.isEmpty else { return 0 }
        
        let today = calendar.startOfDay(for: Date())
        var currentStreak = 0
        var checkDate = today
        
        while photoDays.contains(checkDate) {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        return currentStreak
    }
    
    private func calculateLongestStreak(photoDays: [Date], calendar: Calendar) -> Int {
        guard !photoDays.isEmpty else { return 0 }
        
        var longestStreak = 0
        var currentStreak = 1
        
        for i in 1..<photoDays.count {
            let daysDiff = calendar.dateComponents([.day], from: photoDays[i-1], to: photoDays[i]).day ?? 0
            
            if daysDiff == 1 {
                currentStreak += 1
            } else {
                longestStreak = max(longestStreak, currentStreak)
                currentStreak = 1
            }
        }
        
        return max(longestStreak, currentStreak)
    }
    
    private func generateProgressInsights() -> [ProgressInsight] {
        var insights: [ProgressInsight] = []
        
        // Consistency insight
        if consistencyScore >= 0.8 {
            insights.append(ProgressInsight(
                id: "consistency_excellent",
                title: "Excellent Consistency",
                description: "You're maintaining great consistency with your progress photos. Keep up the excellent work!",
                icon: "star.fill",
                color: .green,
                recommendation: nil
            ))
        } else if consistencyScore < 0.5 {
            insights.append(ProgressInsight(
                id: "consistency_low",
                title: "Consistency Opportunity",
                description: "Your photo consistency could be improved. Regular photos help track progress better.",
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                recommendation: "Try setting daily reminders to take progress photos"
            ))
        }
        
        // Frequency insight
        if averagePhotosPerWeek >= 5 {
            insights.append(ProgressInsight(
                id: "frequency_high",
                title: "Great Photo Frequency",
                description: "You're taking photos regularly, which is excellent for tracking detailed progress.",
                icon: "camera.fill",
                color: .blue,
                recommendation: nil
            ))
        }
        
        // Streak insight
        if currentPhotoStreak >= 7 {
            insights.append(ProgressInsight(
                id: "streak_strong",
                title: "Strong Photo Streak",
                description: "You're on a \(currentPhotoStreak)-day photo streak! This consistency will pay off.",
                icon: "flame.fill",
                color: .red,
                recommendation: nil
            ))
        }
        
        // Challenge progress insight
        if let challenge = challenge {
            let progressPercentage = Double(challenge.currentDay) / Double(challenge.durationInDays)
            
            if progressPercentage >= 0.5 {
                insights.append(ProgressInsight(
                    id: "challenge_midpoint",
                    title: "Challenge Milestone",
                    description: "You've reached the halfway point of your \(challenge.name) challenge! Your photo documentation shows real commitment.",
                    icon: "flag.fill",
                    color: .purple,
                    recommendation: "Consider creating a comparison post to celebrate your progress"
                ))
            }
        }
        
        return insights
    }
}

// MARK: - Supporting Views

struct FrequencyStatCard: View {
    let title: String
    let value: String
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
            
            Text(value)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .cornerRadius(8)
    }
}

struct TimelinePhotoView: View {
    let photo: ProgressPhoto
    let index: Int
    let isFirst: Bool
    let isLast: Bool
    let challenge: Challenge?
    
    private let photoService = ProgressPhotoService()
    
    var body: some View {
        VStack(spacing: 8) {
            // Photo
            if let image = photoService.loadPhoto(from: photo.fileURL) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(3/4, contentMode: .fill)
                    .frame(width: 100, height: 133)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isFirst ? Color.green : (isLast ? Color.blue : DesignSystem.Colors.dividers),
                                lineWidth: isFirst || isLast ? 2 : 1
                            )
                    )
            } else {
                Rectangle()
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 100, height: 133)
                    .cornerRadius(8)
            }
            
            // Date
            Text(photo.date, style: .date)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            // Challenge day (if applicable)
            if let challenge = challenge, let startDate = challenge.startDate {
                let dayNumber = Calendar.current.dateComponents([.day], from: startDate, to: photo.date).day ?? 0
                Text("Day \(dayNumber + 1)")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.primaryAction)
                    .fontWeight(.medium)
            }
            
            // Angle
            Text(photo.angle.description)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
}

// MARK: - Data Models

struct PhotoFrequencyData: Identifiable {
    let id = UUID()
    let date: Date
    let photoCount: Int
}

struct ProgressInsight: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let recommendation: String?
}

enum StreakType {
    case current
    case longest
}

// MARK: - Preview

#Preview {
    let sampleAnalytics = PhotoProgressAnalytics(
        firstPhoto: ProgressPhoto(challenge: nil, date: Date(), angle: .front, fileURL: URL(fileURLWithPath: ""), isBlurred: false),
        secondPhoto: ProgressPhoto(challenge: nil, date: Date(), angle: .front, fileURL: URL(fileURLWithPath: ""), isBlurred: false),
        firstImage: UIImage(),
        secondImage: UIImage(),
        daysBetween: 30
    )
    
    PhotoAnalyticsDetailView(analytics: sampleAnalytics, challenge: nil)
        .modelContainer(for: [User.self, Challenge.self, Task.self, DailyTask.self, ProgressPhoto.self], inMemory: true)
} 