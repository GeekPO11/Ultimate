import SwiftUI
import SwiftData
import Charts

struct ProgressTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Challenge.startDate) private var challenges: [Challenge]
    @Query(sort: \DailyTask.date) private var dailyTasks: [DailyTask]
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var showingAnalytics: Bool = false
    @State private var challengeForAnalytics: Challenge?
    
    // Progress tracking variables
    private var completedChallenges: Int {
        challenges.filter { $0.status == .completed }.count
    }
    
    private var activeChallengesCount: Int {
        challenges.filter { $0.status == .inProgress }.count
    }
    
    private var totalTasksCompleted: Int {
        dailyTasks.filter { $0.status == .completed }.count
    }
    
    private var overallProgress: Double {
        let totalChallenges = challenges.count
        if totalChallenges == 0 {
            return 0.0
        }
        
        let completedWeight = Double(completedChallenges) / Double(totalChallenges)
        let inProgressWeight = challenges.filter { $0.status == .inProgress }
            .reduce(0.0) { $0 + $1.progress } / Double(totalChallenges)
        
        return completedWeight + inProgressWeight
    }
    
    // Task data for charts
    private var filteredTaskData: [PTTaskCompletionData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var startDate: Date
        switch selectedTimeFrame {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: today) ?? today
        case .all:
            startDate = calendar.date(byAdding: .year, value: -1, to: today) ?? today
        }
        
        let filteredTasks = dailyTasks.filter { $0.date >= startDate && $0.date <= today }
        
        // Group by date and count completed tasks
        var tasksByDate: [Date: PTTaskCompletionData] = [:]
        
        for task in filteredTasks {
            let dateKey = calendar.startOfDay(for: task.date)
            
            if tasksByDate[dateKey] == nil {
                tasksByDate[dateKey] = PTTaskCompletionData(
                    date: dateKey,
                    completed: 0,
                    total: 0
                )
            }
            
            var data = tasksByDate[dateKey]!
            data.total += 1
            
            if task.status == .completed {
                data.completed += 1
            }
            
            tasksByDate[dateKey] = data
        }
        
        // Convert to array and sort by date
        return tasksByDate.values.sorted { $0.date < $1.date }
    }
    
    private var maxTaskCount: Int {
        let maxCompleted = filteredTaskData.map { $0.completed }.max() ?? 0
        let maxTotal = filteredTaskData.map { $0.total }.max() ?? 0
        return max(maxCompleted, maxTotal)
    }
    
    // Streak tracking
    private var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    private var longestStreak: Int {
        calculateLongestStreak()
    }
    
    // Get the active challenge (assuming only one is active at a time)
    private var activeChallenge: Challenge? {
        challenges.first(where: { $0.status == .inProgress })
    }
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case all = "All"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ZStack {
            // Premium animated background
            PremiumBackground()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    // Active challenge title
                    if let activeChallenge = activeChallenge {
                        Text(activeChallenge.name)
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    } else {
                        Text("No Active Challenge")
                            .font(DesignSystem.Typography.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                    
                    // Time frame selector
                    timeFrameSelector
                    
                    // Progress summary
                    if let activeChallenge = activeChallenge {
                        challengeProgressSummary(for: activeChallenge)
                            .onTapGesture {
                                challengeForAnalytics = activeChallenge
                                showingAnalytics = true
                            }
                    } else {
                        overallProgressSummary
                    }
                    
                    // Task completion chart
                    taskCompletionChart
                    
                    // New trend chart
                    trendChart
                    
                    // Streak tracking
                    streakTrackingCard
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(DesignSystem.Colors.background)
            .sheet(isPresented: $showingAnalytics) {
                if let challenge = challengeForAnalytics {
                    ChallengeAnalyticsView(challenge: challenge)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Time frame selector
    private var timeFrameSelector: some View {
        TimeFrameSelectorView(selectedTimeFrame: $selectedTimeFrame)
    }
    
    // Helper view for time frame selection
    private struct TimeFrameSelectorView: View {
        @Binding var selectedTimeFrame: TimeFrame
        
        var body: some View {
            HStack(spacing: 0) {
                ForEach(TimeFrame.allCases) { timeFrame in
                    Button(action: {
                        selectedTimeFrame = timeFrame
                    }) {
                        Text(timeFrame.rawValue)
                            .font(DesignSystem.Typography.subheadline)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .frame(maxWidth: .infinity)
                            .background(selectedTimeFrame == timeFrame ? 
                                DesignSystem.Colors.primaryAction : 
                                DesignSystem.Colors.cardBackground)
                            .foregroundColor(selectedTimeFrame == timeFrame ? 
                                .white : 
                                DesignSystem.Colors.primaryText)
                    }
                }
            }
            .cornerRadius(DesignSystem.BorderRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                    .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
            )
        }
    }
    
    /// Challenge progress summary
    private func challengeProgressSummary(for challenge: Challenge) -> some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(challenge.name)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Day \(challenge.currentDay) of \(challenge.durationInDays)")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    CTProgressRing(
                        progress: challenge.progress,
                        size: 60
                    )
                }
                
                let stats = getTaskCompletionStats(for: challenge)
                HStack(spacing: DesignSystem.Spacing.xl) {
                    // Completed tasks
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Completed")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("\(stats.completed)")
                            .font(DesignSystem.Typography.title3)
                    }
                    
                    // Total tasks
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Total Tasks")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("\(stats.total)")
                            .font(DesignSystem.Typography.title3)
                    }
                    
                    // Completion rate
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Completion")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("\(Int(stats.completionRate))%")
                            .font(DesignSystem.Typography.title3)
                    }
                }
                
                // Tap for analytics hint
                HStack {
                    Spacer()
                    
                    Text("Tap for detailed analytics")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.top, DesignSystem.Spacing.xxs)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .padding()
        }
    }
    
    /// Overall progress summary
    private var overallProgressSummary: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Overall Progress")
                    .font(DesignSystem.Typography.headline)
                
                HStack(spacing: DesignSystem.Spacing.xl) {
                    // Active challenges
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Active Challenges")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("\(challenges.filter { $0.status == .inProgress }.count)")
                            .font(DesignSystem.Typography.title2)
                    }
                    
                    // Completed challenges
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Completed")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("\(challenges.filter { $0.status == .completed }.count)")
                            .font(DesignSystem.Typography.title2)
                    }
                    
                    // Failed challenges
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Failed")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("\(challenges.filter { $0.status == .failed }.count)")
                            .font(DesignSystem.Typography.title2)
                    }
                }
                
                // Multi-ring progress
                if !challenges.filter({ $0.status == .inProgress }).isEmpty {
                    HStack {
                        Spacer()
                        
                        CTMultiProgressRing(rings: getMultiRingData())
                        
                        Spacer()
                    }
                    .padding(.top, DesignSystem.Spacing.s)
                }
            }
            .padding()
        }
    }
    
    /// Task completion chart
    private var taskCompletionChart: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Task Completion")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                CTProgressChart(
                    data: getChartData().map { item in
                        ProgressDataPoint(
                            date: item.date,
                            value: Double(item.completed),
                            targetValue: Double(item.completed + item.missed),
                            category: "Completed"
                        )
                    },
                    chartType: .bar,
                    title: "Task Completion",
                    subtitle: "Daily performance"
                )
            }
        }
    }
    
    /// Streak tracking card
    private var streakTrackingCard: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Current Streak")
                    .font(DesignSystem.Typography.headline)
                
                HStack(spacing: DesignSystem.Spacing.xl) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Days")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("\(getCurrentStreak())")
                            .font(DesignSystem.Typography.title1)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Best Streak")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("\(getBestStreak())")
                            .font(DesignSystem.Typography.title3)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Flame icon with streak
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primaryAction.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 30))
                            .foregroundColor(DesignSystem.Colors.primaryAction)
                    }
                }
            }
            .padding()
        }
    }
    
    /// New trend chart
    private var trendChart: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Progress Trend")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                CTProgressChart(
                    data: getTrendData(),
                    chartType: .line,
                    title: "Completion Trend",
                    subtitle: "Task completion over time"
                )
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate the current streak
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentDate = today
        var streak = 0
        
        while true {
            let tasksForDay = dailyTasks.filter { 
                calendar.isDate($0.date, inSameDayAs: currentDate)
            }
            
            if tasksForDay.isEmpty {
                // No tasks for this day, break the streak
                break
            }
            
            let allCompleted = tasksForDay.allSatisfy { $0.status == .completed }
            
            if !allCompleted {
                // Not all tasks completed, break the streak
                break
            }
            
            // Increment streak and move to previous day
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        return streak
    }
    
    /// Calculate the longest streak
    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        
        // Sort tasks by date
        let sortedTasks = dailyTasks.sorted { $0.date < $1.date }
        
        var longestStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for task in sortedTasks {
            let taskDate = calendar.startOfDay(for: task.date)
            
            // Group tasks by date
            if let lastDate = lastDate, !calendar.isDate(taskDate, inSameDayAs: lastDate) {
                // Check if all tasks for the previous day were completed
                let tasksForPreviousDay = dailyTasks.filter { 
                    calendar.isDate($0.date, inSameDayAs: lastDate)
                }
                
                let allCompleted = tasksForPreviousDay.allSatisfy { $0.status == .completed }
                
                if allCompleted {
                    currentStreak += 1
                    longestStreak = max(longestStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            }
            
            lastDate = taskDate
        }
        
        return longestStreak
    }
    
    // Helper methods for UI components
    private func getCurrentStreak() -> Int {
        return currentStreak
    }
    
    private func getBestStreak() -> Int {
        return longestStreak
    }
    
    private func getTaskCompletionStats(for challenge: Challenge) -> (completed: Int, total: Int, completionRate: Double) {
        let completedTasks = dailyTasks.filter { $0.challenge?.id == challenge.id && $0.status == .completed }.count
        let totalTasks = dailyTasks.filter { $0.challenge?.id == challenge.id }.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) * 100 : 0
        
        return (completed: completedTasks, total: totalTasks, completionRate: completionRate)
    }
    
    private func getMultiRingData() -> [CTMultiProgressRing.RingData] {
        return challenges.filter { $0.status == .inProgress }.map { challenge in
            CTMultiProgressRing.RingData(
                progress: challenge.progress,
                color: getColorForChallenge(challenge),
                title: challenge.name
            )
        }
    }
    
    private func getColorForChallenge(_ challenge: Challenge) -> Color {
        switch challenge.type {
        case .seventyFiveHard:
            return .blue
        case .waterFasting:
            return Color(hex: "00C7BE") // Teal
        case .thirtyOneModified:
            return .purple
        case .custom:
            return DesignSystem.Colors.primaryAction
        }
    }
    
    private func getChartData() -> [PTTaskCompletionData] {
        return filteredTaskData
    }
    
    private func getTrendData() -> [ProgressDataPoint] {
        return filteredTaskData.map { data in
            ProgressDataPoint(
                date: data.date,
                value: data.completionRate,
                targetValue: 1.0,
                category: "Completion Rate"
            )
        }
    }
}

// MARK: - Supporting Types

struct PTTaskCompletionData: Identifiable {
    var id = UUID()
    var date: Date
    var completed: Int
    var total: Int
    
    var completionRate: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }
    
    var missed: Int {
        total - completed
    }
    
    var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct PTProgressDataPoint: Identifiable {
    var id = UUID()
    var date: Date
    var value: Double
    var targetValue: Double
    var category: String
}

struct PTProgressRingData {
    var progress: Double
    var color: Color
    var thickness: CGFloat
}

// MARK: - Preview

#Preview {
    ProgressTrackingView()
        .modelContainer(for: [Challenge.self, Task.self, DailyTask.self], inMemory: true)
        .environmentObject(UserSettings())
} 