import Foundation
import OSLog
import SwiftUI

/// A centralized logging system for the Ultimate app
enum Logger {
    /// Log categories to organize logs by feature
    enum Category: String, CaseIterable {
        case app = "App"
        case challenges = "Challenges"
        case tasks = "Tasks"
        case photos = "Photos"
        case progress = "Progress"
        case settings = "Settings"
        case camera = "Camera"
        case network = "Network"
        case database = "Database"
        case ui = "UI"
        case navigation = "Navigation"
        case userAction = "UserAction"
        case notification = "Notification"
        case authentication = "Authentication"
        case analytics = "Analytics"
        case performance = "Performance"
    }
    
    /// Log levels to indicate severity
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
        
        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
    }
    
    // MARK: - Private Properties
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    private static var isLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return UserDefaults.standard.bool(forKey: "enableDetailedLogging")
        #endif
    }
    
    private static let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.ultimate.app", category: "Ultimate")
    
    private static let logQueue = DispatchQueue(label: "com.ultimate.app.logging", qos: .utility)
    
    private static var logFileURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        return documentsDirectory.appendingPathComponent("ultimate_app.log")
    }
    
    // MARK: - Public Methods
    
    /// Log a message with the specified category and level
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The feature category
    ///   - level: The severity level
    ///   - file: The file where the log was called from
    ///   - function: The function where the log was called from
    ///   - line: The line number where the log was called from
    static func log(
        _ message: String,
        category: Category,
        level: Level = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isLoggingEnabled || level == .error || level == .critical else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        
        let logMessage = "\(level.emoji) [\(timestamp)] [\(category.rawValue)] [\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)"
        
        // Print to console in debug mode
        #if DEBUG
        print(logMessage)
        #endif
        
        // Log to system log
        os_log(level.osLogType, log: osLog, "%{public}@", logMessage)
        
        // Save to file
        saveLogToFile(logMessage)
    }
    
    // Convenience methods
    
    static func debug(_ message: String, category: Category, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .debug, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, category: Category, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .info, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, category: Category, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .warning, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, category: Category, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .error, file: file, function: function, line: line)
    }
    
    static func critical(_ message: String, category: Category, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .critical, file: file, function: function, line: line)
    }
    
    // MARK: - File Operations
    
    /// Save a log message to the log file
    /// - Parameter message: The formatted log message to save
    private static func saveLogToFile(_ message: String) {
        logQueue.async {
            guard let fileURL = logFileURL else {
                return
            }
            
            let logMessage = message + "\n"
            
            do {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    // Append to existing file
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    fileHandle.seekToEndOfFile()
                    if let data = logMessage.data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    fileHandle.closeFile()
                } else {
                    // Create new file
                    try logMessage.write(to: fileURL, atomically: true, encoding: .utf8)
                }
            } catch {
                print("Error writing to log file: \(error.localizedDescription)")
            }
        }
    }
    
    /// Read all logs from the log file
    /// - Returns: An array of log messages
    static func readLogs() -> [String] {
        guard let fileURL = logFileURL,
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let logContent = try String(contentsOf: fileURL, encoding: .utf8)
            return logContent.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
        } catch {
            print("Error reading log file: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Clear all logs from the log file
    static func clearLogs() {
        guard let fileURL = logFileURL else {
            return
        }
        
        logQueue.async {
            do {
                try "".write(to: fileURL, atomically: true, encoding: .utf8)
                print("Log file cleared")
            } catch {
                print("Error clearing log file: \(error.localizedDescription)")
            }
        }
    }
    
    /// Get the URL of the log file
    /// - Returns: The URL of the log file, or nil if it doesn't exist
    static func getLogFileURL() -> URL? {
        guard let fileURL = logFileURL,
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return fileURL
    }
}

// MARK: - Logging Middleware

/// Middleware to automatically log user actions and state changes
struct LoggingMiddleware {
    /// Log a button tap action
    /// - Parameters:
    ///   - buttonName: The name or description of the button
    ///   - screen: The screen or view where the button is located
    static func logButtonTap(_ buttonName: String, screen: String) {
        Logger.info("Button tapped: \(buttonName) on \(screen)", category: .userAction)
    }
    
    /// Log a navigation action
    /// - Parameters:
    ///   - from: The source screen
    ///   - to: The destination screen
    static func logNavigation(from: String, to: String) {
        Logger.info("Navigation: \(from) → \(to)", category: .navigation)
    }
    
    /// Log a toggle action
    /// - Parameters:
    ///   - name: The name of the toggle
    ///   - isOn: The new state of the toggle
    ///   - screen: The screen where the toggle is located
    static func logToggle(_ name: String, isOn: Bool, screen: String) {
        Logger.info("Toggle \(name) \(isOn ? "enabled" : "disabled") on \(screen)", category: .userAction)
    }
    
    /// Log a task status change
    /// - Parameters:
    ///   - taskName: The name of the task
    ///   - oldStatus: The previous status
    ///   - newStatus: The new status
    static func logTaskStatusChange(taskName: String, oldStatus: String, newStatus: String) {
        Logger.info("Task status changed: \(taskName) from \(oldStatus) to \(newStatus)", category: .tasks)
    }
    
    /// Log a photo capture action
    /// - Parameters:
    ///   - angle: The angle of the photo
    ///   - source: The source of the photo (camera or library)
    static func logPhotoCapture(angle: String, source: String) {
        Logger.info("Photo captured: \(angle) from \(source)", category: .photos)
    }
    
    /// Log a challenge action
    /// - Parameters:
    ///   - action: The action performed (start, complete, etc.)
    ///   - challengeName: The name of the challenge
    static func logChallengeAction(action: String, challengeName: String) {
        Logger.info("Challenge \(action): \(challengeName)", category: .challenges)
    }
    
    /// Log a settings change
    /// - Parameters:
    ///   - setting: The name of the setting
    ///   - value: The new value
    static func logSettingsChange(setting: String, value: String) {
        Logger.info("Settings changed: \(setting) to \(value)", category: .settings)
    }
    
    /// Log app lifecycle events
    /// - Parameter event: The lifecycle event (launch, background, foreground, terminate)
    static func logAppLifecycle(event: String) {
        Logger.info("App lifecycle: \(event)", category: .app)
    }
    
    /// Log performance metrics
    /// - Parameters:
    ///   - operation: The operation being measured
    ///   - duration: The duration in milliseconds
    static func logPerformance(operation: String, duration: Double) {
        Logger.info("Performance: \(operation) took \(String(format: "%.2f", duration))ms", category: .performance)
    }
}

// MARK: - View Extension for Logging

extension View {
    /// Log when a view appears
    /// - Parameter name: The name of the view
    /// - Returns: A modified view that logs when it appears
    func logAppearance(name: String) -> some View {
        self.onAppear {
            Logger.info("View appeared: \(name)", category: .ui)
        }
    }
    
    /// Log when a view disappears
    /// - Parameter name: The name of the view
    /// - Returns: A modified view that logs when it disappears
    func logDisappearance(name: String) -> some View {
        self.onDisappear {
            Logger.info("View disappeared: \(name)", category: .ui)
        }
    }
    
    /// Log a button tap
    /// - Parameters:
    ///   - name: The name of the button
    ///   - screen: The screen where the button is located
    ///   - action: The action to perform when the button is tapped
    /// - Returns: A button that logs when tapped
    func logButtonTap(name: String, screen: String, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            LoggingMiddleware.logButtonTap(name, screen: screen)
            action()
        }
    }
} 