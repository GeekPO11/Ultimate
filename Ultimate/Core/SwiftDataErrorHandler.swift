import Foundation
import SwiftData
import OSLog

/// A class for handling SwiftData errors and providing logging
class SwiftDataErrorHandler {
    /// Logs a SwiftData error
    static func logError(_ error: Error, context: String) {
        Logger.error("SwiftData error in \(context): \(error.localizedDescription)", category: .database)
        
        // Log additional details for specific error types
        let nsError = error as NSError
        Logger.error("Domain: \(nsError.domain), Code: \(nsError.code)", category: .database)
        
        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            Logger.error("Underlying error: \(underlyingError.localizedDescription)", category: .database)
        }
        
        if let reason = nsError.userInfo["NSLocalizedFailureReason"] as? String {
            Logger.error("Reason: \(reason)", category: .database)
        }
    }
    
    /// Handles a SwiftData error with a completion handler
    static func handleError(_ error: Error, context: String, completion: ((Error) -> Void)? = nil) {
        logError(error, context: context)
        completion?(error)
    }
    
    /// Attempts to perform a SwiftData operation and handles any errors
    static func performOperation<T>(context: String, operation: () throws -> T) -> Result<T, Error> {
        do {
            let result = try operation()
            return .success(result)
        } catch {
            logError(error, context: context)
            return .failure(error)
        }
    }
    
    /// Attempts to fetch entities with error handling
    static func fetchEntities<T: PersistentModel>(
        modelContext: ModelContext,
        fetchDescriptor: FetchDescriptor<T>,
        context: String
    ) -> [T] {
        do {
            let results = try modelContext.fetch(fetchDescriptor)
            Logger.debug("Successfully fetched \(results.count) \(T.self) entities", category: .database)
            return results
        } catch {
            logError(error, context: context)
            return []
        }
    }
    
    /// Attempts to save the model context with error handling
    static func saveContext(_ modelContext: ModelContext, context: String) -> Bool {
        do {
            try modelContext.save()
            Logger.debug("Successfully saved model context for \(context)", category: .database)
            return true
        } catch {
            logError(error, context: context)
            return false
        }
    }
}

// MARK: - ModelContext Extension

extension ModelContext {
    /// Safely fetches entities with error handling
    func safeFetch<T: PersistentModel>(_ fetchDescriptor: FetchDescriptor<T>, context: String) -> [T] {
        return SwiftDataErrorHandler.fetchEntities(
            modelContext: self,
            fetchDescriptor: fetchDescriptor,
            context: context
        )
    }
    
    /// Safely saves the context with error handling
    func safeSave(context: String) -> Bool {
        return SwiftDataErrorHandler.saveContext(self, context: context)
    }
} 