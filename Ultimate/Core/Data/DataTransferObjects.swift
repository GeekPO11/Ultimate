import Foundation

// MARK: - Base DTO Protocol

protocol DataTransferObject: Codable, Equatable {
    var id: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

// MARK: - Challenge DTOs

struct CreateChallengeRequest: Codable, Equatable {
    let name: String
    let description: String
    let type: ChallengeType
    let durationInDays: Int
    let tasks: [CreateTaskRequest]
    let startDate: Date?
    let imageName: String?
}

struct UpdateChallengeRequest: Codable, Equatable {
    let name: String?
    let description: String?
    let durationInDays: Int?
    let startDate: Date?
    let endDate: Date?
    let status: ChallengeStatus?
    let imageName: String?
}

struct ChallengeResponse: DataTransferObject {
    let id: UUID
    let type: ChallengeType
    let name: String
    let description: String
    let startDate: Date?
    let endDate: Date?
    let durationInDays: Int
    let status: ChallengeStatus
    let progress: Double
    let imageName: String?
    let createdAt: Date
    let updatedAt: Date
    let taskCount: Int
    let completedDays: Int
    let totalDays: Int
}

struct ChallengeListItemResponse: DataTransferObject {
    let id: UUID
    let name: String
    let type: ChallengeType
    let status: ChallengeStatus
    let progress: Double
    let durationInDays: Int
    let startDate: Date?
    let endDate: Date?
    let imageName: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Task DTOs

struct CreateTaskRequest: Codable, Equatable {
    let name: String
    let description: String
    let type: TaskType?
    let frequency: TaskFrequency
    let timeOfDay: TimeOfDay
    let durationMinutes: Int?
    let targetValue: Double?
    let targetUnit: String?
    let scheduledTime: Date?
}

struct UpdateTaskRequest: Codable, Equatable {
    let name: String?
    let description: String?
    let type: TaskType?
    let frequency: TaskFrequency?
    let timeOfDay: TimeOfDay?
    let durationMinutes: Int?
    let targetValue: Double?
    let targetUnit: String?
    let scheduledTime: Date?
}

struct TaskResponse: DataTransferObject {
    let id: UUID
    let name: String
    let description: String
    let type: TaskType?
    let frequency: TaskFrequency
    let timeOfDay: TimeOfDay
    let durationMinutes: Int?
    let targetValue: Double?
    let targetUnit: String?
    let scheduledTime: Date?
    let challengeId: UUID?
    let challengeName: String?
    let createdAt: Date
    let updatedAt: Date
}

struct TaskListItemResponse: DataTransferObject {
    let id: UUID
    let name: String
    let type: TaskType?
    let timeOfDay: TimeOfDay
    let targetValue: Double?
    let targetUnit: String?
    let challengeName: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Daily Task DTOs

struct CreateDailyTaskRequest: Codable, Equatable {
    let title: String
    let date: Date
    let challengeId: UUID?
    let taskId: UUID?
    let notes: String?
}

struct UpdateDailyTaskRequest: Codable, Equatable {
    let status: TaskCompletionStatus?
    let notes: String?
    let actualValue: Double?
    let completionTime: Date?
}

struct CompleteDailyTaskRequest: Codable, Equatable {
    let actualValue: Double?
    let notes: String?
    let completionTime: Date?
}

struct DailyTaskResponse: DataTransferObject {
    let id: UUID
    let title: String
    let date: Date
    let status: TaskCompletionStatus
    let notes: String?
    let actualValue: Double?
    let targetValue: Double?
    let targetUnit: String?
    let completionTime: Date?
    let taskId: UUID?
    let taskName: String?
    let taskType: TaskType?
    let challengeId: UUID?
    let challengeName: String?
    let createdAt: Date
    let updatedAt: Date
}

struct DailyTaskListItemResponse: DataTransferObject {
    let id: UUID
    let title: String
    let status: TaskCompletionStatus
    let taskType: TaskType?
    let targetValue: Double?
    let targetUnit: String?
    let actualValue: Double?
    let challengeName: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Progress Photo DTOs

struct CreateProgressPhotoRequest: Codable, Equatable {
    let challengeId: UUID?
    let angle: PhotoAngle
    let notes: String?
    let challengeIteration: Int
    // Note: Image data is handled separately for performance
}

struct UpdateProgressPhotoRequest: Codable, Equatable {
    let notes: String?
    let isBlurred: Bool?
    let angle: PhotoAngle?
}

struct ProgressPhotoResponse: DataTransferObject {
    let id: UUID
    let challengeId: UUID?
    let challengeName: String?
    let date: Date
    let angle: PhotoAngle
    let fileURL: URL
    let notes: String?
    let isBlurred: Bool
    let challengeIteration: Int
    let createdAt: Date
    let updatedAt: Date
    let fileSizeBytes: Int64?
}

struct ProgressPhotoListItemResponse: DataTransferObject {
    let id: UUID
    let angle: PhotoAngle
    let date: Date
    let challengeName: String?
    let challengeIteration: Int
    let isBlurred: Bool
    let thumbnailURL: URL?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - User DTOs

struct CreateUserRequest: Codable, Equatable {
    let name: String
    let email: String?
    let heightCm: Double?
    let weightKg: Double?
    let languageCode: String?
}

struct UpdateUserRequest: Codable, Equatable {
    let name: String?
    let email: String?
    let heightCm: Double?
    let weightKg: Double?
    let profileImageURL: URL?
    let languageCode: String?
    let appearancePreference: String?
    let hasCompletedOnboarding: Bool?
}

struct UserResponse: DataTransferObject {
    let id: UUID
    let name: String
    let email: String?
    let profileImageURL: URL?
    let heightCm: Double?
    let weightKg: Double?
    let languageCode: String?
    let appearancePreference: String
    let hasCompletedOnboarding: Bool
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Analytics DTOs

struct ChallengeAnalyticsResponse: Codable, Equatable {
    let challengeId: UUID
    let challengeName: String
    let totalDays: Int
    let completedDays: Int
    let consistencyScore: Double
    let completionRate: Double
    let currentStreak: Int
    let longestStreak: Int
    let averageTasksPerDay: Double
    let taskCompletionRates: [String: Double] // Task name to completion rate
    let dailyProgress: [DailyProgressResponse]
}

struct DailyProgressResponse: Codable, Equatable {
    let date: Date
    let totalTasks: Int
    let completedTasks: Int
    let completionRate: Double
    let tasksDetails: [TaskProgressResponse]
}

struct TaskProgressResponse: Codable, Equatable {
    let taskName: String
    let taskType: TaskType?
    let status: TaskCompletionStatus
    let targetValue: Double?
    let actualValue: Double?
    let targetUnit: String?
}

struct UserAnalyticsResponse: Codable, Equatable {
    let userId: UUID
    let totalChallenges: Int
    let completedChallenges: Int
    let activeChallenges: Int
    let totalDaysTracked: Int
    let averageConsistency: Double
    let longestStreak: Int
    let currentStreak: Int
    let favoriteTaskTypes: [TaskType]
    let challengeHistory: [ChallengeAnalyticsResponse]
}

// MARK: - Search and Filter DTOs

struct ChallengeSearchRequest: Codable, Equatable {
    let query: String?
    let type: ChallengeType?
    let status: ChallengeStatus?
    let startDateFrom: Date?
    let startDateTo: Date?
    let sortBy: ChallengeSortOption
    let sortOrder: SortOrder
    let limit: Int?
    let offset: Int?
}

struct TaskSearchRequest: Codable, Equatable {
    let query: String?
    let type: TaskType?
    let timeOfDay: TimeOfDay?
    let frequency: TaskFrequency?
    let challengeId: UUID?
    let sortBy: TaskSortOption
    let sortOrder: SortOrder
    let limit: Int?
    let offset: Int?
}

struct DailyTaskSearchRequest: Codable, Equatable {
    let dateFrom: Date?
    let dateTo: Date?
    let status: TaskCompletionStatus?
    let challengeId: UUID?
    let taskType: TaskType?
    let sortBy: DailyTaskSortOption
    let sortOrder: SortOrder
    let limit: Int?
    let offset: Int?
}

// MARK: - Pagination DTOs

struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let totalCount: Int
    let pageSize: Int
    let currentPage: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrevious: Bool
}

struct PaginationRequest: Codable, Equatable {
    let page: Int
    let pageSize: Int
    let sortBy: String?
    let sortOrder: SortOrder
    
    init(page: Int = 1, pageSize: Int = 20, sortBy: String? = nil, sortOrder: SortOrder = .ascending) {
        self.page = max(1, page)
        self.pageSize = min(max(1, pageSize), 100) // Limit page size to 100
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }
    
    var offset: Int {
        return (page - 1) * pageSize
    }
}

// MARK: - Sort Options

enum ChallengeSortOption: String, Codable, CaseIterable {
    case name = "name"
    case createdAt = "createdAt"
    case startDate = "startDate"
    case endDate = "endDate"
    case progress = "progress"
    case status = "status"
}

enum TaskSortOption: String, Codable, CaseIterable {
    case name = "name"
    case type = "type"
    case timeOfDay = "timeOfDay"
    case createdAt = "createdAt"
    case frequency = "frequency"
}

enum DailyTaskSortOption: String, Codable, CaseIterable {
    case date = "date"
    case status = "status"
    case title = "title"
    case completionTime = "completionTime"
    case createdAt = "createdAt"
}

enum SortOrder: String, Codable, CaseIterable {
    case ascending = "asc"
    case descending = "desc"
}

// MARK: - Validation Response DTOs

struct ValidationResponse: Codable, Equatable {
    let isValid: Bool
    let errors: [ValidationErrorResponse]
    let warnings: [ValidationWarningResponse]
}

struct ValidationErrorResponse: Codable, Equatable {
    let field: String?
    let code: String
    let message: String
    let severity: ValidationSeverity
}

struct ValidationWarningResponse: Codable, Equatable {
    let field: String
    let message: String
    let severity: ValidationSeverity
}

enum ValidationSeverity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Error Response DTOs

struct ErrorResponse: Codable, Equatable {
    let code: String
    let message: String
    let details: String?
    let timestamp: Date
    let requestId: UUID
    let suggestions: [String]?
}

struct ApiErrorResponse: Codable, Equatable {
    let error: ErrorResponse
    let validationErrors: [ValidationErrorResponse]?
    let traceId: String?
}

// MARK: - Batch Operations DTOs

struct BatchCreateRequest<T: Codable>: Codable {
    let items: [T]
    let validateAll: Bool
    let stopOnFirstError: Bool
}

struct BatchUpdateRequest<T: Codable>: Codable {
    let items: [T]
    let validateAll: Bool
    let stopOnFirstError: Bool
}

struct BatchDeleteRequest: Codable {
    let ids: [UUID]
    let softDelete: Bool
    let stopOnFirstError: Bool
}

struct BatchOperationResponse<T: Codable>: Codable {
    let successful: [T]
    let failed: [BatchOperationError]
    let totalProcessed: Int
    let successCount: Int
    let failureCount: Int
}

struct BatchOperationError: Codable, Equatable {
    let itemId: UUID?
    let error: ErrorResponse
    let index: Int
}

// MARK: - Health Check DTOs

struct HealthCheckResponse: Codable, Equatable {
    let status: HealthStatus
    let timestamp: Date
    let version: String
    let database: DatabaseHealthResponse
    let storage: StorageHealthResponse
    let uptime: TimeInterval
}

struct DatabaseHealthResponse: Codable, Equatable {
    let status: HealthStatus
    let connectionCount: Int
    let responseTime: TimeInterval
    let lastMigration: String?
}

struct StorageHealthResponse: Codable, Equatable {
    let status: HealthStatus
    let availableSpace: Int64
    let usedSpace: Int64
    let photoCount: Int
}

enum HealthStatus: String, Codable, CaseIterable {
    case healthy = "healthy"
    case degraded = "degraded"
    case unhealthy = "unhealthy"
}

// MARK: - Export/Import DTOs

struct ExportRequest: Codable, Equatable {
    let format: ExportFormat
    let includePhotos: Bool
    let dateRange: DateRange?
    let challengeIds: [UUID]?
    let compression: CompressionLevel
}

struct ImportRequest: Codable, Equatable {
    let format: ExportFormat
    let overwriteExisting: Bool
    let validateData: Bool
    let dryRun: Bool
}

struct ExportResponse: Codable, Equatable {
    let exportId: UUID
    let downloadURL: URL
    let format: ExportFormat
    let fileSize: Int64
    let itemCount: Int
    let expiresAt: Date
    let createdAt: Date
}

struct ImportResponse: Codable, Equatable {
    let importId: UUID
    let status: ImportStatus
    let itemsProcessed: Int
    let itemsSkipped: Int
    let errors: [ImportError]
    let completedAt: Date?
}

struct DateRange: Codable, Equatable {
    let startDate: Date
    let endDate: Date
}

enum ExportFormat: String, Codable, CaseIterable {
    case json = "json"
    case csv = "csv"
    case xml = "xml"
}

enum CompressionLevel: String, Codable, CaseIterable {
    case none = "none"
    case low = "low"
    case medium = "medium"
    case high = "high"
}

enum ImportStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}

struct ImportError: Codable, Equatable {
    let line: Int?
    let field: String?
    let message: String
    let data: String?
}

// MARK: - DTO Extension Helpers

extension DataTransferObject {
    /// Validates that required fields are present and valid
    func validateRequired() throws {
        // Default implementation - can be overridden
    }
}

// MARK: - DTO Conversion Protocols

protocol ModelConvertible {
    associatedtype Model: PersistentModel
    
    func toModel() -> Model
    static func fromModel(_ model: Model) -> Self
}

protocol RequestValidatable {
    func validate() throws
    var validationRules: [String: [ValidationRule]] { get }
}

// MARK: - Common DTO Utilities

struct DTOConstants {
    static let maxStringLength = 1000
    static let maxDescriptionLength = 5000
    static let maxArraySize = 1000
    static let defaultPageSize = 20
    static let maxPageSize = 100
}

// MARK: - DTO Validation Extensions

extension CreateChallengeRequest: RequestValidatable {
    func validate() throws {
        let validator = FieldValidator("name", rules: ValidationRule.challengeName())
        let nameResult = validator.validate(name)
        
        if !nameResult.isValid {
            throw DataError.validationFailed(nameResult.errors)
        }
        
        let descValidator = FieldValidator("description", rules: ValidationRule.challengeDescription())
        let descResult = descValidator.validate(description)
        
        if !descResult.isValid {
            throw DataError.validationFailed(descResult.errors)
        }
        
        let durationValidator = FieldValidator("durationInDays", rules: ValidationRule.challengeDuration())
        let durationResult = durationValidator.validate(Double(durationInDays))
        
        if !durationResult.isValid {
            throw DataError.validationFailed(durationResult.errors)
        }
        
        if tasks.isEmpty {
            throw DataError.validationFailed([.businessRuleViolation("Challenge must have at least one task")])
        }
        
        // Validate all tasks
        for (index, task) in tasks.enumerated() {
            do {
                try task.validate()
            } catch {
                throw DataError.validationFailed([.businessRuleViolation("Task \(index + 1): \(error.localizedDescription)")])
            }
        }
    }
    
    var validationRules: [String: [ValidationRule]] {
        return [
            "name": ValidationRule.challengeName(),
            "description": ValidationRule.challengeDescription(),
            "durationInDays": ValidationRule.challengeDuration()
        ]
    }
}

extension CreateTaskRequest: RequestValidatable {
    func validate() throws {
        let nameValidator = FieldValidator("name", rules: ValidationRule.taskName())
        let nameResult = nameValidator.validate(name)
        
        if !nameResult.isValid {
            throw DataError.validationFailed(nameResult.errors)
        }
        
        if let targetValue = targetValue {
            let valueValidator = FieldValidator("targetValue", rules: ValidationRule.targetValue())
            let valueResult = valueValidator.validate(targetValue)
            
            if !valueResult.isValid {
                throw DataError.validationFailed(valueResult.errors)
            }
            
            if targetUnit?.isEmpty ?? true {
                throw DataError.validationFailed([.required(field: "targetUnit")])
            }
        }
        
        if let duration = durationMinutes, duration <= 0 {
            throw DataError.validationFailed([.invalidRange(field: "durationMinutes", min: 1, max: nil)])
        }
    }
    
    var validationRules: [String: [ValidationRule]] {
        return [
            "name": ValidationRule.taskName(),
            "targetValue": ValidationRule.targetValue()
        ]
    }
} 