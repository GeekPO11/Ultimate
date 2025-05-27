import SwiftUI
import SwiftData
import Charts

import Foundation
import SwiftUI

/// Data structure for task completion statistics per day.
struct TaskCompletionData: Identifiable {
    let id = UUID()
    let date: Date
    let total: Int
    let completed: Int
    let missed: Int
    let completionRate: Double // 0.0 to 100.0
}

/// Data structure for streak information.
struct StreakData {
    let current: Int // Current consecutive days streak
    let best: Int    // Longest consecutive days streak recorded
    let total: Int   // Total number of days where at least one task was completed
} 