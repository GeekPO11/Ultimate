import SwiftUI
import SwiftData
import Charts
import UIKit

// MARK: - Main View

struct ProgressTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Challenge.startDate, order: .reverse) private var challenges: [Challenge]
    @Query(sort: \DailyTask.date) private var dailyTasks: [DailyTask]
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var showingAnalyticsChallenge: Challenge?
    @State private var showingDetailedStats = false
    @State private var isLandscape = false
    
    // --- Computed Properties for Overall Progress ---
    
    private var activeChallenges: [Challenge] {
        challenges.filter { $0.status == .inProgress }
    }
    
    private var completedChallenges: [Challenge] {
        challenges.filter { $0.status == .completed }
    }
    
    private var failedChallenges: [Challenge] {
        challenges.filter { $0.status == .failed }
    }
    
    private var overallStreakData: StreakData {
        calculateOverallStreak(dailyTasks: dailyTasks)
    }
    
    private var overallTaskCompletionData: [TaskCompletionData] {
        calculateOverallTaskCompletion(dailyTasks: dailyTasks, timeFrame: selectedTimeFrame)
    }
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case week = "Last 7 Days"
        case month = "Last 30 Days"
        case all = "All Time"
        
        var id: String { self.rawValue }
    }
    
    // --- Body ---
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        // Overall Summary Stats
                        overallSummaryStats
                        
                        // Fitness Integration View
                        FitnessIntegrationView()
                        
                        // Time frame selector for charts
                        timeFrameSelector
                        
                        // Overall Task Completion Chart
                        overallTaskCompletionChart
                        
                        // Overall Streak Card
                        overallStreakCard
                        
                        // View Detailed Stats Button
                        detailedStatsButton
                        
                        // Active Challenges List
                        activeChallengesList
                    }
                    .padding()
                }
                .background(DesignSystem.Colors.background)
                .navigationTitle("Overall Progress")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(item: $showingAnalyticsChallenge) { challenge in
                    ChallengeAnalyticsView(challenge: challenge)
                }
                .fullScreenCover(isPresented: $showingDetailedStats) {
                    DetailedStatsView(
                        taskCompletionData: overallTaskCompletionData,
                        streakData: overallStreakData,
                        timeFrame: $selectedTimeFrame
                    )
                }
                .onChange(of: selectedTimeFrame) { _, _ in
                    // Data recalculates automatically due to @State / computed properties
                    Logger.info("Time frame changed to: \(selectedTimeFrame.rawValue)", category: .analytics)
                }
                .onAppear {
                    // Add observer for automatic workout completion
                    NotificationCenter.default.addObserver(
                        forName: Notification.Name("WorkoutTaskCompletedAutomatically"),
                        object: nil,
                        queue: .main
                    ) { _ in
                        // Force a view refresh when a workout is completed automatically
                        // Data will update automatically due to @Query
                    }
                }
                .onDisappear {
                    // Remove observer when view disappears
                    NotificationCenter.default.removeObserver(self, name: Notification.Name("WorkoutTaskCompletedAutomatically"), object: nil)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Overall summary stats card
    private var overallSummaryStats: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Lifetime Stats")
                    .font(DesignSystem.Typography.headline)
                
                HStack(spacing: DesignSystem.Spacing.l) {
                    statItem(value: "\(challenges.count)", label: "Total", icon: "target")
                    statItem(value: "\(activeChallenges.count)", label: "Active", icon: "figure.run", color: .orange)
                    statItem(value: "\(completedChallenges.count)", label: "Completed", icon: "checkmark.seal.fill", color: .green)
                    statItem(value: "\(failedChallenges.count)", label: "Failed", icon: "xmark.octagon.fill", color: .red)
                }
            }
            .padding()
        }
    }
    
    /// Time frame selector
    private var timeFrameSelector: some View {
        Picker("Time Frame", selection: $selectedTimeFrame) {
            ForEach(TimeFrame.allCases) { timeFrame in
                Text(timeFrame.rawValue).tag(timeFrame)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    /// Overall Task Completion Chart
    private var overallTaskCompletionChart: some View {
        CTProgressChart(
            data: overallTaskCompletionData.map { dayData in
                ProgressDataPoint(
                    date: dayData.date,
                    value: Double(dayData.completed),
                    targetValue: Double(dayData.total), // Use total for bar chart context
                    category: "Completed"
                )
            },
            chartType: .bar,
            title: "Daily Task Completion",
            subtitle: "Tasks completed across all challenges (\(selectedTimeFrame.rawValue))"
        )
    }
    
    /// Overall Streak Card
    private var overallStreakCard: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Overall Activity Streak") // Clarified title
                    .font(DesignSystem.Typography.headline)
                
                HStack(spacing: DesignSystem.Spacing.xl) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Current")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(overallStreakData.current)")
                                .font(DesignSystem.Typography.title1)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            Text(overallStreakData.current == 1 ? "day" : "days") // Pluralization
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Best")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(overallStreakData.best)")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                             Text(overallStreakData.best == 1 ? "day" : "days") // Pluralization
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Flame icon
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primaryAction.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 30))
                            .foregroundColor(overallStreakData.current > 0 ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.secondaryText)
                    }
                }
                Text("Streak counts days with at least one completed task.") // Explain streak logic
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    /// Detailed stats button
    private var detailedStatsButton: some View {
        Button {
            showingDetailedStats = true
        } label: {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 18))
                Text("View Detailed Statistics")
                    .font(DesignSystem.Typography.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [DesignSystem.Colors.primaryAction, DesignSystem.Colors.primaryAction.opacity(0.7)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignSystem.BorderRadius.medium)
        }
        .padding(.horizontal)
    }
    
    /// List of active challenges
    private var activeChallengesList: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("Active Challenges")
                .font(DesignSystem.Typography.headline)
                .padding(.horizontal)
            
            if activeChallenges.isEmpty {
                CTCard(style: .bordered) {
                    Text("No active challenges.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
            } else {
                ForEach(activeChallenges) { challenge in
                    activeChallengeCard(challenge)
                        .onTapGesture {
                            showingAnalyticsChallenge = challenge
                        }
                        .padding(.horizontal)
                }
            }
        }
    }
    
    /// Card view for an active challenge
    private func activeChallengeCard(_ challenge: Challenge) -> some View {
        CTCard(style: .glass) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text(challenge.name)
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.semibold)
                    Text("Day \(challenge.currentDay) of \(challenge.durationInDays)")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                CTProgressRing(
                    progress: challenge.progress,
                    color: getColorForChallenge(challenge),
                    lineWidth: 6,
                    size: 50
                )
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding()
        }
    }
    
    /// Reusable stat item view
    private func statItem(value: String, label: String, icon: String, color: Color = DesignSystem.Colors.primaryAction) -> some View {
        VStack(spacing: DesignSystem.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Data Calculation Methods
    
    /// Calculate overall streak based on completing at least one task per day across all challenges.
    private func calculateOverallStreak(dailyTasks: [DailyTask]) -> StreakData {
        guard !dailyTasks.isEmpty else {
            return StreakData(current: 0, best: 0, total: 0)
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Group tasks by date for efficient lookup
        let tasksByDate = Dictionary(grouping: dailyTasks) { calendar.startOfDay(for: $0.date) }
        let sortedDates = tasksByDate.keys.sorted()
        guard let firstTaskDate = sortedDates.first, let lastTaskDate = sortedDates.last else {
             return StreakData(current: 0, best: 0, total: 0)
        }

        var currentStreak = 0
        var bestStreak = 0
        var internalCurrentStreak = 0
        var totalCompletedDays = 0
        var dateToCheck = firstTaskDate

        // Calculate Best Streak and Total Completed Days by iterating forward
        while dateToCheck <= lastTaskDate {
            let tasksForDay = tasksByDate[dateToCheck] ?? []
            if tasksForDay.contains(where: { $0.status == .completed }) {
                internalCurrentStreak += 1
                totalCompletedDays += 1
            } else {
                bestStreak = max(bestStreak, internalCurrentStreak)
                internalCurrentStreak = 0
            }
            // Move to the next day
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dateToCheck) else { break }
            dateToCheck = nextDay
            
            // Don't go beyond today when calculating streaks
            if dateToCheck > today {
                break
            }
        }
        bestStreak = max(bestStreak, internalCurrentStreak) // Final check for best streak

        // Calculate Current Streak by iterating backward from today
        dateToCheck = today
        currentStreak = 0 // Reset current streak before calculating
        while true {
            let tasksForDay = tasksByDate[dateToCheck] ?? []
            if tasksForDay.contains(where: { $0.status == .completed }) {
                currentStreak += 1
            } else {
                // If no tasks completed for this day, or no tasks exist, break streak
                break
            }
            
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: dateToCheck) else { break }
            // Stop if we go before the first task date found
            if previousDay < firstTaskDate { break }
            dateToCheck = previousDay
        }

        return StreakData(
            current: currentStreak,
            best: bestStreak,
            total: totalCompletedDays
        )
    }
    
    /// Calculate overall task completion data for the selected time frame.
    private func calculateOverallTaskCompletion(dailyTasks: [DailyTask], timeFrame: TimeFrame) -> [TaskCompletionData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate: Date

        // Determine the start date based on the selected time frame
        switch timeFrame {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        case .month:
            startDate = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        case .all:
            // Use the date of the earliest task or today if no tasks exist
            if let earliestDate = dailyTasks.map({ $0.date }).min() {
                startDate = calendar.startOfDay(for: earliestDate)
            } else {
                startDate = today
            }
        }
        let safeStartDate = calendar.startOfDay(for: startDate)

        // Generate all dates within the calculated range [startDate, today]
        var dateRange: [Date] = []
        var currentDate = safeStartDate
        while currentDate <= today {
            dateRange.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        // Group tasks by date for efficient lookup within the relevant range
        let tasksByDate = Dictionary(grouping: dailyTasks) { calendar.startOfDay(for: $0.date) }

        // Create data points for each day in the generated date range
        let completionData = dateRange.map { date -> TaskCompletionData in
            let dayTasks = tasksByDate[date] ?? [] // Get tasks for the specific day
            let total = dayTasks.count
            let completed = dayTasks.filter { $0.status == .completed }.count
            let completionRate = total > 0 ? (Double(completed) / Double(total)) * 100 : 0

            return TaskCompletionData(
                date: date,
                total: total,
                completed: completed,
                missed: total - completed, // Calculate missed tasks for the day
                completionRate: completionRate
            )
        }

        return completionData
    }
    
    /// Helper to get a color for a challenge type (replace potential missing `colorGradient`)
    private func getColorForChallenge(_ challenge: Challenge) -> Color {
        // Use the existing logic or adapt as needed
        switch challenge.type {
        case .seventyFiveHard:
            return .blue
        case .waterFasting:
            return Color(hex: "00C7BE")
        case .thirtyOneModified:
            return .purple
        case .custom:
            return DesignSystem.Colors.primaryAction
        // Add default or handle other cases if necessary
        }
    }
    
    func rotateDevice() {
        isLandscape.toggle()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let orientationMask: UIInterfaceOrientationMask = isLandscape ? .landscape : .portrait
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientationMask)) { error in
                Logger.error("Failed to rotate device: \(error.localizedDescription)", category: .app)
            }
        }
    }
}

// MARK: - Detailed Stats View

struct DetailedStatsView: View {
    let taskCompletionData: [TaskCompletionData]
    let streakData: StreakData
    @Binding var timeFrame: ProgressTrackingView.TimeFrame
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLandscape: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Time frame selector
                    Picker("Time Frame", selection: $timeFrame) {
                        ForEach(ProgressTrackingView.TimeFrame.allCases) { timeFrame in
                            Text(timeFrame.rawValue).tag(timeFrame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if isLandscape {
                        landscapeLayout
                    } else {
                        portraitLayout
                    }
                }
                .padding(.vertical)
                .navigationTitle("Detailed Statistics")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            rotateDevice()
                        }) {
                            Image(systemName: isLandscape ? "rectangle.portrait.rotate" : "rectangle.landscape.rotate")
                                .font(.system(size: 20))
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .onAppear {
                    // Check the current interface orientation when view appears
                    updateOrientationState()
                }
                // Listen to windowScene size changes
                .onChange(of: UIScreen.main.bounds.size) { oldValue, newValue in
                    updateOrientationState()
                }
            }
        }
    }
    
    private func updateOrientationState() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            isLandscape = windowScene.interfaceOrientation.isLandscape
        }
    }
    
    private func rotateDevice() {
        isLandscape.toggle()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let orientationMask: UIInterfaceOrientationMask = isLandscape ? .landscape : .portrait
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientationMask)) { error in
                Logger.error("Failed to rotate device: \(error.localizedDescription)", category: .app)
            }
        }
    }
    
    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                streakInfoCard
                
                completionTrendChart
                
                taskCompletionByDayChart
            }
            .padding(.horizontal)
        }
    }
    
    private var landscapeLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(alignment: .top, spacing: 16) {
                    streakInfoCard
                        .frame(width: 340)
                    
                    VStack(spacing: 24) {
                        completionTrendChart
                            .frame(height: 300)
                            
                        taskCompletionByDayChart
                            .frame(height: 300)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var streakInfoCard: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Activity Streak")
                    .font(DesignSystem.Typography.headline)
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .center, spacing: 4) {
                            Text("Current Streak")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(streakData.current)")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                Text(streakData.current == 1 ? "day" : "days")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 50)
                        
                        VStack(alignment: .center, spacing: 4) {
                            Text("Best Streak")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(streakData.best)")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                Text(streakData.best == 1 ? "day" : "days")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Perfect Days")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(streakData.total)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("total")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Text("A perfect day is one where you completed at least one task. Your current streak shows consecutive perfect days up to today.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    private var completionTrendChart: some View {
        Chart {
            ForEach(taskCompletionData, id: \.date) { day in
                AreaMark(
                    x: .value("Date", day.date),
                    y: .value("Completion Rate", day.completionRate)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.primaryAction,
                            DesignSystem.Colors.primaryAction.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("Date", day.date),
                    y: .value("Completion Rate", day.completionRate)
                )
                .foregroundStyle(DesignSystem.Colors.primaryAction)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", day.date),
                    y: .value("Completion Rate", day.completionRate)
                )
                .foregroundStyle(Color.white)
                .symbolSize(day.completionRate > 0 ? 50 : 0)
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: timeFrame == .week ? 1 : 7)) { date in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartLegend(.hidden)
        .frame(height: 250)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            VStack(alignment: .leading) {
                Text("Completion Rate")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Percentage of completed tasks by day")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        )
        .padding(.bottom, 40)
    }
    
    private var taskCompletionByDayChart: some View {
        Chart {
            ForEach(taskCompletionData, id: \.date) { day in
                if day.total > 0 {
                    BarMark(
                        x: .value("Date", day.date),
                        y: .value("Tasks", day.completed)
                    )
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
                    
                    BarMark(
                        x: .value("Date", day.date),
                        y: .value("Tasks", day.missed)
                    )
                    .foregroundStyle(DesignSystem.Colors.neonOrange)
                    .position(by: .value("Type", "Missed"))
                }
            }
        }
        .chartForegroundStyleScale(range: [DesignSystem.Colors.neonGreen, DesignSystem.Colors.neonOrange])
        .chartLegend(position: .top)
        .chartXAxis {
            AxisMarks(values: .stride(by: timeFrame == .week ? 1 : 7)) { date in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .frame(height: 250)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            VStack(alignment: .leading) {
                Text("Task Completion")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Tasks completed vs. missed by day")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        )
        .padding(.bottom, 40)
    }
}

// MARK: - Preview

#Preview {
    // Create a view with configured data for preview
    let view = ProgressTrackingView()
        .modelContainer(for: [Challenge.self, Task.self, DailyTask.self], inMemory: true)
        .environmentObject(UserSettings())
    
    // Return the view
    return view
} 