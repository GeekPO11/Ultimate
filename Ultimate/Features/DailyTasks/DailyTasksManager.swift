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
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            Logger.error("Failed to calculate end of day for date: \(date)", category: .tasks)
            return []
        }
        
        do {
            // Use SwiftData predicate for efficient database-level filtering
            let predicate = #Predicate<DailyTask> { dailyTask in
                dailyTask.date >= startOfDay && dailyTask.date < endOfDay
            }
            
            // Create fetch descriptor with predicate and sorting
            var descriptor = FetchDescriptor<DailyTask>(predicate: predicate)
            
            // Sort by date only (status sorting will be done in memory)
            descriptor.sortBy = [
                SortDescriptor(\DailyTask.date)
            ]
            
            let dailyTasks = try modelContext.fetch(descriptor)
            
            // Additional in-memory sorting for complex logic that can't be done in predicate
            return dailyTasks.sorted { task1, task2 in
                // First sort by status (not started, in progress, completed, failed)
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
        
        do {
            try modelContext.save()
        } catch {
            Logger.error("Error marking task missed: \(error)", category: .tasks)
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
        guard challenge.status == .inProgress else { 
            Logger.info("Not updating progress for non-active challenge: \(challenge.name)", category: .tasks)
            return 
        }
        
        // Ensure the challenge has a start date
        guard let challengeStartDate = challenge.startDate else {
            Logger.warning("Challenge '\(challenge.name)' has no start date, cannot calculate progress", category: .tasks)
            return
        }
        
        do {
            // Use SwiftData predicate to efficiently fetch only this challenge's tasks
            let challengeId = challenge.id
            let predicate = #Predicate<DailyTask> { dailyTask in
                dailyTask.challenge?.id == challengeId
            }
            
            let descriptor = FetchDescriptor<DailyTask>(predicate: predicate)
            let challengeTasks = try modelContext.fetch(descriptor)
            
            // Calculate the total number of tasks that should have been completed by now
            let today = Calendar.current.startOfDay(for: Date())
            let challengeStart = Calendar.current.startOfDay(for: challengeStartDate)
            
            // Filter for tasks from challenge start to today (inclusive)
            let tasksToDate = challengeTasks.filter { 
                $0.date >= challengeStart && $0.date <= today 
            }
            let totalTasksToDate = tasksToDate.count
            
            // Calculate the number of completed tasks
            let completedTasks = tasksToDate.filter { $0.status == .completed }.count
            
            Logger.info("Challenge '\(challenge.name)' progress: \(completedTasks)/\(totalTasksToDate) tasks completed (from \(challengeStart) to \(today))", category: .tasks)
            
            // Update the challenge progress if there are tasks to calculate against
            if totalTasksToDate > 0 {
                // Calculate progress as a percentage of completed tasks out of total tasks to date
                let progress = Double(completedTasks) / Double(totalTasksToDate)
                
                // Ensure progress is between 0.0 and 1.0
                let clampedProgress = max(0.0, min(1.0, progress))
                
                // Store progress on challenge
                challenge.progress = clampedProgress
                
                Logger.info("Challenge '\(challenge.name)' progress updated to \(Int(clampedProgress * 100))%", category: .tasks)
                
                // Check if the challenge has ended and should be marked as completed or failed
                if let endDate = challenge.endDate, endDate <= today {
                    // Use a reasonable threshold for completion (80%)
                    let completionThreshold = 0.8
                    let newStatus = clampedProgress >= completionThreshold ? ChallengeStatus.completed : ChallengeStatus.failed
                    
                    if challenge.status != newStatus {
                        challenge.status = newStatus
                        challenge.updatedAt = Date()
                        Logger.info("Challenge '\(challenge.name)' marked as \(newStatus.rawValue) with \(Int(clampedProgress * 100))% completion", category: .tasks)
                    }
                }
                
                // Save the context
                try modelContext.save()
                Logger.info("Challenge progress saved successfully", category: .tasks)
                
            } else {
                Logger.info("No tasks scheduled to date for challenge '\(challenge.name)', progress remains at 0%", category: .tasks)
                // Set progress to 0 if no tasks are scheduled yet
                challenge.progress = 0.0
                try modelContext.save()
            }
        } catch {
            Logger.error("Error updating challenge progress: \(error)", category: .tasks)
        }
    }
    
    /// Gets the history of completed tasks for a challenge
    /// - Parameter challenge: The challenge to get history for
    /// - Returns: An array of completed daily tasks for the challenge
    func getTaskHistory(for challenge: Challenge) -> [DailyTask] {
        do {
            // Use SwiftData predicate to efficiently fetch only this challenge's tasks
            let challengeId = challenge.id
            let predicate = #Predicate<DailyTask> { dailyTask in
                dailyTask.challenge?.id == challengeId
            }
            
            // Create fetch descriptor with predicate and sorting
            var descriptor = FetchDescriptor<DailyTask>(predicate: predicate)
            descriptor.sortBy = [SortDescriptor(\DailyTask.date, order: .reverse)] // Most recent first
            
            let allChallengeTasks = try modelContext.fetch(descriptor)
            
            // Filter for completed/failed tasks in memory
            return allChallengeTasks.filter { 
                $0.status == .completed || $0.status == .failed 
            }
        } catch {
            Logger.error("Error fetching task history for challenge '\(challenge.name)': \(error)", category: .tasks)
            return []
        }
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
        
        do {
            // Use SwiftData predicate to check if we already have daily tasks for this challenge today
            let challengeId = challenge.id
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(24 * 60 * 60)
            let predicate = #Predicate<DailyTask> { dailyTask in
                dailyTask.challenge?.id == challengeId && 
                dailyTask.date >= today && 
                dailyTask.date < nextDay
            }
            
            let descriptor = FetchDescriptor<DailyTask>(predicate: predicate)
            let existingTasksToday = try modelContext.fetch(descriptor)
            
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