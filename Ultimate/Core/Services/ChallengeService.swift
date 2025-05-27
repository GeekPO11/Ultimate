import Foundation
import SwiftData
import OSLog

// MARK: - Challenge Service Protocol

protocol ChallengeServiceProtocol {
    // Core CRUD operations
    func createChallenge(_ request: CreateChallengeRequest) async throws -> ChallengeResponse
    func updateChallenge(_ challengeId: UUID, with request: UpdateChallengeRequest) async throws -> ChallengeResponse
    func deleteChallenge(_ challengeId: UUID, soft: Bool) async throws
    func getChallenge(id: UUID) async throws -> ChallengeResponse?
    func getAllChallenges() async throws -> [ChallengeListItemResponse]
    
    // Challenge lifecycle operations
    func startChallenge(_ challengeId: UUID) async throws -> ChallengeResponse
    func completeChallenge(_ challengeId: UUID) async throws -> ChallengeResponse
    func failChallenge(_ challengeId: UUID) async throws -> ChallengeResponse
    func pauseChallenge(_ challengeId: UUID) async throws -> ChallengeResponse
    func resumeChallenge(_ challengeId: UUID) async throws -> ChallengeResponse
    
    // Query operations
    func getActiveChallenge() async throws -> ChallengeResponse?
    func getChallenges(by status: ChallengeStatus) async throws -> [ChallengeListItemResponse]
    func getChallenges(by type: ChallengeType) async throws -> [ChallengeListItemResponse]
    func searchChallenges(_ request: ChallengeSearchRequest) async throws -> PaginatedResponse<ChallengeListItemResponse>
    
    // Analytics operations
    func getChallengeAnalytics(_ challengeId: UUID) async throws -> ChallengeAnalyticsResponse
    func calculateProgress(_ challengeId: UUID) async throws -> Double
    
    // Validation operations
    func validateChallenge(_ request: CreateChallengeRequest) async throws -> ValidationResponse
    func validateChallengeUpdate(_ challengeId: UUID, request: UpdateChallengeRequest) async throws -> ValidationResponse
}

// MARK: - Challenge Service Implementation

final class ChallengeService: BaseDataService<Challenge>, ChallengeServiceProtocol, CacheableService {
    
    // MARK: - Properties
    
    typealias CacheKey = String
    let cache = DataCache<CacheKey>()
    private let taskService: TaskServiceProtocol
    private let dailyTaskService: DailyTaskServiceProtocol
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        taskService: TaskServiceProtocol,
        dailyTaskService: DailyTaskServiceProtocol,
        auditLogger: AuditLogger = AuditLogger()
    ) {
        self.taskService = taskService
        self.dailyTaskService = dailyTaskService
        super.init(modelContext: modelContext, auditLogger: auditLogger)
    }
    
    // MARK: - Core CRUD Operations
    
    func createChallenge(_ request: CreateChallengeRequest) async throws -> ChallengeResponse {
        // Validate request
        try request.validate()
        
        // Check for active challenges if this is starting immediately
        if request.startDate != nil {
            let activeChallenge = try await getActiveChallenge()
            if activeChallenge != nil {
                throw DataError.businessRuleViolation("Cannot start a new challenge while another is active")
            }
        }
        
        // Create challenge model
        let challenge = Challenge(
            type: request.type,
            name: request.name,
            challengeDescription: request.description,
            startDate: request.startDate,
            durationInDays: request.durationInDays,
            status: request.startDate != nil ? .inProgress : .notStarted,
            imageName: request.imageName
        )
        
        // Create and add tasks
        for taskRequest in request.tasks {
            let task = Task(
                name: taskRequest.name,
                description: taskRequest.description,
                type: taskRequest.type,
                frequency: taskRequest.frequency,
                timeOfDay: taskRequest.timeOfDay,
                durationMinutes: taskRequest.durationMinutes,
                targetValue: taskRequest.targetValue,
                targetUnit: taskRequest.targetUnit,
                scheduledTime: taskRequest.scheduledTime
            )
            
            try challenge.addTask(task)
        }
        
        // Save challenge
        let savedChallenge = try await create(challenge)
        
        // If starting immediately, set up daily tasks
        if savedChallenge.status == .inProgress {
            try await setupDailyTasks(for: savedChallenge)
        }
        
        // Clear cache
        invalidateCache(for: "active_challenge")
        invalidateCache(for: "all_challenges")
        
        // Convert to response
        return try await convertToResponse(savedChallenge)
    }
    
    func updateChallenge(_ challengeId: UUID, with request: UpdateChallengeRequest) async throws -> ChallengeResponse {
        guard let challenge = try await read(id: challengeId) else {
            throw DataError.businessRuleViolation("Challenge not found")
        }
        
        // Validate update request
        try await validateChallengeUpdate(challengeId, request: request)
        
        // Apply updates
        if let name = request.name {
            challenge.name = name
        }
        
        if let description = request.description {
            challenge.challengeDescription = description
        }
        
        if let durationInDays = request.durationInDays {
            // Only allow duration changes for challenges that haven't started
            if challenge.status == .notStarted {
                challenge.durationInDays = durationInDays
            } else {
                throw DataError.businessRuleViolation("Cannot change duration of started challenge")
            }
        }
        
        if let startDate = request.startDate {
            // Only allow start date changes for challenges that haven't started
            if challenge.status == .notStarted {
                challenge.startDate = startDate
                challenge.endDate = Calendar.current.date(byAdding: .day, value: challenge.durationInDays, to: startDate)
            } else {
                throw DataError.businessRuleViolation("Cannot change start date of started challenge")
            }
        }
        
        if let endDate = request.endDate {
            challenge.endDate = endDate
        }
        
        if let status = request.status {
            try await updateChallengeStatus(challenge, to: status)
        }
        
        if let imageName = request.imageName {
            challenge.imageName = imageName
        }
        
        // Save updates
        let updatedChallenge = try await update(challenge)
        
        // Clear relevant caches
        invalidateCache(for: "challenge_\(challengeId)")
        invalidateCache(for: "active_challenge")
        invalidateCache(for: "all_challenges")
        
        return try await convertToResponse(updatedChallenge)
    }
    
    func deleteChallenge(_ challengeId: UUID, soft: Bool = true) async throws {
        guard let challenge = try await read(id: challengeId) else {
            throw DataError.businessRuleViolation("Challenge not found")
        }
        
        // Don't allow deletion of active challenges
        if challenge.status == .inProgress {
            throw DataError.businessRuleViolation("Cannot delete an active challenge. Please complete or fail it first.")
        }
        
        // Delete associated daily tasks if hard delete
        if !soft {
            // This would be handled by cascade rules in a real database
            // For now, we'll manually clean up
        }
        
        try await delete(challenge, soft: soft)
        
        // Clear caches
        invalidateCache(for: "challenge_\(challengeId)")
        invalidateCache(for: "all_challenges")
    }
    
    func getChallenge(id: UUID) async throws -> ChallengeResponse? {
        // Check cache first
        if let cached = getCached("challenge_\(id)", type: ChallengeResponse.self) {
            return cached
        }
        
        guard let challenge = try await read(id: id) else {
            return nil
        }
        
        let response = try await convertToResponse(challenge)
        
        // Cache the response
        setCached(response, for: "challenge_\(id)")
        
        return response
    }
    
    func getAllChallenges() async throws -> [ChallengeListItemResponse] {
        // Check cache first
        if let cached = getCached("all_challenges", type: [ChallengeListItemResponse].self) {
            return cached
        }
        
        let challenges = try await getAll()
        let responses = challenges.map { convertToListItemResponse($0) }
        
        // Cache the responses
        setCached(responses, for: "all_challenges")
        
        return responses
    }
    
    // MARK: - Challenge Lifecycle Operations
    
    func startChallenge(_ challengeId: UUID) async throws -> ChallengeResponse {
        guard let challenge = try await read(id: challengeId) else {
            throw DataError.businessRuleViolation("Challenge not found")
        }
        
        // Check for existing active challenges
        let activeChallenge = try await getActiveChallenge()
        if activeChallenge != nil && activeChallenge!.id != challengeId {
            throw DataError.businessRuleViolation("Cannot start challenge while another is active")
        }
        
        // Start the challenge
        try challenge.startChallenge()
        let updatedChallenge = try await update(challenge)
        
        // Set up daily tasks
        try await setupDailyTasks(for: updatedChallenge)
        
        // Clear caches
        invalidateCache(for: "challenge_\(challengeId)")
        invalidateCache(for: "active_challenge")
        
        return try await convertToResponse(updatedChallenge)
    }
    
    func completeChallenge(_ challengeId: UUID) async throws -> ChallengeResponse {
        guard let challenge = try await read(id: challengeId) else {
            throw DataError.businessRuleViolation("Challenge not found")
        }
        
        try challenge.completeChallenge()
        let updatedChallenge = try await update(challenge)
        
        // Clear caches
        invalidateCache(for: "challenge_\(challengeId)")
        invalidateCache(for: "active_challenge")
        
        return try await convertToResponse(updatedChallenge)
    }
    
    func failChallenge(_ challengeId: UUID) async throws -> ChallengeResponse {
        guard let challenge = try await read(id: challengeId) else {
            throw DataError.businessRuleViolation("Challenge not found")
        }
        
        try challenge.failChallenge()
        let updatedChallenge = try await update(challenge)
        
        // Clear caches
        invalidateCache(for: "challenge_\(challengeId)")
        invalidateCache(for: "active_challenge")
        
        return try await convertToResponse(updatedChallenge)
    }
    
    func pauseChallenge(_ challengeId: UUID) async throws -> ChallengeResponse {
        guard let challenge = try await read(id: challengeId) else {
            throw DataError.businessRuleViolation("Challenge not found")
        }
        
        try challenge.pauseChallenge()
        let updatedChallenge = try await update(challenge)
        
        // Clear caches
        invalidateCache(for: "challenge_\(challengeId)")
        invalidateCache(for: "active_challenge")
        
        return try await convertToResponse(updatedChallenge)
    }
    
    func resumeChallenge(_ challengeId: UUID) async throws -> ChallengeResponse {
        guard let challenge = try await read(id: challengeId) else {
            throw DataError.businessRuleViolation("Challenge not found")
        }
        
        try challenge.resumeChallenge()
        let updatedChallenge = try await update(challenge)
        
        // Clear caches
        invalidateCache(for: "challenge_\(challengeId)")
        invalidateCache(for: "active_challenge")
        
        return try await convertToResponse(updatedChallenge)
    }
    
    // MARK: - Query Operations
    
    func getActiveChallenge() async throws -> ChallengeResponse? {
        // Check cache first
        if let cached = getCached("active_challenge", type: ChallengeResponse.self) {
            return cached
        }
        
        let challenges = try await getChallenges(by: .inProgress)
        let activeChallenge = challenges.first
        
        if let activeResponse = activeChallenge {
            // Get full challenge details
            let fullChallenge = try await getChallenge(id: activeResponse.id)
            
            // Cache the response
            if let full = fullChallenge {
                setCached(full, for: "active_challenge")
            }
            
            return fullChallenge
        }
        
        return nil
    }
    
    func getChallenges(by status: ChallengeStatus) async throws -> [ChallengeListItemResponse] {
        let allChallenges = try await getAllChallenges()
        return allChallenges.filter { $0.status == status }
    }
    
    func getChallenges(by type: ChallengeType) async throws -> [ChallengeListItemResponse] {
        let allChallenges = try await getAllChallenges()
        return allChallenges.filter { $0.type == type }
    }
    
    func searchChallenges(_ request: ChallengeSearchRequest) async throws -> PaginatedResponse<ChallengeListItemResponse> {
        let challenges = try await getAll()
        
        // Apply filters
        var filteredChallenges = challenges
        
        if let query = request.query, !query.isEmpty {
            filteredChallenges = filteredChallenges.filter { challenge in
                challenge.name.localizedCaseInsensitiveContains(query) ||
                challenge.challengeDescription.localizedCaseInsensitiveContains(query)
            }
        }
        
        if let type = request.type {
            filteredChallenges = filteredChallenges.filter { $0.type == type }
        }
        
        if let status = request.status {
            filteredChallenges = filteredChallenges.filter { $0.status == status }
        }
        
        if let startDateFrom = request.startDateFrom {
            filteredChallenges = filteredChallenges.filter { challenge in
                guard let startDate = challenge.startDate else { return false }
                return startDate >= startDateFrom
            }
        }
        
        if let startDateTo = request.startDateTo {
            filteredChallenges = filteredChallenges.filter { challenge in
                guard let startDate = challenge.startDate else { return false }
                return startDate <= startDateTo
            }
        }
        
        // Apply sorting
        filteredChallenges.sort { lhs, rhs in
            switch request.sortBy {
            case .name:
                return request.sortOrder == .ascending ? lhs.name < rhs.name : lhs.name > rhs.name
            case .createdAt:
                return request.sortOrder == .ascending ? lhs.createdAt < rhs.createdAt : lhs.createdAt > rhs.createdAt
            case .startDate:
                let lhsDate = lhs.startDate ?? Date.distantPast
                let rhsDate = rhs.startDate ?? Date.distantPast
                return request.sortOrder == .ascending ? lhsDate < rhsDate : lhsDate > rhsDate
            case .endDate:
                let lhsDate = lhs.endDate ?? Date.distantFuture
                let rhsDate = rhs.endDate ?? Date.distantFuture
                return request.sortOrder == .ascending ? lhsDate < rhsDate : lhsDate > rhsDate
            case .progress:
                return request.sortOrder == .ascending ? lhs.progress < rhs.progress : lhs.progress > rhs.progress
            case .status:
                return request.sortOrder == .ascending ? lhs.status.rawValue < rhs.status.rawValue : lhs.status.rawValue > rhs.status.rawValue
            }
        }
        
        // Apply pagination
        let totalCount = filteredChallenges.count
        let limit = request.limit ?? 20
        let offset = request.offset ?? 0
        
        let startIndex = min(offset, totalCount)
        let endIndex = min(offset + limit, totalCount)
        
        let paginatedChallenges = Array(filteredChallenges[startIndex..<endIndex])
        let responses = paginatedChallenges.map { convertToListItemResponse($0) }
        
        let pageSize = limit
        let currentPage = (offset / pageSize) + 1
        let totalPages = (totalCount + pageSize - 1) / pageSize
        
        return PaginatedResponse(
            items: responses,
            totalCount: totalCount,
            pageSize: pageSize,
            currentPage: currentPage,
            totalPages: totalPages,
            hasNext: endIndex < totalCount,
            hasPrevious: offset > 0
        )
    }
    
    // MARK: - Analytics Operations
    
    func getChallengeAnalytics(_ challengeId: UUID) async throws -> ChallengeAnalyticsResponse {
        guard let challenge = try await read(id: challengeId) else {
            throw DataError.businessRuleViolation("Challenge not found")
        }
        
        // Get daily tasks for this challenge
        let dailyTasks = try await dailyTaskService.getDailyTasks(for: challengeId)
        
        // Calculate analytics
        let totalDays = challenge.totalDays
        let completedDays = challenge.completedDays
        let consistencyScore = challenge.calculateConsistencyScore()
        let completionRate = totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0.0
        
        // Calculate streaks and task completion rates
        let (currentStreak, longestStreak) = calculateStreaks(from: dailyTasks)
        let taskCompletionRates = calculateTaskCompletionRates(from: dailyTasks)
        let averageTasksPerDay = calculateAverageTasksPerDay(from: dailyTasks)
        let dailyProgress = calculateDailyProgress(from: dailyTasks)
        
        return ChallengeAnalyticsResponse(
            challengeId: challenge.id,
            challengeName: challenge.name,
            totalDays: totalDays,
            completedDays: completedDays,
            consistencyScore: consistencyScore,
            completionRate: completionRate,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            averageTasksPerDay: averageTasksPerDay,
            taskCompletionRates: taskCompletionRates,
            dailyProgress: dailyProgress
        )
    }
    
    func calculateProgress(_ challengeId: UUID) async throws -> Double {
        guard let challenge = try await read(id: challengeId) else {
            throw DataError.businessRuleViolation("Challenge not found")
        }
        
        return challenge.progress
    }
    
    // MARK: - Validation Operations
    
    func validateChallenge(_ request: CreateChallengeRequest) async throws -> ValidationResponse {
        do {
            try request.validate()
            return ValidationResponse(isValid: true, errors: [], warnings: [])
        } catch let error as DataError {
            if case .validationFailed(let validationErrors) = error {
                let errorResponses = validationErrors.map { validationError in
                    ValidationErrorResponse(
                        field: extractFieldName(from: validationError),
                        code: "validation_error",
                        message: validationError.localizedDescription,
                        severity: .high
                    )
                }
                return ValidationResponse(isValid: false, errors: errorResponses, warnings: [])
            }
            throw error
        }
    }
    
    func validateChallengeUpdate(_ challengeId: UUID, request: UpdateChallengeRequest) async throws -> ValidationResponse {
        guard let challenge = try await read(id: challengeId) else {
            throw DataError.businessRuleViolation("Challenge not found")
        }
        
        var errors: [ValidationErrorResponse] = []
        var warnings: [ValidationWarningResponse] = []
        
        // Validate individual fields if provided
        if let name = request.name {
            let validator = FieldValidator("name", rules: ValidationRule.challengeName())
            let result = validator.validate(name)
            if !result.isValid {
                errors.append(contentsOf: result.errors.map { error in
                    ValidationErrorResponse(
                        field: "name",
                        code: "validation_error",
                        message: error.localizedDescription,
                        severity: .high
                    )
                })
            }
        }
        
        if let description = request.description {
            let validator = FieldValidator("description", rules: ValidationRule.challengeDescription())
            let result = validator.validate(description)
            if !result.isValid {
                errors.append(contentsOf: result.errors.map { error in
                    ValidationErrorResponse(
                        field: "description",
                        code: "validation_error",
                        message: error.localizedDescription,
                        severity: .high
                    )
                })
            }
        }
        
        // Business rule validations
        if request.durationInDays != nil && challenge.status != .notStarted {
            warnings.append(ValidationWarningResponse(
                field: "durationInDays",
                message: "Cannot change duration of started challenge",
                severity: .high
            ))
        }
        
        if request.startDate != nil && challenge.status != .notStarted {
            warnings.append(ValidationWarningResponse(
                field: "startDate",
                message: "Cannot change start date of started challenge",
                severity: .high
            ))
        }
        
        return ValidationResponse(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Cacheable Service Implementation
    
    func getCached<T>(_ key: CacheKey, type: T.Type) -> T? {
        return cache.get(key, type: type)
    }
    
    func setCached<T>(_ value: T, for key: CacheKey) {
        cache.set(value, for: key)
    }
    
    func invalidateCache(for key: CacheKey) {
        cache.remove(key)
    }
    
    func clearCache() {
        cache.clear()
    }
    
    // MARK: - Private Helper Methods
    
    private func updateChallengeStatus(_ challenge: Challenge, to status: ChallengeStatus) async throws {
        switch status {
        case .inProgress:
            try challenge.startChallenge()
            try await setupDailyTasks(for: challenge)
        case .completed:
            try challenge.completeChallenge()
        case .failed:
            try challenge.failChallenge()
        case .notStarted:
            // Allow reverting to not started only if no progress has been made
            if challenge.completedDays == 0 {
                challenge.status = .notStarted
                challenge.startDate = nil
                challenge.endDate = nil
            } else {
                throw DataError.businessRuleViolation("Cannot revert challenge with existing progress")
            }
        }
    }
    
    private func setupDailyTasks(for challenge: Challenge) async throws {
        // This would integrate with the DailyTaskService to create daily task instances
        // For now, this is a placeholder
        Logger.info("Setting up daily tasks for challenge: \(challenge.name)", category: .database)
    }
    
    private func convertToResponse(_ challenge: Challenge) async throws -> ChallengeResponse {
        let taskCount = challenge.tasks.count
        let completedDays = challenge.completedDays
        let totalDays = challenge.totalDays
        
        return ChallengeResponse(
            id: challenge.id,
            type: challenge.type,
            name: challenge.name,
            description: challenge.challengeDescription,
            startDate: challenge.startDate,
            endDate: challenge.endDate,
            durationInDays: challenge.durationInDays,
            status: challenge.status,
            progress: challenge.progress,
            imageName: challenge.imageName,
            createdAt: challenge.createdAt,
            updatedAt: challenge.updatedAt,
            taskCount: taskCount,
            completedDays: completedDays,
            totalDays: totalDays
        )
    }
    
    private func convertToListItemResponse(_ challenge: Challenge) -> ChallengeListItemResponse {
        return ChallengeListItemResponse(
            id: challenge.id,
            name: challenge.name,
            type: challenge.type,
            status: challenge.status,
            progress: challenge.progress,
            durationInDays: challenge.durationInDays,
            startDate: challenge.startDate,
            endDate: challenge.endDate,
            imageName: challenge.imageName,
            createdAt: challenge.createdAt,
            updatedAt: challenge.updatedAt
        )
    }
    
    private func extractFieldName(from error: ValidationError) -> String? {
        switch error {
        case .required(let field),
             .invalidLength(let field, _, _),
             .invalidRange(let field, _, _),
             .invalidFormat(let field, _),
             .invalidDate(let field, _),
             .constraintViolation(let field, _),
             .relationshipViolation(let field, _):
            return field
        case .businessRuleViolation:
            return nil
        }
    }
    
    private func calculateStreaks(from dailyTasks: [DailyTaskResponse]) -> (current: Int, longest: Int) {
        // Simplified streak calculation
        // In a real implementation, this would be more sophisticated
        return (current: 0, longest: 0)
    }
    
    private func calculateTaskCompletionRates(from dailyTasks: [DailyTaskResponse]) -> [String: Double] {
        // Group by task name and calculate completion rates
        let groupedTasks = Dictionary(grouping: dailyTasks) { $0.taskName ?? "Unknown" }
        
        var rates: [String: Double] = [:]
        for (taskName, tasks) in groupedTasks {
            let completedCount = tasks.filter { $0.status == .completed }.count
            let totalCount = tasks.count
            rates[taskName] = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        }
        
        return rates
    }
    
    private func calculateAverageTasksPerDay(from dailyTasks: [DailyTaskResponse]) -> Double {
        let groupedByDate = Dictionary(grouping: dailyTasks) { Calendar.current.startOfDay(for: $0.date) }
        let taskCounts = groupedByDate.values.map { $0.count }
        return taskCounts.isEmpty ? 0.0 : Double(taskCounts.reduce(0, +)) / Double(taskCounts.count)
    }
    
    private func calculateDailyProgress(from dailyTasks: [DailyTaskResponse]) -> [DailyProgressResponse] {
        let groupedByDate = Dictionary(grouping: dailyTasks) { Calendar.current.startOfDay(for: $0.date) }
        
        return groupedByDate.map { date, tasks in
            let completedTasks = tasks.filter { $0.status == .completed }.count
            let totalTasks = tasks.count
            let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
            
            let taskDetails = tasks.map { task in
                TaskProgressResponse(
                    taskName: task.taskName ?? "Unknown",
                    taskType: task.taskType,
                    status: task.status,
                    targetValue: task.targetValue,
                    actualValue: task.actualValue,
                    targetUnit: task.targetUnit
                )
            }
            
            return DailyProgressResponse(
                date: date,
                totalTasks: totalTasks,
                completedTasks: completedTasks,
                completionRate: completionRate,
                tasksDetails: taskDetails
            )
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Service Protocols (to be implemented)

protocol TaskServiceProtocol {
    // Task service methods would be defined here
}

protocol DailyTaskServiceProtocol {
    func getDailyTasks(for challengeId: UUID) async throws -> [DailyTaskResponse]
    // Other daily task service methods would be defined here
} 