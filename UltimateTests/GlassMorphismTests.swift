import XCTest
import SwiftUI
import ViewInspector
@testable import Ultimate

extension UIMaterial: Inspectable {}
extension MaterialCard: Inspectable {}
extension MaterialTabBar: Inspectable {}
extension PremiumBackground: Inspectable {}
extension AnimatedBackgroundElement: Inspectable {}
extension StatItem: Inspectable {}
extension ChallengeItem: Inspectable {}
extension DetailRow: Inspectable {}
extension GlassProgressCircle: Inspectable {}

final class GlassMorphismTests: XCTestCase {
    
    func testAppleMaterial() throws {
        let material = UIMaterial(style: .regular, cornerRadius: 16)
        let view = Text("Test").modifier(material)
        
        // Verify the material is applied
        let backgroundMaterial = try view.inspect().modifier(UIMaterial.self).viewModifierContent().background().material()
        XCTAssertEqual(backgroundMaterial, .regularMaterial)
        
        // Verify the corner radius
        let cornerRadius = try view.inspect().modifier(UIMaterial.self).viewModifierContent().background().cornerRadius()
        XCTAssertEqual(cornerRadius, 16)
    }
    
    func testMaterialCard() throws {
        let card = MaterialCard {
            Text("Test Card")
        }
        
        // Verify the content is present
        let text = try card.inspect().find(text: "Test Card")
        XCTAssertEqual(try text.string(), "Test Card")
        
        // Verify the UIMaterial modifier is applied
        let uiMaterial = try card.inspect().modifier(UIMaterial.self)
        XCTAssertNotNil(uiMaterial)
    }
    
    func testMaterialTabBar() throws {
        @State var selectedTab = 0
        let tabs = [(icon: "house.fill", title: "Home"), (icon: "person.fill", title: "Profile")]
        
        let tabBar = MaterialTabBar(selectedTab: $selectedTab, tabs: tabs)
        
        // Verify the correct number of tabs
        let buttons = try tabBar.inspect().hStack().forEach(0)
        XCTAssertEqual(buttons.count, 2)
        
        // Verify the first tab has the correct icon and title
        let firstTabVStack = try tabBar.inspect().hStack().forEach(0)[0].button().vStack()
        let icon = try firstTabVStack.image(0)
        let title = try firstTabVStack.text(1)
        
        XCTAssertEqual(try icon.actualImage().name(), "house.fill")
        XCTAssertEqual(try title.string(), "Home")
    }
    
    func testStatItem() throws {
        let statItem = StatItem(value: "100", label: "Steps", icon: "figure.walk", color: .blue)
        
        // Verify the value text
        let valueText = try statItem.inspect().vStack().text(1)
        XCTAssertEqual(try valueText.string(), "100")
        
        // Verify the label text
        let labelText = try statItem.inspect().vStack().text(2)
        XCTAssertEqual(try labelText.string(), "Steps")
        
        // Verify the icon
        let icon = try statItem.inspect().vStack().zStack(0).image(1)
        XCTAssertEqual(try icon.actualImage().name(), "figure.walk")
    }
    
    func testChallengeItem() throws {
        let challengeItem = ChallengeItem(title: "Running", progress: 0.75, icon: "figure.run", color: .blue)
        
        // Verify the title text
        let titleText = try challengeItem.inspect().vStack().text(1)
        XCTAssertEqual(try titleText.string(), "Running")
        
        // Verify the progress percentage
        let percentText = try challengeItem.inspect().vStack().hStack(0).text(1)
        XCTAssertEqual(try percentText.string(), "75%")
        
        // Verify the icon
        let icon = try challengeItem.inspect().vStack().hStack(0).image(0)
        XCTAssertEqual(try icon.actualImage().name(), "figure.run")
        
        // Verify the progress view
        let progressView = try challengeItem.inspect().vStack().progressView(2)
        XCTAssertNotNil(progressView)
    }
    
    func testDetailRow() throws {
        let detailRow = DetailRow(label: "Daily Goal", value: "10,000 steps", icon: "figure.walk", color: .blue)
        
        // Verify the label text
        let labelText = try detailRow.inspect().hStack().text(1)
        XCTAssertEqual(try labelText.string(), "Daily Goal")
        
        // Verify the value text
        let valueText = try detailRow.inspect().hStack().text(2)
        XCTAssertEqual(try valueText.string(), "10,000 steps")
        
        // Verify the icon
        let icon = try detailRow.inspect().hStack().image(0)
        XCTAssertEqual(try icon.actualImage().name(), "figure.walk")
    }
    
    func testGlassProgressCircle() throws {
        let progressCircle = GlassProgressCircle(
            progress: 0.75,
            colors: [.blue, .cyan],
            icon: "figure.walk",
            label: "Steps"
        )
        
        // Verify the percentage text
        let percentText = try progressCircle.inspect().zStack().vStack().text(1)
        XCTAssertEqual(try percentText.string(), "75%")
        
        // Verify the label text
        let labelText = try progressCircle.inspect().zStack().vStack().text(2)
        XCTAssertEqual(try labelText.string(), "Steps")
        
        // Verify the icon
        let icon = try progressCircle.inspect().zStack().vStack().image(0)
        XCTAssertEqual(try icon.actualImage().name(), "figure.walk")
    }
} 