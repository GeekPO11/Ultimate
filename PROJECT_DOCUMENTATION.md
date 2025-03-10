# Ultimate App - Project Documentation

## Project Overview
Ultimate is a premium iOS fitness and habit tracking app designed to help users transform their lives through structured challenges and consistent habit building. The app enables users to create and manage challenges, track daily tasks, visualize progress, and capture progress photos, all wrapped in a modern, gesture-driven UI inspired by visionOS design principles.

## Architecture

### System Architecture
The Ultimate app follows a clean, modular architecture based on MVVM (Model-View-ViewModel) with Coordinators:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│       View      │◄────┤    ViewModel    │◄────┤    Repository   │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        │
                                                        ▼
                                             ┌─────────────────┐
                                             │                 │
                                             │     Models      │
                                             │                 │
                                             └─────────────────┘
```

- **Views**: SwiftUI views responsible for UI rendering and user interaction
- **ViewModels**: Contain business logic and transform data for display
- **Repositories**: Handle data access operations and provide a clean API
- **Models**: SwiftData models representing the business domain

### Data Flow
1. User interactions trigger methods in the ViewModel
2. ViewModels process the request and call appropriate Repository methods
3. Repositories perform data operations using SwiftData
4. Changes are observed by the ViewModels through Combine publishers
5. ViewModels transform and prepare data for display
6. Views update automatically through @Published properties

### Dependency Management
- Swift Package Manager for external dependencies
- Dependency injection for services and repositories
- Environment objects for shared state across the view hierarchy

## Directory Structure
```
Ultimate/
├── Features/
│   ├── Challenges/
│   │   ├── ChallengesView.swift
│   │   ├── ChallengeDetailView.swift
│   │   └── ChallengeAnalyticsView.swift
│   ├── DailyTasks/
│   │   ├── TodayView.swift
│   │   └── DailyTasksManager.swift
│   ├── Progress/
│   │   └── ProgressTrackingView.swift
│   └── Photos/
│       ├── PhotosView.swift
│       └── PhotoDetailView.swift
├── Core/
│   ├── Models/
│   │   ├── Challenge.swift
│   │   ├── Task.swift
│   │   ├── DailyTask.swift
│   │   ├── User.swift
│   │   ├── ProgressPhoto.swift
│   │   ├── ChecklistItem.swift
│   │   ├── NotificationPreference.swift
│   │   ├── TaskCompletionEvent.swift
│   │   ├── TaskCompletionData.swift
│   │   ├── PhotoSession.swift
│   │   └── AnalyticsModels.swift
│   ├── Services/
│   │   ├── NotificationManager.swift
│   │   ├── DataMigrationService.swift
│   │   ├── NotificationOptimizationService.swift
│   │   ├── PhotoQualityService.swift
│   │   ├── TaskTemplateService.swift
│   │   ├── ProgressAnalyticsService.swift
│   │   └── TaskHistoryService.swift
│   ├── ViewModels/
│   │   ├── ChallengeViewModel.swift
│   │   ├── TaskViewModel.swift
│   │   └── ProgressViewModel.swift
│   ├── Utilities/
│   │   ├── Logger.swift
│   │   └── Extensions/
│   └── Settings/
│       └── UserSettings.swift
├── UI/
│   ├── Components/
│   │   ├── CTButton.swift
│   │   ├── CTCard.swift
│   │   ├── CTProgressChart.swift
│   │   ├── CTProgressRing.swift
│   │   └── InteractiveCalendar.swift
│   ├── DesignSystem/
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   ├── Spacing.swift
│   │   └── DesignSystem.swift
│   └── Modifiers/
│       ├── ButtonStyles.swift
│       ├── CardStyles.swift
│       └── AppleMaterial.swift
└── UltimateApp.swift
```

## Core Features

### 1. Challenge Management

#### Overview
The Challenge Management feature allows users to create, customize, and track various fitness and habit-building challenges, including pre-built templates like 75 Hard, Water Fasting, and 31 Modified, as well as fully customizable challenges.

#### Key Components
- **ChallengesView**: Main listing of active and completed challenges
- **ChallengeDetailView**: Detailed view of a specific challenge
- **ChallengeViewModel**: Manages challenge data and business logic
- **Challenge Model**: Data structure for challenges

#### User Flow
1. User accesses the Challenges tab
2. Views list of active and available challenges
3. Creates a new challenge or selects an existing one
4. Customizes challenge parameters (duration, tasks, etc.)
5. Starts the challenge
6. Views daily progress and completion statistics

#### Technical Implementation
- SwiftData for persistent storage of challenges
- CRUD operations via ViewModel
- Real-time progress calculations
- Challenge-specific notifications

### 2. Daily Task Tracking

#### Overview
The Daily Task Tracking feature enables users to view and complete tasks for the current day, supporting various task types with specialized tracking interfaces based on the task measurement type (binary, quantity, duration, or checklist).

#### Key Components
- **TodayView**: Primary interface for viewing and completing daily tasks
- **DailyTasksManager**: Service for generating and managing daily tasks
- **DailyTask Model**: Represents a specific task instance for a particular day
- **Task Model**: Template for recurring tasks

#### Task Measurement Types
- **Binary**: Simple completion (yes/no)
- **Quantity**: Numerical value with units (e.g., 8 glasses of water)
- **Duration**: Time-based (e.g., 45 minutes of reading)
- **Checklist**: Multiple sub-items to complete

#### User Flow
1. User opens the Today tab
2. Views list of tasks for the current day
3. Taps a task to access detailed completion interface
4. Marks task as complete with relevant data
5. Views completion status and statistics

#### Technical Implementation
- SwiftData relationships between Challenge, Task, and DailyTask
- Custom UI for different task types
- Background generation of daily tasks
- Support for retroactive completion

### 3. Progress Analytics

#### Overview
The Progress Analytics feature provides users with visual representations of their challenge progress, consistency scores, and performance metrics to help them understand their habits and progress over time.

#### Key Components
- **ProgressTrackingView**: Main analytics interface
- **ChallengeAnalyticsView**: Challenge-specific analytics
- **ProgressViewModel**: Manages analytics data
- **ProgressAnalyticsService**: Calculates metrics and generates visualization data

#### Key Metrics
- **Completion Rate**: Percentage of tasks completed
- **Consistency Score**: Measure of regular adherence
- **Current Streak**: Consecutive days of task completion
- **Longest Streak**: Record streak for the challenge

#### User Flow
1. User accesses the Progress tab
2. Views overall progress across all challenges
3. Selects a specific challenge for detailed analytics
4. Explores different time periods (day, week, month, year)
5. Examines specific metrics and visualizations

#### Technical Implementation
- Custom chart components for data visualization
- Time-series analysis of task completion data
- Aggregation services for summarizing performance
- Period-based comparisons and trending

### 4. Photo Progress Tracking

#### Overview
The Photo Progress Tracking feature allows users to capture, organize, and compare progress photos over time, providing visual feedback on physical changes during their challenges.

#### Key Components
- **PhotosView**: Gallery view of progress photos
- **PhotoDetailView**: Detailed view with comparison tools
- **PhotoSession Model**: Groups related photos taken at the same time
- **ProgressPhoto Model**: Represents individual photos
- **PhotoQualityService**: Handles image processing and optimization

#### Photo Categories
- **Front View**: Standard front-facing pose
- **Side View**: Profile photo from the side
- **Back View**: Rear-facing pose
- **Custom**: User-defined angles or poses

#### User Flow
1. User navigates to the Photos tab
2. Views photo timeline organized by date
3. Takes new progress photos within the app
4. Compares photos from different dates
5. Views progress over time via visual comparison

#### Technical Implementation
- PhotoKit integration for camera access
- Secure photo storage with FileManager
- On-device processing for privacy
- Optimized thumbnail generation
- Side-by-side comparison tools

### 5. Smart Notification System

#### Overview
The Smart Notification System delivers context-aware, timely reminders based on user preferences, notification strategy, and task types to help users stay on track with their challenges.

#### Key Components
- **NotificationManager**: Core service for scheduling and managing notifications
- **NotificationOptimizationService**: Adapts notification timing based on user behavior
- **NotificationPreference Model**: Stores user preferences for notifications

#### Notification Strategies
- **Fixed**: Regular notifications at predetermined times
- **Adaptive**: Notifications that adapt to user completion patterns
- **Progressive**: Frequency increases as deadlines approach
- **Minimal**: Only essential reminders for critical tasks

#### User Flow
1. User configures notification preferences
2. System schedules notifications based on tasks and preferences
3. User receives contextual reminders
4. User can respond directly from notifications
5. System adapts timing based on response patterns

#### Technical Implementation
- UNUserNotificationCenter integration
- Background notification scheduling
- Actionable notification interfaces
- Adaptive timing algorithms
- Quiet hours and do-not-disturb respect

## Design System

### 1. Visual Language

The Ultimate app implements a premium, modern design language inspired by visionOS principles, featuring:

#### Glass Morphism
- Translucent, frosted-glass backgrounds
- Subtle backdrop blur effects
- Light border highlights
- Depth through layering

#### Color System
- **Primary Palette**: 
  - Primary action: Deep purple (#5E17EB)
  - Secondary action: Teal (#00C7BE)
  - Background: Dark navy (#141E30)
- **Semantic Colors**:
  - Success: Green (#34C759)
  - Warning: Orange (#FF9500)
  - Error: Red (#FF3B30)
  - Info: Blue (#007AFF)
- **Dynamic Light/Dark adaptations**
- **Accessibility contrast ratios**

#### Typography System
- **Font Family**: SF Pro and SF Pro Display
- **Type Scale**:
  - Extra large title: 34pt, bold
  - Large title: 28pt, bold
  - Title 1: 22pt, bold
  - Title 2: 20pt, semibold
  - Headline: 17pt, semibold
  - Body: 17pt, regular
  - Callout: 16pt, regular
  - Subheadline: 15pt, regular
  - Footnote: 13pt, regular
  - Caption 1: 12pt, regular
  - Caption 2: 11pt, regular
- **Dynamic Type support** for accessibility

#### Spacing System
- **Base Units**:
  - xs: 4pt
  - s: 8pt
  - m: 16pt
  - l: 24pt
  - xl: 32pt
  - xxl: 48pt
- **Contextual Spacing**:
  - Item spacing: 8pt
  - Group spacing: 16pt
  - Section spacing: 24pt
  - Screen padding: 16pt
  - Card padding: 16pt
- **Adaptive scaling** based on device size

### 2. Component Library

#### Buttons
- **Primary Button**: Filled background, prominent
- **Secondary Button**: Outlined style
- **Tertiary Button**: Text-only style
- **Icon Button**: Circular button with icon

#### Cards
- **Standard Card**: Rounded corners, drop shadow
- **Glass Card**: Translucent background with blur
- **Task Card**: Specialized for task display
- **Progress Card**: Includes progress indicators

#### Navigation
- **Tab Bar**: Custom floating design
- **Navigation Bar**: Translucent with blur effect
- **Modal Presentation**: Custom transitions

#### Progress Indicators
- **Progress Ring**: Circular progress indicator
- **Progress Bar**: Linear progress indicator
- **Streak Counter**: Visual display of streaks
- **Charts**: Various chart types for analytics

### 3. Animation & Motion

#### Transitions
- **Page Transitions**: Smooth, spatial transitions between screens
- **Card Animations**: Spring-based reveal and dismiss
- **List Animations**: Staggered animations for list items

#### Micro-interactions
- **Button Feedback**: Scale and opacity changes
- **Toggle States**: Smooth state transitions
- **Loading States**: Custom loading animations
- **Success/Error States**: Visual feedback animations

#### Gesture-driven Interactions
- **Swipe-to-complete**: Quick task completion
- **Long-press**: Contextual actions
- **Pinch-to-zoom**: Photo manipulation
- **Drag-to-reorder**: List reordering

## User Flows

### 1. Onboarding Flow

```
┌────────────┐     ┌────────────┐     ┌────────────┐     ┌────────────┐
│            │     │            │     │            │     │            │
│  Welcome   ├────►│ User Info  ├────►│Notification├────►│  Feature   │
│   Screen   │     │ Collection │     │ Permission │     │ Highlights │
│            │     │            │     │            │     │            │
└────────────┘     └────────────┘     └────────────┘     └────────────┘
                                                                │
                                                                ▼
                                                         ┌────────────┐
                                                         │            │
                                                         │ Challenge  │
                                                         │ Selection  │
                                                         │            │
                                                         └────────────┘
```

### 2. Challenge Creation Flow

```
┌────────────┐     ┌────────────┐     ┌────────────┐     ┌────────────┐
│            │     │            │     │            │     │            │
│ Challenge  ├────►│ Challenge  ├────►│   Task     ├────►│ Notification│
│  Gallery   │     │   Type     │     │ Selection  │     │  Settings  │
│            │     │            │     │            │     │            │
└────────────┘     └────────────┘     └────────────┘     └────────────┘
                                                                │
                                                                ▼
                                                         ┌────────────┐
                                                         │            │
                                                         │ Challenge  │
                                                         │  Review    │
                                                         │            │
                                                         └────────────┘
```

### 3. Daily Task Completion Flow

```
┌────────────┐     ┌────────────┐     ┌────────────┐     ┌────────────┐
│            │     │            │     │            │     │            │
│  Today     ├────►│   Task     ├────►│  Task      ├────►│ Completion │
│   Tab      │     │  Details   │     │ Completion │     │ Celebration│
│            │     │            │     │ Interface  │     │            │
└────────────┘     └────────────┘     └────────────┘     └────────────┘
                                                                │
                                                                ▼
                                                         ┌────────────┐
                                                         │            │
                                                         │  Updated   │
                                                         │  Progress  │
                                                         │            │
                                                         └────────────┘
```

### 4. Progress Photo Flow

```
┌────────────┐     ┌────────────┐     ┌────────────┐     ┌────────────┐
│            │     │            │     │            │     │            │
│   Photos   ├────►│   Photo    ├────►│   Camera   ├────►│   Review   │
│    Tab     │     │  Session   │     │  Interface │     │    & Save  │
│            │     │            │     │            │     │            │
└────────────┘     └────────────┘     └────────────┘     └────────────┘
                                                                │
                                                                ▼
                                                         ┌────────────┐
                                                         │            │
                                                         │   Photo    │
                                                         │  Gallery   │
                                                         │            │
                                                         └────────────┘
```

## Core Models

### Challenge (`Core/Models/Challenge.swift`)
- **Properties**:
  - `id: UUID` - Unique identifier
  - `name: String` - Challenge name
  - `type: ChallengeType` - Type of challenge (75Hard, WaterFasting, etc.)
  - `status: ChallengeStatus` - Current status (inProgress, completed, failed)
  - `startDate: Date?` - When the challenge started
  - `endDate: Date?` - Target completion date
  - `durationInDays: Int` - Total days for the challenge
  - `tasks: [Task]` - Associated tasks
  - `progressPhotos: [ProgressPhoto]` - Photos documenting progress
  - `imageName: String?` - Name of the image for the challenge
- **Computed Properties**:
  - `progress: Double` - Completion percentage (0.0-1.0)
  - `currentDay: Int` - Current day in the challenge
  - `daysRemaining: Int` - Days left in the challenge
  - `completedDays: Int` - Days already completed
- **Methods**:
  - `startChallenge()` - Begins the challenge
  - `completeChallenge()` - Marks the challenge as completed
  - `failChallenge()` - Marks the challenge as failed

### Task (`Core/Models/Task.swift`)
- **Properties**:
  - `id: UUID` - Unique identifier
  - `name: String` - Task name
  - `taskDescription: String` - Description of the task
  - `type: TaskType` - Type of task (workout, nutrition, etc.)
  - `frequency: TaskFrequency` - How often the task repeats
  - `measurementType: TaskMeasurementType` - How the task is measured
  - `timeOfDayMinutes: Int?` - Time of day in minutes from midnight
  - `targetQuantity: Double?` - Target quantity for quantity-based tasks
  - `quantityUnit: String?` - Unit for quantity
  - `targetDurationMinutes: Int?` - Target duration for duration-based tasks
  - `checklistItems: [ChecklistItem]` - Items for checklist-based tasks
  - `challenge: Challenge?` - Associated challenge
- **Computed Properties**:
  - `timeOfDay: DateComponents?` - Formatted time of day
  - `completionPercentage: Double` - Progress towards completion

### DailyTask (`Core/Models/DailyTask.swift`)
- **Properties**:
  - `id: UUID` - Unique identifier
  - `title: String` - Task title
  - `date: Date` - Date for this instance
  - `isCompleted: Bool` - Whether the task is completed
  - `status: TaskCompletionStatus` - Status (notStarted, inProgress, completed, missed, failed)
  - `task: Task?` - Associated task
  - `challenge: Challenge?` - Associated challenge
  - `notes: String?` - Notes for this daily task
  - `actualValue: Double?` - Actual value achieved
  - `completedQuantity: Double?` - Quantity completed
  - `completedDurationMinutes: Int?` - Duration completed
  - `completedChecklistItems: [ChecklistItem]` - Completed checklist items
- **Methods**:
  - `complete(actualValue:notes:)` - Marks task as completed
  - `completeWithQuantity(_ quantity: Double, notes:)` - Completes with quantity
  - `completeWithDuration(_ minutes: Int, notes:)` - Completes with duration
  - `updateChecklistItemCompletion(itemId:isCompleted:)` - Updates checklist item
  - `markInProgress(notes:)` - Marks task as in progress
  - `markMissed(notes:)` - Marks task as missed
  - `markFailed(notes:)` - Marks task as failed
  - `reset()` - Resets task to not started

### User (`Core/Models/User.swift`)
- **Properties**:
  - `id: UUID` - Unique identifier
  - `name: String` - User's name
  - `email: String?` - User's email
  - `profileImageURL: URL?` - Profile image location
  - `heightCm: Double?` - Height in centimeters
  - `weightKg: Double?` - Weight in kilograms
  - `notificationPreferences: NotificationPreferences` - Notification settings
  - `unitPreferences: UnitPreferences` - Preferred units
  - `appearancePreference: String` - Theme preference
  - `hasCompletedOnboarding: Bool` - Onboarding status
- **Methods**:
  - `updateProfile(name:email:...)` - Updates profile information
  - `updateNotificationPreferences(_:)` - Updates notification settings
  - `completeOnboarding()` - Marks onboarding as complete

### ProgressPhoto (`Core/Models/ProgressPhoto.swift`)
- **Properties**:
  - `id: UUID` - Unique identifier
  - `challenge: Challenge?` - Associated challenge
  - `date: Date` - When the photo was taken
  - `angle: PhotoAngle` - Angle of the photo (front, side, back)
  - `fileURL: URL` - File location
  - `isBlurred: Bool` - Whether the photo is blurred
  - `notes: String?` - Optional notes
  - `session: PhotoSession?` - Associated photo session
- **Methods**:
  - `blurPhoto()` - Applies blurring for privacy
  - `unblurPhoto()` - Removes blurring

## Services

### NotificationManager (`Core/Services/NotificationManager.swift`)
Manages all notification scheduling, handling, and user preferences.

### DataMigrationService (`Core/Services/DataMigrationService.swift`)
Handles database schema migrations and data transfers between app versions.

### PhotoQualityService (`Core/Services/PhotoQualityService.swift`)
Processes and optimizes photos for storage and display.

### ProgressAnalyticsService (`Core/Services/ProgressAnalyticsService.swift`)
Calculates metrics and generates visualization data for progress tracking.

### TaskHistoryService (`Core/Services/TaskHistoryService.swift`)
Manages historical task data and provides access to past completion records.

### TaskTemplateService (`Core/Services/TaskTemplateService.swift`)
Provides predefined task templates for common challenge types.

## Testing Strategy

### Unit Tests
- Model validation and business logic
- Service layer functionality
- ViewModel transformation logic

### UI Tests
- Critical user flows
- Accessibility compliance
- UI component rendering

### Integration Tests
- Data persistence and retrieval
- Notification scheduling and handling
- Photo capture and storage

## Development Guidelines

### Code Style
- Follow Swift API Design Guidelines
- Use clear, descriptive naming
- Document public APIs with documentation comments
- Use meaningful commit messages

### Performance Considerations
- Optimize image loading and processing
- Use lazy loading for list views
- Implement efficient notification handling
- Follow memory management best practices

### Accessibility
- Support Dynamic Type for text scaling
- Ensure proper VoiceOver support
- Maintain sufficient color contrast
- Provide alternative text for images

### Security
- Securely store sensitive user data
- Implement proper error handling
- Validate user input
- Protect photo data

## Future Enhancements

### Planned Features
- Social sharing capabilities
- Cloud sync across devices
- Advanced analytics and insights
- Gamification elements
- AI-powered recommendations
- Custom workout features
- Goal setting framework
- Advanced tracking with device integration

### Technical Improvements
- Performance optimizations
- Enhanced SwiftData implementation
- Improved image handling
- Better notification management
- More comprehensive testing 