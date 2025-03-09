import SwiftUI
import SwiftData

struct CustomChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var userSettings: UserSettings
    
    // Challenge properties
    @State private var challengeName: String = ""
    @State private var challengeDescription: String = ""
    @State private var challengeDuration: Int = 30
    @State private var selectedStartDate = Date()
    
    // Task management
    @State private var customTasks: [CustomTaskItem] = []
    @State private var newTaskName: String = ""
    @State private var newTaskType: TaskType = .custom
    @State private var newTaskFrequency: TaskFrequency = .daily
    @State private var newTaskTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var newTaskWaterAmount: Double = 2.0
    @State private var newTaskWaterUnit: String = "liters"
    @State private var isAddingTask: Bool = false
    
    // Notification settings
    @State private var enableNotifications: Bool = true
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    
    // UI States
    @State private var showingTaskSheet: Bool = false
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var currentStep: Int = 1
    
    // Validation
    private var isFormValid: Bool {
        !challengeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !challengeDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !customTasks.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium animated background
                PremiumBackground()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Progress indicator
                        progressIndicator
                        
                        // Step content
                        VStack(spacing: DesignSystem.Spacing.xl) {
                            Group {
                                switch currentStep {
                                case 1:
                                    basicInfoSection
                                case 2:
                                    tasksSection
                                case 3:
                                    notificationsSection
                                case 4:
                                    reviewSection
                                default:
                                    EmptyView()
                                }
                            }
                            .transition(.opacity)
                            
                            navigationButtons
                        }
                        .padding(.horizontal, DesignSystem.Spacing.l)
                    }
                    .padding(.vertical, DesignSystem.Spacing.l)
                }
                .background(DesignSystem.Colors.background)
                .navigationTitle("Create Custom Challenge")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .alert(isPresented: $showingErrorAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .sheet(isPresented: $showingTaskSheet) {
                    addTaskSheet
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var progressIndicator: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            ForEach(1...4, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.dividers)
                    .frame(width: 12, height: 12)
                
                if step < 4 {
                    Rectangle()
                        .fill(step < currentStep ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.dividers)
                        .frame(height: 2)
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.m)
    }
    
    // MARK: - Step 1: Basic Info
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
            Text("Challenge Details")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
            
            CTCard(style: .glass) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    // Challenge name
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Challenge Name")
                            .font(DesignSystem.Typography.headline)
                        
                        TextField("e.g. My Fitness Journey", text: $challengeName)
                            .padding()
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.BorderRadius.small)
                    }
                    
                    // Challenge description
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Description")
                            .font(DesignSystem.Typography.headline)
                        
                        TextEditor(text: $challengeDescription)
                            .frame(minHeight: 100)
                            .padding()
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.BorderRadius.small)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                                    .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                            )
                    }
                    
                    // Duration
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Duration (Days)")
                            .font(DesignSystem.Typography.headline)
                        
                        HStack {
                            Text("\(challengeDuration)")
                                .font(DesignSystem.Typography.title2)
                                .frame(width: 60, alignment: .center)
                            
                            Slider(value: Binding(
                                get: { Double(challengeDuration) },
                                set: { challengeDuration = Int($0) }
                            ), in: 7...100, step: 1)
                        }
                    }
                    
                    // Start date
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Start Date")
                            .font(DesignSystem.Typography.headline)
                        
                        DatePicker("", selection: $selectedStartDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Step 2: Tasks
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
            HStack {
                Text("Challenge Tasks")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                CTButton(
                    title: "Add Task",
                    icon: "plus",
                    style: .neon,
                    size: .small,
                    customNeonColor: DesignSystem.Colors.neonCyan
                ) {
                    showingTaskSheet = true
                }
            }
            
            if customTasks.isEmpty {
                CTCard(style: .bordered) {
                    VStack(spacing: DesignSystem.Spacing.m) {
                        Image(systemName: "checklist")
                            .font(.system(size: 40))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("No tasks added yet")
                            .font(DesignSystem.Typography.headline)
                        
                        Text("Add at least one task to your challenge")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        CTButton(
                            title: "Add Your First Task",
                            icon: "plus",
                            style: .neon,
                            customNeonColor: DesignSystem.Colors.neonCyan
                        ) {
                            showingTaskSheet = true
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(customTasks) { task in
                    HStack(spacing: DesignSystem.Spacing.m) {
                        Image(systemName: task.type?.icon ?? "checkmark.circle")
                            .foregroundColor(task.type?.color ?? Color.gray)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            Text(task.name)
                                .font(DesignSystem.Typography.body)
                            
                            Text("\(task.frequency.rawValue) • \(task.frequency != .anytime ? task.time.formatted(date: .omitted, time: .shortened) : "Anytime")")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }
            }
        }
    }
    
    private var addTaskSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $newTaskName)
                    
                    Picker("Task Type", selection: $newTaskType) {
                        ForEach(TaskType.allCases, id: \.self) { type in
                            Label(type.rawValue.capitalized, systemImage: type.icon)
                                .foregroundColor(type.color)
                                .tag(type)
                        }
                    }
                    
                    Picker("Frequency", selection: $newTaskFrequency) {
                        ForEach(TaskFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue)
                                .tag(frequency)
                        }
                    }
                    
                    if newTaskFrequency != .anytime {
                        DatePicker("Time", selection: $newTaskTime, displayedComponents: .hourAndMinute)
                    }
                    
                    // Water tracking specific fields
                    if newTaskType == .water {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                            Text("Water Target")
                                .font(DesignSystem.Typography.subheadline)
                            
                            HStack {
                                TextField("Amount", value: $newTaskWaterAmount, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                
                                Picker("Unit", selection: $newTaskWaterUnit) {
                                    Text("liters").tag("liters")
                                    Text("gallon").tag("gallon")
                                    Text("glasses").tag("glasses")
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.s)
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingTaskSheet = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if newTaskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            errorMessage = "Task name cannot be empty"
                            showingErrorAlert = true
                            return
                        }
                        
                        let newTask = CustomTaskItem(
                            name: newTaskName,
                            type: newTaskType,
                            frequency: newTaskFrequency,
                            time: newTaskTime,
                            targetValue: newTaskType == .water ? newTaskWaterAmount : nil,
                            targetUnit: newTaskType == .water ? newTaskWaterUnit : nil
                        )
                        
                        withAnimation {
                            customTasks.append(newTask)
                        }
                        
                        // Reset fields
                        newTaskName = ""
                        newTaskType = .custom
                        newTaskFrequency = .daily
                        
                        showingTaskSheet = false
                    }
                    .disabled(newTaskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Step 3: Notifications
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
            Text("Notification Settings")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
            
            CTCard(style: .glass) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                        .font(DesignSystem.Typography.headline)
                    
                    if enableNotifications {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                            Text("Daily Reminder Time")
                                .font(DesignSystem.Typography.subheadline)
                            
                            DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        Text("You'll receive a daily reminder to complete your tasks at this time.")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                .padding()
            }
            
            Text("Task-specific notifications will be sent based on the time you set for each task.")
                .font(DesignSystem.Typography.footnote)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .padding(.top, DesignSystem.Spacing.s)
        }
    }
    
    // MARK: - Step 4: Review
    
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
            Text("Review Your Challenge")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
            
            // Challenge summary
            CTCard(style: .highlight) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    Text(challengeName)
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.bold)
                    
                    Text(challengeDescription)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            Text("Duration")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text("\(challengeDuration) days")
                                .font(DesignSystem.Typography.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
                            Text("Start Date")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text(selectedStartDate.formatted(date: .abbreviated, time: .omitted))
                                .font(DesignSystem.Typography.headline)
                        }
                    }
                }
                .padding()
            }
            
            // Analytics note
            CTCard(style: .glass) {
                HStack(spacing: DesignSystem.Spacing.m) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Detailed Analytics")
                            .font(DesignSystem.Typography.headline)
                        
                        Text("Track your progress with detailed analytics once your challenge begins")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                .padding()
            }
            
            // Tasks summary
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Tasks (\(customTasks.count))")
                    .font(DesignSystem.Typography.headline)
                
                ForEach(customTasks) { task in
                    HStack(spacing: DesignSystem.Spacing.m) {
                        Image(systemName: task.type?.icon ?? "checkmark.circle")
                            .foregroundColor(task.type?.color ?? Color.gray)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            Text(task.name)
                                .font(DesignSystem.Typography.body)
                            
                            Text("\(task.frequency.rawValue) • \(task.frequency != .anytime ? task.time.formatted(date: .omitted, time: .shortened) : "Anytime")")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.BorderRadius.medium)
            
            // Notification summary
            if enableNotifications {
                CTCard {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(DesignSystem.Colors.primaryAction)
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            Text("Daily Reminder")
                                .font(DesignSystem.Typography.headline)
                            
                            Text("Every day at \(reminderTime.formatted(date: .omitted, time: .shortened))")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            } else {
                CTCard {
                    HStack {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .font(.system(size: 20))
                        
                        Text("Notifications Disabled")
                            .font(DesignSystem.Typography.headline)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            // Back button (except on first step)
            if currentStep > 1 {
                CTButton(
                    title: "Back",
                    style: .neon,
                    customNeonColor: DesignSystem.Colors.neonPink
                ) {
                    withAnimation {
                        currentStep -= 1
                    }
                }
            }
            
            Spacer()
            
            // Next/Create button
            if currentStep < 4 {
                CTButton(
                    title: "Next",
                    icon: "arrow.right",
                    style: .neon,
                    customNeonColor: DesignSystem.Colors.neonBlue
                ) {
                    validateCurrentStep()
                }
                .disabled(currentStep == 2 && customTasks.isEmpty)
            } else {
                CTButton(
                    title: "Create Challenge",
                    icon: "checkmark",
                    style: .neon,
                    customNeonColor: DesignSystem.Colors.neonGreen
                ) {
                    createChallenge()
                }
            }
        }
        .padding(.top, DesignSystem.Spacing.m)
    }
    
    // MARK: - Logic
    
    private func validateCurrentStep() {
        var isValid = true
        
        switch currentStep {
        case 1:
            if challengeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "Please enter a challenge name"
                isValid = false
            } else if challengeDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "Please enter a challenge description"
                isValid = false
            }
        case 2:
            if customTasks.isEmpty {
                errorMessage = "Please add at least one task"
                isValid = false
            }
        default:
            break
        }
        
        if isValid {
            withAnimation {
                currentStep += 1
            }
        } else {
            showingErrorAlert = true
        }
    }
    
    /// Creates the challenge
    private func createChallenge() {
        do {
            // Create the challenge
            let challenge = Challenge(
                type: .custom,
                name: challengeName,
                challengeDescription: challengeDescription,
                durationInDays: challengeDuration
            )
            
            // Add tasks to the challenge
            for taskItem in customTasks {
                let task = Task(
                    name: taskItem.name,
                    description: "Custom task for \(challengeName)",
                    type: taskItem.type,
                    frequency: taskItem.frequency,
                    timeOfDay: taskItem.frequency != .anytime ? Calendar.current.dateComponents([.hour, .minute], from: taskItem.time) : nil,
                    targetValue: taskItem.targetValue,
                    targetUnit: taskItem.targetUnit
                )
                task.challenge = challenge
                challenge.tasks.append(task)
            }
            
            // Set the start date
            challenge.startDate = selectedStartDate
            
            // Calculate end date
            if let startDate = challenge.startDate {
                challenge.endDate = Calendar.current.date(byAdding: .day, value: challengeDuration, to: startDate)
            }
            
            // Save to model context
            modelContext.insert(challenge)
            try modelContext.save()
            
            // Start the challenge
            challenge.startChallenge()
            
            // Dismiss the view
            dismiss()
        } catch {
            errorMessage = "Failed to create challenge: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

// MARK: - Supporting Types

struct CustomTaskItem: Identifiable {
    let id = UUID()
    let name: String
    let type: TaskType?
    let frequency: TaskFrequency
    let time: Date
    let targetValue: Double?
    let targetUnit: String?
}

// MARK: - Preview

#Preview {
    CustomChallengeView()
        .modelContainer(for: [Challenge.self, Task.self, DailyTask.self], inMemory: true)
        .environmentObject(UserSettings())
} 