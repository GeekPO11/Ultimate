# Ultimate - System Architecture Documentation

> **Version:** 1.0.0  
> **Last Updated:** January 2025  
> **Author:** Sanchay Gumber  
> **License:** Apache-2.0

---

## Table of Contents

1. [Overview](#overview)
2. [High-Level Architecture](#high-level-architecture)
3. [Architecture Patterns](#architecture-patterns)
4. [Data Architecture](#data-architecture)
5. [Module Structure](#module-structure)
6. [Component Interaction](#component-interaction)
7. [Data Flow](#data-flow)
8. [Design Patterns](#design-patterns)
9. [Security Architecture](#security-architecture)
10. [Performance Considerations](#performance-considerations)
11. [Testing Strategy](#testing-strategy)
12. [Deployment Architecture](#deployment-architecture)

---

## Overview

Ultimate is a native iOS application built using modern Apple technologies, following clean architecture principles with a strong emphasis on separation of concerns, testability, and maintainability.

### Technology Stack

```
┌─────────────────────────────────────────────┐
│           Frontend & Business Logic          │
│              SwiftUI + Swift 5.9             │
├─────────────────────────────────────────────┤
│         Data Persistence Layer               │
│            SwiftData Framework               │
├─────────────────────────────────────────────┤
│         System Integration Layer             │
│  HealthKit │ UserNotifications │ PhotoKit   │
├─────────────────────────────────────────────┤
│              iOS 17.0+ Runtime               │
│            iPhone & iPad Support             │
└─────────────────────────────────────────────┘
```

### Key Architectural Principles

1. **Separation of Concerns**: Clear boundaries between UI, business logic, and data layers
2. **SOLID Principles**: Each component has a single responsibility
3. **Dependency Injection**: Services are injected rather than instantiated
4. **Testability**: All components are designed to be testable in isolation
5. **Reactive Programming**: State management through Combine and SwiftUI's reactive bindings

---

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                         Presentation Layer                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │  SwiftUI   │  │  ViewModels│  │ UI Comp.   │             │
│  │   Views    │◄─┤ (@StateObj)│◄─┤ Library    │             │
│  └────────────┘  └────────────┘  └────────────┘             │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│                        Business Logic Layer                   │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │  Services  │  │ Managers   │  │ Validators │             │
│  │            │◄─┤            │◄─┤            │             │
│  └────────────┘  └────────────┘  └────────────┘             │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│                         Data Layer                            │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │ SwiftData  │  │  Models    │  │ Repository │             │
│  │  Context   │◄─┤ (@Model)   │◄─┤  Pattern   │             │
│  └────────────┘  └────────────┘  └────────────┘             │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│                     System Integration Layer                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │ HealthKit  │  │UserNotif.  │  │ PhotoKit   │             │
│  │ Service    │  │ Manager    │  │ Service    │             │
│  └────────────┘  └────────────┘  └────────────┘             │
└──────────────────────────────────────────────────────────────┘
```

---

## Architecture Patterns

### MVVM (Model-View-ViewModel)

Ultimate implements the MVVM pattern with some enhancements:

```
View (SwiftUI)
    │
    │ @StateObject / @ObservedObject
    ▼
ViewModel (ObservableObject)
    │
    │ Uses Services
    ▼
Service Layer (Business Logic)
    │
    │ Repository Pattern
    ▼
Model (@Model from SwiftData)
    │
    │ Persistence
    ▼
SwiftData Storage
```

### Repository Pattern

Each major data entity has a corresponding service that acts as a repository:

```swift
// Example: ChallengeService acts as a repository
protocol ChallengeServiceProtocol {
    func fetchChallenges() async throws -> [Challenge]
    func createChallenge(_ challenge: Challenge) async throws
    func updateChallenge(_ challenge: Challenge) async throws
    func deleteChallenge(_ id: UUID) async throws
}
```

### Service Layer Pattern

Business logic is encapsulated in services:

```
┌──────────────────────────────────────────┐
│         Service Layer                     │
├──────────────────────────────────────────┤
│ • ChallengeService                       │
│ • DailyTaskManager                       │
│ • NotificationManager                    │
│ • DataMigrationService                   │
│ • HealthKitService                       │
│ • PhotoQualityService (planned)          │
└──────────────────────────────────────────┘
```

---

## Data Architecture

### Data Model Hierarchy

```
┌─────────────────────────────────────────────────────────┐
│                     User (@Model)                        │
│  • Profile information                                   │
│  • Settings & preferences                                │
│  • Notification preferences                              │
└─────────────────┬───────────────────────────────────────┘
                  │ One-to-Many
                  ▼
┌─────────────────────────────────────────────────────────┐
│                  Challenge (@Model)                      │
│  • Challenge metadata                                    │
│  • Start/End dates                                       │
│  • Status tracking                                       │
│  • Progress calculations                                 │
└─────────┬───────────────────────┬───────────────────────┘
          │ One-to-Many           │ One-to-Many
          ▼                       ▼
┌──────────────────┐    ┌──────────────────────────────┐
│  Task (@Model)   │    │  ProgressPhoto (@Model)      │
│  • Task details  │    │  • Photo metadata            │
│  • Frequency     │    │  • File location             │
│  • Measurement   │    │  • Angle/category            │
└────────┬─────────┘    └──────────────────────────────┘
         │ One-to-Many
         ▼
┌────────────────────────┐
│  DailyTask (@Model)    │
│  • Daily instance      │
│  • Completion status   │
│  • Actual values       │
└────────────────────────┘
```

### SwiftData Schema

```swift
// Core Models with @Model macro
@Model final class Challenge {
    @Attribute(.unique) var id: UUID
    var name: String
    var challengeDescription: String
    var type: ChallengeType
    var status: ChallengeStatus
    var startDate: Date?
    var endDate: Date?
    var durationInDays: Int
    @Relationship(deleteRule: .cascade) var tasks: [Task]
    @Relationship(deleteRule: .cascade) var progressPhotos: [ProgressPhoto]
}

@Model final class Task {
    @Attribute(.unique) var id: UUID
    var name: String
    var taskDescription: String
    var type: TaskType
    var frequency: TaskFrequency
    var measurementType: TaskMeasurementType
    @Relationship(inverse: \Challenge.tasks) var challenge: Challenge?
    @Relationship(deleteRule: .cascade) var dailyTasks: [DailyTask]
}

@Model final class DailyTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var isCompleted: Bool
    var status: TaskCompletionStatus
    @Relationship(inverse: \Task.dailyTasks) var task: Task?
}
```

### Data Persistence Strategy

```
┌───────────────────────────────────────────────────┐
│            ModelContainer                          │
│  • Singleton for app lifecycle                    │
│  • Manages ModelContext instances                 │
│  • Configured in UltimateApp.swift                │
└────────────────┬──────────────────────────────────┘
                 │
                 ▼
┌───────────────────────────────────────────────────┐
│            ModelContext                            │
│  • Passed through environment                     │
│  • Tracks changes automatically                   │
│  • Supports async/await operations                │
└────────────────┬──────────────────────────────────┘
                 │
                 ▼
┌───────────────────────────────────────────────────┐
│         Persistent Storage                         │
│  • SQLite backend (managed by SwiftData)          │
│  • Automatic schema migration                     │
│  • Write-ahead logging for consistency            │
└───────────────────────────────────────────────────┘
```

---

## Module Structure

### Directory Organization

```
Ultimate/
├── Features/                    # Feature-based organization
│   ├── Challenges/
│   │   ├── ChallengesView.swift
│   │   ├── ChallengeDetailView.swift
│   │   └── CustomChallengeView.swift
│   ├── DailyTasks/
│   │   ├── TodayView.swift
│   │   └── DailyTasksManager.swift
│   ├── Photos/
│   │   ├── PhotosView.swift
│   │   ├── PhotoDetailView.swift
│   │   └── OptimizedCameraView.swift
│   ├── Progress/
│   │   ├── ProgressTrackingView.swift
│   │   └── ChallengeAnalyticsView.swift
│   └── Settings/
│       └── SettingsView.swift
│
├── Core/                        # Core business logic
│   ├── Models/                  # Data models
│   │   ├── Challenge.swift
│   │   ├── Task.swift
│   │   ├── DailyTask.swift
│   │   ├── User.swift
│   │   └── ProgressPhoto.swift
│   ├── Services/                # Business logic services
│   │   ├── ChallengeService.swift
│   │   ├── DailyTaskManager.swift
│   │   ├── NotificationManager.swift
│   │   ├── HealthKitService.swift
│   │   └── DataMigrationService.swift
│   ├── Data/                    # Data layer abstractions
│   │   ├── DataTransferObjects.swift
│   │   ├── ServiceLayer.swift
│   │   └── ValidationFramework.swift
│   └── Utilities/
│       └── Logger.swift
│
├── UI/                          # Reusable UI components
│   ├── Components/
│   │   ├── CTButton.swift
│   │   ├── CTCard.swift
│   │   ├── CTProgressRing.swift
│   │   └── MaterialCard.swift
│   ├── Modifiers/
│   │   └── AppleMaterial.swift
│   └── Styles/
│       └── DesignSystem.swift
│
└── UltimateApp.swift            # App entry point
```

### Feature Module Pattern

Each feature follows a consistent structure:

```
Feature/
├── Views/              # SwiftUI views
├── ViewModels/         # Business logic (if needed)
├── Models/             # Feature-specific models
└── Services/           # Feature-specific services
```

---

## Component Interaction

### Challenge Creation Flow

```
┌──────────────────┐
│  User taps       │
│ "New Challenge"  │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  CustomChallengeView                 │
│  • Collects challenge details        │
│  • Validates input                   │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  ChallengeService                    │
│  • Creates Challenge model           │
│  • Creates associated Tasks          │
│  • Saves to SwiftData                │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  NotificationManager                 │
│  • Schedules task notifications      │
│  • Sets up reminders                 │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  DailyTaskManager                    │
│  • Generates first day's tasks       │
│  • Initializes tracking              │
└──────────────────────────────────────┘
```

### Daily Task Completion Flow

```
┌──────────────────┐
│  User marks      │
│  task complete   │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  TodayView                           │
│  • Updates UI state                  │
│  • Triggers completion handler       │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  DailyTask Model                     │
│  • Updates completion status         │
│  • Records timestamp                 │
│  • Saves actual values               │
└────────┬─────────────────────────────┘
         │
         ├─────────────────┐
         │                 │
         ▼                 ▼
┌──────────────────┐  ┌──────────────────┐
│ SwiftData saves  │  │ Analytics update │
│ automatically    │  │ Progress calcs   │
└──────────────────┘  └──────────────────┘
```

### HealthKit Integration Flow

```
┌──────────────────────────────────────┐
│  DailyTaskManager                    │
│  • Requests HealthKit authorization  │
│  • Sets up workout query             │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  HealthKitService                    │
│  • Monitors workout data             │
│  • Queries exercise minutes          │
└────────┬─────────────────────────────┘
         │ Background observer
         ▼
┌──────────────────────────────────────┐
│  Workout Detected                    │
│  • Matches with daily tasks          │
│  • Auto-completes workout tasks      │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  Update UI & Notifications           │
│  • Refresh task list                 │
│  • Send completion notification      │
└──────────────────────────────────────┘
```

---

## Data Flow

### Unidirectional Data Flow

```
┌──────────────────────────────────────────────────────┐
│                    User Action                        │
│                  (Button Tap, etc.)                   │
└───────────────────────┬──────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────┐
│                   View Handler                        │
│             (Calls ViewModel/Service)                 │
└───────────────────────┬──────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────┐
│                Service/Manager                        │
│            (Business Logic Execution)                 │
└───────────────────────┬──────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────┐
│                  Model Update                         │
│            (SwiftData Model Changes)                  │
└───────────────────────┬──────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────┐
│              SwiftData Auto-Save                      │
│            (Persistence Triggered)                    │
└───────────────────────┬──────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────┐
│               SwiftUI Re-render                       │
│          (View updates automatically)                 │
└──────────────────────────────────────────────────────┘
```

### State Management

```
┌─────────────────────────────────────┐
│         App-Level State              │
│                                      │
│  • UserSettings (@StateObject)       │
│  • NotificationManager (Singleton)   │
│  • DailyTaskManager (Singleton)      │
└─────────────┬───────────────────────┘
              │
              │ Environment Objects
              ▼
┌─────────────────────────────────────┐
│        Feature-Level State           │
│                                      │
│  • @State for local UI state         │
│  • @Query for SwiftData queries      │
│  • @Environment for shared state     │
└─────────────────────────────────────┘
```

---

## Design Patterns

### Singleton Pattern

Used for app-wide services:

```swift
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private init() { }
}

class DailyTaskManager: ObservableObject {
    static let shared = DailyTaskManager()
    private init() { }
}
```

### Observer Pattern

SwiftUI and Combine provide reactive bindings:

```swift
class UserSettings: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var selectedTab: Int = 0
}
```

### Factory Pattern

Challenge creation uses factory-like methods:

```swift
extension Challenge {
    static func seventyFiveHard() -> Challenge {
        // Creates a 75 Hard challenge with predefined tasks
    }
    
    static func waterFasting(duration: Int) -> Challenge {
        // Creates a water fasting challenge
    }
}
```

### Strategy Pattern

Task measurement types use strategy pattern:

```swift
enum TaskMeasurementType {
    case binary          // Complete/Incomplete
    case quantity        // Measured in units
    case duration        // Measured in time
    case checklist       // Multiple items
}
```

---

## Security Architecture

### Data Protection

```
┌──────────────────────────────────────┐
│        App Sandbox                    │
│  • All data stored in app sandbox    │
│  • Protected by iOS encryption        │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│     SwiftData Encryption              │
│  • Automatic encryption at rest       │
│  • Secure attribute support           │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│    Photo Storage Security             │
│  • Photos stored in Documents dir     │
│  • File protection attributes         │
│  • Not backed up by default           │
└──────────────────────────────────────┘
```

### Permission Management

```
┌────────────────────────┐
│   App Permissions       │
├────────────────────────┤
│ • User Notifications   │
│ • HealthKit (optional) │
│ • Camera Access        │
│ • Photo Library        │
└────────────────────────┘
```

All permissions are:
- Requested at appropriate times
- Optional (app works without them)
- Explained with clear usage descriptions

---

## Performance Considerations

### Lazy Loading

```swift
// SwiftData queries are lazy by default
@Query(sort: \Challenge.startDate, order: .reverse) 
var challenges: [Challenge]
```

### Efficient Image Handling

```
┌──────────────────────────────────────┐
│         Photo Capture                 │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│      Image Compression                │
│  • JPEG with 80% quality              │
│  • Resize to max dimensions           │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│     Persistent Storage                │
│  • Save to Documents directory        │
│  • Store file URL in SwiftData        │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│      Thumbnail Generation             │
│  • Create thumbnails on demand        │
│  • Cache in memory                    │
└──────────────────────────────────────┘
```

### Background Processing

```swift
// HealthKit observations in background
// Daily task generation at midnight
// Notification scheduling
```

---

## Testing Strategy

### Test Pyramid

```
┌────────────────────────────────┐
│         E2E Tests              │  ← Few
│      (UI Testing)              │
├────────────────────────────────┤
│      Integration Tests         │  ← Some
│    (Service + Model)           │
├────────────────────────────────┤
│        Unit Tests              │  ← Many
│  (Business Logic)              │
└────────────────────────────────┘
```

### Test Coverage by Layer

- **Models**: Unit tests for computed properties and methods
- **Services**: Integration tests for business logic
- **Views**: UI tests for critical user flows
- **Utilities**: Unit tests for helper functions

### Key Test Files

```
UltimateTests/
├── NotificationManagerTests.swift
├── ChallengeAnalyticsTests.swift
├── DataLayerIntegrationTests.swift
└── GlassMorphismTests.swift

UltimateUITests/
├── UltimateUITests.swift
├── GlassMorphismUITests.swift
└── UltimateUITestsLaunchTests.swift
```

---

## Deployment Architecture

### Build Configuration

```
┌──────────────────────────────────────┐
│         Development                   │
│  • Debug symbols included             │
│  • Extended logging                   │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│         Production                    │
│  • Optimized build                    │
│  • Minimal logging                    │
│  • App Store distribution             │
└──────────────────────────────────────┘
```

### Requirements

- **Minimum iOS Version**: 17.0
- **Supported Devices**: iPhone (all iOS 17+ compatible)
- **Architectures**: arm64
- **Capabilities**:
  - HealthKit
  - Push Notifications
  - Background Fetch

### App Size Optimization

- Asset catalogs with compression
- Thinning for device-specific builds
- On-demand resources (future consideration)

---

## Future Architecture Considerations

### Planned Enhancements

1. **Cloud Sync Layer**
   ```
   CloudKit Integration
   ├── Sync Engine
   ├── Conflict Resolution
   └── Offline Support
   ```

2. **Analytics Layer**
   ```
   Privacy-Focused Analytics
   ├── On-Device Processing
   ├── Aggregated Metrics
   └── No PII Collected
   ```

3. **Widget Extension**
   ```
   Today Extension
   ├── Quick Task View
   ├── Progress Summary
   └── Streak Display
   ```

4. **Watch App**
   ```
   watchOS Companion
   ├── Quick Task Completion
   ├── Workout Integration
   └── Progress Glance
   ```

---

## Code References

### Key Files

| Component | File Path | Lines of Code | Description |
|-----------|-----------|---------------|-------------|
| App Entry | `UltimateApp.swift` | 362 | App initialization, model container setup |
| Challenge Model | `Core/Models/Challenge.swift` | ~200 | Core challenge data model |
| Task Manager | `Core/Services/DailyTaskManager.swift` | ~300 | Daily task generation and management |
| Notifications | `Core/Services/NotificationManager.swift` | ~400 | Notification scheduling and handling |
| Design System | `UI/Styles/DesignSystem.swift` | ~150 | UI constants and theming |

---

## Glossary

- **SwiftData**: Apple's modern data persistence framework
- **@Model**: Macro that makes a class persistable with SwiftData
- **@Query**: Property wrapper for reactive database queries
- **ModelContainer**: Top-level SwiftData container managing persistence
- **ModelContext**: SwiftData context for tracking and saving changes

---

## Conclusion

Ultimate's architecture is designed to be:
- **Scalable**: Easy to add new features and challenges
- **Maintainable**: Clear separation of concerns and consistent patterns
- **Testable**: Each layer can be tested independently
- **Performant**: Optimized for iOS with modern frameworks
- **Secure**: Following iOS security best practices

For questions or suggestions about the architecture, please open an issue on GitHub.

---

**Document Version:** 1.0.0  
**Last Updated:** January 2025  
**Copyright:** 2025 Sanchay Gumber  
**License:** Apache-2.0

