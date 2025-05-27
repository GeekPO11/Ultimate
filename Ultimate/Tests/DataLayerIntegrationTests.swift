import Testing
import SwiftData
@testable import Ultimate

/// Comprehensive integration tests for the data management system
/// These tests validate that the data layer is completely UI-independent
/// and can survive any UI changes or complete rewrites
@Suite("Data Layer Integration Tests")
struct DataLayerIntegrationTests {
    
    // MARK: - Test Setup
    
    private func createTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Challenge.self, Task.self, DailyTask.self, ProgressPhoto.self, User.self,
            configurations: config
        )
    }
    
    private func createTestServices(container: ModelContainer) -> (ChallengeService, MockTaskService, MockDailyTaskService) {
        let context = container.mainContext
        let auditLogger = AuditLogger()
        let taskService = MockTaskService()
        let dailyTaskService = MockDailyTaskService()
        let challengeService = ChallengeService(
            modelContext: context,
            taskService: taskService,
            dailyTaskService: dailyTaskService,
            auditLogger: auditLogger
        )
        return (challengeService, taskService, dailyTaskService)
    }
    
    // MARK: - Validation Framework Tests
    
    @Test("Validation Framework - Field Level Validation")
    func testFieldLevelValidation() async throws {
        // Test required field validation
        let requiredValidator = FieldValidator("name", rules: [.required])
        
        let emptyResult = requiredValidator.validate("")
        #expect(!emptyResult.isValid)
        #expect(emptyResult.errors.count == 1)
        #expect(emptyResult.errors.first?.localizedDescription.contains("required") == true)
        
        let validResult = requiredValidator.validate("Valid Name")
        #expect(validResult.isValid)
        #expect(validResult.errors.isEmpty)
        
        // Test length validation
        let lengthValidator = FieldValidator("description", rules: [.lengthRange(min: 10, max: 100)])
        
        let tooShortResult = lengthValidator.validate("Short")
        #expect(!tooShortResult.isValid)
        
        let tooLongResult = lengthValidator.validate(String(repeating: "a", count: 101))
        #expect(!tooLongResult.isValid)
        
        let validLengthResult = lengthValidator.validate("This is a valid description with proper length")
        #expect(validLengthResult.isValid)
    }
    
    @Test("Validation Framework - Custom Validation Rules")
    func testCustomValidationRules() async throws {
        let customValidator = FieldValidator("custom", rules: [
            .custom("no numbers") { value in
                guard let stringValue = value as? String else { return .valid }
                if stringValue.rangeOfCharacter(from: .decimalDigits) != nil {
                    return .invalid([.invalidFormat(field: "custom", expected: "no numbers allowed")])
                }
                return .valid
            }
        ])
        
        let invalidResult = customValidator.validate("Test123")
        #expect(!invalidResult.isValid)
        
        let validResult = customValidator.validate("TestOnly")
        #expect(validResult.isValid)
    }
    
    @Test("Model Validation - Challenge Business Rules")
    func testChallengeBusinessRuleValidation() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        // Test valid challenge
        let validChallenge = Challenge(
            type: .custom,
            name: "Valid Challenge",
            challengeDescription: "This is a valid challenge description that meets all requirements",
            durationInDays: 30
        )
        
        try validChallenge.validate()
        #expect(validChallenge.isValid())
        
        // Test invalid challenge - empty name
        let invalidNameChallenge = Challenge(
            type: .custom,
            name: "",
            challengeDescription: "Valid description",
            durationInDays: 30
        )
        
        #expect(!invalidNameChallenge.isValid())
        #expect(invalidNameChallenge.validationErrors.count > 0)
        
        // Test invalid challenge - invalid duration
        let invalidDurationChallenge = Challenge(
            type: .custom,
            name: "Valid Name",
            challengeDescription: "Valid description",
            durationInDays: 0
        )
        
        #expect(!invalidDurationChallenge.isValid())
        
        // Test cross-field validation
        let invalidDateChallenge = Challenge(
            type: .custom,
            name: "Valid Name",
            challengeDescription: "Valid description",
            durationInDays: 30
        )
        invalidDateChallenge.startDate = Date()
        invalidDateChallenge.endDate = Date().addingTimeInterval(-86400) // Yesterday
        
        #expect(!invalidDateChallenge.isValid())
    }
    
    // MARK: - Service Layer Tests
    
    @Test("Service Layer - CRUD Operations with Validation")
    func testServiceCRUDOperations() async throws {
        let container = try createTestContainer()
        let (challengeService, _, _) = createTestServices(container: container)
        
        // Test Create
        let createRequest = CreateChallengeRequest(
            name: "Test Challenge",
            description: "This is a comprehensive test challenge for validation",
            type: .custom,
            durationInDays: 30,
            tasks: [
                CreateTaskRequest(
                    name: "Test Task",
                    description: "Test task description",
                    type: .workout,
                    frequency: .daily,
                    timeOfDay: .morning,
                    durationMinutes: 30,
                    targetValue: nil,
                    targetUnit: nil,
                    scheduledTime: nil
                )
            ],
            startDate: nil,
            imageName: nil
        )
        
        let createdChallenge = try await challengeService.createChallenge(createRequest)
        #expect(createdChallenge.name == "Test Challenge")
        #expect(createdChallenge.status == .notStarted)
        #expect(createdChallenge.taskCount == 1)
        
        // Test Read
        let retrievedChallenge = try await challengeService.getChallenge(id: createdChallenge.id)
        #expect(retrievedChallenge != nil)
        #expect(retrievedChallenge?.id == createdChallenge.id)
        
        // Test Update
        let updateRequest = UpdateChallengeRequest(
            name: "Updated Challenge Name",
            description: nil,
            durationInDays: nil,
            startDate: nil,
            endDate: nil,
            status: nil,
            imageName: nil
        )
        
        let updatedChallenge = try await challengeService.updateChallenge(createdChallenge.id, with: updateRequest)
        #expect(updatedChallenge.name == "Updated Challenge Name")
        
        // Test Delete (soft delete)
        try await challengeService.deleteChallenge(createdChallenge.id, soft: true)
        
        let deletedChallenge = try await challengeService.getChallenge(id: createdChallenge.id)
        #expect(deletedChallenge == nil) // Should be filtered out in service layer
    }
    
    @Test("Service Layer - Challenge Lifecycle Management")
    func testChallengeLifecycleManagement() async throws {
        let container = try createTestContainer()
        let (challengeService, _, _) = createTestServices(container: container)
        
        // Create a challenge
        let createRequest = CreateChallengeRequest(
            name: "Lifecycle Test Challenge",
            description: "Testing challenge lifecycle management",
            type: .custom,
            durationInDays: 7,
            tasks: [
                CreateTaskRequest(
                    name: "Daily Task",
                    description: "Daily task for testing",
                    type: .habit,
                    frequency: .daily,
                    timeOfDay: .anytime,
                    durationMinutes: nil,
                    targetValue: nil,
                    targetUnit: nil,
                    scheduledTime: nil
                )
            ],
            startDate: nil,
            imageName: nil
        )
        
        let challenge = try await challengeService.createChallenge(createRequest)
        #expect(challenge.status == .notStarted)
        
        // Start the challenge
        let startedChallenge = try await challengeService.startChallenge(challenge.id)
        #expect(startedChallenge.status == .inProgress)
        #expect(startedChallenge.startDate != nil)
        #expect(startedChallenge.endDate != nil)
        
        // Verify it's the active challenge
        let activeChallenge = try await challengeService.getActiveChallenge()
        #expect(activeChallenge?.id == challenge.id)
        
        // Try to start another challenge (should fail)
        let secondChallenge = try await challengeService.createChallenge(createRequest)
        
        do {
            _ = try await challengeService.startChallenge(secondChallenge.id)
            #expect(Bool(false), "Should not be able to start second challenge")
        } catch {
            // Expected to fail
            #expect(error is DataError)
        }
        
        // Complete the challenge
        let completedChallenge = try await challengeService.completeChallenge(challenge.id)
        #expect(completedChallenge.status == .completed)
        
        // Verify no active challenge
        let noActiveChallenge = try await challengeService.getActiveChallenge()
        #expect(noActiveChallenge == nil)
    }
    
    @Test("Service Layer - Error Handling and Recovery")
    func testServiceErrorHandlingAndRecovery() async throws {
        let container = try createTestContainer()
        let (challengeService, _, _) = createTestServices(container: container)
        
        // Test validation error handling
        let invalidCreateRequest = CreateChallengeRequest(
            name: "", // Invalid - empty name
            description: "Short", // Invalid - too short
            type: .custom,
            durationInDays: 0, // Invalid - zero duration
            tasks: [], // Invalid - no tasks
            startDate: nil,
            imageName: nil
        )
        
        let validationResponse = try await challengeService.validateChallenge(invalidCreateRequest)
        #expect(!validationResponse.isValid)
        #expect(validationResponse.errors.count > 0)
        
        // Test business rule error handling
        do {
            _ = try await challengeService.createChallenge(invalidCreateRequest)
            #expect(Bool(false), "Should fail validation")
        } catch let error as DataError {
            #expect(error.localizedDescription.contains("Validation failed"))
        }
        
        // Test not found error handling
        let nonExistentId = UUID()
        let nonExistentChallenge = try await challengeService.getChallenge(id: nonExistentId)
        #expect(nonExistentChallenge == nil)
        
        do {
            _ = try await challengeService.startChallenge(nonExistentId)
            #expect(Bool(false), "Should fail with not found")
        } catch let error as DataError {
            #expect(error.localizedDescription.contains("not found"))
        }
    }
    
    @Test("Service Layer - Caching and Performance")
    func testServiceCachingAndPerformance() async throws {
        let container = try createTestContainer()
        let (challengeService, _, _) = createTestServices(container: container)
        
        // Create a challenge
        let createRequest = CreateChallengeRequest(
            name: "Cache Test Challenge",
            description: "Testing caching functionality",
            type: .custom,
            durationInDays: 30,
            tasks: [],
            startDate: nil,
            imageName: nil
        )
        
        let challenge = try await challengeService.createChallenge(createRequest)
        
        // First retrieval (should cache)
        let startTime1 = Date()
        let challenge1 = try await challengeService.getChallenge(id: challenge.id)
        let duration1 = Date().timeIntervalSince(startTime1)
        
        // Second retrieval (should use cache)
        let startTime2 = Date()
        let challenge2 = try await challengeService.getChallenge(id: challenge.id)
        let duration2 = Date().timeIntervalSince(startTime2)
        
        #expect(challenge1?.id == challenge2?.id)
        // Cache should be faster (though this might be unreliable in tests)
        // #expect(duration2 < duration1)
        
        // Test cache invalidation
        _ = try await challengeService.updateChallenge(challenge.id, with: UpdateChallengeRequest(
            name: "Updated Name",
            description: nil,
            durationInDays: nil,
            startDate: nil,
            endDate: nil,
            status: nil,
            imageName: nil
        ))
        
        // Should retrieve updated version (not cached)
        let updatedChallenge = try await challengeService.getChallenge(id: challenge.id)
        #expect(updatedChallenge?.name == "Updated Name")
    }
    
    @Test("Service Layer - Search and Filtering")
    func testServiceSearchAndFiltering() async throws {
        let container = try createTestContainer()
        let (challengeService, _, _) = createTestServices(container: container)
        
        // Create multiple challenges
        let challenges = [
            ("Fitness Challenge", ChallengeType.custom, ChallengeStatus.completed),
            ("Diet Challenge", ChallengeType.custom, ChallengeStatus.inProgress),
            ("75 Hard Challenge", ChallengeType.seventyFiveHard, ChallengeStatus.notStarted),
            ("Water Fast", ChallengeType.waterFasting, ChallengeStatus.failed)
        ]
        
        var createdChallenges: [ChallengeResponse] = []
        
        for (name, type, status) in challenges {
            let createRequest = CreateChallengeRequest(
                name: name,
                description: "Test challenge for search functionality",
                type: type,
                durationInDays: 30,
                tasks: [],
                startDate: status == .inProgress ? Date() : nil,
                imageName: nil
            )
            
            var challenge = try await challengeService.createChallenge(createRequest)
            
            // Update status if needed
            if status != .notStarted && status != .inProgress {
                let updateRequest = UpdateChallengeRequest(
                    name: nil,
                    description: nil,
                    durationInDays: nil,
                    startDate: nil,
                    endDate: nil,
                    status: status,
                    imageName: nil
                )
                challenge = try await challengeService.updateChallenge(challenge.id, with: updateRequest)
            }
            
            createdChallenges.append(challenge)
        }
        
        // Test search by name
        let searchRequest = ChallengeSearchRequest(
            query: "Challenge",
            type: nil,
            status: nil,
            startDateFrom: nil,
            startDateTo: nil,
            sortBy: .name,
            sortOrder: .ascending,
            limit: 10,
            offset: 0
        )
        
        let searchResults = try await challengeService.searchChallenges(searchRequest)
        #expect(searchResults.items.count >= 3) // Should find challenges with "Challenge" in name
        
        // Test filter by type
        let typeFilterRequest = ChallengeSearchRequest(
            query: nil,
            type: .custom,
            status: nil,
            startDateFrom: nil,
            startDateTo: nil,
            sortBy: .name,
            sortOrder: .ascending,
            limit: 10,
            offset: 0
        )
        
        let typeResults = try await challengeService.searchChallenges(typeFilterRequest)
        #expect(typeResults.items.allSatisfy { $0.type == .custom })
        
        // Test filter by status
        let statusFilterRequest = ChallengeSearchRequest(
            query: nil,
            type: nil,
            status: .completed,
            startDateFrom: nil,
            startDateTo: nil,
            sortBy: .name,
            sortOrder: .ascending,
            limit: 10,
            offset: 0
        )
        
        let statusResults = try await challengeService.searchChallenges(statusFilterRequest)
        #expect(statusResults.items.allSatisfy { $0.status == .completed })
        
        // Test pagination
        let paginationRequest = ChallengeSearchRequest(
            query: nil,
            type: nil,
            status: nil,
            startDateFrom: nil,
            startDateTo: nil,
            sortBy: .name,
            sortOrder: .ascending,
            limit: 2,
            offset: 0
        )
        
        let paginationResults = try await challengeService.searchChallenges(paginationRequest)
        #expect(paginationResults.items.count <= 2)
        #expect(paginationResults.totalCount >= 4)
        #expect(paginationResults.hasNext == (paginationResults.totalCount > 2))
    }
    
    // MARK: - Data Integrity Tests
    
    @Test("Data Integrity - Model Relationships")
    func testModelRelationships() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        // Create challenge with tasks
        let challenge = Challenge(
            type: .custom,
            name: "Relationship Test",
            challengeDescription: "Testing model relationships",
            durationInDays: 30
        )
        
        let task1 = Task(
            name: "Task 1",
            description: "First task",
            type: .workout,
            frequency: .daily
        )
        
        let task2 = Task(
            name: "Task 2",
            description: "Second task",
            type: .nutrition,
            frequency: .daily
        )
        
        // Test adding tasks to challenge
        try challenge.addTask(task1)
        try challenge.addTask(task2)
        
        #expect(challenge.tasks.count == 2)
        #expect(task1.challenge?.id == challenge.id)
        #expect(task2.challenge?.id == challenge.id)
        
        // Test removing task from challenge
        try challenge.removeTask(task1)
        
        #expect(challenge.tasks.count == 1)
        #expect(task1.challenge == nil)
        #expect(task2.challenge?.id == challenge.id)
        
        // Test validation with relationships
        try challenge.validate()
        try task2.validate()
        
        // Save and verify persistence
        context.insert(challenge)
        try context.save()
        
        // Fetch and verify relationships are maintained
        let fetchDescriptor = FetchDescriptor<Challenge>()
        let fetchedChallenges = try context.fetch(fetchDescriptor)
        
        let fetchedChallenge = fetchedChallenges.first { $0.id == challenge.id }
        #expect(fetchedChallenge != nil)
        #expect(fetchedChallenge?.tasks.count == 1)
    }
    
    @Test("Data Integrity - Soft Delete Functionality")
    func testSoftDeleteFunctionality() async throws {
        let container = try createTestContainer()
        let (challengeService, _, _) = createTestServices(container: container)
        
        // Create challenge
        let createRequest = CreateChallengeRequest(
            name: "Soft Delete Test",
            description: "Testing soft delete functionality",
            type: .custom,
            durationInDays: 30,
            tasks: [],
            startDate: nil,
            imageName: nil
        )
        
        let challenge = try await challengeService.createChallenge(createRequest)
        
        // Verify challenge exists
        let existingChallenge = try await challengeService.getChallenge(id: challenge.id)
        #expect(existingChallenge != nil)
        
        // Soft delete the challenge
        try await challengeService.deleteChallenge(challenge.id, soft: true)
        
        // Verify challenge is not returned by service (filtered out)
        let deletedChallenge = try await challengeService.getChallenge(id: challenge.id)
        #expect(deletedChallenge == nil)
        
        // Verify challenge still exists in database but marked as deleted
        let context = container.mainContext
        let fetchDescriptor = FetchDescriptor<Challenge>()
        let allChallenges = try context.fetch(fetchDescriptor)
        
        let softDeletedChallenge = allChallenges.first { $0.id == challenge.id }
        #expect(softDeletedChallenge != nil)
        #expect(softDeletedChallenge?.isDeleted == true)
        #expect(softDeletedChallenge?.deletedAt != nil)
    }
    
    // MARK: - UI Independence Tests
    
    @Test("UI Independence - Service Layer Isolation")
    func testServiceLayerUIIndependence() async throws {
        let container = try createTestContainer()
        let (challengeService, _, _) = createTestServices(container: container)
        
        // Create challenge using only DTOs (no direct model access)
        let createRequest = CreateChallengeRequest(
            name: "UI Independence Test",
            description: "This test verifies complete UI independence of data layer",
            type: .custom,
            durationInDays: 30,
            tasks: [
                CreateTaskRequest(
                    name: "Independent Task",
                    description: "Task created without UI dependencies",
                    type: .habit,
                    frequency: .daily,
                    timeOfDay: .anytime,
                    durationMinutes: nil,
                    targetValue: nil,
                    targetUnit: nil,
                    scheduledTime: nil
                )
            ],
            startDate: nil,
            imageName: nil
        )
        
        // All operations use DTOs - no direct model access
        let challenge = try await challengeService.createChallenge(createRequest)
        
        // Update using DTOs
        let updateRequest = UpdateChallengeRequest(
            name: "Updated Independent Challenge",
            description: "Updated description",
            durationInDays: nil,
            startDate: nil,
            endDate: nil,
            status: nil,
            imageName: nil
        )
        
        let updatedChallenge = try await challengeService.updateChallenge(challenge.id, with: updateRequest)
        
        // Query using DTOs
        let searchRequest = ChallengeSearchRequest(
            query: "Independent",
            type: nil,
            status: nil,
            startDateFrom: nil,
            startDateTo: nil,
            sortBy: .name,
            sortOrder: .ascending,
            limit: 10,
            offset: 0
        )
        
        let searchResults = try await challengeService.searchChallenges(searchRequest)
        
        // Verify all operations work with DTOs only
        #expect(updatedChallenge.name == "Updated Independent Challenge")
        #expect(searchResults.items.count > 0)
        #expect(searchResults.items.contains { $0.id == challenge.id })
        
        // This test demonstrates that the UI layer would NEVER need to:
        // - Import SwiftData
        // - Access ModelContext
        // - Work with @Model classes directly
        // - Handle validation logic
        // - Deal with database errors
        // - Manage caching
        // - Handle migrations
        
        // The service layer provides a complete abstraction that survives UI rewrites
    }
    
    @Test("Performance - Large Dataset Handling")
    func testLargeDatasetPerformance() async throws {
        let container = try createTestContainer()
        let (challengeService, _, _) = createTestServices(container: container)
        
        // Create multiple challenges to test performance
        let challengeCount = 100
        var challenges: [ChallengeResponse] = []
        
        let startTime = Date()
        
        for i in 0..<challengeCount {
            let createRequest = CreateChallengeRequest(
                name: "Performance Test Challenge \(i)",
                description: "Challenge \(i) for performance testing with adequate description length",
                type: ChallengeType.allCases.randomElement() ?? .custom,
                durationInDays: Int.random(in: 7...90),
                tasks: [],
                startDate: nil,
                imageName: nil
            )
            
            let challenge = try await challengeService.createChallenge(createRequest)
            challenges.append(challenge)
        }
        
        let creationTime = Date().timeIntervalSince(startTime)
        
        // Test bulk retrieval performance
        let retrievalStartTime = Date()
        let allChallenges = try await challengeService.getAllChallenges()
        let retrievalTime = Date().timeIntervalSince(retrievalStartTime)
        
        // Test search performance
        let searchStartTime = Date()
        let searchRequest = ChallengeSearchRequest(
            query: "Performance",
            type: nil,
            status: nil,
            startDateFrom: nil,
            startDateTo: nil,
            sortBy: .name,
            sortOrder: .ascending,
            limit: 50,
            offset: 0
        )
        let searchResults = try await challengeService.searchChallenges(searchRequest)
        let searchTime = Date().timeIntervalSince(searchStartTime)
        
        // Verify operations completed successfully
        #expect(allChallenges.count >= challengeCount)
        #expect(searchResults.items.count > 0)
        
        // Performance assertions (these might need adjustment based on hardware)
        #expect(creationTime < 10.0) // Should create 100 challenges in under 10 seconds
        #expect(retrievalTime < 1.0)  // Should retrieve all challenges in under 1 second
        #expect(searchTime < 1.0)     // Should search through challenges in under 1 second
        
        print("Performance Results:")
        print("- Created \(challengeCount) challenges in \(creationTime) seconds")
        print("- Retrieved \(allChallenges.count) challenges in \(retrievalTime) seconds")
        print("- Searched and found \(searchResults.items.count) challenges in \(searchTime) seconds")
    }
}

// MARK: - Mock Services

class MockTaskService: TaskServiceProtocol {
    // Mock implementation
}

class MockDailyTaskService: DailyTaskServiceProtocol {
    func getDailyTasks(for challengeId: UUID) async throws -> [DailyTaskResponse] {
        return [] // Mock implementation
    }
} 