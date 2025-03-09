import XCTest

final class GlassMorphismUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        
        // Navigate to the UI components showcase if needed
        // This depends on your app's navigation structure
        if app.tabBars.buttons["UI Components"].exists {
            app.tabBars.buttons["UI Components"].tap()
        }
    }
    
    func testMaterialCardExists() throws {
        // Assuming there's a MaterialCard with this text in your UI
        let materialCard = app.staticTexts["Material Card"]
        XCTAssertTrue(materialCard.exists, "Material Card should be visible in the UI")
    }
    
    func testMaterialTabBarInteraction() throws {
        // Assuming your app has a tab bar with these items
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Test tapping on different tabs
        if tabBar.buttons["Profile"].exists {
            tabBar.buttons["Profile"].tap()
            // Verify something that should be visible in the Profile tab
            let profileElement = app.staticTexts["Profile"]
            XCTAssertTrue(profileElement.waitForExistence(timeout: 2), "Profile tab content should be visible")
            
            // Go back to Home tab
            tabBar.buttons["Home"].tap()
            // Verify something that should be visible in the Home tab
            let homeElement = app.staticTexts["Home"]
            XCTAssertTrue(homeElement.waitForExistence(timeout: 2), "Home tab content should be visible")
        }
    }
    
    func testProgressRingExists() throws {
        // Scroll to find the progress ring if needed
        let progressRingLabel = app.staticTexts["Progress"]
        
        // Scroll until we find the element or reach the bottom
        var attempts = 0
        while !progressRingLabel.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }
        
        XCTAssertTrue(progressRingLabel.exists, "Progress ring should be visible in the UI")
    }
    
    func testChallengeItemsExist() throws {
        // Scroll to find challenge items if needed
        let challengeTitle = app.staticTexts["Challenges"]
        
        // Scroll until we find the element or reach the bottom
        var attempts = 0
        while !challengeTitle.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }
        
        XCTAssertTrue(challengeTitle.exists, "Challenges section should be visible in the UI")
        
        // Check if at least one challenge item exists
        let challengeItem = app.staticTexts["30-Day Run"]
        XCTAssertTrue(challengeItem.exists, "At least one challenge item should be visible")
    }
    
    func testStatItemsExist() throws {
        // Scroll to find stat items if needed
        let stepsLabel = app.staticTexts["Steps"]
        
        // Scroll until we find the element or reach the bottom
        var attempts = 0
        while !stepsLabel.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }
        
        XCTAssertTrue(stepsLabel.exists, "Steps stat item should be visible in the UI")
    }
    
    func testDarkModeToggle() throws {
        // Assuming there's a way to toggle dark mode in your app
        // This is just an example and should be adapted to your app's UI
        
        if app.buttons["Settings"].exists {
            app.buttons["Settings"].tap()
            
            // Look for appearance settings
            let appearanceButton = app.buttons["Appearance"]
            if appearanceButton.exists {
                appearanceButton.tap()
                
                // Toggle dark mode
                let darkModeToggle = app.switches["Dark Mode"]
                if darkModeToggle.exists {
                    let initialValue = darkModeToggle.value as? String
                    darkModeToggle.tap()
                    
                    // Verify the toggle changed
                    let newValue = darkModeToggle.value as? String
                    XCTAssertNotEqual(initialValue, newValue, "Dark mode toggle should change value")
                    
                    // Go back to previous screen
                    app.navigationBars.buttons.firstMatch.tap()
                }
            }
            
            // Go back to main screen
            if app.tabBars.buttons["Home"].exists {
                app.tabBars.buttons["Home"].tap()
            }
        }
    }
} 