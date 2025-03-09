import Foundation
import SwiftData
import Combine

/// Service for managing daily tasks
class DailyTasksManager: ObservableObject {
    var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Generates daily tasks for all active challenges for the specified date
    /// - Parameter date: The date to generate tasks for (defaults to today)
    /// - Returns: An array of generated daily tasks
    func generateDailyTasks(for date: Date = Date()) -> [DailyTask] {
        Logger.info("Generating daily tasks for date: \(date)", category: .tasks)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Safely fetch challenges with error handling
        var allChallenges: [Challenge] = []
        do {
            let fetchDescriptor: FetchDescriptor<Challenge> = FetchDescriptor()
            allChallenges = try modelContext.fetch(fetchDescriptor)
            Logger.info("Successfully fetched \(allChallenges.count) challenges", category: .tasks)
        } catch {
            Logger.error("Error fetching challenges: \(error)", category: .tasks)
            return []
        }
        
        // Filter for active challenges in memory
        let activeChallenges: [Challenge] = allChallenges.filter { 
            $0.status == .inProgress 
        }
        
        Logger.info("Found \(activeChallenges.count) active challenges", category: .tasks)
        
        // If there are no active challenges, return empty array
        if activeChallenges.isEmpty {
            Logger.info("No active challenges found", category: .tasks)
            return []
        }
        
        var generatedTasks: [DailyTask] = []
        
        // Check if we already have daily tasks for this date
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Safely fetch daily tasks with error handling
        var existingDailyTasks: [DailyTask] = []
        do {
            let dailyTaskDescriptor = FetchDescriptor<DailyTask>()
            let allDailyTasks = try modelContext.fetch(dailyTaskDescriptor)
            
            // Filter in memory
            existingDailyTasks = allDailyTasks.filter { 
                let taskDate = $0.date
                return taskDate >= startOfDay && taskDate < endOfDay
            }
            Logger.info("Found \(existingDailyTasks.count) existing daily tasks for today", category: .tasks)
        } catch {
            Logger.error("Error fetching daily tasks: \(error)", category: .tasks)
            return []
        }
        
        let existingTaskIds = Set(existingDailyTasks.compactMap { $0.task?.id })
        
        // For each active challenge, create daily tasks for its tasks
        for challenge in activeChallenges {
            Logger.info("Processing challenge: \(challenge.name) with \(challenge.tasks.count) tasks", category: .tasks)
            
            for task in challenge.tasks {
                // Skip if we already have a daily task for this task
                if existingTaskIds.contains(task.id) {
                    Logger.info("Task \(task.name) already has a daily task", category: .tasks)
                    continue
                }
                
                // Check if the task should be scheduled for this day based on recurrence
                if shouldScheduleTask(task, for: date) {
                    Logger.info("Scheduling task: \(task.name) for date: \(date)", category: .tasks)
                    
                    let dailyTask = DailyTask(
                        title: task.name,
                        date: startOfDay,
                        isCompleted: false,
                        challenge: challenge,
                        task: task
                    )
                    
                    modelContext.insert(dailyTask)
                    generatedTasks.append(dailyTask)
                }
            }
        }
        
        // Save the context with error handling
        do {
            if !generatedTasks.isEmpty {
                try modelContext.save()
                Logger.info("Generated and saved \(generatedTasks.count) new daily tasks", category: .tasks)
            } else {
                Logger.info("No new tasks to generate", category: .tasks)
            }
        } catch {
            Logger.error("Error saving daily tasks: \(error)", category: .tasks)
            return []
        }
        
        return generatedTasks
    }
    
    /// Retrieves daily tasks for a specific date
    /// - Parameter date: The date to retrieve tasks for (defaults to today)
    /// - Returns: An array of daily tasks for the specified date
    func getDailyTasks(for date: Date = Date()) -> [DailyTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            // Fetch all daily tasks and filter in memory
            let allDailyTasks = try modelContext.fetch(FetchDescriptor<DailyTask>())
            
            // Filter for the specific date
            let dailyTasks = allDailyTasks.filter { 
                let taskDate = $0.date
                return taskDate >= startOfDay && taskDate < endOfDay
            }
            
            // Sort by status and scheduled time in memory
            return dailyTasks.sorted { task1, task2 in
                // First sort by status
                if task1.status != task2.status {
                    return task1.status.rawValue < task2.status.rawValue
                }
                
                // Then sort by scheduled time if available
                guard let task1Unwrapped = task1.task, 
                      let time1 = task1Unwrapped.scheduledTime else { return true }
                guard let task2Unwrapped = task2.task,
                      let time2 = task2Unwrapped.scheduledTime else { return false }
                return time1 < time2
            }
        } catch {
            Logger.error("Error fetching daily tasks: \(error)", category: .tasks)
            return []
        }
    }
    
    /// Completes a daily task
    /// - Parameters:
    ///   - dailyTask: The daily task to complete
    ///   - actualValue: The actual value achieved (optional)
    ///   - notes: Notes for the completion (optional)
    func completeTask(_ dailyTask: DailyTask, actualValue: Double? = nil, notes: String? = nil) {
        dailyTask.complete(actualValue: actualValue, notes: notes)
        
        // Update challenge progress after completing a task
        if let challenge = dailyTask.challenge {
            updateChallengeProgress(for: challenge)
        }
        
        do {
            try modelContext.save()
        } catch {
            Logger.error("Error completing task: \(error)", category: .tasks)
        }
    }
    
    /// Marks a daily task as in progress
    /// - Parameters:
    ///   - dailyTask: The daily task to mark as in progress
    ///   - notes: Notes for the progress (optional)
    func markTaskInProgress(_ dailyTask: DailyTask, notes: String? = nil) {
        dailyTask.markInProgress(notes: notes)
        
        do {
            try modelContext.save()
        } catch {
            Logger.error("Error marking task in progress: \(error)", category: .tasks)
        }
    }
    
    /// Marks a daily task as failed
    /// - Parameters:
    ///   - dailyTask: The daily task to mark as failed
    ///   - notes: Notes for the failure (optional)
    func markTaskFailed(_ dailyTask: DailyTask, notes: String? = nil) {
        dailyTask.status = .failed
        dailyTask.completionTime = Date()
        dailyTask.notes = notes
        
        // Update the task's challenge progress if needed
        if let challenge = dailyTask.challenge {
            updateChallengeProgress(for: challenge)
        }
        
        do {
            try modelContext.save()
        } catch {
            Logger.error("Error marking task failed: \(error)", category: .tasks)
        }
    }
    
    /// Marks a task as missed
    /// - Parameters:
    ///   - dailyTask: The daily task to mark as missed
    ///   - notes: Optional notes about why it was missed
    func markTaskMissed(_ dailyTask: DailyTask, notes: String? = nil) {
        dailyTask.status = .missed
        dailyTask.completionTime = Date()
        dailyTask.notes = notes
        
        // Update the task's challenge progress if needed
        if let challenge = dailyTask.challenge {
            updateChallengeProgress(for: challenge)
        }
    }
    
    /// Resets a daily task to not started
    /// - Parameter dailyTask: The daily task to reset
    func resetTask(_ dailyTask: DailyTask) {
        dailyTask.reset()
        
        // Update challenge progress after resetting a task
        if let challenge = dailyTask.challenge {
            updateChallengeProgress(for: challenge)
        }
        
        do {
            try modelContext.save()
        } catch {
            Logger.error("Error resetting task: \(error)", category: .tasks)
        }
    }
    
    /// Updates the progress for a challenge
    func updateChallengeProgress(for challenge: Challenge) {
        guard challenge.status.rawValue == "inProgress" else { return }
        
        // Get all daily tasks
        let allDailyTasks = (try? modelContext.fetch(FetchDescriptor<DailyTask>())) ?? []
        
        // Filter for this challenge
        let challengeId = challenge.id
        let dailyTasks = allDailyTasks.filter { 
            guard let taskChallenge = $0.challenge else { return false }
            return taskChallenge.id == challengeId 
        }
        
        // Calculate the total number of tasks that should have been completed by now
        let today = Calendar.current.startOfDay(for: Date())
        let totalTasksToDate = dailyTasks.filter { $0.date <= today }.count
        
        // Calculate the number of completed tasks
        let completedTasks = dailyTasks.filter { $0.status.rawValue == "completed" }.count
        
        // Update the challenge progress
        if totalTasksToDate > 0 {
            // Calculate progress as a percentage of completed tasks out of total tasks to date
            let progress = Double(completedTasks) / Double(totalTasksToDate)
            
            // Check if the challenge is completed
            if let endDate = challenge.endDate, endDate <= today {
                challenge.status = progress >= 0.8 ? .completed : .failed
            }
            
            // Save the context
            do {
                try modelContext.save()
            } catch {
                Logger.error("Error updating challenge progress: \(error)", category: .tasks)
            }
        }
    }
    
    /// Gets the history of completed tasks for a challenge
    /// - Parameter challenge: The challenge to get history for
    /// - Returns: An array of completed daily tasks for the challenge
    func getTaskHistory(for challenge: Challenge) -> [DailyTask] {
        // Get all daily tasks
        let allDailyTasks = (try? modelContext.fetch(FetchDescriptor<DailyTask>())) ?? []
        
        // Filter for this challenge and completed/failed tasks
        let challengeId = challenge.id
        let completedTasks = allDailyTasks.filter {
            guard let taskChallenge = $0.challenge else { return false }
            return taskChallenge.id == challengeId && 
                  ($0.status == .completed || $0.status == .failed)
        }
        
        // Sort by date (most recent first)
        return completedTasks.sorted { $0.date > $1.date }
    }
    
    /// Generates tasks for a newly started challenge
    /// - Parameter challenge: The challenge that was just started
    /// - Returns: An array of generated daily tasks
    func generateTasksForNewChallenge(_ challenge: Challenge) -> [DailyTask] {
        guard challenge.status == .inProgress else { return [] }
        
        Logger.info("Generating tasks for new challenge: \(challenge.name) with \(challenge.tasks.count) tasks", category: .tasks)
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var generatedTasks: [DailyTask] = []
        
        // Check if we already have daily tasks for this challenge today
        let allDailyTasks = (try? modelContext.fetch(FetchDescriptor<DailyTask>())) ?? []
        let existingTasksToday = allDailyTasks.filter { 
            guard let taskChallenge = $0.challenge else { return false }
            return taskChallenge.id == challenge.id && calendar.isDate($0.date, inSameDayAs: today)
        }
        
        // If we already have tasks for this challenge today, return them
        if !existingTasksToday.isEmpty {
            return existingTasksToday
        }
        
        // Create daily tasks for each task in the challenge
        for task in challenge.tasks {
            // Check if the task should be scheduled for today
            if shouldScheduleTask(task, for: today) {
                let dailyTask = DailyTask(
                    title: task.name,
                    date: today,
                    isCompleted: false,
                    challenge: challenge,
                    task: task
                )
                
                modelContext.insert(dailyTask)
                generatedTasks.append(dailyTask)
                Logger.info("Generated daily task: \(dailyTask.title) for challenge: \(challenge.name)", category: .tasks)
            }
        }
        
        // Save the context
        do {
            try modelContext.save()
        } catch {
            Logger.error("Error saving daily tasks for new challenge: \(error)", category: .tasks)
        }
        
        return generatedTasks
    }
    
    // MARK: - Private Methods
    
    /// Determines if a task should be scheduled for the specified date based on its recurrence type
    /// - Parameters:
    ///   - task: The task to check
    ///   - date: The date to check against
    /// - Returns: True if the task should be scheduled for the date, false otherwise
    private func shouldScheduleTask(_ task: Task, for date: Date) -> Bool {
        let calendar = Calendar.current
        
        switch task.frequency {
        case .daily:
            return true
            
        case .weekly:
            // Check if the day of the week matches
            guard let startDate = task.challenge?.startDate else { return false }
            let startDay = calendar.component(.weekday, from: startDate)
            let dateDay = calendar.component(.weekday, from: date)
            return startDay == dateDay
            
        case .monthly:
            // Check if the day of the month matches
            guard let startDate = task.challenge?.startDate else { return false }
            let startDay = calendar.component(.day, from: startDate)
            let dateDay = calendar.component(.day, from: date)
            return startDay == dateDay
            
        case .anytime:
            // Only schedule once on the start date
            guard let startDate = task.challenge?.startDate else { return false }
            let startDay = calendar.startOfDay(for: startDate)
            let checkDay = calendar.startOfDay(for: date)
            return startDay == checkDay
        }
    }
} 