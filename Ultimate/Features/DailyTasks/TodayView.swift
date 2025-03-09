import SwiftUI
import SwiftData
import Foundation

/// The main view for displaying today's tasks and active challenges
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Use simple queries without predicates
    @Query private var allChallenges: [Challenge]
    @Query private var allDailyTasks: [DailyTask]
    @Query private var users: [User]
    
    // Define an enum to track which sheet is being presented
    enum SheetType: Identifiable {
        case addChallenge
        case taskDetail(DailyTask)
        case challengeDetail(Challenge)
        
        var id: String {
            switch self {
            case .addChallenge:
                return "addChallenge"
            case .taskDetail(let task):
                return "taskDetail-\(task.id)"
            case .challengeDetail(let challenge):
                return "challengeDetail-\(challenge.id)"
            }
        }
    }
    
    @State private var activeSheet: SheetType? = nil
    @State private var showingNoActiveChallengeAlert = false
    @State private var hasCheckedForActiveChallenges = false
    @State private var hasInitialized = false
    
    // Initialize tasksManager in onAppear using the environment's modelContext
    @State private var tasksManager: DailyTasksManager?
    
    // Computed property to get today's tasks
    var dailyTasks: [DailyTask] {
        let today = Calendar.current.startOfDay(for: Date())
        return allDailyTasks.filter { task in
            Calendar.current.isDate(task.date, inSameDayAs: today)
        }
    }
    
    // Computed property to get sorted daily tasks
    var sortedDailyTasks: [DailyTask] {
        dailyTasks.sorted { task1, task2 in
            if let time1 = task1.task?.scheduledTime, let time2 = task2.task?.scheduledTime {
                return time1 < time2
            } else if task1.task?.scheduledTime != nil {
                return true
            } else if task2.task?.scheduledTime != nil {
                return false
            } else {
                return task1.title < task2.title
            }
        }
    }
    
    // Computed property to get active challenges
    var activeChallenges: [Challenge] {
        allChallenges.filter { challenge in
            challenge.status == .inProgress
        }
    }
    
    // Computed property to get sorted active challenges
    var sortedActiveChallenges: [Challenge] {
        activeChallenges.sorted { challenge1, challenge2 in
            if let date1 = challenge1.startDate, let date2 = challenge2.startDate {
                return date1 > date2
            }
            return false
        }
    }
    
    var body: some View {
        ZStack {
            // Premium animated background
            PremiumBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with date and greeting
                    headerView
                    
                    // Daily progress summary
                    progressSummaryView
                    
                    // Active challenges section
                    if !sortedActiveChallenges.isEmpty {
                        activeChallengesSection
                    }
                    
                    // Today's tasks section
                    if !sortedDailyTasks.isEmpty {
                        todaysTasksSection
                    } else {
                        emptyTasksView
                    }
                    
                    // Add challenge button (if no active challenges)
                    if sortedActiveChallenges.isEmpty {
                        addChallengeButton
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .refreshable {
                generateTasksIfNeeded()
            }
            
            // Overlay for challenge details
            if case .challengeDetail(let challenge) = activeSheet {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Allow tapping outside to dismiss
                        withAnimation {
                            activeSheet = nil
                        }
                    }
                
                VStack(spacing: 0) {
                    // Navigation bar
                    HStack {
                        Text("Challenge Details")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                activeSheet = nil
                                
                                // Force refresh tasks after returning from challenge detail
                                if let tasksManager = tasksManager {
                                    let _ = tasksManager.generateDailyTasks()
                                }
                            }
                        } label: {
                            Text("Done")
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                        }
                    }
                    .padding()
                    .background(DesignSystem.Colors.cardBackground.opacity(0.95))
                    
                    // Content
                    ScrollView {
                        if challenge.tasks.isEmpty {
                            VStack {
                                ProgressView("Loading challenge details...")
                                    .padding()
                                Text("Please wait while we load the challenge data.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                            .padding()
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(16)
                            .padding()
                        } else {
                            ChallengeDetailSheet(challenge: challenge, onStart: {
                                // This is already an active challenge, so we don't need to start it
                            })
                            .padding()
                        }
                    }
                }
                .background(DesignSystem.Colors.background)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.vertical, 40)
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(100) // Ensure it's above other content
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet, content: { sheet in
            if case .addChallenge = sheet {
                NavigationView {
                    ChallengesView()
                        .navigationTitle("Add Challenge")
                        .navigationBarItems(trailing: Button("Done") {
                            activeSheet = nil
                        })
                }
            } else if case .taskDetail(let task) = sheet {
                NavigationView {
                    TaskDetailView(task: task, tasksManager: tasksManager)
                        .navigationTitle("Task Details")
                        .navigationBarItems(trailing: Button("Done") {
                            activeSheet = nil
                            // Update challenge progress when a task is updated
                            if let challengeID = task.challenge?.id,
                               let challenge = sortedActiveChallenges.first(where: { $0.id == challengeID }) {
                                tasksManager?.updateChallengeProgress(for: challenge)
                            }
                        })
                }
            }
        })
        .alert("No Active Challenge", isPresented: $showingNoActiveChallengeAlert) {
            Button("OK") {
                showingNoActiveChallengeAlert = false
            }
            Button("Add Challenge") {
                showingNoActiveChallengeAlert = false
                // Use a slight delay to prevent race conditions when dismissing the alert
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    activeSheet = .addChallenge
                }
            }
        } message: {
            Text("You don't have any active challenges. Add a challenge to start tracking your progress.")
        }
        .onAppear {
            Logger.info("TodayView appeared, initializing...", category: .tasks)
            
            if !hasInitialized {
                hasInitialized = true
                initializeTasksManager()
                
                // Add a slight delay to ensure tasksManager is initialized
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    generateTasksIfNeeded()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        MaterialCard(materialStyle: .ultraThin) {
            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(formattedDate)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var progressSummaryView: some View {
        VStack(spacing: 16) {
            Text("Daily Progress")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatItem(
                    value: "\(sortedDailyTasks.count)",
                    label: "Tasks",
                    icon: "checklist",
                    color: .blue
                )
                
                StatItem(
                    value: "\(sortedDailyTasks.filter { $0.status == .completed }.count)",
                    label: "Completed",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatItem(
                    value: "\(Int(overallProgress * 100))%",
                    label: "Progress",
                    icon: "chart.bar.fill",
                    color: DesignSystem.Colors.primaryAction
                )
            }
            .padding()
            .appleMaterial()
        }
    }
    
    private var activeChallengesSection: some View {
        VStack(spacing: 16) {
            Text("Active Challenges")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sortedActiveChallenges) { challenge in
                        Button {
                            // Log challenge details before showing sheet
                            print("TodayView: Challenge selected - \(challenge.name)")
                            print("TodayView: Challenge ID - \(challenge.id)")
                            print("TodayView: Challenge has \(challenge.tasks.count) tasks")
                            
                            // Use withAnimation to show the challenge detail overlay
                            withAnimation(.easeInOut(duration: 0.3)) {
                                activeSheet = .challengeDetail(challenge)
                            }
                        } label: {
                            ChallengeItem(
                                title: challenge.name,
                                progress: challenge.progress,
                                icon: iconForChallenge(challenge),
                                color: colorForChallenge(challenge)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var todaysTasksSection: some View {
        VStack(spacing: 16) {
            Text("Today's Tasks")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(sortedDailyTasks) { task in
                CTTaskCard(
                    title: task.title,
                    time: formattedTime(for: task),
                    isCompleted: task.status == .completed,
                    taskType: task.task?.type,
                    onToggle: {
                        toggleTaskCompletion(task)
                    },
                    onTap: {
                        activeSheet = .taskDetail(task)
                    }
                )
            }
        }
    }
    
    private var emptyTasksView: some View {
        MaterialCard(materialStyle: .thin) {
            VStack(spacing: 16) {
                Text("No Tasks for Today")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Tasks will be generated based on your active challenges.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }
    
    private var addChallengeButton: some View {
        CTButton(
            title: "Add Challenge",
            icon: "plus.circle.fill",
            style: .neon,
            size: .large,
            customNeonColor: DesignSystem.Colors.neonGreen
        ) {
            // Instead of posting a notification, directly set the activeSheet
            activeSheet = .addChallenge
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeTasksManager() {
        tasksManager = DailyTasksManager(modelContext: modelContext)
    }
    
    private func generateTasksIfNeeded() {
        guard let tasksManager = tasksManager else {
            Logger.warning("TasksManager not initialized", category: .tasks)
            return
        }
        
        // Check if we have active challenges
        if !hasCheckedForActiveChallenges {
            hasCheckedForActiveChallenges = true
            
            // Don't show the alert when the app starts for the first time
            // Only generate tasks if there are active challenges
            if !activeChallenges.isEmpty {
                // Generate tasks for today
                let _ = tasksManager.generateDailyTasks()
            }
            return
        }
        
        // Generate tasks for today
        let _ = tasksManager.generateDailyTasks()
    }
    
    // MARK: - Computed Properties
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let userName = users.first?.name ?? ""
        
        let timeGreeting: String
        if hour < 12 {
            timeGreeting = "Good Morning"
        } else if hour < 17 {
            timeGreeting = "Good Afternoon"
        } else {
            timeGreeting = "Good Evening"
        }
        
        // Add the user's name if available
        if !userName.isEmpty {
            return "\(timeGreeting), \(userName)"
        } else {
            return timeGreeting
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    private var overallProgress: Double {
        let completedTasks = sortedDailyTasks.filter { $0.status == .completed }.count
        let totalTasks = sortedDailyTasks.count
        
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    private func statusText(for task: DailyTask) -> String {
        switch task.status {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .missed:
            return "Missed"
        case .failed:
            return "Failed"
        }
    }
    
    private func statusColor(for task: DailyTask) -> Color {
        switch task.status {
        case .notStarted:
            return DesignSystem.Colors.secondaryText
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .missed:
            return .yellow
        }
    }
    
    // MARK: - Task Management Methods
    
    /// Toggles the completion status of a task
    private func toggleTaskCompletion(_ task: DailyTask) {
        guard let tasksManager = tasksManager else { return }
        
        if task.status == .completed {
            tasksManager.resetTask(task)
        } else {
            tasksManager.completeTask(task)
        }
        
        // Update challenge progress
        if let challenge = task.challenge {
            tasksManager.updateChallengeProgress(for: challenge)
        }
    }
    
    /// Marks a task as not started
    private func markTaskNotStarted(_ task: DailyTask) {
        guard let tasksManager = tasksManager else { return }
        tasksManager.resetTask(task)
        
        // Update challenge progress
        if let challenge = task.challenge {
            tasksManager.updateChallengeProgress(for: challenge)
        }
    }
    
    /// Marks a task as in progress
    private func markTaskInProgress(_ task: DailyTask) {
        guard let tasksManager = tasksManager else { return }
        tasksManager.markTaskInProgress(task)
        
        // Update challenge progress
        if let challenge = task.challenge {
            tasksManager.updateChallengeProgress(for: challenge)
        }
    }
    
    /// Marks a task as completed
    private func markTaskCompleted(_ task: DailyTask) {
        guard let tasksManager = tasksManager else { return }
        tasksManager.completeTask(task)
        
        // Update challenge progress
        if let challenge = task.challenge {
            tasksManager.updateChallengeProgress(for: challenge)
        }
    }
    
    /// Marks a task as failed
    private func markTaskFailed(_ task: DailyTask) {
        guard let tasksManager = tasksManager else { return }
        tasksManager.markTaskFailed(task)
        
        // Update challenge progress
        if let challenge = task.challenge {
            tasksManager.updateChallengeProgress(for: challenge)
        }
    }
    
    // Helper function to format time for tasks
    private func formattedTime(for task: DailyTask) -> String {
        if let scheduledTime = task.task?.scheduledTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: scheduledTime)
        }
        return ""
    }
    
    // Helper function to determine icon for challenge
    private func iconForChallenge(_ challenge: Challenge) -> String {
        switch challenge.type {
        case .seventyFiveHard:
            return "figure.run"
        case .waterFasting:
            return "drop.fill"
        case .thirtyOneModified:
            return "brain.head.profile"
        case .custom:
            return "star.fill"
        }
    }
    
    // Helper function to determine color for challenge
    private func colorForChallenge(_ challenge: Challenge) -> Color {
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
}

// Preview provider for TodayView
struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView()
            .modelContainer(for: [Challenge.self, DailyTask.self, Task.self])
    }
}

// MARK: - TaskDetailView
struct TaskDetailView: View {
    let task: DailyTask
    let tasksManager: DailyTasksManager?
    
    @State private var notes: String = ""
    @State private var actualValue: String = ""
    @State private var showingConfirmation = false
    @State private var showingSaveConfirmation = false
    @State private var showingWaterTracker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Task header
                taskHeaderSection
                
                // Water tracking button for water tasks
                if let taskObj = task.task, taskObj.type == .water {
                    waterTrackingSection
                }
                
                // Task details
                taskDetailsSection
                
                // Task status
                taskStatusSection
                
                // Notes section
                notesSection
                
                // Action buttons
                actionButtonsSection
            }
            .padding()
            .overlay(
                // Save confirmation toast
                ZStack {
                    if showingSaveConfirmation {
                        VStack {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Notes saved")
                                    .font(DesignSystem.Typography.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
                .animation(.easeInOut, value: showingSaveConfirmation)
            )
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .onAppear {
            // Initialize notes from task if available
            notes = task.notes ?? ""
            
            // Initialize actual value if available
            if let value = task.actualValue {
                actualValue = String(format: "%.1f", value)
            }
        }
        .alert(isPresented: $showingConfirmation) {
            Alert(
                title: Text("Confirm Status Change"),
                message: Text("Are you sure you want to mark this task as \(statusActionText)?"),
                primaryButton: .default(Text("Yes")) {
                    updateTaskStatus()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showingWaterTracker) {
            if let tasksManager = tasksManager {
                WaterTrackingView(dailyTask: task, tasksManager: tasksManager)
            }
        }
    }
    
    // MARK: - View Components
    
    // Water tracking section for water-type tasks
    private var waterTrackingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Water Tracking")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Button {
                showingWaterTracker = true
            } label: {
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("Track Glass by Glass")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color.blue)
                .cornerRadius(DesignSystem.BorderRadius.medium)
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.BorderRadius.medium)
    }
    
    private var taskHeaderSection: some View {
        VStack(spacing: 16) {
            // Task icon
            if let taskType = task.task?.type {
                Image(systemName: taskType.icon)
                    .font(.system(size: 48))
                    .foregroundColor(taskType.color)
                    .frame(width: 80, height: 80)
                    .background(taskType.color.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Task title
            Text(task.title)
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .multilineTextAlignment(.center)
            
            // Task status
            HStack {
                Text(statusText(for: task))
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor(for: task))
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.BorderRadius.medium)
    }
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: 12) {
                // Challenge
                if let challenge = task.challenge {
                    detailRow(label: "Challenge", value: challenge.name)
                    Divider()
                }
                
                // Date
                detailRow(label: "Date", value: formattedDate(task.date))
                Divider()
                
                // Scheduled time
                if let taskObj = task.task, let scheduledTime = taskObj.scheduledTime {
                    detailRow(label: "Scheduled Time", value: formattedTime(scheduledTime))
                    Divider()
                }
                
                // Target value
                if let taskObj = task.task, let targetValue = taskObj.targetValue, let targetUnit = taskObj.targetUnit {
                    detailRow(label: "Target", value: "\(targetValue) \(targetUnit)")
                    Divider()
                }
                
                // Completion time
                if let completionTime = task.completionTime {
                    detailRow(label: "Completed At", value: formattedTime(completionTime))
                }
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.BorderRadius.medium)
        }
    }
    
    private var taskStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Update Status")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            HStack(spacing: 12) {
                statusButton(status: .notStarted, icon: "circle", label: "Not Started")
                statusButton(status: .inProgress, icon: "clock", label: "In Progress")
                statusButton(status: .completed, icon: "checkmark.circle", label: "Completed")
                statusButton(status: .failed, icon: "xmark.circle", label: "Failed")
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.BorderRadius.medium)
            
            // Actual value field (if task has a target)
            if let taskObj = task.task, taskObj.targetValue != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Actual Value")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    TextField("Enter actual value", text: $actualValue)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding()
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.BorderRadius.medium)
                .submitLabel(.done)
                .onSubmit {
                    saveNotes()
                }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button {
                saveNotes()
            } label: {
                Text("Save Notes")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.primaryAction)
                    .cornerRadius(DesignSystem.BorderRadius.medium)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
    }
    
    private func statusButton(status: TaskCompletionStatus, icon: String, label: String) -> some View {
        Button {
            if task.status != status {
                // Set the status we want to change to
                selectedStatus = status
                showingConfirmation = true
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(task.status == status ? .white : statusColorForType(status))
                
                Text(label)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(task.status == status ? .white : statusColorForType(status))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(task.status == status ? statusColorForType(status) : statusColorForType(status).opacity(0.1))
            .cornerRadius(DesignSystem.BorderRadius.small)
        }
    }
    
    // MARK: - State
    
    @State private var selectedStatus: TaskCompletionStatus?
    
    // MARK: - Helper Methods
    
    private func statusText(for task: DailyTask) -> String {
        switch task.status {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .missed:
            return "Missed"
        case .failed:
            return "Failed"
        }
    }
    
    private func statusColor(for task: DailyTask) -> Color {
        switch task.status {
        case .notStarted:
            return DesignSystem.Colors.secondaryText
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .missed:
            return .yellow
        }
    }
    
    private func statusColorForType(_ status: TaskCompletionStatus) -> Color {
        switch status {
        case .notStarted:
            return DesignSystem.Colors.secondaryText
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .missed:
            return .yellow
        }
    }
    
    private var statusActionText: String {
        guard let status = selectedStatus else { return "" }
        
        switch status {
        case .notStarted:
            return "not started"
        case .inProgress:
            return "in progress"
        case .completed:
            return "completed"
        case .failed:
            return "failed"
        case .missed:
            return "missed"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func updateTaskStatus() {
        guard let status = selectedStatus, let tasksManager = tasksManager else { return }
        
        // Convert actual value to Double if provided
        let actualValueDouble = Double(actualValue)
        
        switch status {
        case .notStarted:
            tasksManager.resetTask(task)
        case .inProgress:
            tasksManager.markTaskInProgress(task, notes: notes.isEmpty ? nil : notes)
        case .completed:
            tasksManager.completeTask(task, actualValue: actualValueDouble, notes: notes.isEmpty ? nil : notes)
        case .failed:
            tasksManager.markTaskFailed(task, notes: notes.isEmpty ? nil : notes)
        case .missed:
            tasksManager.markTaskMissed(task, notes: notes.isEmpty ? nil : notes)
        }
        
        // Update challenge progress
        if let challenge = task.challenge {
            tasksManager.updateChallengeProgress(for: challenge)
        }
    }
    
    private func saveNotes() {
        guard let tasksManager = tasksManager else { return }
        
        // Update the task with the new notes
        task.notes = notes.isEmpty ? nil : notes
        
        // Convert actual value to Double if provided
        if let actualValueDouble = Double(actualValue) {
            task.actualValue = actualValueDouble
        }
        
        // Save the context
        do {
            try tasksManager.modelContext.save()
            
            // Show save confirmation
            withAnimation {
                showingSaveConfirmation = true
            }
            
            // Hide confirmation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showingSaveConfirmation = false
                }
            }
        } catch {
            Logger.error("Error saving notes: \(error)", category: .tasks)
        }
    }
} 