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
            } else if case .challengeDetail(let challenge) = sheet {
                ChallengeDetailView(challenge: challenge)
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
                            
                            // Present the challenge detail as a sheet
                            activeSheet = .challengeDetail(challenge)
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
        // Don't count missed or failed tasks in the total
        let validTasks = sortedDailyTasks.filter { $0.status != .missed && $0.status != .failed }
        let completedTasks = validTasks.filter { $0.status == .completed }.count
        let totalTasks = validTasks.count
        
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
    
    // Water tracking specific states
    @State private var glassesConsumed: Int = 0
    @State private var totalGlasses: Int = 8
    @State private var glassSize: Double = 250 // ml
    @State private var customGlassSize: String = ""
    @State private var totalWaterInMl: Double = 0 // Track total water in ml directly
    @State private var showingCustomizeView: Bool = false
    
    // MARK: - State
    @State private var selectedStatus: TaskCompletionStatus?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Task header
                taskHeaderSection
                
                // Water tracking UI for water tasks
                if let taskObj = task.task, taskObj.type == .water {
                    waterTrackingIntegratedSection
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
                
                // For water tasks, initialize glasses consumed
                if let taskObj = task.task, taskObj.type == .water {
                    glassesConsumed = Int(value)
                }
            }
            
            // Initialize water tracking data
            initializeWaterTrackingData()
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
        .sheet(isPresented: $showingCustomizeView) {
            waterCustomizeView
        }
    }
    
    // MARK: - View Components
    
    // Water tracking section with integrated UI
    private var waterTrackingIntegratedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Water Tracking")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button {
                    showingCustomizeView.toggle()
                } label: {
                    Image(systemName: "gear")
                        .foregroundColor(DesignSystem.Colors.neonCyan)
                }
            }
            
            // Progress Visualization
            ZStack {
                // Water container
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(height: 150)
                
                // Water level
                VStack {
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(height: 150 * min(CGFloat(glassesConsumed) / CGFloat(totalGlasses), 1.0))
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Water drops animation when adding a glass
                if glassesConsumed > 0 {
                    WaterDropsAnimation()
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // Progress text
                VStack(spacing: 8) {
                    Text("\(glassesConsumed)/\(totalGlasses)")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    
                    if totalWaterInMl >= 1000 {
                        // Show in liters if over 1000ml
                        Text("\(String(format: "%.1f", Double(glassesConsumed) * glassSize / 1000))/\(String(format: "%.1f", totalWaterInMl / 1000)) L")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    } else {
                        Text("\(Int(Double(glassesConsumed) * glassSize))/\(Int(totalWaterInMl)) ml")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    
                    Text("\(Int((Double(glassesConsumed) / Double(totalGlasses)) * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
            }
            .frame(height: 150)
            
            // Quick add buttons
            Text("Add Water")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top, 8)
            
            // Common container buttons
            HStack(spacing: 12) {
                quickAddButton(name: "Glass", size: Int(glassSize), icon: "glass.and.bottle.fill")
                quickAddButton(name: "Bottle", size: 500, icon: "waterbottle")
                quickAddButton(name: "Big Bottle", size: 1000, icon: "waterbottle.fill")
            }
            
            // Manual counter adjustment
            HStack(spacing: 20) {
                Button {
                    if glassesConsumed > 0 {
                        glassesConsumed -= 1
                        updateActualValue()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                }
                
                VStack {
                    Text("\(glassesConsumed)")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("glasses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 100)
                
                Button {
                    glassesConsumed += 1
                    updateActualValue()
                    
                    // Check if goal is completed
                    if glassesConsumed >= totalGlasses && task.status != .completed {
                        // Ask if they want to mark it complete
                        selectedStatus = .completed
                        showingConfirmation = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical)
            
            // Auto-complete button
            if glassesConsumed < totalGlasses {
                Button {
                    glassesConsumed = totalGlasses
                    updateActualValue()
                    
                    // Ask if they want to mark it complete
                    selectedStatus = .completed
                    showingConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark All Consumed")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.BorderRadius.medium)
    }
    
    /// Create a quick add button for a specific container size
    private func quickAddButton(name: String, size: Int, icon: String) -> some View {
        Button {
            // Calculate how many "glasses" this container represents
            let glassesInContainer = ceil(Double(size) / glassSize)
            glassesConsumed += Int(glassesInContainer)
            updateActualValue()
            
            // Check if goal is completed
            if glassesConsumed >= totalGlasses && task.status != .completed {
                // Ask if they want to mark it complete
                selectedStatus = .completed
                showingConfirmation = true
            }
        } label: {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(name)
                    .font(.caption)
                Text("\(size) ml")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .foregroundColor(.primary)
    }
    
    /// Customization view (shown in sheet)
    private var waterCustomizeView: some View {
        NavigationView {
            Form {
                Section(header: Text("Glass Size")) {
                    HStack {
                        Text("\(Int(glassSize)) ml")
                        Spacer()
                        Button("Edit") {
                            customGlassSize = String(Int(glassSize))
                        }
                    }
                    
                    TextField("Glass size in ml", text: $customGlassSize)
                        .keyboardType(.numberPad)
                        .onSubmit {
                            if let size = Double(customGlassSize), size > 0 {
                                glassSize = size
                                updateTotalGlasses()
                            }
                        }
                }
                
                Section(header: Text("Total Water Goal")) {
                    if totalWaterInMl >= 1000 {
                        Text("\(String(format: "%.1f", totalWaterInMl / 1000)) L")
                    } else {
                        Text("\(Int(totalWaterInMl)) ml")
                    }
                    
                    Stepper("\(totalGlasses) glasses", value: $totalGlasses, in: 1...20)
                        .onChange(of: totalGlasses) { oldValue, newValue in
                            // Keep the total water amount the same
                            glassSize = totalWaterInMl / Double(newValue)
                        }
                }
                
                Section(header: Text("Preset Container Sizes")) {
                    Button("Standard Glass (250ml)") {
                        glassSize = 250
                        updateTotalGlasses()
                    }
                    
                    Button("Large Glass (330ml)") {
                        glassSize = 330
                        updateTotalGlasses()
                    }
                    
                    Button("Small Bottle (500ml)") {
                        glassSize = 500
                        updateTotalGlasses()
                    }
                    
                    Button("Large Bottle (1000ml)") {
                        glassSize = 1000
                        updateTotalGlasses()
                    }
                }
            }
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingCustomizeView = false
                    }
                }
            }
        }
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
            
            // Actual value field (if task has a target and is not a water task)
            if let taskObj = task.task, taskObj.targetValue != nil, taskObj.type != .water {
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
    
    // MARK: - Helper Methods
    
    /// Initialize water tracking data based on task properties
    private func initializeWaterTrackingData() {
        if let taskObj = task.task, taskObj.type == .water {
            // Initialize with existing data if available
            if let actualValue = task.actualValue {
                glassesConsumed = Int(actualValue)
            }
            
            // Set up total glasses based on challenge type and target value
            if let targetValue = taskObj.targetValue {
                // Check if this is a water-related task
                if taskObj.type == .water {
                    // For 75Hard, the target is 1 gallon (3.8L)
                    if task.challenge?.type == .seventyFiveHard {
                        totalGlasses = 8 // 1 gallon divided into 8 glasses
                        glassSize = 3800 / 8 // ~475ml per glass
                        totalWaterInMl = 3800
                    } 
                    // For 31Modified, the target is 2 liters
                    else if task.challenge?.type == .thirtyOneModified {
                        totalGlasses = 8 // 2L divided into 8 glasses
                        glassSize = 2000 / 8 // 250ml per glass
                        totalWaterInMl = 2000
                    }
                    // For water fasting, the target is 3 liters
                    else if task.challenge?.type == .waterFasting {
                        totalGlasses = 12 // 3L divided into 12 glasses
                        glassSize = 3000 / 12 // 250ml per glass
                        totalWaterInMl = 3000
                    }
                    // For custom challenges with a target value
                    else if let targetUnit = taskObj.targetUnit {
                        if targetUnit.lowercased().contains("liter") || targetUnit.lowercased().contains("l") {
                            let liters = targetValue
                            totalGlasses = 8 // Default to 8 glasses
                            glassSize = (liters * 1000) / Double(8) // Convert to ml
                            totalWaterInMl = liters * 1000
                        } else if targetUnit.lowercased().contains("gallon") {
                            let gallons = targetValue
                            totalGlasses = 8 // Default to 8 glasses
                            glassSize = (gallons * 3800) / Double(8) // Convert to ml
                            totalWaterInMl = gallons * 3800
                        } else if targetUnit.lowercased().contains("glass") {
                            totalGlasses = Int(targetValue)
                            glassSize = 250 // Default glass size
                            totalWaterInMl = targetValue * 250
                        } else {
                            totalGlasses = Int(targetValue)
                            totalWaterInMl = targetValue * 250 // Assume default
                        }
                    }
                }
            }
        }
    }
    
    /// Updates total glasses based on glass size while maintaining total volume
    private func updateTotalGlasses() {
        guard glassSize > 0 else { return }
        totalGlasses = max(1, Int(ceil(totalWaterInMl / glassSize)))
    }
    
    /// Update the actual value based on glasses consumed
    private func updateActualValue() {
        actualValue = String(glassesConsumed)
        saveNotes() // Save automatically when glasses are changed
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
        let actualValueDouble: Double? = actualValue.isEmpty ? nil : Double(actualValue)
        
        // Log the status change
        Logger.info("Updating task status: \(task.title) -> \(status.rawValue)", category: .tasks)
        Logger.info("Actual value: \(actualValueDouble?.description ?? "nil")", category: .tasks)
        
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
            // Ensure the challenge progress is updated
            Logger.info("Updating progress for challenge: \(challenge.name)", category: .tasks)
            tasksManager.updateChallengeProgress(for: challenge)
        }
        
        // Force UI refresh by explicitly saving
        do {
            try tasksManager.modelContext.save()
            Logger.info("Task status updated successfully", category: .tasks)
        } catch {
            Logger.error("Error saving task status: \(error)", category: .tasks)
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

// MARK: - Water Drops Animation

struct WaterDropsAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<10) { index in
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .offset(x: isAnimating ? randomOffset() : 0, y: isAnimating ? randomOffset() : 0)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 1...2))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...1)),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func randomOffset() -> CGFloat {
        CGFloat.random(in: -20...20)
    }
} 