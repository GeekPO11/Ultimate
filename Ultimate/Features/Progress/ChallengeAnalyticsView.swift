import SwiftUI
import SwiftData
import Charts

struct ChallengeAnalyticsView: View {
    // MARK: - Properties
    let challenge: Challenge
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var dailyTasks: [DailyTask]
    
    @State private var selectedTimeFrame: TimeFrame = .all
    @State private var taskCompletionByDay: [TaskCompletionData] = []
    @State private var taskCompletionByType: [TaskTypeData] = []
    @State private var streakData: StreakData = StreakData(current: 0, best: 0, total: 0)
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case all = "All"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium animated background
                PremiumBackground()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        // Challenge summary card
                        challengeSummaryCard
                        
                        // Time frame selector
                        timeFrameSelector
                        
                        // Completion trend chart
                        completionTrendChart
                        
                        // Task completion by type
                        taskTypeBreakdownChart
                        
                        // Streak information
                        streakCard
                        
                        // Daily performance
                        dailyPerformanceChart
                        
                        // Consistency score
                        consistencyScoreCard
                    }
                    .padding()
                }
                .background(DesignSystem.Colors.background)
                .navigationTitle("Challenge Analytics")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    loadAnalyticsData()
                }
                .onChange(of: selectedTimeFrame) { _, _ in
                    loadAnalyticsData()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Challenge summary card
    private var challengeSummaryCard: some View {
        CTCard(style: .glass) {
            VStack(spacing: DesignSystem.Spacing.m) {
                // Header with progress ring
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text(challenge.name)
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                        
                        Text(challenge.description)
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    CTProgressRing(
                        progress: challenge.progress,
                        lineWidth: 10,
                        size: 80
                    )
                }
                
                Divider()
                
                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: DesignSystem.Spacing.m) {
                    statItem(
                        value: "\(challenge.currentDay)",
                        label: "Days In",
                        icon: "calendar"
                    )
                    
                    statItem(
                        value: "\(challenge.daysRemaining)",
                        label: "Days Left",
                        icon: "hourglass"
                    )
                    
                    statItem(
                        value: "\(Int(challenge.progress * 100))%",
                        label: "Complete",
                        icon: "chart.pie.fill"
                    )
                }
                
                // Date range
                if let startDate = challenge.startDate, let endDate = challenge.endDate {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Started")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text(startDate.formatted(date: .abbreviated, time: .omitted))
                                .font(DesignSystem.Typography.subheadline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Ends")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text(endDate.formatted(date: .abbreviated, time: .omitted))
                                .font(DesignSystem.Typography.subheadline)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.xs)
                }
            }
            .padding()
        }
    }
    
    /// Time frame selector
    private var timeFrameSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeFrame.allCases) { timeFrame in
                Button(action: {
                    selectedTimeFrame = timeFrame
                }) {
                    Text(timeFrame.rawValue)
                        .font(DesignSystem.Typography.subheadline)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .frame(maxWidth: .infinity)
                        .background(selectedTimeFrame == timeFrame ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.cardBackground)
                        .foregroundColor(selectedTimeFrame == timeFrame ? .white : DesignSystem.Colors.primaryText)
                }
            }
        }
        .cornerRadius(DesignSystem.BorderRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
        )
    }
    
    /// Completion trend chart
    private var completionTrendChart: some View {
        CTProgressChart(
            data: taskCompletionByDay.map { day in
                ProgressDataPoint(
                    date: day.date,
                    value: day.completionRate,
                    targetValue: 100
                )
            },
            chartType: .area,
            title: "Completion Trend",
            subtitle: "Daily completion rate"
        )
    }
    
    /// Task type breakdown chart
    private var taskTypeBreakdownChart: some View {
        CTProgressChart(
            data: taskCompletionByType.map { typeData in
                ProgressDataPoint(
                    date: Date(),
                    value: Double(typeData.completed),
                    category: typeData.type.rawValue.capitalized
                )
            },
            chartType: .pie,
            title: "Task Breakdown",
            subtitle: "Completion by task type"
        )
    }
    
    /// Streak card
    private var streakCard: some View {
        CTCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Streak Information")
                    .font(DesignSystem.Typography.headline)
                
                HStack(spacing: DesignSystem.Spacing.xl) {
                    // Current streak
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Current Streak")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(streakData.current)")
                                .font(DesignSystem.Typography.title2)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("days")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Best streak
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Best Streak")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(streakData.best)")
                                .font(DesignSystem.Typography.title2)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("days")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Perfect days
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Perfect Days")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(streakData.total)")
                                .font(DesignSystem.Typography.title2)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("total")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    /// Daily performance chart
    private var dailyPerformanceChart: some View {
        CTProgressChart(
            data: taskCompletionByDay.map { day in
                ProgressDataPoint(
                    date: day.date,
                    value: Double(day.completed),
                    targetValue: Double(day.total),
                    category: "Completed"
                )
            },
            chartType: .bar,
            title: "Daily Performance",
            subtitle: "Tasks completed each day"
        )
    }
    
    /// Consistency score card
    private var consistencyScoreCard: some View {
        let consistencyScore = calculateConsistencyScore()
        
        return CTCard(style: .gradient) {
            VStack(spacing: DesignSystem.Spacing.m) {
                Text("Consistency Score")
                    .font(DesignSystem.Typography.headline)
                
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.dividers, lineWidth: 15)
                        .opacity(0.3)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(consistencyScore) / 100)
                        .stroke(
                            consistencyScoreGradient(for: consistencyScore),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: DesignSystem.Spacing.xxs) {
                        Text("\(Int(consistencyScore))")
                            .font(.system(size: 40, weight: .bold))
                        
                        Text("out of 100")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                .frame(height: 180)
                .padding(.vertical, DesignSystem.Spacing.s)
                
                Text(consistencyScoreMessage(for: consistencyScore))
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    // MARK: - Helper Views
    
    /// Stat item for the summary card
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.primaryAction)
            
            Text(value)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Data Methods
    
    /// Loads all analytics data
    private func loadAnalyticsData() {
        loadTaskCompletionByDay()
        loadTaskCompletionByType()
        loadStreakData()
    }
    
    /// Loads task completion data by day
    private func loadTaskCompletionByDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Determine start date based on time frame
        let startDate: Date
        switch selectedTimeFrame {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        case .month:
            startDate = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        case .all:
            startDate = challenge.startDate ?? calendar.date(byAdding: .day, value: -29, to: today) ?? today
        }
        
        var completionData: [TaskCompletionData] = []
        var currentDate = startDate
        
        while currentDate <= today {
            let dayTasks = dailyTasks.filter { task in
                if let challengeId = task.task?.challenge?.id {
                    return calendar.isDate(task.date, inSameDayAs: currentDate) && challengeId == challenge.id
                }
                return false
            }
            
            let total = dayTasks.count
            let completed = dayTasks.filter { $0.status == .completed }.count
            let completionRate = total > 0 ? Double(completed) / Double(total) * 100 : 0
            
            completionData.append(
                TaskCompletionData(
                    date: currentDate,
                    total: total,
                    completed: completed,
                    missed: total - completed,
                    completionRate: completionRate
                )
            )
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        taskCompletionByDay = completionData
    }
    
    /// Loads task completion data by type
    private func loadTaskCompletionByType() {
        var typeData: [TaskType: (total: Int, completed: Int)] = [:]
        
        // Get all daily tasks for this challenge
        let challengeTasks = dailyTasks.filter { task in
            task.task?.challenge?.id == challenge.id
        }
        
        // Group by task type
        for dailyTask in challengeTasks {
            if let taskType = dailyTask.task?.type {
                let currentData = typeData[taskType] ?? (total: 0, completed: 0)
                let newCompleted = dailyTask.status == .completed ? currentData.completed + 1 : currentData.completed
                
                typeData[taskType] = (total: currentData.total + 1, completed: newCompleted)
            }
        }
        
        // Convert to array
        taskCompletionByType = typeData.map { type, data in
            TaskTypeData(
                type: type,
                total: data.total,
                completed: data.completed
            )
        }
    }
    
    /// Loads streak data
    private func loadStreakData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all daily tasks for this challenge
        let challengeTasks = dailyTasks.filter { task in
            task.task?.challenge?.id == challenge.id
        }
        
        // Group tasks by date
        var tasksByDate: [Date: [DailyTask]] = [:]
        for task in challengeTasks {
            let startOfDay = calendar.startOfDay(for: task.date)
            var tasks = tasksByDate[startOfDay] ?? []
            tasks.append(task)
            tasksByDate[startOfDay] = tasks
        }
        
        // Calculate perfect days (all tasks completed)
        var perfectDays: [Date] = []
        for (date, tasks) in tasksByDate {
            let allCompleted = tasks.allSatisfy { $0.status == .completed }
            if allCompleted && !tasks.isEmpty {
                perfectDays.append(date)
            }
        }
        
        // Calculate current streak
        var currentStreak = 0
        var currentDate = today
        
        while true {
            let dayTasks = tasksByDate[currentDate] ?? []
            
            // If no tasks for this day or not all completed, break
            if dayTasks.isEmpty || !dayTasks.allSatisfy({ $0.status == .completed }) {
                break
            }
            
            currentStreak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        // Calculate best streak
        var bestStreak = 0
        var currentBestStreak = 0
        
        // Sort dates in ascending order
        let sortedDates = perfectDays.sorted()
        
        for i in 0..<sortedDates.count {
            if i == 0 {
                currentBestStreak = 1
            } else {
                let previousDate = sortedDates[i-1]
                let currentDate = sortedDates[i]
                
                // Check if dates are consecutive
                let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
                
                if daysBetween == 1 {
                    currentBestStreak += 1
                } else {
                    currentBestStreak = 1
                }
            }
            
            bestStreak = max(bestStreak, currentBestStreak)
        }
        
        streakData = StreakData(
            current: currentStreak,
            best: bestStreak,
            total: perfectDays.count
        )
    }
    
    /// Calculates consistency score (0-100)
    private func calculateConsistencyScore() -> Double {
        // If no data, return 0
        if taskCompletionByDay.isEmpty {
            return 0
        }
        
        // Calculate average completion rate
        let totalCompletionRate = taskCompletionByDay.reduce(0) { $0 + $1.completionRate }
        let averageCompletionRate = totalCompletionRate / Double(taskCompletionByDay.count)
        
        // Calculate streak factor (0-20 points)
        let streakFactor = min(Double(streakData.current) / Double(challenge.durationInDays) * 20, 20)
        
        // Calculate consistency factor (0-30 points)
        // Lower standard deviation means more consistent performance
        let mean = averageCompletionRate
        let sumOfSquaredDifferences = taskCompletionByDay.reduce(0) { $0 + pow($1.completionRate - mean, 2) }
        let standardDeviation = sqrt(sumOfSquaredDifferences / Double(taskCompletionByDay.count))
        let normalizedStdDev = min(standardDeviation / 100, 1) // Normalize to 0-1
        let consistencyFactor = 30 * (1 - normalizedStdDev)
        
        // Base score from average completion (0-50 points)
        let baseScore = averageCompletionRate * 0.5
        
        // Combine factors
        let score = baseScore + streakFactor + consistencyFactor
        
        return min(score, 100) // Cap at 100
    }
    
    /// Returns gradient for consistency score
    private func consistencyScoreGradient(for score: Double) -> LinearGradient {
        if score < 40 {
            return LinearGradient(
                gradient: Gradient(colors: [DesignSystem.Colors.accent, DesignSystem.Colors.neonOrange]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if score < 70 {
            return LinearGradient(
                gradient: Gradient(colors: [DesignSystem.Colors.neonOrange, DesignSystem.Colors.neonGreen]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [DesignSystem.Colors.neonGreen, DesignSystem.Colors.primaryAction]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    /// Returns message for consistency score
    private func consistencyScoreMessage(for score: Double) -> String {
        if score < 40 {
            return "You're just getting started. Keep pushing to build consistency!"
        } else if score < 70 {
            return "Good progress! Your consistency is building. Focus on maintaining your streak."
        } else if score < 90 {
            return "Great work! You're showing strong consistency in your challenge."
        } else {
            return "Outstanding! Your dedication and consistency are exceptional."
        }
    }
}

// MARK: - Supporting Types

/// Data structure for task completion by day
struct TaskCompletionData {
    let date: Date
    let total: Int
    let completed: Int
    let missed: Int
    let completionRate: Double
}

/// Data structure for task completion by type
struct TaskTypeData {
    let type: TaskType
    let total: Int
    let completed: Int
}

/// Data structure for streak information
struct StreakData {
    let current: Int
    let best: Int
    let total: Int
}

// MARK: - Preview

#Preview {
    // Create a sample challenge for preview
    let challenge = Challenge(
        type: .custom,
        name: "Sample Challenge",
        challengeDescription: "A sample challenge for preview",
        durationInDays: 30
    )
    
    return ChallengeAnalyticsView(challenge: challenge)
        .modelContainer(for: [Challenge.self, Task.self, DailyTask.self], inMemory: true)
} 