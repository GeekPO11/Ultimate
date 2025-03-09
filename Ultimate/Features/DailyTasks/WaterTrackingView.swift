import SwiftUI
import SwiftData

/// A view for tracking water consumption glass by glass
struct WaterTrackingView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let dailyTask: DailyTask
    @ObservedObject var tasksManager: DailyTasksManager
    
    // State for tracking glasses
    @State private var glassesConsumed: Int = 0
    @State private var totalGlasses: Int = 8
    @State private var glassSize: Double = 250 // ml
    @State private var customGlassSize: String = ""
    @State private var isEditingGlassSize: Bool = false
    @State private var showingCompletionAlert: Bool = false
    @State private var notes: String = ""
    
    // MARK: - Initialization
    
    init(dailyTask: DailyTask, tasksManager: DailyTasksManager) {
        self.dailyTask = dailyTask
        self.tasksManager = tasksManager
        
        // Initialize with existing data if available
        if let actualValue = dailyTask.actualValue {
            _glassesConsumed = State(initialValue: Int(actualValue))
        }
        
        if let notes = dailyTask.notes {
            _notes = State(initialValue: notes)
        }
        
        // Set up total glasses based on challenge type and target value
        if let task = dailyTask.task, let targetValue = task.targetValue {
            // Check if this is a water-related task
            let isWaterTask = task.type?.rawValue == "Water" || task.type == .water
            
            if isWaterTask {
                // For 75Hard, the target is 1 gallon (3.8L)
                if dailyTask.challenge?.type == .seventyFiveHard {
                    _totalGlasses = State(initialValue: 8) // 1 gallon divided into 8 glasses
                    _glassSize = State(initialValue: 3800 / 8) // ~475ml per glass
                } 
                // For 31Modified, the target is 2 liters
                else if dailyTask.challenge?.type == .thirtyOneModified {
                    _totalGlasses = State(initialValue: 8) // 2L divided into 8 glasses
                    _glassSize = State(initialValue: 2000 / 8) // 250ml per glass
                }
                // For water fasting, the target is 3 liters
                else if dailyTask.challenge?.type == .waterFasting {
                    _totalGlasses = State(initialValue: 12) // 3L divided into 12 glasses
                    _glassSize = State(initialValue: 3000 / 12) // 250ml per glass
                }
                // For custom challenges with a target value
                else if let targetUnit = task.targetUnit {
                    if targetUnit.lowercased().contains("liter") || targetUnit.lowercased().contains("l") {
                        let liters = targetValue
                        _totalGlasses = State(initialValue: 8) // Default to 8 glasses
                        _glassSize = State(initialValue: (liters * 1000) / Double(8)) // Convert to ml
                    } else if targetUnit.lowercased().contains("gallon") {
                        let gallons = targetValue
                        _totalGlasses = State(initialValue: 8) // Default to 8 glasses
                        _glassSize = State(initialValue: (gallons * 3800) / Double(8)) // Convert to ml
                    } else if targetUnit.lowercased().contains("glass") {
                        _totalGlasses = State(initialValue: Int(targetValue))
                        _glassSize = State(initialValue: 250) // Default glass size
                    } else {
                        _totalGlasses = State(initialValue: Int(targetValue))
                    }
                }
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Water progress visualization
                    waterProgressView
                    
                    // Glass tracking controls
                    glassTrackingControls
                    
                    // Glass size customization
                    glassSizeCustomization
                    
                    // Notes section
                    notesSection
                    
                    // Action buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Water Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.neonPink)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProgress()
                    }
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                }
            }
            .alert("Congratulations!", isPresented: $showingCompletionAlert) {
                Button("OK") {
                    saveProgress(markCompleted: true)
                    dismiss()
                }
            } message: {
                Text("You've completed your water goal for today!")
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Water progress visualization
    private var waterProgressView: some View {
        VStack(spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack {
                // Water container
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(height: 200)
                
                // Water level
                VStack {
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(height: 200 * min(CGFloat(glassesConsumed) / CGFloat(totalGlasses), 1.0))
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Water drops animation when adding a glass
                if glassesConsumed > 0 {
                    WaterDropsAnimation()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // Progress text
                VStack {
                    Text("\(glassesConsumed)/\(totalGlasses)")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    
                    Text("\(Int(Double(glassesConsumed) * glassSize)) ml")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
            }
            .frame(height: 200)
            
            // Progress percentage
            Text("\(Int((Double(glassesConsumed) / Double(totalGlasses)) * 100))% Complete")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    /// Glass tracking controls
    private var glassTrackingControls: some View {
        VStack(spacing: 16) {
            Text("Track Your Glasses")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                Button {
                    if glassesConsumed > 0 {
                        glassesConsumed -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.red)
                }
                
                VStack {
                    Text("\(glassesConsumed)")
                        .font(.system(size: 44, weight: .bold))
                    
                    Text("glasses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 100)
                
                Button {
                    glassesConsumed += 1
                    
                    // Check if goal is completed
                    if glassesConsumed >= totalGlasses {
                        showingCompletionAlert = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                }
            }
            .padding()
            
            // Progress text
            Text("\(Int((Double(glassesConsumed) / Double(totalGlasses)) * 100))% Complete")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    /// Glass size customization
    private var glassSizeCustomization: some View {
        VStack(spacing: 16) {
            Text("Customize")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Glass Size")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(Int(glassSize)) ml")
                        .font(.title3)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button {
                        customGlassSize = String(Int(glassSize))
                        isEditingGlassSize = true
                    } label: {
                        Text("Edit")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.clear)
                            .foregroundColor(DesignSystem.Colors.neonCyan)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(DesignSystem.Colors.neonCyan, lineWidth: 1.5)
                                    .shadow(color: DesignSystem.Colors.neonCyan, radius: 3, x: 0, y: 0)
                            )
                    }
                }
                
                if isEditingGlassSize {
                    HStack {
                        TextField("Glass size in ml", text: $customGlassSize)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Button("Apply") {
                            if let size = Double(customGlassSize), size > 0 {
                                glassSize = size
                            }
                            isEditingGlassSize = false
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.clear)
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(DesignSystem.Colors.neonGreen, lineWidth: 1.5)
                                .shadow(color: DesignSystem.Colors.neonGreen, radius: 3, x: 0, y: 0)
                        )
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Glasses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Stepper("\(totalGlasses) glasses", value: $totalGlasses, in: 1...20)
                    .onChange(of: totalGlasses) { oldValue, newValue in
                        // Adjust glass size to maintain the same total volume
                        if let task = dailyTask.task, let targetValue = task.targetValue, let targetUnit = task.targetUnit {
                            if targetUnit.lowercased().contains("liter") || targetUnit.lowercased().contains("l") {
                                let totalMl = targetValue * 1000
                                glassSize = totalMl / Double(newValue)
                            } else if targetUnit.lowercased().contains("gallon") {
                                let totalMl = targetValue * 3800
                                glassSize = totalMl / Double(newValue)
                            }
                        }
                    }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    /// Notes section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    /// Action buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button {
                saveProgress(markCompleted: true)
                dismiss()
            } label: {
                Text("Mark as Completed")
                    .font(.headline)
                    .foregroundColor(Color.green.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.green.opacity(0.8), lineWidth: 1.5)
                            .shadow(color: Color.green.opacity(0.8), radius: 4, x: 0, y: 0)
                            .shadow(color: Color.green.opacity(0.6), radius: 8, x: 0, y: 0)
                    )
            }
            .disabled(glassesConsumed < totalGlasses)
            .opacity(glassesConsumed < totalGlasses ? 0.6 : 1)
            
            Button {
                saveProgress(markInProgress: true)
                dismiss()
            } label: {
                Text("Save Progress")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.neonBlue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(DesignSystem.Colors.neonBlue, lineWidth: 1.5)
                            .shadow(color: DesignSystem.Colors.neonBlue, radius: 4, x: 0, y: 0)
                            .shadow(color: DesignSystem.Colors.neonBlue, radius: 8, x: 0, y: 0)
                    )
            }
        }
    }
    
    // MARK: - Methods
    
    /// Saves the current progress
    private func saveProgress(markCompleted: Bool = false, markInProgress: Bool = false) {
        // Calculate total water consumed in ml
        let _ = Double(glassesConsumed) * glassSize
        
        // Update the daily task
        dailyTask.actualValue = Double(glassesConsumed)
        dailyTask.notes = notes.isEmpty ? nil : notes
        
        // Mark as completed if all glasses are consumed or explicitly requested
        if markCompleted || glassesConsumed >= totalGlasses {
            tasksManager.completeTask(dailyTask, actualValue: Double(glassesConsumed), notes: notes.isEmpty ? nil : notes)
        } 
        // Mark as in progress if explicitly requested
        else if markInProgress {
            tasksManager.markTaskInProgress(dailyTask, notes: notes.isEmpty ? nil : notes)
        }
        // Otherwise just save the context
        else {
            do {
                try modelContext.save()
            } catch {
                Logger.error("Error saving water tracking progress: \(error)", category: .tasks)
            }
        }
        
        // Update challenge progress
        if let challenge = dailyTask.challenge {
            tasksManager.updateChallengeProgress(for: challenge)
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

// MARK: - Preview

struct WaterTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        let modelContainer = try! ModelContainer(for: Challenge.self, DailyTask.self, Task.self)
        let modelContext = ModelContext(modelContainer)
        
        let challenge = Challenge.createSeventyFiveHardChallenge()
        let waterTask = challenge.tasks.first { $0.type == .water }!
        let dailyTask = DailyTask(title: waterTask.name, challenge: challenge, task: waterTask)
        
        let tasksManager = DailyTasksManager(modelContext: modelContext)
        
        return WaterTrackingView(dailyTask: dailyTask, tasksManager: tasksManager)
    }
} 