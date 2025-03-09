import XCTest
import UserNotifications
@testable import Ultimate

class NotificationManagerTests: XCTestCase {
    
    var notificationManager: NotificationManager!
    var mockUserNotificationCenter: MockUserNotificationCenter!
    
    override func setUp() {
        super.setUp()
        mockUserNotificationCenter = MockUserNotificationCenter()
        notificationManager = NotificationManager.shared
        // Replace the real UNUserNotificationCenter with our mock
        UNUserNotificationCenterOverride.current = mockUserNotificationCenter
    }
    
    override func tearDown() {
        notificationManager = nil
        mockUserNotificationCenter = nil
        UNUserNotificationCenterOverride.current = nil
        super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testCheckAuthorizationStatus() {
        // Given
        let expectation = XCTestExpectation(description: "Authorization status checked")
        mockUserNotificationCenter.getNotificationSettingsHandler = { completion in
            let settings = MockNotificationSettings(authorizationStatus: .authorized)
            completion(settings)
            expectation.fulfill()
        }
        
        // When
        notificationManager.checkAuthorizationStatus()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationManager.isAuthorized)
    }
    
    func testRequestAuthorization_Success() {
        // Given
        let expectation = XCTestExpectation(description: "Authorization requested")
        mockUserNotificationCenter.requestAuthorizationHandler = { _, completion in
            completion(true, nil)
            expectation.fulfill()
        }
        
        // When
        notificationManager.requestAuthorization()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationManager.isAuthorized)
    }
    
    func testRequestAuthorization_Failure() {
        // Given
        let expectation = XCTestExpectation(description: "Authorization requested")
        mockUserNotificationCenter.requestAuthorizationHandler = { _, completion in
            completion(false, NSError(domain: "test", code: 1, userInfo: nil))
            expectation.fulfill()
        }
        
        // When
        notificationManager.requestAuthorization()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(notificationManager.isAuthorized)
    }
    
    // MARK: - Challenge Notification Tests
    
    func testScheduleNotificationsForChallenge_WhenNotAuthorized() {
        // Given
        notificationManager.isAuthorized = false
        let challenge = Challenge(type: .custom, name: "Test Challenge", challengeDescription: "Test", durationInDays: 30)
        
        // When
        notificationManager.scheduleNotificationsForChallenge(challenge)
        
        // Then
        XCTAssertEqual(mockUserNotificationCenter.addedRequests.count, 0)
    }
    
    func testScheduleNotificationsForChallenge_SeventyFiveHard() {
        // Given
        notificationManager.isAuthorized = true
        let challenge = Challenge(type: .seventyFiveHard, name: "75 Hard", challengeDescription: "Test", durationInDays: 75)
        
        // When
        notificationManager.scheduleNotificationsForChallenge(challenge)
        
        // Then
        // 75 Hard should have 5 notifications: morning workout, evening workout, water, reading, photo
        XCTAssertEqual(mockUserNotificationCenter.addedRequests.count, 9) // 5 main notifications + 4 water reminders
        
        // Verify notification times
        let morningWorkoutRequest = mockUserNotificationCenter.addedRequests.first { 
            $0.identifier.contains("morning-workout") 
        }
        XCTAssertNotNil(morningWorkoutRequest)
        
        if let trigger = morningWorkoutRequest?.trigger as? UNCalendarNotificationTrigger {
            XCTAssertEqual(trigger.dateComponents.hour, 6)
            XCTAssertEqual(trigger.dateComponents.minute, 0)
        }
        
        // Verify photo notification is scheduled for evening (8 PM)
        let photoRequest = mockUserNotificationCenter.addedRequests.first { 
            $0.identifier.contains("progress-photo") 
        }
        XCTAssertNotNil(photoRequest)
        
        if let trigger = photoRequest?.trigger as? UNCalendarNotificationTrigger {
            XCTAssertEqual(trigger.dateComponents.hour, 20) // 8 PM
            XCTAssertEqual(trigger.dateComponents.minute, 0)
        }
    }
    
    func testScheduleNotificationsForChallenge_WaterFasting() {
        // Given
        notificationManager.isAuthorized = true
        let challenge = Challenge(type: .waterFasting, name: "Water Fasting", challengeDescription: "Test", durationInDays: 3)
        challenge.startDate = Date()
        
        // When
        notificationManager.scheduleNotificationsForChallenge(challenge)
        
        // Then
        // Water fasting should have hourly hydration reminders (13 per day) + milestone notifications + weight tracking
        XCTAssertGreaterThanOrEqual(mockUserNotificationCenter.addedRequests.count, 14) // At least 13 hydration + 1 weight
        
        // Verify hydration notifications
        let hydrationRequests = mockUserNotificationCenter.addedRequests.filter { 
            $0.identifier.contains("water-") 
        }
        XCTAssertEqual(hydrationRequests.count, 13) // One for each hour from 8 AM to 8 PM
        
        // Verify weight tracking notification
        let weightRequest = mockUserNotificationCenter.addedRequests.first { 
            $0.identifier.contains("weight-tracking") 
        }
        XCTAssertNotNil(weightRequest)
        
        if let trigger = weightRequest?.trigger as? UNCalendarNotificationTrigger {
            XCTAssertEqual(trigger.dateComponents.hour, 7)
            XCTAssertEqual(trigger.dateComponents.minute, 0)
        }
    }
    
    func testScheduleNotificationsForChallenge_HabitBuilder() {
        // Given
        notificationManager.isAuthorized = true
        let challenge = Challenge(type: .thirtyOneModified, name: "Habit Builder", challengeDescription: "Test", durationInDays: 31)
        
        // When
        notificationManager.scheduleNotificationsForChallenge(challenge)
        
        // Then
        // Habit builder should have 4 notifications: morning, midday, evening, reflection
        XCTAssertEqual(mockUserNotificationCenter.addedRequests.count, 4)
        
        // Verify notification times
        let morningRequest = mockUserNotificationCenter.addedRequests.first { 
            $0.identifier.contains("morning-habits") 
        }
        XCTAssertNotNil(morningRequest)
        
        if let trigger = morningRequest?.trigger as? UNCalendarNotificationTrigger {
            XCTAssertEqual(trigger.dateComponents.hour, 7)
            XCTAssertEqual(trigger.dateComponents.minute, 30)
        }
    }
    
    func testScheduleNotificationsForChallenge_Custom() {
        // Given
        notificationManager.isAuthorized = true
        let challenge = Challenge(type: .custom, name: "Custom Challenge", challengeDescription: "Test", durationInDays: 30)
        
        // Add tasks of different types
        let workoutTask = Task(name: "Morning Workout", taskDescription: "30 min cardio", type: .workout)
        let waterTask = Task(name: "Drink Water", taskDescription: "1 gallon", type: .water)
        let readingTask = Task(name: "Read", taskDescription: "10 pages", type: .reading)
        
        challenge.tasks = [workoutTask, waterTask, readingTask]
        
        // When
        notificationManager.scheduleNotificationsForChallenge(challenge)
        
        // Then
        // Should have notifications for each task type
        XCTAssertGreaterThanOrEqual(mockUserNotificationCenter.addedRequests.count, 8) // 1 workout + 6 water + 1 reading
        
        // Verify reading notification
        let readingRequest = mockUserNotificationCenter.addedRequests.first { 
            $0.identifier.contains("reading") 
        }
        XCTAssertNotNil(readingRequest)
        
        if let trigger = readingRequest?.trigger as? UNCalendarNotificationTrigger {
            XCTAssertEqual(trigger.dateComponents.hour, 21) // 9 PM
            XCTAssertEqual(trigger.dateComponents.minute, 0)
        }
    }
    
    func testRemoveNotificationsForChallenge() {
        // Given
        let challenge = Challenge(type: .custom, name: "Test Challenge", challengeDescription: "Test", durationInDays: 30)
        mockUserNotificationCenter.pendingNotificationRequests = [
            createMockNotificationRequest(identifier: "challenge_\(challenge.id.uuidString)_task_1"),
            createMockNotificationRequest(identifier: "challenge_\(challenge.id.uuidString)_task_2"),
            createMockNotificationRequest(identifier: "challenge_other_id_task_3")
        ]
        
        // When
        notificationManager.removeNotificationsForChallenge(challenge)
        
        // Then
        XCTAssertEqual(mockUserNotificationCenter.removedRequestIdentifiers.count, 2)
        XCTAssertTrue(mockUserNotificationCenter.removedRequestIdentifiers.contains("challenge_\(challenge.id.uuidString)_task_1"))
        XCTAssertTrue(mockUserNotificationCenter.removedRequestIdentifiers.contains("challenge_\(challenge.id.uuidString)_task_2"))
        XCTAssertFalse(mockUserNotificationCenter.removedRequestIdentifiers.contains("challenge_other_id_task_3"))
    }
    
    func testRemoveAllPendingNotifications() {
        // Given
        mockUserNotificationCenter.setBadgeCountHandler = { count, completion in
            completion(nil)
        }
        
        // When
        notificationManager.removeAllPendingNotifications()
        
        // Then
        XCTAssertTrue(mockUserNotificationCenter.allPendingNotificationRequestsRemoved)
        XCTAssertEqual(notificationManager.currentBadgeCount, 0)
    }
    
    func testResetBadgeCount() {
        // Given
        mockUserNotificationCenter.setBadgeCountHandler = { count, completion in
            completion(nil)
        }
        
        // When
        notificationManager.resetBadgeCount()
        
        // Then
        XCTAssertEqual(notificationManager.currentBadgeCount, 0)
    }
    
    func testEnableAllNotifications() {
        // Given
        notificationManager.isAuthorized = true
        let userSettings = UserSettings()
        userSettings.notifyWorkouts = false
        userSettings.notifyNutrition = false
        userSettings.notifyWater = false
        userSettings.notifyReading = false
        userSettings.notifyPhotos = false
        
        // When
        notificationManager.enableAllNotifications(userSettings: userSettings)
        
        // Then
        // Wait for the async updates to complete
        let expectation = XCTestExpectation(description: "Settings updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(userSettings.notifyWorkouts)
        XCTAssertTrue(userSettings.notifyNutrition)
        XCTAssertTrue(userSettings.notifyWater)
        XCTAssertTrue(userSettings.notifyReading)
        XCTAssertTrue(userSettings.notifyPhotos)
        XCTAssertTrue(mockUserNotificationCenter.categoriesSet)
    }
    
    func testEnableAllNotifications_WhenNotAuthorized() {
        // Given
        notificationManager.isAuthorized = false
        let userSettings = UserSettings()
        userSettings.notifyWorkouts = false
        
        // When
        notificationManager.enableAllNotifications(userSettings: userSettings)
        
        // Then
        // Wait for the async updates to complete
        let expectation = XCTestExpectation(description: "Settings updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertFalse(userSettings.notifyWorkouts)
        XCTAssertFalse(mockUserNotificationCenter.categoriesSet)
    }
    
    // MARK: - Notification Response Tests
    
    func testHandleNotificationResponse_DefaultAction() {
        // Given
        let challenge = Challenge(type: .custom, name: "Test Challenge", challengeDescription: "Test", durationInDays: 30)
        let content = UNMutableNotificationContent()
        content.userInfo = ["challengeId": challenge.id.uuidString]
        
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: nil)
        let notification = UNNotification(request: request, date: Date())
        let response = MockNotificationResponse(notification: notification, actionIdentifier: UNNotificationDefaultActionIdentifier)
        
        // Set up notification center observer
        let expectation = XCTestExpectation(description: "Notification posted")
        var notificationPosted = false
        
        let observer = NotificationCenter.default.addObserver(
            forName: Notification.Name("SwitchToTodayTab"),
            object: nil,
            queue: .main
        ) { _ in
            notificationPosted = true
            expectation.fulfill()
        }
        
        // When
        notificationManager.handleNotificationResponse(response, completionHandler: {
            // Completion handler
        })
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationPosted)
        
        // Clean up
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testHandleNotificationResponse_CompleteAction() {
        // Given
        let challenge = Challenge(type: .custom, name: "Test Challenge", challengeDescription: "Test", durationInDays: 30)
        let taskId = UUID()
        let content = UNMutableNotificationContent()
        content.userInfo = [
            "challengeId": challenge.id.uuidString,
            "taskId": taskId.uuidString
        ]
        
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: nil)
        let notification = UNNotification(request: request, date: Date())
        let response = MockNotificationResponse(notification: notification, actionIdentifier: "COMPLETE_ACTION")
        
        // Set up notification center observer
        let expectation = XCTestExpectation(description: "Notification posted")
        var receivedTaskId: UUID?
        
        let observer = NotificationCenter.default.addObserver(
            forName: Notification.Name("CompleteTaskFromNotification"),
            object: nil,
            queue: .main
        ) { notification in
            receivedTaskId = notification.userInfo?["taskId"] as? UUID
            expectation.fulfill()
        }
        
        // When
        notificationManager.handleNotificationResponse(response, completionHandler: {
            // Completion handler
        })
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedTaskId, taskId)
        
        // Clean up
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testHandleNotificationResponse_LaterAction() {
        // Given
        let challenge = Challenge(type: .custom, name: "Test Challenge", challengeDescription: "Test", durationInDays: 30)
        let taskId = UUID()
        let content = UNMutableNotificationContent()
        content.title = "Original Title"
        content.userInfo = [
            "challengeId": challenge.id.uuidString,
            "taskId": taskId.uuidString
        ]
        
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: nil)
        let notification = UNNotification(request: request, date: Date())
        let response = MockNotificationResponse(notification: notification, actionIdentifier: "LATER_ACTION")
        
        // When
        notificationManager.handleNotificationResponse(response, completionHandler: {
            // Completion handler
        })
        
        // Then
        XCTAssertEqual(mockUserNotificationCenter.addedRequests.count, 1)
        let reminderRequest = mockUserNotificationCenter.addedRequests.first
        XCTAssertNotNil(reminderRequest)
        XCTAssertTrue(reminderRequest?.identifier.contains("reminder_\(taskId.uuidString)") ?? false)
        
        // Check content
        let reminderContent = reminderRequest?.content
        XCTAssertEqual(reminderContent?.title, "Reminder: Original Title")
        
        // Check trigger
        let trigger = reminderRequest?.trigger as? UNTimeIntervalNotificationTrigger
        XCTAssertNotNil(trigger)
        XCTAssertEqual(trigger?.timeInterval, 30 * 60) // 30 minutes
    }
    
    // MARK: - Helper Methods
    
    private func createMockNotificationRequest(identifier: String) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Test"
        content.body = "Test"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
    
    func testScheduleTestNotification() {
        // When
        notificationManager.scheduleTestNotification()
        
        // Then
        XCTAssertEqual(mockUserNotificationCenter.addedRequests.count, 1)
        
        let request = mockUserNotificationCenter.addedRequests.first
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.identifier, "testNotification")
        
        let content = request?.content
        XCTAssertEqual(content?.title, "Test Notification")
        XCTAssertEqual(content?.body, "This is a test notification from the Challenge Tracker app.")
        
        let trigger = request?.trigger as? UNTimeIntervalNotificationTrigger
        XCTAssertNotNil(trigger)
        XCTAssertEqual(trigger?.timeInterval, 5)
        XCTAssertFalse(trigger?.repeats ?? true)
    }
}

// MARK: - Mock Classes

class MockNotificationResponse: UNNotificationResponse {
    private let _notification: UNNotification
    private let _actionIdentifier: String
    
    init(notification: UNNotification, actionIdentifier: String) {
        _notification = notification
        _actionIdentifier = actionIdentifier
        super.init()
    }
    
    override var notification: UNNotification {
        return _notification
    }
    
    override var actionIdentifier: String {
        return _actionIdentifier
    }
}

class MockUserNotificationCenter: UNUserNotificationCenter {
    var getNotificationSettingsHandler: ((UNNotificationSettingsCompletionHandler) -> Void)?
    var requestAuthorizationHandler: ((UNAuthorizationOptions, (Bool, Error?) -> Void) -> Void)?
    var setBadgeCountHandler: ((Int, (Error?) -> Void) -> Void)?
    var addedRequests: [UNNotificationRequest] = []
    var removedRequestIdentifiers: [String] = []
    var pendingNotificationRequests: [UNNotificationRequest] = []
    var allPendingNotificationRequestsRemoved = false
    var categoriesSet = false
    
    override func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void) {
        if let handler = getNotificationSettingsHandler {
            handler(completionHandler)
        } else {
            completionHandler(MockNotificationSettings(authorizationStatus: .notDetermined))
        }
    }
    
    override func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        if let handler = requestAuthorizationHandler {
            handler(options, completionHandler)
        } else {
            completionHandler(false, nil)
        }
    }
    
    override func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        addedRequests.append(request)
        completionHandler?(nil)
    }
    
    override func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedRequestIdentifiers.append(contentsOf: identifiers)
    }
    
    override func removeAllPendingNotificationRequests() {
        allPendingNotificationRequestsRemoved = true
    }
    
    override func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
        completionHandler(pendingNotificationRequests)
    }
    
    override func setBadgeCount(_ count: Int, withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        if let handler = setBadgeCountHandler {
            handler(count, { error in
                completionHandler?(error)
            })
        } else {
            completionHandler?(nil)
        }
    }
    
    override func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        categoriesSet = true
    }
}

class MockNotificationSettings: UNNotificationSettings {
    private let _authorizationStatus: UNAuthorizationStatus
    
    init(authorizationStatus: UNAuthorizationStatus) {
        _authorizationStatus = authorizationStatus
        super.init()
    }
    
    override var authorizationStatus: UNAuthorizationStatus {
        return _authorizationStatus
    }
}

// MARK: - UNUserNotificationCenter Override

class UNUserNotificationCenterOverride {
    static var current: UNUserNotificationCenter?
}

extension UNUserNotificationCenter {
    @objc class func current() -> UNUserNotificationCenter {
        return UNUserNotificationCenterOverride.current ?? UNUserNotificationCenter.current
    }
} 