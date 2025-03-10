import SwiftUI
import SwiftData

// This file will be updated with proper implementation later
struct ChallengeDetailView: View {
    // MARK: - Properties
    var challenge: Challenge
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var dailyTasks: [DailyTask]
    
    @State private var selectedTab = 0
    @State private var showingStopConfirmation = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Premium animated background
                PremiumBackground()
                
                VStack(spacing: 0) {
                    // Content
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.l) {
                            // Challenge header
                            challengeHeaderView
                            
                            // Tab selector
                            tabSelector
                            
                            // Tab content
                            tabContent
                        }
                        .padding()
                    }
                }
                .background(DesignSystem.Colors.background)
                .navigationTitle(challenge.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if challenge.status == .inProgress {
                            Button(action: {
                                showingStopConfirmation = true
                            }) {
                                Image(systemName: "stop.circle")
                                    .foregroundColor(Color.red)
                                    .font(.system(size: 20))
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .alert("Stop Challenge", isPresented: $showingStopConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Stop Challenge", role: .destructive) {
                stopChallenge()
            }
        } message: {
            Text("Are you sure you want to stop this challenge? Your progress will be saved, but the challenge will be marked as failed.")
        }
    }
    
    // MARK: - View Components
    
    private var challengeHeaderView: some View {
        CTCard(style: .glass) {
            VStack(spacing: DesignSystem.Spacing.m) {
                // Challenge name and progress
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text(challenge.name)
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text(challenge.description)
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    CTProgressRing(
                        progress: challenge.progress,
                        lineWidth: 8,
                        size: 70
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
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Overview", index: 0)
            tabButton(title: "Tasks", index: 1)
            tabButton(title: "Analytics", index: 2)
        }
        .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
        .cornerRadius(DesignSystem.BorderRadius.medium)
    }
    
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case 0:
                overviewTab
            case 1:
                tasksTab
            case 2:
                analyticsTab
            default:
                EmptyView()
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Tab Contents
    
    private var overviewTab: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            // Challenge description
            CTCard(style: .glass) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    Text("About This Challenge")
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.bold)
                    
                    Text(challenge.description)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                .padding()
            }
            
            // Today's progress
            CTCard(style: .glass) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    Text("Today's Progress")
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.bold)
                    
                    let todaysTasks = dailyTasksForToday()
                    if todaysTasks.isEmpty {
                        Text("No tasks for today")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    } else {
                        let completed = todaysTasks.filter { $0.status == .completed }.count
                        let total = todaysTasks.count
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                            Text("\(completed)/\(total) tasks completed")
                                .font(DesignSystem.Typography.subheadline)
                            
                            ProgressView(value: Double(completed), total: Double(total))
                                .tint(DesignSystem.Colors.primaryAction)
                        }
                        
                        CTButton(
                            title: "View Today's Tasks",
                            icon: "list.bullet",
                            style: .neon,
                            customNeonColor: DesignSystem.Colors.neonBlue
                        ) {
                            // Navigate to today's tasks
                            NotificationCenter.default.post(name: Notification.Name("SwitchToTodayTab"), object: nil)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            
            // Action buttons
            if challenge.status == .inProgress {
                CTButton(
                    title: "View Analytics",
                    icon: "chart.bar.fill",
                    style: .neon,
                    customNeonColor: DesignSystem.Colors.neonPurple
                ) {
                    withAnimation {
                        selectedTab = 2
                    }
                }
            }
        }
    }
    
    private var tasksTab: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            ForEach(challenge.tasks) { task in
                taskCard(task)
            }
        }
    }
    
    private var analyticsTab: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            // Analytics preview
            CTCard(style: .glass) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    Text("Challenge Analytics")
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.bold)
                    
                    Text("View detailed analytics for your challenge progress")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    // Basic stats preview
                    HStack(spacing: DesignSystem.Spacing.xl) {
                        // Completion rate
                        let stats = getTaskCompletionStats()
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            Text("Completion Rate")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text("\(Int(stats.completionRate))%")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        
                        // Current streak
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            Text("Current Streak")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text("\(getCurrentStreak()) days")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, DesignSystem.Spacing.s)
                    
                    NavigationLink {
                        ChallengeAnalyticsView(challenge: challenge)
                    } label: {
                        HStack {
                            Text("View Full Analytics")
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                            
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 16))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .padding()
                        .background(DesignSystem.Colors.primaryAction.opacity(0.1))
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = index
            }
        }) {
            Text(title)
                .font(DesignSystem.Typography.subheadline)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .frame(maxWidth: .infinity)
                .background(selectedTab == index ? DesignSystem.Colors.primaryAction : Color.clear)
                .foregroundColor(selectedTab == index ? .white : DesignSystem.Colors.primaryText)
        }
    }
    
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
    
    private func taskCard(_ task: Task) -> some View {
        HStack(spacing: 16) {
            Image(systemName: task.type?.icon ?? "checkmark.circle")
                .font(.system(size: 24))
                .foregroundColor(task.type?.color ?? Color.gray)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(task.taskDescription)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
                
                Text(task.frequency.rawValue)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.secondaryText.opacity(0.1))
                    .cornerRadius(4)
                    .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding(16)
        .background(DesignSystem.Colors.cardBackground.opacity(0.7))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func dailyTasksForToday() -> [DailyTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return dailyTasks.filter { task in
            if let challengeId = task.challenge?.id {
                return calendar.isDate(task.date, inSameDayAs: today) && challengeId == challenge.id
            }
            return false
        }
    }
    
    private func stopChallenge() {
        // Mark the challenge as failed
        challenge.status = .failed
        challenge.endDate = Date()
        
        // Delete any daily tasks associated with this challenge
        let dailyTaskDescriptor = FetchDescriptor<DailyTask>()
        let allDailyTasks = SwiftDataErrorHandler.fetchEntities(
            modelContext: modelContext,
            fetchDescriptor: dailyTaskDescriptor,
            context: "ChallengeDetailView.stopChallenge - fetching daily tasks"
        )
        
        let challengeTasks = allDailyTasks.filter { $0.challenge?.id == challenge.id }
        for task in challengeTasks {
            modelContext.delete(task)
        }
        
        // Save changes
        if SwiftDataErrorHandler.saveContext(modelContext, context: "ChallengeDetailView.stopChallenge") {
            Logger.info("Challenge stopped successfully: \(challenge.name)", category: .challenges)
        } else {
            Logger.error("Error stopping challenge: \(challenge.name)", category: .challenges)
        }
        
        dismiss()
    }
    
    private func getTaskCompletionStats() -> (completed: Int, total: Int, completionRate: Double) {
        let completedTasks = dailyTasks.filter { $0.challenge?.id == challenge.id && $0.status == .completed }.count
        let totalTasks = dailyTasks.filter { $0.challenge?.id == challenge.id }.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) * 100 : 0
        
        return (completed: completedTasks, total: totalTasks, completionRate: completionRate)
    }
    
    private func getCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentDate = today
        var streak = 0
        
        while true {
            let tasksForDay = dailyTasks.filter { task in
                calendar.isDate(task.date, inSameDayAs: currentDate) && task.challenge?.id == challenge.id
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
}

// MARK: - Preview

#Preview {
    NavigationView {
        ChallengeDetailView(challenge: Challenge(
            type: .custom,
            name: "Sample Challenge",
            challengeDescription: "A sample challenge for preview",
            durationInDays: 30
        ))
        .modelContainer(for: [Challenge.self, Task.self, DailyTask.self], inMemory: true)
    }
}
