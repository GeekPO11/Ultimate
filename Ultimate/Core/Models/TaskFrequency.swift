import Foundation

/// Represents the frequency of a task
enum TaskFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case anytime = "Anytime"
} 