import XCTest
import SwiftUI
import ViewInspector
@testable import Ultimate

extension NotificationSettingsView: Inspectable {}

class NotificationSettingsViewTests: XCTestCase {
    
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
    
    func testNotificationSettingsView_WhenAuthorized() throws {
        // Given
        notificationManager.isAuthorized = true
        let userSettings = UserSettings()
        
        // When
        let view = NotificationSettingsView()
            .environmentObject(userSettings)
        
        // Then
        // Verify the view shows the authorized state
        let authorizationSection = try view.inspect().find(viewWithId: "authorizationSection")
        let statusText = try authorizationSection.find(text: "Enabled")
        XCTAssertNotNil(statusText)
    }
    
    func testNotificationSettingsView_WhenNotAuthorized() throws {
        // Given
        notificationManager.isAuthorized = false
        let userSettings = UserSettings()
        
        // When
        let view = NotificationSettingsView()
            .environmentObject(userSettings)
        
        // Then
        // Verify the view shows the unauthorized state
        let authorizationSection = try view.inspect().find(viewWithId: "authorizationSection")
        let statusText = try authorizationSection.find(text: "Disabled")
        XCTAssertNotNil(statusText)
        
        // Verify the enable button is present
        let enableButton = try authorizationSection.find(button: "Enable Notifications")
        XCTAssertNotNil(enableButton)
    }
    
    func testNotificationSettingsView_ToggleWorkoutNotifications() throws {
        // Given
        notificationManager.isAuthorized = true
        let userSettings = UserSettings()
        userSettings.notifyWorkouts = false
        
        // When
        let view = NotificationSettingsView()
            .environmentObject(userSettings)
        
        // Then
        // Verify the toggle is present and matches the userSettings value
        let workoutToggle = try view.inspect().find(toggle: "Workout Reminders")
        XCTAssertFalse(try workoutToggle.value())
        
        // Toggle the value
        try workoutToggle.tap()
        
        // Verify the userSettings value was updated
        XCTAssertTrue(userSettings.notifyWorkouts)
    }
    
    func testNotificationSettingsView_TestNotificationButton() throws {
        // Given
        notificationManager.isAuthorized = true
        let userSettings = UserSettings()
        
        // When
        let view = NotificationSettingsView()
            .environmentObject(userSettings)
        
        // Then
        // Verify the test notification button is present
        let testButton = try view.inspect().find(button: "Send Test Notification")
        XCTAssertNotNil(testButton)
        
        // Tap the button
        try testButton.tap()
        
        // Verify a notification was scheduled
        XCTAssertEqual(mockUserNotificationCenter.addedRequests.count, 1)
        XCTAssertEqual(mockUserNotificationCenter.addedRequests.first?.identifier, "testNotification")
    }
}

// Add this extension to make UserSettings observable in tests
extension UserSettings {
    func objectWillChange() {
        self.objectWillChange.send()
    }
} 