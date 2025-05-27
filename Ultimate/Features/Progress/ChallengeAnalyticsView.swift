import SwiftUI
import SwiftData
import Charts

// MARK: - Main View

struct ChallengeAnalyticsView: View {
    // MARK: - Properties
    let challenge: Challenge
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allDailyTasks: [DailyTask]
    
    private var challengeTasks: [DailyTask] {
        allDailyTasks.filter { $0.task?.challenge?.id == challenge.id }
    }
    
    @State private var taskCompletionByDay: [TaskCompletionData] = []
    @State private var taskCompletionByType: [TaskTypeData] = []
    @State private var streakData: StreakData = StreakData(current: 0, best: 0, total: 0)
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        challengeSummaryCard
                        
                        consistencyScoreCard
                        
                        streakCard
                        
                        completionTrendChart
                        
                        taskTypeBreakdownChart
                        
                        dailyPerformanceChart
                    }
                    .padding()
                }
                .background(DesignSystem.Colors.background)
                .navigationTitle("\(challenge.name) Analytics")
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
            }
        }
    }
    
    // MARK: - View Components
    
    /// Challenge summary card
    private var challengeSummaryCard: some View {
        CTCard(style: .glass) {
            VStack(spacing: DesignSystem.Spacing.m) {
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
                        color: getColorForChallenge(challenge),
                        lineWidth: 10,
                        size: 100
                    )
                }
                
                Divider()
                
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
    
    /// Consistency score card
    private var consistencyScoreCard: some View {
        let consistencyScore = calculateConsistencyScore(completionData: taskCompletionByDay, streakData: streakData)
        
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
                        .animation(.easeOut(duration: 0.8), value: consistencyScore)
                    
                    VStack(spacing: DesignSystem.Spacing.xxs) {
                        Text("\(Int(consistencyScore.rounded()))")
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
    
    /// Streak card
    private var streakCard: some View {
        CTCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Streak Information")
                    .font(DesignSystem.Typography.headline)
                
                HStack(spacing: DesignSystem.Spacing.xl) {
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
                Text("Streak counts consecutive days with *all* tasks completed for this challenge.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    /// Completion trend chart
    private var completionTrendChart: some View {
        CTProgressChart(
            data: taskCompletionByDay.map { day in
                ProgressDataPoint(
                    date: day.date,
                    value: day.completionRate,
                    targetValue: 100,
                    category: "Rate"
                )
            },
            chartType: .area,
            title: "Completion Trend",
            subtitle: "Daily completion rate (%) for this challenge"
        )
    }
    
    /// Task type breakdown chart
    private var taskTypeBreakdownChart: some View {
        let filteredData = taskCompletionByType.filter { $0.completed > 0 }
        
        return Group {
             if filteredData.isEmpty {
                 CTCard(style: .bordered) {
                     Text("No tasks completed yet to show breakdown.")
                         .font(.caption)
                         .foregroundColor(.secondary)
                         .padding()
                         .frame(maxWidth: .infinity, alignment: .center)
                 }
             } else {
                 CTProgressChart(
                     data: filteredData.map { typeData in
                         ProgressDataPoint(
                             date: Date(),
                             value: Double(typeData.completed),
                             category: typeData.type.rawValue.capitalized
                         )
                     },
                     chartType: .pie,
                     title: "Task Breakdown",
                     subtitle: "Total tasks completed by type for this challenge"
                 )
            }
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
            subtitle: "Tasks completed vs. total scheduled per day"
        )
    }
    
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
        let startDate = challenge.startDate ?? today
        let endDate = challenge.endDate ?? today
        
        var completionData: [TaskCompletionData] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayTasks = challengeTasks.filter { task in
                calendar.isDate(task.date, inSameDayAs: currentDate)
            }
            
            let total = dayTasks.count
            let completed = dayTasks.filter { $0.status == .completed }.count
            let completionRate = total > 0 ? Double(completed) / Double(total) * 100 : 0
            
            if total > 0 || (currentDate >= startDate && currentDate <= endDate) {
                completionData.append(
                    TaskCompletionData(
                        date: currentDate,
                        total: total,
                        completed: completed,
                        missed: total - completed,
                        completionRate: completionRate
                    )
                )
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
            if currentDate > today && challenge.status == .inProgress { break }
        }
        
        taskCompletionByDay = completionData
    }
    
    /// Loads task completion data by type
    private func loadTaskCompletionByType() {
        var typeData: [TaskType: (total: Int, completed: Int)] = [:]
        
        for dailyTask in challengeTasks {
            if let taskType = dailyTask.task?.type {
                let currentData = typeData[taskType] ?? (total: 0, completed: 0)
                let newCompleted = dailyTask.status == .completed ? currentData.completed + 1 : currentData.completed
                
                typeData[taskType] = (total: currentData.total + 1, completed: newCompleted)
            }
        }
        
        taskCompletionByType = typeData.map { type, data in
            TaskTypeData(
                type: type,
                total: data.total,
                completed: data.completed
            )
        }.sorted { $0.completed > $1.completed }
    }
    
    /// Loads streak data
    private func loadStreakData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var tasksByDate: [Date: [DailyTask]] = [:]
        for task in challengeTasks {
            let startOfDay = calendar.startOfDay(for: task.date)
            tasksByDate[startOfDay, default: []].append(task)
        }
        
        let challengeStartDate = calendar.startOfDay(for: challenge.startDate ?? Date())
        let challengeEndDate = calendar.startOfDay(for: challenge.endDate ?? Date())
        
        var perfectDays: [Date] = []
        var currentStreakDate = today
        var currentStreak = 0
        var bestStreak = 0
        var currentBestStreakInternal = 0
        
        while currentStreakDate >= challengeStartDate {
            let dayTasks = tasksByDate[currentStreakDate] ?? []
            if !dayTasks.isEmpty && dayTasks.allSatisfy({ $0.status == .completed }) {
                currentStreak += 1
                perfectDays.append(currentStreakDate)
            } else if !dayTasks.isEmpty {
                break
            }
            
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentStreakDate) else { break }
            currentStreakDate = previousDay
        }
        
        let sortedDates = tasksByDate.keys.filter { $0 >= challengeStartDate && $0 <= challengeEndDate }.sorted()
        
        for date in sortedDates {
            let dayTasks = tasksByDate[date] ?? []
            if !dayTasks.isEmpty && dayTasks.allSatisfy({ $0.status == .completed }) {
                currentBestStreakInternal += 1
            } else if !dayTasks.isEmpty {
                bestStreak = max(bestStreak, currentBestStreakInternal)
                currentBestStreakInternal = 0
            }
        }
        bestStreak = max(bestStreak, currentBestStreakInternal)
        
        streakData = StreakData(
            current: currentStreak,
            best: bestStreak,
            total: perfectDays.count
        )
    }
    
    /// Calculates consistency score (0-100)
    private func calculateConsistencyScore(completionData: [TaskCompletionData], streakData: StreakData) -> Double {
        let relevantDays = completionData.filter { $0.total > 0 }
        guard !relevantDays.isEmpty else { return 0 }

        let totalCompletionRate = relevantDays.reduce(0) { $0 + $1.completionRate }
        let averageCompletionRate = totalCompletionRate / Double(relevantDays.count)
        
        let streakRatio = Double(streakData.best) / Double(challenge.durationInDays)
        let streakFactor = min(streakRatio * 25, 25)
        
        let mean = averageCompletionRate
        let sumOfSquaredDifferences = relevantDays.reduce(0) { $0 + pow($1.completionRate - mean, 2) }
        let variance = sumOfSquaredDifferences / Double(relevantDays.count)
        let standardDeviation = sqrt(variance)
        let consistencyFactor = max(0, 25 - (standardDeviation / 2))
        
        let baseScore = averageCompletionRate * 0.5
        
        let score = baseScore + streakFactor + consistencyFactor
        return min(max(score, 0), 100)
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
            return "Keep going! Building habits takes time. Focus on completing tasks daily."
        } else if score < 70 {
            return "Good effort! You're developing consistency. Try to maintain your streaks."
        } else if score < 90 {
            return "Great consistency! You're showing strong dedication to the challenge."
        } else {
            return "Excellent! Your consistency is top-notch. Keep up the amazing work!"
        }
    }
    
    /// Helper to get a color for a challenge type
    private func getColorForChallenge(_ challenge: Challenge) -> Color {
        switch challenge.type {
        case .seventyFiveHard:
            return .blue
        case .waterFasting:
            return Color(hex: "00C7BE")
        case .thirtyOneModified:
            return .purple
        case .custom:
            return DesignSystem.Colors.primaryAction
        }
    }
}

// MARK: - Supporting Types

/// Data structure for task completion by day

/// Data structure for task completion by type
struct TaskTypeData {
    let type: TaskType
    let total: Int
    let completed: Int
}

/// Data structure for streak information

// MARK: - Preview

#Preview {
    // Create a sample challenge for preview
    let sampleChallenge = Challenge(
        type: .seventyFiveHard,
        name: "75 Hard Preview",
        challengeDescription: "Previewing analytics for 75 Hard.",
        startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
        durationInDays: 75
    )
    
    // Return the view
    ChallengeAnalyticsView(challenge: sampleChallenge)
        .modelContainer(for: [Challenge.self, Task.self, DailyTask.self], inMemory: true)
        .environmentObject(UserSettings())
} 