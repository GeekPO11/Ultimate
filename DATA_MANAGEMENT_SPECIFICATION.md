# Data Management Specification
## Ultimate App - Data Layer Architecture & Rules

### Version: 2.0.0
### Last Updated: December 2024

---

## 🎯 **CORE PRINCIPLE**
> "The data layer must be completely independent of the UI layer. Any UI changes, redesigns, or complete rewrites must NOT affect data integrity, accessibility, or business logic."

---

## 📋 **TABLE OF CONTENTS**

1. [Data Layer Independence Rules](#data-layer-independence-rules)
2. [Model Design Standards](#model-design-standards)
3. [Validation Framework](#validation-framework)
4. [Service Layer Architecture](#service-layer-architecture)
5. [Error Handling & Recovery](#error-handling--recovery)
6. [Migration & Versioning Strategy](#migration--versioning-strategy)
7. [Testing Requirements](#testing-requirements)
8. [API Contract Standards](#api-contract-standards)
9. [Performance & Optimization](#performance--optimization)
10. [Security & Privacy](#security--privacy)

---

## 1. **DATA LAYER INDEPENDENCE RULES**

### 1.1 Separation of Concerns
```
UI Layer (Views/ViewModels) 
    ↓ (Only through Services)
Service Layer (Business Logic)
    ↓ (Only through Repositories)  
Repository Layer (Data Access)
    ↓ (Only through Models)
Model Layer (Data Entities)
    ↓
Storage Layer (SwiftData/CoreData)
```

### 1.2 **MANDATORY RULES:**

#### ❌ **NEVER ALLOWED:**
- Direct SwiftData/CoreData access from Views
- UI-specific code in Models or Services
- Business logic in Views or ViewModels
- Direct file system access from UI
- Hardcoded UI strings in data models
- Color/styling information in data models

#### ✅ **ALWAYS REQUIRED:**
- All data access through Service layer
- All business logic in Services
- Complete input validation in Services
- Comprehensive error handling at every layer
- Audit logging for all data operations
- Version migration support for all models

### 1.3 Interface Contracts
Every service MUST implement a protocol defining its public interface:

```swift
protocol ChallengeServiceProtocol {
    func createChallenge(_ request: CreateChallengeRequest) async throws -> Challenge
    func updateChallenge(_ challenge: Challenge, with request: UpdateChallengeRequest) async throws
    func deleteChallenge(_ challenge: Challenge) async throws
    func getAllChallenges() async throws -> [Challenge]
    func getActiveChallenge() async throws -> Challenge?
}
```

---

## 2. **MODEL DESIGN STANDARDS**

### 2.1 Required Properties
Every model MUST have:
```swift
@Model
final class ModelName {
    @Attribute(.unique) var id: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var version: Int = 1
    var isDeleted: Bool = false // Soft delete
    
    // Business properties...
}
```

### 2.2 Validation Rules
Every model MUST implement:
```swift
protocol ValidatableModel {
    func validate() throws
    func isValid() -> Bool
    var validationErrors: [ValidationError] { get }
}
```

### 2.3 Relationship Guidelines
- Use `@Relationship` for all foreign keys
- Always define inverse relationships
- Implement cascading delete rules
- Use lazy loading for large collections

### 2.4 Migration Support
Every model change MUST:
- Increment version number
- Include migration logic
- Maintain backward compatibility
- Include rollback capability

---

## 3. **VALIDATION FRAMEWORK**

### 3.1 Field-Level Validation
```swift
enum ValidationRule {
    case required
    case minLength(Int)
    case maxLength(Int)
    case range(min: Double, max: Double)
    case email
    case phone
    case url
    case dateRange(start: Date?, end: Date?)
    case custom((Any) -> ValidationResult)
}

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
}
```

### 3.2 Model-Level Validation
```swift
// Every model must validate business rules
func validateBusinessRules() throws {
    // Challenge-specific validation
    if durationInDays <= 0 {
        throw ValidationError.invalidDuration
    }
    
    if startDate != nil && endDate != nil && endDate! <= startDate! {
        throw ValidationError.invalidDateRange
    }
    
    if tasks.isEmpty && status == .inProgress {
        throw ValidationError.noTasksForActiveChallenge
    }
}
```

### 3.3 Cross-Model Validation
```swift
// Service-level validation across multiple models
func validateChallengeCreation(_ challenge: Challenge, with tasks: [Task]) throws {
    try challenge.validate()
    
    for task in tasks {
        try task.validate()
    }
    
    // Cross-validation rules
    if challenge.type == .seventyFiveHard && tasks.count != 5 {
        throw ValidationError.invalid75HardTasks
    }
}
```

---

## 4. **SERVICE LAYER ARCHITECTURE**

### 4.1 Service Responsibilities
Each service handles:
- Business logic validation
- Data transformation
- Error handling and recovery
- Audit logging
- Performance optimization
- Caching strategies

### 4.2 Required Service Methods
Every service MUST implement:
```swift
protocol BaseService {
    // CRUD Operations
    func create<T: ValidatableModel>(_ model: T) async throws -> T
    func read<T: PersistentModel>(id: UUID, type: T.Type) async throws -> T?
    func update<T: ValidatableModel>(_ model: T) async throws -> T
    func delete<T: PersistentModel>(_ model: T, soft: Bool) async throws
    
    // Validation
    func validate<T: ValidatableModel>(_ model: T) async throws
    
    // Error Recovery
    func recover(from error: Error) async throws
    
    // Audit
    func logOperation(_ operation: DataOperation, on model: Any)
}
```

### 4.3 Data Transfer Objects (DTOs)
Use DTOs for all service boundaries:
```swift
struct CreateChallengeRequest {
    let name: String
    let description: String
    let type: ChallengeType
    let durationInDays: Int
    let tasks: [CreateTaskRequest]
    let startDate: Date?
}

struct ChallengeResponse {
    let id: UUID
    let name: String
    let description: String
    let type: ChallengeType
    let status: ChallengeStatus
    let progress: Double
    let createdAt: Date
    let updatedAt: Date
}
```

---

## 5. **ERROR HANDLING & RECOVERY**

### 5.1 Error Hierarchy
```swift
enum DataError: LocalizedError {
    case validationFailed([ValidationError])
    case constraintViolation(String)
    case concurrencyConflict
    case storageUnavailable
    case corruptedData(String)
    case migrationFailed(String)
    case insufficientStorage
    case permissionDenied
    
    var errorDescription: String? { /* Implementation */ }
    var recoverySuggestion: String? { /* Implementation */ }
}
```

### 5.2 Recovery Strategies
```swift
protocol ErrorRecoverable {
    func canRecover(from error: Error) -> Bool
    func recover(from error: Error) async throws
}

// Implementation in services
func handleError(_ error: Error) async throws {
    switch error {
    case DataError.concurrencyConflict:
        try await retryWithExponentialBackoff()
    case DataError.corruptedData:
        try await attemptDataRepair()
    case DataError.storageUnavailable:
        try await switchToOfflineMode()
    default:
        throw error
    }
}
```

### 5.3 Audit Logging
```swift
struct DataOperation {
    let id: UUID
    let operation: OperationType
    let modelType: String
    let modelId: UUID?
    let userId: UUID?
    let timestamp: Date
    let success: Bool
    let error: String?
    let metadata: [String: Any]
}

enum OperationType {
    case create, read, update, delete
    case migrate, backup, restore
    case validate, sync
}
```

---

## 6. **MIGRATION & VERSIONING STRATEGY**

### 6.1 Version Management
```swift
struct SchemaVersion {
    let major: Int      // Breaking changes
    let minor: Int      // Feature additions
    let patch: Int      // Bug fixes
    
    static let current = SchemaVersion(major: 2, minor: 0, patch: 0)
}
```

### 6.2 Migration Rules
1. **Always backward compatible within major version**
2. **Provide automatic migration paths**
3. **Include data validation after migration**
4. **Support rollback for failed migrations**
5. **Backup data before major version migrations**

### 6.3 Migration Implementation
```swift
protocol MigrationStep {
    var fromVersion: SchemaVersion { get }
    var toVersion: SchemaVersion { get }
    var description: String { get }
    var isReversible: Bool { get }
    
    func execute(context: ModelContext) async throws
    func rollback(context: ModelContext) async throws
    func validate(context: ModelContext) async throws -> Bool
}
```

---

## 7. **TESTING REQUIREMENTS**

### 7.1 Test Coverage Requirements
- **100%** coverage for all validation logic
- **100%** coverage for all service methods
- **95%** coverage for error handling paths
- **90%** coverage for migration logic

### 7.2 Required Test Types
```swift
// Unit Tests - Every model and service
func testChallengeValidation() async throws {
    let challenge = Challenge(/* invalid data */)
    await assertThrows { try challenge.validate() }
}

// Integration Tests - Service interactions
func testChallengeServiceCRUD() async throws {
    let service = ChallengeService()
    let challenge = try await service.create(validRequest)
    let retrieved = try await service.read(challenge.id)
    assertEqual(challenge.id, retrieved.id)
}

// Migration Tests - Data integrity
func testMigrationFromV1ToV2() async throws {
    // Setup V1 data
    // Run migration
    // Validate V2 data integrity
}

// Performance Tests - Scalability
func testLargeDataSetPerformance() async throws {
    // Test with 10,000+ records
    // Validate response times
}
```

### 7.3 Test Data Management
- Use in-memory databases for tests
- Provide test data builders
- Ensure test isolation
- Clean up after each test

---

## 8. **API CONTRACT STANDARDS**

### 8.1 Request/Response Patterns
```swift
// All service methods follow this pattern:
func operationName(
    _ request: OperationRequest
) async throws -> OperationResponse

// Example:
func createChallenge(
    _ request: CreateChallengeRequest
) async throws -> ChallengeResponse
```

### 8.2 Async/Await Standards
- All database operations are async
- Use structured concurrency
- Handle cancellation properly
- Provide progress updates for long operations

### 8.3 Result Types
```swift
// For operations that might fail gracefully
enum ServiceResult<T> {
    case success(T)
    case failure(DataError)
    case partial(T, warnings: [ValidationWarning])
}
```

---

## 9. **PERFORMANCE & OPTIMIZATION**

### 9.1 Query Optimization
```swift
// Use specific fetch descriptors
var descriptor = FetchDescriptor<Challenge>(
    predicate: #Predicate { $0.status == .inProgress },
    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
)
descriptor.fetchLimit = 50
```

### 9.2 Caching Strategy
```swift
protocol CacheableService {
    var cache: DataCache { get }
    func getCached<T>(_ key: CacheKey, type: T.Type) -> T?
    func setCached<T>(_ value: T, for key: CacheKey)
    func invalidateCache(for key: CacheKey)
}
```

### 9.3 Lazy Loading
- Use `@Relationship` with lazy loading
- Implement pagination for large datasets
- Prefetch related data when needed

---

## 10. **SECURITY & PRIVACY**

### 10.1 Data Encryption
```swift
protocol EncryptableModel {
    var encryptedFields: [String] { get }
    func encrypt() throws
    func decrypt() throws
}
```

### 10.2 Access Control
```swift
protocol SecureService {
    func authorize(_ operation: DataOperation, for user: User) throws
    func audit(_ operation: DataOperation, by user: User)
}
```

### 10.3 Data Anonymization
```swift
protocol AnonymizableModel {
    func anonymize() -> Self
    var sensitiveFields: [String] { get }
}
```

---

## 🚨 **ENFORCEMENT CHECKLIST**

Before ANY code change, verify:

- [ ] Does this change follow the separation of concerns?
- [ ] Are all inputs validated?
- [ ] Is error handling comprehensive?
- [ ] Are tests updated/added?
- [ ] Is migration logic included (if needed)?
- [ ] Does this maintain backward compatibility?
- [ ] Is audit logging implemented?
- [ ] Are DTOs used for service boundaries?
- [ ] Is the change documented?
- [ ] Will this survive a complete UI rewrite?

---

## 📝 **IMPLEMENTATION PRIORITY**

### Phase 1: Foundation (Week 1)
1. Create validation framework
2. Implement service layer protocols
3. Add comprehensive error handling
4. Set up audit logging

### Phase 2: Robustness (Week 2)
1. Implement data integrity checks
2. Add migration framework
3. Create comprehensive tests
4. Performance optimization

### Phase 3: Advanced Features (Week 3)
1. Add caching layer
2. Implement security features
3. Advanced error recovery
4. Monitoring and analytics

---

## 🎯 **SUCCESS METRICS**

- **Zero** data corruption incidents
- **100%** test coverage for critical paths
- **< 100ms** average response time for queries
- **Zero** breaking changes in minor versions
- **100%** successful migrations
- **< 1%** error rate in production

---

*This document is the single source of truth for all data management decisions. Any deviation requires explicit approval and documentation.* 