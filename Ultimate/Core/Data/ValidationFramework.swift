import Foundation
import SwiftData

// MARK: - Validation Framework Core Types

enum ValidationError: LocalizedError, Equatable {
    case required(field: String)
    case invalidLength(field: String, min: Int?, max: Int?)
    case invalidRange(field: String, min: Double?, max: Double?)
    case invalidFormat(field: String, expected: String)
    case invalidDate(field: String, reason: String)
    case constraintViolation(field: String, rule: String)
    case businessRuleViolation(rule: String)
    case relationshipViolation(field: String, reason: String)
    
    var errorDescription: String? {
        switch self {
        case .required(let field):
            return "\(field) is required"
        case .invalidLength(let field, let min, let max):
            if let min = min, let max = max {
                return "\(field) must be between \(min) and \(max) characters"
            } else if let min = min {
                return "\(field) must be at least \(min) characters"
            } else if let max = max {
                return "\(field) must be no more than \(max) characters"
            }
            return "\(field) has invalid length"
        case .invalidRange(let field, let min, let max):
            if let min = min, let max = max {
                return "\(field) must be between \(min) and \(max)"
            } else if let min = min {
                return "\(field) must be at least \(min)"
            } else if let max = max {
                return "\(field) must be no more than \(max)"
            }
            return "\(field) has invalid value"
        case .invalidFormat(let field, let expected):
            return "\(field) has invalid format. Expected: \(expected)"
        case .invalidDate(let field, let reason):
            return "\(field) has invalid date: \(reason)"
        case .constraintViolation(let field, let rule):
            return "\(field) violates constraint: \(rule)"
        case .businessRuleViolation(let rule):
            return "Business rule violation: \(rule)"
        case .relationshipViolation(let field, let reason):
            return "\(field) relationship error: \(reason)"
        }
    }
}

struct ValidationWarning: Equatable {
    let field: String
    let message: String
    let severity: WarningSeverity
    
    enum WarningSeverity {
        case low, medium, high
    }
}

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationWarning]
    
    static let valid = ValidationResult(isValid: true, errors: [], warnings: [])
    
    static func invalid(_ errors: [ValidationError], warnings: [ValidationWarning] = []) -> ValidationResult {
        return ValidationResult(isValid: false, errors: errors, warnings: warnings)
    }
    
    static func warning(_ warnings: [ValidationWarning]) -> ValidationResult {
        return ValidationResult(isValid: true, errors: [], warnings: warnings)
    }
}

// MARK: - Validation Rules

enum ValidationRule {
    case required
    case minLength(Int)
    case maxLength(Int)
    case lengthRange(min: Int, max: Int)
    case minValue(Double)
    case maxValue(Double)
    case valueRange(min: Double, max: Double)
    case email
    case phone
    case url
    case uuid
    case positiveInteger
    case dateRange(start: Date?, end: Date?)
    case futureDate
    case pastDate
    case custom(String, (Any) -> ValidationResult)
    
    func validate(_ value: Any?, fieldName: String) -> ValidationResult {
        switch self {
        case .required:
            if value == nil {
                return .invalid([.required(field: fieldName)])
            }
            if let stringValue = value as? String, stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .invalid([.required(field: fieldName)])
            }
            return .valid
            
        case .minLength(let min):
            guard let stringValue = value as? String else {
                return .invalid([.invalidFormat(field: fieldName, expected: "string")])
            }
            if stringValue.count < min {
                return .invalid([.invalidLength(field: fieldName, min: min, max: nil)])
            }
            return .valid
            
        case .maxLength(let max):
            guard let stringValue = value as? String else {
                return .invalid([.invalidFormat(field: fieldName, expected: "string")])
            }
            if stringValue.count > max {
                return .invalid([.invalidLength(field: fieldName, min: nil, max: max)])
            }
            return .valid
            
        case .lengthRange(let min, let max):
            guard let stringValue = value as? String else {
                return .invalid([.invalidFormat(field: fieldName, expected: "string")])
            }
            if stringValue.count < min || stringValue.count > max {
                return .invalid([.invalidLength(field: fieldName, min: min, max: max)])
            }
            return .valid
            
        case .minValue(let min):
            guard let numericValue = value as? Double else {
                return .invalid([.invalidFormat(field: fieldName, expected: "number")])
            }
            if numericValue < min {
                return .invalid([.invalidRange(field: fieldName, min: min, max: nil)])
            }
            return .valid
            
        case .maxValue(let max):
            guard let numericValue = value as? Double else {
                return .invalid([.invalidFormat(field: fieldName, expected: "number")])
            }
            if numericValue > max {
                return .invalid([.invalidRange(field: fieldName, min: nil, max: max)])
            }
            return .valid
            
        case .valueRange(let min, let max):
            guard let numericValue = value as? Double else {
                return .invalid([.invalidFormat(field: fieldName, expected: "number")])
            }
            if numericValue < min || numericValue > max {
                return .invalid([.invalidRange(field: fieldName, min: min, max: max)])
            }
            return .valid
            
        case .email:
            guard let stringValue = value as? String else {
                return .invalid([.invalidFormat(field: fieldName, expected: "string")])
            }
            let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: stringValue) {
                return .invalid([.invalidFormat(field: fieldName, expected: "valid email address")])
            }
            return .valid
            
        case .phone:
            guard let stringValue = value as? String else {
                return .invalid([.invalidFormat(field: fieldName, expected: "string")])
            }
            let phoneRegex = #"^\+?[1-9]\d{1,14}$"#
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            if !phonePredicate.evaluate(with: stringValue) {
                return .invalid([.invalidFormat(field: fieldName, expected: "valid phone number")])
            }
            return .valid
            
        case .url:
            guard let stringValue = value as? String else {
                return .invalid([.invalidFormat(field: fieldName, expected: "string")])
            }
            if URL(string: stringValue) == nil {
                return .invalid([.invalidFormat(field: fieldName, expected: "valid URL")])
            }
            return .valid
            
        case .uuid:
            guard let stringValue = value as? String else {
                return .invalid([.invalidFormat(field: fieldName, expected: "string")])
            }
            if UUID(uuidString: stringValue) == nil {
                return .invalid([.invalidFormat(field: fieldName, expected: "valid UUID")])
            }
            return .valid
            
        case .positiveInteger:
            guard let intValue = value as? Int else {
                return .invalid([.invalidFormat(field: fieldName, expected: "integer")])
            }
            if intValue <= 0 {
                return .invalid([.invalidRange(field: fieldName, min: 1, max: nil)])
            }
            return .valid
            
        case .dateRange(let start, let end):
            guard let dateValue = value as? Date else {
                return .invalid([.invalidFormat(field: fieldName, expected: "date")])
            }
            if let start = start, dateValue < start {
                return .invalid([.invalidDate(field: fieldName, reason: "date is before allowed start date")])
            }
            if let end = end, dateValue > end {
                return .invalid([.invalidDate(field: fieldName, reason: "date is after allowed end date")])
            }
            return .valid
            
        case .futureDate:
            guard let dateValue = value as? Date else {
                return .invalid([.invalidFormat(field: fieldName, expected: "date")])
            }
            if dateValue <= Date() {
                return .invalid([.invalidDate(field: fieldName, reason: "date must be in the future")])
            }
            return .valid
            
        case .pastDate:
            guard let dateValue = value as? Date else {
                return .invalid([.invalidFormat(field: fieldName, expected: "date")])
            }
            if dateValue >= Date() {
                return .invalid([.invalidDate(field: fieldName, reason: "date must be in the past")])
            }
            return .valid
            
        case .custom(let name, let validator):
            let result = validator(value)
            if !result.isValid {
                // Add context to custom validation errors
                let contextualErrors = result.errors.map { error in
                    switch error {
                    case .businessRuleViolation(let rule):
                        return .businessRuleViolation("\(name): \(rule)")
                    default:
                        return error
                    }
                }
                return .invalid(contextualErrors, warnings: result.warnings)
            }
            return result
        }
    }
}

// MARK: - Field Validator

struct FieldValidator {
    let fieldName: String
    let rules: [ValidationRule]
    
    init(_ fieldName: String, rules: [ValidationRule]) {
        self.fieldName = fieldName
        self.rules = rules
    }
    
    func validate(_ value: Any?) -> ValidationResult {
        var allErrors: [ValidationError] = []
        var allWarnings: [ValidationWarning] = []
        
        for rule in rules {
            let result = rule.validate(value, fieldName: fieldName)
            allErrors.append(contentsOf: result.errors)
            allWarnings.append(contentsOf: result.warnings)
            
            // Stop on first error for required fields
            if case .required = rule, !result.isValid {
                break
            }
        }
        
        return allErrors.isEmpty ? .warning(allWarnings) : .invalid(allErrors, warnings: allWarnings)
    }
}

// MARK: - Model Validation Protocol

protocol ValidatableModel {
    func validate() throws
    func isValid() -> Bool
    var validationErrors: [ValidationError] { get }
    var validationWarnings: [ValidationWarning] { get }
    
    /// Override this to provide field-level validation rules
    func fieldValidators() -> [FieldValidator]
    
    /// Override this to provide business rule validation
    func validateBusinessRules() throws
    
    /// Override this to provide cross-field validation
    func validateCrossFields() throws
}

// MARK: - Default Implementation

extension ValidatableModel {
    func validate() throws {
        // 1. Field-level validation
        let fieldValidationResult = validateFields()
        
        // 2. Business rules validation
        try validateBusinessRules()
        
        // 3. Cross-field validation
        try validateCrossFields()
        
        // Throw if any field validation errors
        if !fieldValidationResult.isValid {
            throw DataError.validationFailed(fieldValidationResult.errors)
        }
    }
    
    func isValid() -> Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
    
    var validationErrors: [ValidationError] {
        do {
            try validate()
            return []
        } catch let error as DataError {
            if case .validationFailed(let errors) = error {
                return errors
            }
            return []
        } catch {
            return [.businessRuleViolation("Unknown validation error: \(error.localizedDescription)")]
        }
    }
    
    var validationWarnings: [ValidationWarning] {
        let fieldResult = validateFields()
        return fieldResult.warnings
    }
    
    func fieldValidators() -> [FieldValidator] {
        return []
    }
    
    func validateBusinessRules() throws {
        // Default implementation - override in concrete types
    }
    
    func validateCrossFields() throws {
        // Default implementation - override in concrete types
    }
    
    private func validateFields() -> ValidationResult {
        var allErrors: [ValidationError] = []
        var allWarnings: [ValidationWarning] = []
        
        let validators = fieldValidators()
        let mirror = Mirror(reflecting: self)
        
        for validator in validators {
            // Use reflection to get the field value
            let fieldValue = mirror.children.first { $0.label == validator.fieldName }?.value
            let result = validator.validate(fieldValue)
            
            allErrors.append(contentsOf: result.errors)
            allWarnings.append(contentsOf: result.warnings)
        }
        
        return allErrors.isEmpty ? .warning(allWarnings) : .invalid(allErrors, warnings: allWarnings)
    }
}

// MARK: - Data Error Definition

enum DataError: LocalizedError {
    case validationFailed([ValidationError])
    case constraintViolation(String)
    case concurrencyConflict
    case storageUnavailable
    case corruptedData(String)
    case migrationFailed(String)
    case insufficientStorage
    case permissionDenied
    case relationshipViolation(String)
    case businessRuleViolation(String)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return "Validation failed: \(errors.map { $0.localizedDescription }.joined(separator: ", "))"
        case .constraintViolation(let constraint):
            return "Database constraint violation: \(constraint)"
        case .concurrencyConflict:
            return "Data was modified by another process"
        case .storageUnavailable:
            return "Database storage is unavailable"
        case .corruptedData(let details):
            return "Data corruption detected: \(details)"
        case .migrationFailed(let details):
            return "Data migration failed: \(details)"
        case .insufficientStorage:
            return "Insufficient storage space"
        case .permissionDenied:
            return "Permission denied for data operation"
        case .relationshipViolation(let details):
            return "Relationship constraint violation: \(details)"
        case .businessRuleViolation(let rule):
            return "Business rule violation: \(rule)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .validationFailed:
            return "Please correct the highlighted fields and try again"
        case .constraintViolation:
            return "Please ensure all required relationships are properly set"
        case .concurrencyConflict:
            return "Please refresh the data and try your operation again"
        case .storageUnavailable:
            return "Please check your device storage and try again"
        case .corruptedData:
            return "Please contact support for data recovery assistance"
        case .migrationFailed:
            return "Please restart the app or contact support if the issue persists"
        case .insufficientStorage:
            return "Please free up storage space and try again"
        case .permissionDenied:
            return "Please check app permissions in device settings"
        case .relationshipViolation:
            return "Please ensure all related data is properly configured"
        case .businessRuleViolation:
            return "Please review the operation requirements and try again"
        }
    }
}

// MARK: - Validation Helper Functions

extension ValidationRule {
    static func challengeName() -> [ValidationRule] {
        return [
            .required,
            .lengthRange(min: 2, max: 100),
            .custom("no special characters") { value in
                guard let stringValue = value as? String else { return .valid }
                let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "-_"))
                if stringValue.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
                    return .invalid([.invalidFormat(field: "name", expected: "letters, numbers, spaces, hyphens, and underscores only")])
                }
                return .valid
            }
        ]
    }
    
    static func challengeDescription() -> [ValidationRule] {
        return [
            .required,
            .lengthRange(min: 10, max: 500)
        ]
    }
    
    static func challengeDuration() -> [ValidationRule] {
        return [
            .required,
            .valueRange(min: 1, max: 365)
        ]
    }
    
    static func taskName() -> [ValidationRule] {
        return [
            .required,
            .lengthRange(min: 2, max: 80)
        ]
    }
    
    static func targetValue() -> [ValidationRule] {
        return [
            .minValue(0.01)
        ]
    }
} 