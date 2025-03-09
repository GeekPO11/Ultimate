import SwiftUI
import SwiftData

// MARK: - Type Aliases
typealias ChallengeSelectionHandler = (Challenge) -> Void

/// View for displaying and managing challenges
struct ChallengesView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Challenge.startDate, order: .reverse) private var challenges: [Challenge]
    @State private var showingAddChallenge: Bool = false
    @State private var showingCustomChallengeView: Bool = false
    @State private var selectedChallenge: Challenge? = nil
    @State private var isLoadingChallenge: Bool = false
    
    // Pre-filtered arrays instead of computed properties
    @State private var activeChallenges: [Challenge] = []
    @State private var upcomingChallenges: [Challenge] = []
    @State private var completedChallenges: [Challenge] = []
    
    // Challenge selection properties
    enum ChallengeCategory: String, CaseIterable {
        case all = "All"
        case fitness = "Fitness"
        case fasting = "Fasting"
        case habits = "Habits"
    }
    
    @State private var selectedCategory: ChallengeCategory = .all
    @State private var searchText: String = ""
    @State private var showingChallengeDetail: Bool = false
    @State private var selectedTemplateChallenge: Challenge? = nil
    @State private var availableChallenges: [Challenge] = []
    @State private var showingSelectionView: Bool = true
    @State private var isProcessingTap: Bool = false
    
    // MARK: - Initializer
    init() {
        // Default initializer with no parameters
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Premium animated background
            PremiumBackground()
            
            if challenges.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Challenge selection view is always shown
                challengeSelectionView
            }
            
            // Overlay the challenge detail view when a challenge is selected
            if showingChallengeDetail, let challenge = selectedTemplateChallenge {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Allow tapping outside to dismiss
                        withAnimation {
                            showingChallengeDetail = false
                            selectedTemplateChallenge = nil
                        }
                    }
                
                VStack(spacing: 0) {
                    // Navigation bar
                    HStack {
                        Text(challenge.name)
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                showingChallengeDetail = false
                                selectedTemplateChallenge = nil
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
                        ChallengeDetailSheet(challenge: challenge, onStart: {
                            startChallenge(challenge)
                            withAnimation {
                                showingChallengeDetail = false
                                selectedTemplateChallenge = nil
                            }
                        })
                        .padding()
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
        .sheet(isPresented: $showingCustomChallengeView) {
            CustomChallengeView()
        }
        .sheet(item: $selectedChallenge) { challenge in
            ChallengeDetailView(challenge: challenge)
        }
        .onChange(of: challenges) { _, _ in
            filterChallenges()
        }
        .onAppear {
            // Filter challenges on initial load
            filterChallenges()
            
            // Create predefined challenges if none exist
            if challenges.isEmpty {
                createPredefinedChallenges()
            }
            
            // Load available challenge templates
            loadPredefinedChallenges()
        }
    }
    
    // MARK: - Subviews
    
    private var addButton: some View {
        Button {
            showingSelectionView = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
        }
    }
    
    private var backButton: some View {
        Button {
            showingSelectionView = false
        } label: {
            Text("Done")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.primaryAction.opacity(0.7))
            
            Text("No Challenges Yet")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("We're preparing some challenges for you. They'll appear here shortly, or you can create your own custom challenge.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            CTButton(
                title: "Add Challenge",
                icon: "plus",
                style: .primary,
                size: .large
            ) {
                showingSelectionView = true
            }
            .padding(.top, DesignSystem.Spacing.l)
            .padding(.horizontal, DesignSystem.Spacing.xl)
        }
    }
    
    private var challengeListView: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.l) {
                // Active challenges section
                if !activeChallenges.isEmpty {
                    ChallengeSection(
                        title: "Active Challenges",
                        challenges: activeChallenges,
                        onSelect: { challenge in
                            selectChallenge(challenge)
                        }
                    )
                }
                
                // Upcoming challenges section
                if !upcomingChallenges.isEmpty {
                    ChallengeSection(
                        title: "Upcoming Challenges",
                        challenges: upcomingChallenges,
                        onSelect: { challenge in
                            selectChallenge(challenge)
                        }
                    )
                }
                
                // Completed challenges section
                if !completedChallenges.isEmpty {
                    ChallengeSection(
                        title: "Completed Challenges",
                        challenges: completedChallenges,
                        onSelect: { challenge in
                            selectChallenge(challenge)
                        }
                    )
                }
            }
            .padding()
        }
        .overlay(
            Group {
                if isLoadingChallenge {
                    ProgressView("Loading challenge...")
                        .padding()
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                        .shadow(radius: 5)
                }
            }
        )
    }
    
    private var challengeSelectionView: some View {
        VStack(spacing: 0) {
            // Header
            Text("Choose Challenge")
                .font(DesignSystem.Typography.title1)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.s) {
                    ForEach(ChallengeCategory.allCases, id: \.self) { category in
                        categoryButton(category)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, DesignSystem.Spacing.s)
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                TextField("Search challenges", text: $searchText)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
                if !searchText.isEmpty {
                    Button(action: {
                        print("ChallengeSelectionView: Clearing search text")
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.BorderRadius.medium)
            .padding(.horizontal)
            
            // Challenge list
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    ForEach(filteredChallenges) { challenge in
                        challengeTemplateCard(challenge)
                    }
                    
                    // Custom challenge button
                    customChallengeButton
                }
                .padding()
            }
        }
    }
    
    private func categoryButton(_ category: ChallengeCategory) -> some View {
        Button(action: {
            withAnimation {
                print("ChallengeSelectionView: Category selected - \(category.rawValue)")
                selectedCategory = category
            }
        }) {
            Text(category.rawValue)
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    selectedCategory == category ?
                    DesignSystem.Colors.primaryAction :
                    DesignSystem.Colors.cardBackground
                )
                .foregroundColor(
                    selectedCategory == category ?
                    .white :
                    DesignSystem.Colors.primaryText
                )
                .cornerRadius(DesignSystem.BorderRadius.pill)
        }
    }
    
    private func challengeTemplateCard(_ challenge: Challenge) -> some View {
        Button(action: {
            selectChallenge(challenge)
        }) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                // Challenge name and difficulty
                HStack {
                    Text(challenge.name)
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text(challengeDifficulty(challenge))
                        .font(DesignSystem.Typography.caption1)
                        .fontWeight(.medium)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, 4)
                        .background(difficultyColor(challenge))
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.BorderRadius.small)
                }
                
                // Duration
                Text("\(challenge.durationInDays) Days")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                // Description
                Text(challenge.description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(2)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                
                // Tasks preview
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(challenge.tasks.prefix(3)) { task in
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                                .font(.system(size: 14))
                            
                            Text(task.name)
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .lineLimit(1)
                        }
                    }
                    
                    if challenge.tasks.count > 3 {
                        Text("+ \(challenge.tasks.count - 3) more tasks")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            .padding()
            .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
            .cornerRadius(DesignSystem.BorderRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private var customChallengeButton: some View {
        Button(action: {
            print("ChallengeSelectionView: Custom challenge button tapped")
            showingSelectionView = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("ChallengeSelectionView: Showing custom challenge view")
                showingCustomChallengeView = true
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                    HStack {
                        Text("Create Custom Challenge")
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.Colors.primaryAction)
                    }
                    
                    Text("Design your own challenge with custom tasks and duration")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
            .cornerRadius(DesignSystem.BorderRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                    .stroke(DesignSystem.Colors.primaryAction, lineWidth: 2)
                    .opacity(0.5)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Filters challenges into their respective categories
    private func filterChallenges() {
        let inProgressString: String = "inProgress"
        let notStartedString: String = "notStarted"
        let completedString: String = "completed"
        let failedString: String = "failed"
        
        activeChallenges = challenges.filter { $0.status.rawValue == inProgressString }
        upcomingChallenges = challenges.filter { $0.status.rawValue == notStartedString }
        
        var completed: [Challenge] = []
        for challenge in challenges {
            let status: String = challenge.status.rawValue
            if status == completedString || status == failedString {
                completed.append(challenge)
            }
        }
        completedChallenges = completed
    }
    
    // MARK: - Predefined Challenges
    
    /// Creates predefined challenges for the user to choose from
    private func createPredefinedChallenges() {
        print("ChallengeSelectionView: Creating predefined challenges")
        
        // Check if we already have any challenges
        if !challenges.isEmpty {
            print("ChallengeSelectionView: Challenges already exist, skipping creation")
            return
        }
        
        // Create 75 Hard challenge
        let seventyFiveHard = Challenge.createSeventyFiveHardChallenge()
        seventyFiveHard.name = "75 Hard Challenge"
        seventyFiveHard.challengeDescription = "Transform your life with this intense mental toughness program. Complete 2 workouts, drink water, read, and follow strict nutrition rules daily."
        seventyFiveHard.status = .notStarted
        
        // Create 21 Day Habit Builder challenge
        let habitBuilder = Challenge.createThirtyOneModifiedChallenge()
        habitBuilder.name = "21 Day Habit Builder"
        habitBuilder.challengeDescription = "Build lasting habits in 21 days. Choose your habits and track them daily to make them stick."
        habitBuilder.durationInDays = 21
        habitBuilder.status = .notStarted
        
        // Create Water Fasting challenge
        let waterFasting = Challenge.createWaterFastingChallenge()
        waterFasting.name = "7 Day Water Fast"
        waterFasting.challengeDescription = "A week-long water fast to reset your body and mind. Track your fasting hours, water intake, and daily weight."
        waterFasting.status = .notStarted
        
        // Create 3 Day Water Fasting challenge
        let shortWaterFasting = Challenge.createWaterFastingChallenge(durationInDays: 3)
        shortWaterFasting.name = "3 Day Water Fast"
        shortWaterFasting.challengeDescription = "A short but effective water fast to reset your body and mind. Perfect for beginners or those with busy schedules."
        shortWaterFasting.status = .notStarted
        
        // Insert challenges into the model context
        modelContext.insert(seventyFiveHard)
        modelContext.insert(habitBuilder)
        modelContext.insert(waterFasting)
        modelContext.insert(shortWaterFasting)
        
        // Save the context to persist changes
        do {
            try modelContext.save()
            print("ChallengeSelectionView: Created and saved predefined challenges")
            print("ChallengeSelectionView: Created 75 Hard Challenge with ID \(seventyFiveHard.id)")
            print("ChallengeSelectionView: Created 21 Day Habit Builder with ID \(habitBuilder.id)")
            print("ChallengeSelectionView: Created 7 Day Water Fast with ID \(waterFasting.id)")
            print("ChallengeSelectionView: Created 3 Day Water Fast with ID \(shortWaterFasting.id)")
        } catch {
            print("Error creating predefined challenges: \(error)")
        }
    }
    
    private func loadPredefinedChallenges() {
        print("ChallengeSelectionView: Loading predefined challenges")
        
        // Check if we already have challenges loaded
        if !availableChallenges.isEmpty {
            print("ChallengeSelectionView: Challenges already loaded, skipping creation")
            return
        }
        
        // Create 75 Hard challenge template
        let seventyFiveHard = Challenge.createSeventyFiveHardChallenge()
        seventyFiveHard.status = .notStarted
        seventyFiveHard.name = "75 Hard Challenge"
        seventyFiveHard.challengeDescription = "Transform your life with this intense mental toughness program. Complete 2 workouts, drink water, read, and follow strict nutrition rules daily."
        
        // Create 21 Day Habit Builder challenge template
        let habitBuilder = Challenge.createThirtyOneModifiedChallenge()
        habitBuilder.name = "21 Day Habit Builder"
        habitBuilder.challengeDescription = "Build lasting habits in 21 days. Choose your habits and track them daily to make them stick."
        habitBuilder.durationInDays = 21
        habitBuilder.status = .notStarted
        
        // Create Water Fasting challenge template
        let waterFasting = Challenge.createWaterFastingChallenge()
        waterFasting.name = "7 Day Water Fast"
        waterFasting.challengeDescription = "A week-long water fast to reset your body and mind. Track your fasting hours, water intake, and daily weight."
        waterFasting.status = .notStarted
        
        // Create 3 Day Water Fasting challenge template
        let shortWaterFasting = Challenge.createWaterFastingChallenge(durationInDays: 3)
        shortWaterFasting.name = "3 Day Water Fast"
        shortWaterFasting.challengeDescription = "A short but effective water fast to reset your body and mind. Perfect for beginners or those with busy schedules."
        shortWaterFasting.status = .notStarted
        
        // Store templates in availableChallenges array
        availableChallenges = [seventyFiveHard, waterFasting, shortWaterFasting, habitBuilder]
        print("ChallengeSelectionView: Loaded \(availableChallenges.count) predefined challenges")
        
        // Log challenge details for debugging
        for challenge in availableChallenges {
            print("ChallengeSelectionView: Loaded challenge - \(challenge.name) with ID \(challenge.id)")
            print("ChallengeSelectionView: Challenge has \(challenge.tasks.count) tasks")
        }
    }
    
    private var filteredChallenges: [Challenge] {
        var challenges = availableChallenges
        
        // Filter by category
        if selectedCategory != .all {
            challenges = challenges.filter { challengeMatchesCategory($0, category: selectedCategory) }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            challenges = challenges.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.description.lowercased().contains(searchText.lowercased())
            }
        }
        
        return challenges
    }
    
    private func challengeMatchesCategory(_ challenge: Challenge, category: ChallengeCategory) -> Bool {
        switch category {
        case .all:
            return true
        case .fitness:
            return challenge.type == .seventyFiveHard || challenge.type == .thirtyOneModified
        case .fasting:
            return challenge.type == .waterFasting
        case .habits:
            return challenge.type == .thirtyOneModified
        }
    }
    
    private func challengeDifficulty(_ challenge: Challenge) -> String {
        switch challenge.type {
        case .seventyFiveHard:
            return "Hard"
        case .waterFasting:
            return "Medium"
        case .thirtyOneModified:
            return "Easy"
        case .custom:
            return "Custom"
        }
    }
    
    private func difficultyColor(_ challenge: Challenge) -> Color {
        switch challenge.type {
        case .seventyFiveHard:
            return Color.red
        case .waterFasting:
            return Color.orange
        case .thirtyOneModified:
            return Color.green
        case .custom:
            return DesignSystem.Colors.primaryAction
        }
    }
    
    private func startChallenge(_ challenge: Challenge) {
        print("ChallengeSelectionView: Starting challenge - \(challenge.name)")
        
        // Create a copy of the challenge
        let newChallenge: Challenge
        
        switch challenge.type {
        case .seventyFiveHard:
            newChallenge = Challenge.createSeventyFiveHardChallenge()
            print("ChallengeSelectionView: Created 75 Hard challenge")
        case .waterFasting:
            newChallenge = Challenge.createWaterFastingChallenge()
            print("ChallengeSelectionView: Created Water Fasting challenge")
        case .thirtyOneModified:
            newChallenge = Challenge.createThirtyOneModifiedChallenge()
            print("ChallengeSelectionView: Created 31 Modified challenge")
        case .custom:
            newChallenge = Challenge(
                type: .custom,
                name: challenge.name,
                challengeDescription: challenge.description,
                durationInDays: challenge.durationInDays
            )
            print("ChallengeSelectionView: Created Custom challenge")
        }
        
        // Ensure the new challenge has the exact same name and description as the template
        newChallenge.name = challenge.name
        newChallenge.challengeDescription = challenge.description
        
        // Start the challenge
        newChallenge.startChallenge()
        print("ChallengeSelectionView: Challenge started with start date: \(String(describing: newChallenge.startDate))")
        
        // Insert into model context
        modelContext.insert(newChallenge)
        print("ChallengeSelectionView: Challenge inserted into model context")
        
        // Save changes with error handling
        do {
            try modelContext.save()
            print("ChallengeSelectionView: Challenge saved successfully")
            
            // Force generate daily tasks for the new challenge
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("ChallengeSelectionView: Generating daily tasks for new challenge")
                let tasksManager = DailyTasksManager(modelContext: self.modelContext)
                let generatedTasks = tasksManager.generateDailyTasks()
                print("ChallengeSelectionView: Generated \(generatedTasks.count) daily tasks")
                
                // Navigate to Today tab after tasks are generated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    print("ChallengeSelectionView: Posting notification to switch to Today tab")
                    NotificationCenter.default.post(name: Notification.Name("SwitchToTodayTab"), object: nil)
                }
            }
        } catch {
            print("ChallengeSelectionView: Error saving challenge: \(error)")
        }
    }
    
    private func stopActiveChallenges() {
        for challenge in activeChallenges {
            stopChallenge(challenge)
        }
    }
    
    private func stopChallenge(_ challenge: Challenge) {
        // Find the actual challenge instance if this is a template
        let challengeToStop: Challenge
        if challenge.status != .inProgress {
            if let activeChallenge = activeChallenges.first(where: { 
                $0.name == challenge.name && $0.type == challenge.type 
            }) {
                challengeToStop = activeChallenge
                print("Found active challenge to stop: \(activeChallenge.name) with ID \(activeChallenge.id)")
            } else {
                print("No matching active challenge found to stop for: \(challenge.name)")
                return
            }
        } else {
            challengeToStop = challenge
            print("Stopping already active challenge: \(challenge.name) with ID \(challenge.id)")
        }
        
        // Delete any daily tasks associated with this challenge
        let dailyTaskDescriptor = FetchDescriptor<DailyTask>()
        let allDailyTasks = SwiftDataErrorHandler.fetchEntities(
            modelContext: modelContext,
            fetchDescriptor: dailyTaskDescriptor,
            context: "ChallengeDetailSheet.stopChallenge - fetching daily tasks"
        )
        
        let challengeTasks = allDailyTasks.filter { $0.challenge?.id == challengeToStop.id }
        for task in challengeTasks {
            modelContext.delete(task)
        }
        print("Deleted \(challengeTasks.count) daily tasks for challenge: \(challengeToStop.name)")
        
        // Mark the challenge as failed
        challengeToStop.status = .failed
        challengeToStop.endDate = Date()
        
        // Save changes
        if SwiftDataErrorHandler.saveContext(modelContext, context: "ChallengeDetailSheet.stopChallenge") {
            print("Challenge stopped successfully: \(challengeToStop.name)")
        } else {
            print("Error stopping challenge: \(challengeToStop.name)")
        }
    }
    
    // Add this method to handle challenge selection
    private func selectChallenge(_ challenge: Challenge) {
        if isProcessingTap {
            print("ChallengeSelectionView: Ignoring tap, already processing")
            return
        }
        
        isProcessingTap = true
        
        print("ChallengeSelectionView: Challenge selected - \(challenge.name)")
        print("ChallengeSelectionView: Challenge ID - \(challenge.id)")
        print("ChallengeSelectionView: Challenge image - \(challenge.imageName ?? "nil")")
        
        // Set loading state
        isLoadingChallenge = true
        
        // Create a deep copy of the challenge to ensure it's fully loaded
        let challengeCopy: Challenge
        
        switch challenge.type {
        case .seventyFiveHard:
            challengeCopy = Challenge.createSeventyFiveHardChallenge()
            challengeCopy.name = challenge.name
            challengeCopy.challengeDescription = challenge.description
            challengeCopy.status = .notStarted
        case .waterFasting:
            challengeCopy = Challenge.createWaterFastingChallenge(durationInDays: challenge.durationInDays)
            challengeCopy.name = challenge.name
            challengeCopy.challengeDescription = challenge.description
            challengeCopy.status = .notStarted
        case .thirtyOneModified:
            challengeCopy = Challenge.createThirtyOneModifiedChallenge()
            challengeCopy.name = challenge.name
            challengeCopy.challengeDescription = challenge.description
            challengeCopy.durationInDays = challenge.durationInDays
            challengeCopy.status = .notStarted
        case .custom:
            challengeCopy = Challenge(
                type: .custom,
                name: challenge.name,
                challengeDescription: challenge.description,
                durationInDays: challenge.durationInDays
            )
        }
        
        // First set the selected challenge
        selectedTemplateChallenge = challengeCopy
        
        // Then show the detail view with animation
        print("ChallengeSelectionView: Showing detail for - \(challengeCopy.name)")
        print("ChallengeSelectionView: Challenge copy has \(challengeCopy.tasks.count) tasks")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showingChallengeDetail = true
        }
        
        // Reset loading state
        isLoadingChallenge = false
        
        // Reset the processing flag
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isProcessingTap = false
        }
    }
    
    // Helper method to create default tasks for a challenge
    private func createDefaultTasksForChallenge(_ challenge: Challenge) {
        // Implementation depends on your task model
        // This is a simplified version
        switch challenge.type {
        case .seventyFiveHard:
            let workoutTask = Task(name: "Complete two 45-minute workouts", description: "Workout sessions to build strength and endurance", type: .workout)
            workoutTask.challenge = challenge
            modelContext.insert(workoutTask)
            
            let waterTask = Task(name: "Drink 1 gallon of water", description: "Stay hydrated throughout the day", type: .water)
            waterTask.challenge = challenge
            modelContext.insert(waterTask)
            
        case .waterFasting:
            let fastingTask = Task(name: "Complete fasting hours", description: "Follow your intermittent fasting schedule", type: .fasting)
            fastingTask.challenge = challenge
            modelContext.insert(fastingTask)
            
        case .thirtyOneModified:
            let habitTask = Task(name: "Complete daily habits", description: "Maintain consistency with your daily habits", type: .habit)
            habitTask.challenge = challenge
            modelContext.insert(habitTask)
            
        case .custom:
            // Custom challenges should have user-defined tasks
            break
        }
        
        // Save changes
        do {
            try modelContext.save()
            print("Created default tasks for challenge: \(challenge.name)")
        } catch {
            print("Error creating default tasks: \(error)")
        }
    }
}

/// Section for displaying a group of challenges
struct ChallengeSection: View {
    // MARK: - Properties
    let title: String
    let challenges: [Challenge]
    let onSelect: ChallengeSelectionHandler
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text(title)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: DesignSystem.Spacing.m) {
                ForEach(challenges) { challenge in
                    challengeCard(for: challenge)
                        .id(challenge.id) // Ensure each card has a unique ID
                }
            }
        }
        .onAppear {
            print("ChallengeSection: Section appeared with title \(title) and \(challenges.count) challenges")
            for challenge in challenges {
                print("ChallengeSection: Challenge in section - \(challenge.name), ID: \(challenge.id)")
            }
        }
    }
    
    // MARK: - Subviews
    private func challengeCard(for challenge: Challenge) -> some View {
        CTChallengeCard(
            title: challenge.name,
            description: challenge.description,
            progress: challenge.progress,
            image: challenge.imageName,
            style: .glass
        ) {
            print("Challenge selected: \(challenge.name), ID: \(challenge.id), Status: \(challenge.status.rawValue)")
            print("Challenge details - Start date: \(String(describing: challenge.startDate)), End date: \(String(describing: challenge.endDate))")
            print("Challenge tasks count: \(challenge.tasks.count)")
            
            // Add a small delay before calling onSelect to ensure UI is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                print("ChallengeSection: Calling onSelect for challenge - \(challenge.name)")
                onSelect(challenge)
            }
        }
    }
}

/// Sheet for displaying challenge details before starting
struct ChallengeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Challenge.startDate, order: .reverse) private var allChallenges: [Challenge]
    
    var activeChallenges: [Challenge] {
        allChallenges.filter { $0.status == .inProgress }
    }
    
    let challenge: Challenge
    var onStart: () -> Void
    
    @State private var showingAlreadyActiveAlert = false
    @State private var showingStopConfirmation = false
    @State private var isViewReady = true // Set to true by default
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    
    var body: some View {
        ZStack {
            // Premium animated background
            PremiumBackground()
            
            ScrollView {
                if let errorMessage = errorMessage {
                    VStack {
                        Text("Error Loading Challenge")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding(.top)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            loadChallengeData()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    .padding()
                } else if isViewReady {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                        challengeHeaderView
                        challengeDescriptionView
                        dailyTasksView
                        benefitsView
                        actionButtonView
                    }
                    .padding(.vertical)
                } else {
                    VStack {
                        ProgressView("Loading challenge details...")
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            // Load challenge data immediately
            loadChallengeData()
        }
        .alert("Challenge Already Active", isPresented: $showingAlreadyActiveAlert) {
            Button("OK", role: .cancel) { }
            Button("Stop Current Challenge", role: .destructive) {
                stopActiveChallenges()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onStart()
                    dismiss()
                }
            }
        } message: {
            Text("You already have an active challenge. You need to stop it before starting a new one.")
        }
        .alert("Stop Challenge", isPresented: $showingStopConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Stop Challenge", role: .destructive) {
                stopChallenge(challenge)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to stop this challenge? Your progress will be saved, but the challenge will be marked as failed.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func loadChallengeData() {
        print("ChallengeDetailSheet: Loading data for challenge - \(challenge.name)")
        print("ChallengeDetailSheet: Challenge ID - \(challenge.id)")
        
        // Reset error state
        errorMessage = nil
        
        // Verify challenge data
        if challenge.tasks.isEmpty {
            print("ChallengeDetailSheet: WARNING - Challenge has no tasks")
            // Instead of showing an error, we'll just log a warning
            // This allows the view to still be displayed even if tasks aren't loaded yet
            print("ChallengeDetailSheet: Will attempt to continue without tasks")
            return
        }
        
        print("ChallengeDetailSheet: Appeared for challenge - \(challenge.name)")
        print("ChallengeDetailSheet: Challenge status - \(challenge.status.rawValue)")
        print("ChallengeDetailSheet: Challenge ID - \(challenge.id)")
        print("ChallengeDetailSheet: Challenge has \(challenge.tasks.count) tasks")
        print("ChallengeDetailSheet: Active challenges count - \(activeChallenges.count)")
        
        // Log all active challenges for debugging
        if activeChallenges.isEmpty {
            print("ChallengeDetailSheet: No active challenges found")
        } else {
            for activeChallenge in activeChallenges {
                print("ChallengeDetailSheet: Active challenge - \(activeChallenge.name) with ID \(activeChallenge.id)")
            }
        }
        
        // Check if this challenge is already active
        let isActive = isChallengeActive(challenge)
        print("ChallengeDetailSheet: Is challenge active? \(isActive)")
    }
    
    // MARK: - Subviews
    
    private var challengeHeaderView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text(challenge.name)
                .font(DesignSystem.Typography.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            HStack {
                Label("\(challenge.durationInDays) Days", systemImage: "calendar")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Text(challengeDifficulty(challenge))
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.medium)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, 4)
                    .background(difficultyColor(challenge))
                    .foregroundColor(.white)
                    .cornerRadius(DesignSystem.BorderRadius.small)
            }
        }
        .padding()
        .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
        .cornerRadius(DesignSystem.BorderRadius.medium)
        .padding(.horizontal)
    }
    
    private var challengeDescriptionView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("About This Challenge")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(challenge.description)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
        .cornerRadius(DesignSystem.BorderRadius.medium)
        .padding(.horizontal)
    }
    
    private var dailyTasksView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("Daily Tasks")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            if challenge.tasks.isEmpty {
                // Show a placeholder if no tasks are available
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.m) {
                        ProgressView()
                            .padding()
                        Text("Loading tasks...")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    Spacer()
                }
                .padding()
                .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                .cornerRadius(DesignSystem.BorderRadius.medium)
            } else {
                // Show tasks if available
                ForEach(challenge.tasks) { task in
                    taskCard(task)
                }
            }
        }
        .padding()
        .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
        .cornerRadius(DesignSystem.BorderRadius.medium)
        .padding(.horizontal)
    }
    
    private var benefitsView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("Benefits")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
                
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                benefitRow(icon: "brain.head.profile", text: "Improved mental toughness")
                benefitRow(icon: "figure.walk", text: "Enhanced physical fitness")
                benefitRow(icon: "heart.fill", text: "Better overall health")
                benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Measurable progress")
            }
        }
        .padding()
        .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
        .cornerRadius(DesignSystem.BorderRadius.medium)
        .padding(.horizontal)
    }
    
    private var actionButtonView: some View {
        Group {
            if isChallengeActive(challenge) {
                CTButton(
                    title: "Stop Challenge",
                    icon: "stop.fill",
                    style: .danger,
                    size: .large
                ) {
                    print("ChallengeDetailSheet: Stopping challenge - \(challenge.name)")
                    showingStopConfirmation = true
                }
                        .padding()
                } else {
                CTButton(
                    title: "Start Challenge",
                    icon: "play.fill",
                    style: .primary,
                    size: .large
                ) {
                    print("ChallengeDetailSheet: Starting challenge - \(challenge.name)")
                    if !activeChallenges.isEmpty {
                        showingAlreadyActiveAlert = true
                    } else {
                        onStart()
                        dismiss()
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func taskCard(_ task: Task) -> some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: task.type?.icon ?? "checkmark.circle")
                .font(.system(size: 24))
                .foregroundColor(task.type?.color ?? Color.gray)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(task.name)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
                Text(task.taskDescription)
                    .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
            }
        
            Spacer()
        }
        .padding()
        .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
        .cornerRadius(DesignSystem.BorderRadius.medium)
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
                HStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 18))
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            
            Spacer()
        }
    }
    
    private func challengeDifficulty(_ challenge: Challenge) -> String {
        switch challenge.type {
        case .seventyFiveHard:
            return "Hard"
        case .waterFasting:
            return "Medium"
        case .thirtyOneModified:
            return "Easy"
        case .custom:
            return "Custom"
        }
    }
    
    private func difficultyColor(_ challenge: Challenge) -> Color {
        switch challenge.type {
        case .seventyFiveHard:
            return Color.red
        case .waterFasting:
            return Color.orange
        case .thirtyOneModified:
            return Color.green
        case .custom:
            return DesignSystem.Colors.primaryAction
        }
    }
    
    private func isChallengeActive(_ challenge: Challenge) -> Bool {
        print("ChallengeDetailSheet: Checking if challenge is active - \(challenge.name)")
        print("ChallengeDetailSheet: Challenge status - \(challenge.status.rawValue)")
        print("ChallengeDetailSheet: Challenge ID - \(challenge.id)")
        
        // First check if this specific challenge is active
        if challenge.status == .inProgress {
            print("Challenge is active by status check: \(challenge.name)")
            return true
        }
        
        // For template challenges, check if there's an active challenge with the same name AND type
        let matchingActiveChallenges = activeChallenges.filter { 
            $0.name == challenge.name && $0.type == challenge.type 
        }
        
        if !matchingActiveChallenges.isEmpty {
            print("ChallengeDetailSheet: Found \(matchingActiveChallenges.count) matching active challenges")
            
            for activeChallenge in matchingActiveChallenges {
                print("ChallengeDetailSheet: Matching active challenge - \(activeChallenge.name) with ID \(activeChallenge.id) and status \(activeChallenge.status.rawValue)")
            }
            
            print("Challenge active by name and type check: \(challenge.name) - true")
            return true
        }
        
        print("Challenge is not active: \(challenge.name)")
        return false
    }
    
    private func stopActiveChallenges() {
        for challenge in activeChallenges {
            stopChallenge(challenge)
        }
    }
    
    private func stopChallenge(_ challenge: Challenge) {
        // Find the actual challenge instance if this is a template
        let challengeToStop: Challenge
        if challenge.status != .inProgress {
            if let activeChallenge = activeChallenges.first(where: { 
                $0.name == challenge.name && $0.type == challenge.type 
            }) {
                challengeToStop = activeChallenge
                print("Found active challenge to stop: \(activeChallenge.name) with ID \(activeChallenge.id)")
            } else {
                print("No matching active challenge found to stop for: \(challenge.name)")
                return
            }
        } else {
            challengeToStop = challenge
            print("Stopping already active challenge: \(challenge.name) with ID \(challenge.id)")
        }
        
        // Delete any daily tasks associated with this challenge
        let dailyTaskDescriptor = FetchDescriptor<DailyTask>()
        let allDailyTasks = SwiftDataErrorHandler.fetchEntities(
            modelContext: modelContext,
            fetchDescriptor: dailyTaskDescriptor,
            context: "ChallengeDetailSheet.stopChallenge - fetching daily tasks"
        )
        
        let challengeTasks = allDailyTasks.filter { $0.challenge?.id == challengeToStop.id }
        for task in challengeTasks {
            modelContext.delete(task)
        }
        print("Deleted \(challengeTasks.count) daily tasks for challenge: \(challengeToStop.name)")
        
        // Mark the challenge as failed
        challengeToStop.status = .failed
        challengeToStop.endDate = Date()
        
        // Save changes
        if SwiftDataErrorHandler.saveContext(modelContext, context: "ChallengeDetailSheet.stopChallenge") {
            print("Challenge stopped successfully: \(challengeToStop.name)")
        } else {
            print("Error stopping challenge: \(challengeToStop.name)")
        }
    }
}

#Preview {
    ChallengesView()
        .modelContainer(for: Challenge.self, inMemory: true)
} 