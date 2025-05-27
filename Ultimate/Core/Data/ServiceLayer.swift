import Foundation
import SwiftData
import OSLog

// MARK: - Base Service Protocol

protocol BaseService {
    associatedtype Model: ValidatableModel & PersistentModel
    
    var modelContext: ModelContext { get }
    var auditLogger: AuditLogger { get }
    
    // CRUD Operations
    func create(_ model: Model) async throws -> Model
    func read(id: UUID) async throws -> Model?
    func update(_ model: Model) async throws -> Model
    func delete(_ model: Model, soft: Bool) async throws
    func getAll() async throws -> [Model]
    
    // Validation
    func validate(_ model: Model) async throws
    
    // Error Recovery
    func recover(from error: Error) async throws
    
    // Audit
    func logOperation(_ operation: DataOperation, on model: Model)
}

// MARK: - Error Recovery Protocol

protocol ErrorRecoverable {
    func canRecover(from error: Error) -> Bool
    func recover(from error: Error) async throws
}

// MARK: - Cacheable Service Protocol

protocol CacheableService {
    associatedtype CacheKey: Hashable
    
    var cache: DataCache<CacheKey> { get }
    
    func getCached<T>(_ key: CacheKey, type: T.Type) -> T?
    func setCached<T>(_ value: T, for key: CacheKey)
    func invalidateCache(for key: CacheKey)
    func clearCache()
}

// MARK: - Data Cache Implementation

class DataCache<Key: Hashable> {
    private var storage: [Key: CacheEntry] = [:]
    private let queue = DispatchQueue(label: "DataCache", attributes: .concurrent)
    private let maxSize: Int
    private let ttl: TimeInterval
    
    struct CacheEntry {
        let value: Any
        let timestamp: Date
        let accessCount: Int
        
        var isExpired: Bool {
            return Date().timeIntervalSince(timestamp) > 300 // 5 minutes default TTL
        }
    }
    
    init(maxSize: Int = 100, ttl: TimeInterval = 300) {
        self.maxSize = maxSize
        self.ttl = ttl
    }
    
    func get<T>(_ key: Key, type: T.Type) -> T? {
        return queue.sync {
            guard let entry = storage[key], !entry.isExpired else {
                storage.removeValue(forKey: key)
                return nil
            }
            
            // Update access count
            storage[key] = CacheEntry(
                value: entry.value,
                timestamp: entry.timestamp,
                accessCount: entry.accessCount + 1
            )
            
            return entry.value as? T
        }
    }
    
    func set<T>(_ value: T, for key: Key) {
        queue.async(flags: .barrier) {
            // Remove expired entries first
            self.removeExpiredEntries()
            
            // If at max capacity, remove least recently used
            if self.storage.count >= self.maxSize {
                self.removeLeastRecentlyUsed()
            }
            
            self.storage[key] = CacheEntry(
                value: value,
                timestamp: Date(),
                accessCount: 1
            )
        }
    }
    
    func remove(_ key: Key) {
        queue.async(flags: .barrier) {
            self.storage.removeValue(forKey: key)
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.storage.removeAll()
        }
    }
    
    private func removeExpiredEntries() {
        let now = Date()
        storage = storage.filter { _, entry in
            now.timeIntervalSince(entry.timestamp) <= ttl
        }
    }
    
    private func removeLeastRecentlyUsed() {
        guard let lruKey = storage.min(by: { $0.value.accessCount < $1.value.accessCount })?.key else {
            return
        }
        storage.removeValue(forKey: lruKey)
    }
}

// MARK: - Audit Logger

class AuditLogger {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Ultimate", category: "DataAudit")
    private var operations: [DataOperation] = []
    private let queue = DispatchQueue(label: "AuditLogger", qos: .utility)
    
    func log(_ operation: DataOperation) {
        queue.async {
            self.operations.append(operation)
            
            // Log to system logger
            self.logger.info("""
                Data Operation: \(operation.operation.rawValue)
                Model: \(operation.modelType)
                ID: \(operation.modelId?.uuidString ?? "nil")
                Success: \(operation.success)
                Error: \(operation.error ?? "none")
                """)
            
            // Keep only last 1000 operations
            if self.operations.count > 1000 {
                self.operations.removeFirst(100)
            }
        }
    }
    
    func getOperations(for modelType: String? = nil, limit: Int = 100) -> [DataOperation] {
        return queue.sync {
            let filtered = modelType != nil 
                ? operations.filter { $0.modelType == modelType }
                : operations
            
            return Array(filtered.suffix(limit))
        }
    }
    
    func getFailedOperations(limit: Int = 50) -> [DataOperation] {
        return queue.sync {
            let failed = operations.filter { !$0.success }
            return Array(failed.suffix(limit))
        }
    }
}

// MARK: - Data Operation

struct DataOperation {
    let id: UUID = UUID()
    let operation: OperationType
    let modelType: String
    let modelId: UUID?
    let userId: UUID?
    let timestamp: Date = Date()
    let success: Bool
    let error: String?
    let metadata: [String: Any]
    
    init(
        operation: OperationType,
        modelType: String,
        modelId: UUID? = nil,
        userId: UUID? = nil,
        success: Bool,
        error: String? = nil,
        metadata: [String: Any] = [:]
    ) {
        self.operation = operation
        self.modelType = modelType
        self.modelId = modelId
        self.userId = userId
        self.success = success
        self.error = error
        self.metadata = metadata
    }
}

enum OperationType: String {
    case create, read, update, delete
    case migrate, backup, restore
    case validate, sync
}

// MARK: - Base Service Implementation

class BaseDataService<Model: ValidatableModel & PersistentModel>: BaseService, ErrorRecoverable {
    let modelContext: ModelContext
    let auditLogger: AuditLogger
    private let retryQueue = DispatchQueue(label: "RetryQueue", qos: .utility)
    
    init(modelContext: ModelContext, auditLogger: AuditLogger = AuditLogger()) {
        self.modelContext = modelContext
        self.auditLogger = auditLogger
    }
    
    // MARK: - CRUD Operations
    
    func create(_ model: Model) async throws -> Model {
        let operation = DataOperation(
            operation: .create,
            modelType: String(describing: Model.self),
            modelId: (model as? any Identifiable)?.id as? UUID,
            success: false
        )
        
        do {
            // Validate before creating
            try await validate(model)
            
            // Insert into context
            modelContext.insert(model)
            
            // Save context
            try modelContext.save()
            
            // Log successful operation
            auditLogger.log(DataOperation(
                operation: .create,
                modelType: String(describing: Model.self),
                modelId: (model as? any Identifiable)?.id as? UUID,
                success: true
            ))
            
            Logger.debug("Successfully created \(String(describing: Model.self))", category: .database)
            return model
            
        } catch {
            // Log failed operation
            auditLogger.log(DataOperation(
                operation: .create,
                modelType: String(describing: Model.self),
                modelId: (model as? any Identifiable)?.id as? UUID,
                success: false,
                error: error.localizedDescription
            ))
            
            Logger.error("Failed to create \(String(describing: Model.self)): \(error.localizedDescription)", category: .database)
            throw error
        }
    }
    
    func read(id: UUID) async throws -> Model? {
        let operation = DataOperation(
            operation: .read,
            modelType: String(describing: Model.self),
            modelId: id,
            success: false
        )
        
        do {
            let predicate = #Predicate<Model> { model in
                (model as! any Identifiable).id as! UUID == id
            }
            
            let descriptor = FetchDescriptor<Model>(predicate: predicate)
            let results = try modelContext.fetch(descriptor)
            
            auditLogger.log(DataOperation(
                operation: .read,
                modelType: String(describing: Model.self),
                modelId: id,
                success: true
            ))
            
            return results.first
            
        } catch {
            auditLogger.log(DataOperation(
                operation: .read,
                modelType: String(describing: Model.self),
                modelId: id,
                success: false,
                error: error.localizedDescription
            ))
            
            Logger.error("Failed to read \(String(describing: Model.self)) with id \(id): \(error.localizedDescription)", category: .database)
            throw error
        }
    }
    
    func update(_ model: Model) async throws -> Model {
        do {
            // Validate before updating
            try await validate(model)
            
            // Update timestamp if available
            if let timestampedModel = model as? any TimestampedModel {
                timestampedModel.updatedAt = Date()
            }
            
            // Save context
            try modelContext.save()
            
            auditLogger.log(DataOperation(
                operation: .update,
                modelType: String(describing: Model.self),
                modelId: (model as? any Identifiable)?.id as? UUID,
                success: true
            ))
            
            Logger.debug("Successfully updated \(String(describing: Model.self))", category: .database)
            return model
            
        } catch {
            auditLogger.log(DataOperation(
                operation: .update,
                modelType: String(describing: Model.self),
                modelId: (model as? any Identifiable)?.id as? UUID,
                success: false,
                error: error.localizedDescription
            ))
            
            Logger.error("Failed to update \(String(describing: Model.self)): \(error.localizedDescription)", category: .database)
            throw error
        }
    }
    
    func delete(_ model: Model, soft: Bool = true) async throws {
        do {
            if soft, let softDeletable = model as? any SoftDeletableModel {
                softDeletable.isDeleted = true
                softDeletable.deletedAt = Date()
                try modelContext.save()
            } else {
                modelContext.delete(model)
                try modelContext.save()
            }
            
            auditLogger.log(DataOperation(
                operation: .delete,
                modelType: String(describing: Model.self),
                modelId: (model as? any Identifiable)?.id as? UUID,
                success: true,
                metadata: ["soft_delete": soft]
            ))
            
            Logger.debug("Successfully deleted \(String(describing: Model.self))", category: .database)
            
        } catch {
            auditLogger.log(DataOperation(
                operation: .delete,
                modelType: String(describing: Model.self),
                modelId: (model as? any Identifiable)?.id as? UUID,
                success: false,
                error: error.localizedDescription
            ))
            
            Logger.error("Failed to delete \(String(describing: Model.self)): \(error.localizedDescription)", category: .database)
            throw error
        }
    }
    
    func getAll() async throws -> [Model] {
        do {
            let descriptor = FetchDescriptor<Model>()
            let results = try modelContext.fetch(descriptor)
            
            // Filter out soft-deleted items
            let filtered = results.filter { model in
                if let softDeletable = model as? any SoftDeletableModel {
                    return !softDeletable.isDeleted
                }
                return true
            }
            
            auditLogger.log(DataOperation(
                operation: .read,
                modelType: String(describing: Model.self),
                success: true,
                metadata: ["count": filtered.count]
            ))
            
            return filtered
            
        } catch {
            auditLogger.log(DataOperation(
                operation: .read,
                modelType: String(describing: Model.self),
                success: false,
                error: error.localizedDescription
            ))
            
            Logger.error("Failed to fetch all \(String(describing: Model.self)): \(error.localizedDescription)", category: .database)
            throw error
        }
    }
    
    // MARK: - Validation
    
    func validate(_ model: Model) async throws {
        do {
            try model.validate()
            
            auditLogger.log(DataOperation(
                operation: .validate,
                modelType: String(describing: Model.self),
                modelId: (model as? any Identifiable)?.id as? UUID,
                success: true
            ))
            
        } catch {
            auditLogger.log(DataOperation(
                operation: .validate,
                modelType: String(describing: Model.self),
                modelId: (model as? any Identifiable)?.id as? UUID,
                success: false,
                error: error.localizedDescription
            ))
            
            throw error
        }
    }
    
    // MARK: - Error Recovery
    
    func canRecover(from error: Error) -> Bool {
        switch error {
        case DataError.concurrencyConflict,
             DataError.storageUnavailable:
            return true
        default:
            return false
        }
    }
    
    func recover(from error: Error) async throws {
        switch error {
        case DataError.concurrencyConflict:
            try await retryWithExponentialBackoff { [weak self] in
                try self?.modelContext.save()
            }
        case DataError.storageUnavailable:
            try await waitForStorageAvailability()
        default:
            throw error
        }
    }
    
    // MARK: - Audit
    
    func logOperation(_ operation: DataOperation, on model: Model) {
        auditLogger.log(operation)
    }
    
    // MARK: - Private Helper Methods
    
    private func retryWithExponentialBackoff(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 0.5,
        operation: @escaping () throws -> Void
    ) async throws {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                try operation()
                return
            } catch {
                lastError = error
                
                if attempt < maxRetries - 1 {
                    let delay = baseDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? DataError.concurrencyConflict
    }
    
    private func waitForStorageAvailability() async throws {
        for _ in 0..<10 {
            try await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
            
            // Try to perform a simple operation
            do {
                let descriptor = FetchDescriptor<Model>()
                descriptor.fetchLimit = 1
                _ = try modelContext.fetch(descriptor)
                return // Storage is available
            } catch {
                continue
            }
        }
        
        throw DataError.storageUnavailable
    }
}

// MARK: - Supporting Protocols

protocol TimestampedModel {
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}

protocol SoftDeletableModel {
    var isDeleted: Bool { get set }
    var deletedAt: Date? { get set }
}

protocol VersionedModel {
    var version: Int { get set }
}

// MARK: - Result Types

enum ServiceResult<T> {
    case success(T)
    case failure(DataError)
    case partial(T, warnings: [ValidationWarning])
    
    var value: T? {
        switch self {
        case .success(let value), .partial(let value, _):
            return value
        case .failure:
            return nil
        }
    }
    
    var isSuccess: Bool {
        switch self {
        case .success, .partial:
            return true
        case .failure:
            return false
        }
    }
    
    var warnings: [ValidationWarning] {
        switch self {
        case .partial(_, let warnings):
            return warnings
        default:
            return []
        }
    }
} 