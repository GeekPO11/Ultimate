# Ultimate App - Project Documentation

## Project Overview
Ultimate is an iOS app for habit tracking and challenge management. It allows users to create and manage challenges, track daily tasks, view progress, and capture photos related to their challenges.

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
│   │   └── User.swift
│   └── Services/
│       ├── NotificationManager.swift
│       └── DataManager.swift
├── UI/
│   ├── Components/
│   │   ├── CTButton.swift
│   │   ├── CTCard.swift
│   │   ├── CTProgressChart.swift
│   │   └── CTProgressRing.swift
│   └── DesignSystem/
│       ├── Colors.swift
│       └── Typography.swift
└── UltimateApp.swift
```

## Recent Improvements

### UI Design
- Implemented a futuristic Glass UI design across the app for a modern, premium feel
- Enhanced visual hierarchy with consistent spacing, typography, and color schemes
- Added subtle animations and transitions for a more engaging user experience
- Improved card components with glass-like effects, gradients, and shadows

### Progress Tracking
- Enhanced the progress tracking logic to provide more accurate analysis of task completion
- Improved integration between task data and visualization components
- Added comprehensive analytics for challenges with detailed metrics
- Implemented consistency scoring based on completion rate, streak, and regularity

### Charts and Visualizations
- Redesigned all charts with a futuristic aesthetic that aligns with the app's UI
- Enhanced CTProgressChart component with:
  - Gradient fills and animations
  - Improved readability and visual appeal
  - Better responsiveness to different data sets
  - Support for multiple chart types (bar, line, area, pie, progress)
- Removed unnecessary legends from charts where they don't add value
- Added contextual information to make data more meaningful

### Challenge Analytics
- Completely redesigned the ChallengeAnalyticsView with the Glass UI design
- Improved chart quality and removed redundant legends
- Added more detailed statistics and metrics for better insights
- Enhanced the visual presentation of streak information and consistency scores

### Challenge Detail View
- Fixed sizing issues to ensure proper display across all devices
- Improved layout with better spacing and visual hierarchy
- Enhanced the progress visualization with gradient-filled progress bars
- Added more detailed statistics and a direct link to analytics

## Core Features

### Challenge Management
Users can create, edit, and manage challenges with customizable:
- Duration (start and end dates)
- Task types and frequencies
- Progress tracking metrics

### Daily Task Tracking
- Daily view of tasks that need to be completed
- Task completion tracking with status updates
- Streak tracking for consistent task completion

### Progress Analytics
- Visual representations of progress over time
- Detailed analytics for each challenge
- Consistency scoring and performance metrics

### Photo Capture
- Ability to capture and store photos related to challenges
- Photo gallery view for reviewing progress visually
- Photo detail view with metadata and notes

## Technical Implementation

### SwiftData Integration
- Uses SwiftData for persistent storage of challenges, tasks, and photos
- Implements proper relationships between models
- Handles data migrations and schema updates

### Notification System
- Local notifications for task reminders
- Customizable notification settings
- Background scheduling of notifications

### Design System
- Consistent color palette and typography
- Reusable UI components
- Accessibility considerations

## Future Enhancements
- Social sharing capabilities
- Cloud sync across devices
- Advanced analytics and insights
- Gamification elements
- AI-powered recommendations

## Development Guidelines
- Follow Swift style guide and naming conventions
- Use SwiftUI best practices for view composition
- Implement proper error handling and logging
- Write unit tests for core functionality
- Document public APIs and complex logic

## Data Models

### Challenge (`Core/Models/Challenge.swift`)
- **Properties**:
  - `id: UUID` - Unique identifier
  - `name: String` - Challenge name
  - `type: ChallengeType` - Type of challenge (fitness, nutrition, etc.)
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
- **Relationships**:
  - One-to-many with Task
  - One-to-many with ProgressPhoto

### Task (`Core/Models/Task.swift`)
- **Properties**:
  - `id: UUID` - Unique identifier
  - `name: String` - Task name
  - `taskDescription: String` - Description of the task
  - `type: TaskType` - Type of task
  - `frequency: TaskFrequency` - How often the task repeats
  - `timeOfDayMinutes: Int?` - Time of day in minutes from midnight
  - `durationMinutes: Int?` - Duration in minutes
  - `targetValue: Double?` - Target value (e.g., pages to read)
  - `targetUnit: String?` - Unit for target value
  - `scheduledTime: Date?` - When the task should be performed
  - `challenge: Challenge?` - Associated challenge
  - `isCompleted: Bool` - Whether the task is completed
- **Relationships**:
  - Many-to-one with Challenge
  - One-to-many with DailyTask

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
  - `completionTime: Date?` - When the task was completed
- **Methods**:
  - `complete(actualValue:notes:)` - Marks task as completed
  - `markInProgress(notes:)` - Marks task as in progress
  - `markMissed(notes:)` - Marks task as missed
  - `markFailed(notes:)` - Marks task as failed
  - `reset()` - Resets task to not started
- **Relationships**:
  - Many-to-one with Task
  - Many-to-one with Challenge

### ProgressPhoto (`Core/Models/ProgressPhoto.swift`)
- **Properties**:
  - `id: UUID` - Unique identifier
  - `challenge: Challenge?` - Associated challenge
  - `date: Date` - When the photo was taken
  - `angle: PhotoAngle` - Angle of the photo (front, leftSide, rightSide, back)
  - `fileURL: URL` - File location
  - `notes: String?` - Optional notes
  - `isBlurred: Bool` - Whether the photo is blurred for privacy
  - `createdAt: Date` - Creation date
  - `updatedAt: Date` - Last update date
- **Relationships**:
  - Many-to-one with Challenge

### PhotoAngle (enum in `Core/Models/ProgressPhoto.swift`)
- **Cases**:
  - `front` - Front view
  - `leftSide` - Left side view
  - `rightSide` - Right side view
  - `back` - Back view
- **Properties**:
  - `description: String` - Human-readable description
  - `icon: String` - System icon name (updated to use more appropriate figure-based icons)

### ProgressPhotoService (class in `Core/Models/ProgressPhoto.swift`)
- **Key Methods**:
  - `savePhoto(image:challengeId:angle:) -> URL?` - Saves a photo to the app's storage
  - `loadPhoto(from:) -> UIImage?` - Loads a photo from storage
  - `deletePhoto(at:) -> Bool` - Deletes a photo from storage
  - `blurPhoto(image:radius:) -> UIImage?` - Applies a blur effect for privacy
  - `savePhotoToLibrary(image:completion:)` - Saves a photo to the user's photo library

## Feature Modules

### Challenges Module

#### ChallengesView (`Features/Challenges/ChallengesView.swift`)
- **Purpose**: Main view for managing challenges
- **Key State Variables**:
  - `@Query private var challenges: [Challenge]` - All challenges
  - `@State private var activeChallenges: [Challenge]` - Currently active challenges
  - `@State private var showingAddChallenge: Bool` - Controls new challenge sheet
  - `@State private var selectedCategory: ChallengeCategory` - Selected category filter
- **Key Methods**:
  - `stopChallenge(name: String, type: ChallengeType)` - Stops a challenge by name and type
  - `isChallengeActive(name: String, type: ChallengeType) -> Bool` - Checks if a challenge is active
  - `createChallenge(...)` - Creates a new challenge
  - `filterChallenges()` - Filters challenges based on status and category
- **UI Sections**:
  - Active challenges section
  - Upcoming challenges section
  - Completed challenges section
  - Challenge selection view
  - Empty state view

#### ChallengeDetailView (`Features/Challenges/ChallengeDetailView.swift`)
- **Purpose**: Shows details for a specific challenge
- **Key Parameters**:
  - `challenge: Challenge` - The challenge to display
- **UI Sections**:
  - Custom navigation bar with challenge name and done button
  - Challenge info header with progress ring
  - Tab-based interface (Overview, Tasks, Analytics)
  - Task cards with icons and descriptions
- **Recent Changes**:
  - Updated to use custom navigation bar instead of standard navigation
  - Applied glass design to match app's visual style
  - Improved tab selector with better visual feedback
  - Enhanced layout with proper spacing and padding

#### ChallengeDetailSheet (`Features/Challenges/ChallengesView.swift`)
- **Purpose**: Shows details for a challenge before starting it
- **Key Parameters**:
  - `challenge: Challenge` - The challenge to display
  - `onStart: () -> Void` - Callback when starting the challenge
- **UI Sections**:
  - Challenge header
  - Challenge description
  - Daily tasks
  - Benefits
  - Action button
- **Recent Changes**:
  - Updated navigation bar to use "Done" button instead of "Cancel" for consistency
  - Improved presentation with overlay instead of sheet for better reliability

### Daily Tasks Module

#### TodayView (`Features/DailyTasks/TodayView.swift`)
- **Purpose**: Shows and manages tasks for the current day
- **Key State Variables**:
  - `@Query private var allChallenges: [Challenge]` - All challenges
  - `@Query private var allDailyTasks: [DailyTask]` - All daily tasks
  - `@State private var activeSheet: SheetType?` - Controls which sheet is shown
  - `@State private var tasksManager: DailyTasksManager?` - Manager for daily tasks
- **Key Computed Properties**:
  - `dailyTasks: [DailyTask]` - Tasks for today
  - `sortedDailyTasks: [DailyTask]` - Sorted tasks for today
  - `activeChallenges: [Challenge]` - Currently active challenges
- **Key Methods**:
  - `completeTask(dailyTask:)` - Marks a task as completed
  - `missTask(dailyTask:)` - Marks a task as missed
  - `resetTask(dailyTask:)` - Resets a task to pending
- **UI Sections**:
  - Header with date and greeting
  - Daily progress summary
  - Active challenges section
  - Today's tasks section
  - Empty state view

#### TaskDetailView (`Features/DailyTasks/TodayView.swift`)
- **Purpose**: Shows details for a specific daily task
- **Key Parameters**:
  - `task: DailyTask` - The task to display
  - `tasksManager: DailyTasksManager?` - Manager for daily tasks
- **Key State Variables**:
  - `@State private var notes: String` - Notes for the task
  - `@State private var actualValue: String` - Actual value achieved
  - `@State private var selectedStatus: TaskCompletionStatus?` - Selected status
- **Key Methods**:
  - `saveNotes()` - Saves notes to the task
  - `updateTaskStatus()` - Updates the task status
- **UI Sections**:
  - Task header
  - Task details
  - Task status
  - Notes section
  - Action buttons

#### DailyTasksManager (`Features/DailyTasks/DailyTasksManager.swift`)
- **Purpose**: Manages the creation and updating of daily tasks
- **Key Methods**:
  - `createDailyTasksIfNeeded()` - Creates daily tasks for active challenges
  - `createDailyTask(for:on:)` - Creates a daily task for a specific task and date
  - `completeTask(_:actualValue:notes:)` - Marks a task as completed
  - `markTaskInProgress(_:notes:)` - Marks a task as in progress
  - `markTaskMissed(_:notes:)` - Marks a task as missed
  - `markTaskFailed(_:notes:)` - Marks a task as failed
  - `resetTask(_:)` - Resets a task to not started
  - `updateChallengeProgress(for:)` - Updates challenge progress

### Notification System

#### NotificationManager (`Core/Services/NotificationManager.swift`)
- **Purpose**: Manages app notifications with intelligent scheduling based on challenge and task types
- **Key Properties**:
  - `@Published var isAuthorized: Bool` - Whether notifications are authorized
- **Key Methods**:
  - `requestAuthorization()` - Requests notification permission from the user
  - `scheduleNotificationsForChallenge(_ challenge: Challenge)` - Schedules notifications for a challenge
  - `removeNotificationsForChallenge(_ challenge: Challenge)` - Removes notifications for a challenge
- **Challenge-Specific Notification Logic**:
  - **75 Hard Challenge**:
    - Morning workout reminder at 6:00 AM
    - Evening workout reminder at 5:00 PM
    - Water reminders every 2 hours from 8 AM to 8 PM
    - Reading reminder at 9:00 PM
    - Progress photo reminder at 8:00 AM
  - **Water Fasting Challenge**:
    - Hydration reminders every hour from 8 AM to 8 PM
    - Fasting milestone notifications at key intervals (12h, 16h, 20h, 24h, 36h, 48h, 60h, 72h)
    - Weight tracking reminder at 7:00 AM
  - **Habit Builder Challenge**:
    - Morning habit reminder at 7:30 AM
    - Midday check-in at 12:30 PM
    - Evening habit reminder at 7:00 PM
    - Daily reflection reminder at 9:00 PM
  - **Custom Challenges**:
    - Notifications scheduled based on task types and scheduled times
- **Task-Specific Notification Logic**:
  - **Workout Tasks**: Scheduled at task's time or defaults to 6 AM/5 PM
  - **Water Tasks**: Reminders every 2 hours from 8 AM to 8 PM
  - **Reading Tasks**: Evening reminder at 9:00 PM
  - **Nutrition Tasks**: Meal reminders at 7 AM (breakfast), 12 PM (lunch), 6 PM (dinner)
  - **Fasting Tasks**: Start and end reminders based on fasting window
  - **Habit Tasks**: Morning (7:30 AM), midday (12:30 PM), and evening (7:00 PM) reminders
  - **Weight Tasks**: Morning reminder at 7:00 AM
  - **Photo Tasks**: Morning reminder at 8:00 AM
  - **Meditation Tasks**: Morning reminder at 7:00 AM or at scheduled time
  - **Sleep Tasks**: Bedtime reminder at 10:00 PM
  - **Custom Tasks**: Scheduled at task's time or defaults to noon

### Progress Module

#### ProgressTrackingView (`Features/Progress/ProgressTrackingView.swift`)
- **Purpose**: Shows progress for active challenges
- **Key State Variables**:
  - `@Query(sort: \Challenge.startDate) private var challenges: [Challenge]` - All challenges
  - `@Query(sort: \DailyTask.date) private var dailyTasks: [DailyTask]` - All daily tasks
  - `@State private var selectedTimeFrame: TimeFrame` - Selected time frame
- **Key Computed Properties**:
  - `activeChallenge: Challenge?` - Returns the first active challenge
- **Key Methods**:
  - `getCurrentStreak() -> Int` - Calculates current streak
  - `getBestStreak() -> Int` - Calculates best streak historically
  - `getTrendData() -> [ProgressDataPoint]` - Generates trend chart data
  - `getChartData() -> [(date: Date, completed: Int, missed: Int)]` - Generates task completion data
  - `getTaskCompletionStats(for: Challenge) -> (completed: Int, total: Int, completionRate: Double)` - Gets task completion stats
- **UI Components**:
  - Time frame selector
  - Challenge progress summary
  - Overall progress summary
  - Task completion chart
  - Trend chart
  - Streak tracking card

### Photos Module

#### PhotosView (`Features/Photos/PhotosView.swift`)
- **Purpose**: Shows and manages progress photos
- **Key State Variables**:
  - `@Query private var photos: [ProgressPhoto]` - All progress photos
  - `@State private var selectedChallenge: Challenge?` - Selected challenge for filtering
  - `@State private var selectedAngle: PhotoAngle = .front` - Selected photo angle
  - `@State private var showingPhotoSessionSheet = false` - Controls photo session sheet
- **Key Methods**:
  - `hasPhotoForToday(angle: PhotoAngle) -> Bool` - Checks if there's a photo for today for a specific angle
  - `savePhoto(image: UIImage)` - Saves a photo to the database (updated to fix duplication issue)
- **UI Components**:
  - Challenge selector
  - Photo capture section
  - Photo gallery
  - Comparison tools section
- **Recent Changes**:
  - Fixed photo duplication issue by improving duplicate detection logic
  - Updated to replace existing photos for the same day and angle instead of creating duplicates

#### PhotoSessionView (`Features/Photos/PhotoSessionView.swift`)
- **Purpose**: Guides the user through capturing photos from all 4 angles
- **Key State Variables**:
  - `@State private var currentAngleIndex = 0` - Current angle being captured
  - `@State private var capturedImages: [PhotoAngle: UIImage] = [:]` - Captured images for each angle
  - `@State private var showingCameraView = false` - Controls camera view
  - `@State private var showingPhotoLibrary = false` - Controls photo library picker
- **Key Methods**:
  - `getInstructionsForAngle(_ angle: PhotoAngle) -> String` - Gets instructions for a specific angle
  - `saveAllPhotos()` - Saves all captured photos to the database
- **UI Components**:
  - Progress indicator
  - Angle instructions
  - Image preview
  - Capture buttons
  - Navigation buttons
- **Important Implementation Details**:
  - Creates a binding for `currentAngle` to pass to `CameraView` and `PhotoPicker`
  - Uses a sheet to present `CameraView` and `PhotoPicker`

#### CameraView (`Features/Photos/CameraView.swift`)
- **Purpose**: Custom camera interface for taking progress photos
- **Key Parameters**:
  - `selectedChallenge: Challenge?` - Challenge to associate with the photo
  - `selectedAngle: Binding<PhotoAngle>` - Angle being captured
  - `onPhotoTaken: (UIImage) -> Void` - Callback when a photo is taken
- **Key State Variables**:
  - `@StateObject private var cameraController = CameraController()` - Controller for camera operations
  - `@State private var showingCameraPermissionAlert = false` - Controls camera permission alert
  - `@State private var showingCountdown = false` - Controls countdown timer
  - `@State private var countdown = 3` - Countdown value
  - `@State private var flashMode: AVCaptureDevice.FlashMode = .off` - Flash mode
  - `@State private var isFrontCamera = false` - Whether front camera is active
  - `@State private var cameraInitialized = false` - Whether camera is initialized
- **Key Methods**:
  - `toggleFlash()` - Toggles flash mode
  - `startCountdown()` - Starts countdown timer
  - `capturePhoto()` - Captures a photo
  - `silhouetteShape(for:in:) -> some Shape` - Creates silhouette shape for positioning
- **UI Components**:
  - Camera preview
  - Silhouette overlay
  - Camera controls (close, flash, capture, timer, switch camera)
  - Angle indicator
- **Important Implementation Details**:
  - Uses `AVFoundation` for camera access
  - Initializes camera in `onAppear`
  - Handles camera permissions
  - Provides visual guidance with silhouette overlay

#### CameraController (class in `Features/Photos/CameraView.swift`)
- **Purpose**: Manages camera operations
- **Key Properties**:
  - `captureSession: AVCaptureSession` - Session for capturing photos
  - `previewLayer: AVCaptureVideoPreviewLayer` - Layer for displaying camera preview
- **Key Methods**:
  - `checkAuthorization(completion:)` - Checks camera authorization
  - `setupCaptureSession()` - Sets up the capture session
  - `switchCamera()` - Switches between front and back camera
  - `setFlashMode(_:)` - Sets the flash mode
  - `capturePhoto(completion:)` - Captures a photo
- **Important Implementation Details**:
  - Initializes camera session on background thread
  - Handles camera device selection
  - Configures photo output
  - Implements `AVCapturePhotoCaptureDelegate` for photo capture

#### PhotoPicker (`Features/Photos/PhotoPicker.swift`)
- **Purpose**: Interface for selecting photos from the photo library
- **Key Parameters**:
  - `selectedChallenge: Challenge?` - Challenge to associate with the photo
  - `selectedAngle: Binding<PhotoAngle>` - Angle being captured
  - `onPhotoSelected: (UIImage) -> Void` - Callback when a photo is selected
- **Key State Variables**:
  - `@State private var selectedItem: PhotosPickerItem?` - Selected photo item
  - `@State private var selectedImage: UIImage?` - Selected image
- **Key Methods**:
  - `loadTransferable(from:)` - Loads the selected image
- **UI Components**:
  - Angle selector
  - Photo picker
  - Selected image preview
  - Action buttons

#### PhotoDetailView (`Features/Photos/PhotoDetailView.swift`)
- **Purpose**: Detailed view for a single photo
- **Key Parameters**:
  - `photo: ProgressPhoto` - The photo to display
  - `photoService: ProgressPhotoService` - Service for photo operations
- **Key State Variables**:
  - `@State private var image: UIImage?` - The loaded image
  - `@State private var isBlurred: Bool` - Whether the image is blurred
  - `@State private var notes: String` - Notes for the photo
- **Key Methods**:
  - `loadImage()` - Loads the photo image
  - `saveChanges()` - Saves changes to the photo
  - `deletePhoto()` - Deletes the photo
- **UI Components**:
  - Photo display
  - Metadata display (date, angle, challenge)
  - Notes editor
  - Privacy toggle
  - Action buttons (share, delete)
- **Important Implementation Details**:
  - Initializes state from photo properties
  - Saves changes in `saveChanges()` method
  - Called when "Save" button is tapped or when dismissing the view

## UI Components

### CTButton (`UI/Components/CTButton.swift`)
- **Purpose**: Reusable button component with customizable appearance
- **Key Parameters**:
  - `title: String` - Button title
  - `icon: String?` - Optional icon name
  - `style: CTButtonStyle` - Button style
  - `size: CTButtonSize` - Button size
  - `action: () -> Void` - Callback when button is tapped
- **Styles**:
  - `.primary` - Primary action button
  - `.secondary` - Secondary action button
  - `.tertiary` - Tertiary action button
  - `.success` - Success action button
  - `.danger` - Danger action button
  - `.glass` - Glass-style button
  - `.regularMaterial`, `.thinMaterial`, `.ultraThinMaterial` - Material-style buttons
- **Recent Changes**:
  - Updated all button styles to use a glass design with appropriate opacity
  - Applied ultraThinMaterial background to all buttons for consistent glass effect

### CTChallengeCard (`UI/Components/CTCard.swift`)
- **Purpose**: Card component for displaying challenge information
- **Key Parameters**:
  - `title: String` - Challenge title
  - `description: String` - Challenge description
  - `progress: Double` - Challenge progress
  - `image: String?` - Optional image name
  - `style: CTCardStyle` - Card style
  - `onTap: () -> Void` - Callback when card is tapped
- **UI Components**:
  - Header with image (if available)
  - Title and description
  - Progress indicator
- **Important Implementation Details**:
  - Uses `CTCard` as base component
  - Displays progress differently based on whether image is present

### CTProgressChart (`UI/Components/CTProgressChart.swift`)
- **Purpose**: Custom chart component for visualizing progress
- **Key Parameters**:
  - `data: [ProgressDataPoint]` - Data points for the chart
  - `chartType: ChartType` - Type of chart to display
  - `title: String` - Chart title
  - `subtitle: String?` - Optional subtitle
  - `showLegend: Bool` - Whether to show the legend
- **Chart Types**:
  - `.bar` - Bar chart for daily values
  - `.line` - Line chart for trends
  - `.area` - Area chart for cumulative data
  - `.pie` - Pie chart for category distribution
  - `.progress` - Circular progress indicator
- **Color Implementation**:
  - Uses `DesignSystem.Colors` for consistent app-wide theming
  - Implements dynamic gradients based on chart type and data values
  - Supports both light and dark mode with appropriate color adjustments
  - Uses neon accent colors for highlighting important data points
- **Recent Changes**:
  - Replaced hardcoded colors with DesignSystem color references
  - Enhanced visual appeal with futuristic glass UI design
  - Improved gradient implementations for better data visualization
  - Optimized for consistency with the app's overall design language

### MainTabView (`App/MainTabView.swift`)
- **Purpose**: Main tab view for the app
- **Tabs**:
  - Today - Shows daily tasks and active challenges
  - Challenges - Shows and manages challenges
  - Progress - Shows progress tracking
  - Photos - Shows and manages progress photos
  - Settings - Shows app settings
- **Recent Changes**:
  - Updated tab bar to use glass design with blur effect
  - Customized tab bar appearance for normal and selected states
  - Applied consistent design language across the app

## Settings and Logging

### SettingsView (`Features/Settings/SettingsView.swift`)
- **Purpose**: Shows app settings
- **Sections**:
  - Profile - User profile information
  - Appearance - App appearance settings
  - Notifications - Notification settings
  - Logging - Log viewing and detailed logging toggle
  - About - App information and privacy policy
- **Recent Changes**:
  - Added Logging section with View Logs link and Detailed Logging toggle
  - Applied glass design to all settings sections

### LogViewerView (`Features/Settings/SettingsView.swift`)
- **Purpose**: Shows app logs
- **Features**:
  - Filtering logs by category and level
  - Searching logs
  - Sharing logs
- **Recent Changes**:
  - Applied glass design to log viewer
  - Enhanced visual hierarchy with styled section headers

## Photo Angle Icons

### PhotoAngle Icons (`Core/Models/ProgressPhoto.swift`)
- **Purpose**: Icons for different photo angles
- **Icons**:
  - Front: "figure.stand" - Standing figure icon
  - Left Side: "figure.walk.motion" - Walking figure in motion
  - Right Side: "figure.walk" - Walking figure
  - Back: "figure.stand.line.dotted.figure.stand" - Two figures standing
- **Recent Changes**:
  - Updated icons to use more appropriate figure-based icons instead of generic person icons

## Recent Changes

### UI Improvements
- Applied glass design to all buttons for consistent appearance
- Updated tab bar to use glass design with blur effect
- Fixed cancel button in challenge detail sheet
- Updated photo angle icons to be more appropriate
- Added logging section to settings view
- Improved ChallengeDetailView with custom navigation bar and consistent styling
- Enhanced challenge detail presentation with overlay approach for better reliability
- Updated chart components with futuristic glass UI design that aligns with app theme
- Improved progress visualization with theme-consistent color gradients
- Enhanced ChallengeAnalyticsView with app theme colors for better visual consistency
- Optimized CTProgressChart component to use DesignSystem colors instead of hardcoded values

### Notification System
- Implemented intelligent notification scheduling based on challenge and task types
- Created challenge-specific notification patterns for different challenge types
- Added task-specific notification timing based on task type and scheduled time
- Implemented milestone notifications for fasting challenges
- Added support for both repeating daily notifications and one-time event notifications

### Bug Fixes
- Fixed photo duplication issue by improving duplicate detection
- Fixed settings display issues
- Resolved challenge detail loading issues with improved presentation approach

### Documentation Updates
- Updated PROJECT_DOCUMENTATION.md with recent changes
- Added information about glass UI design
- Added details about photo angle icons
- Added information about tab bar styling
- Added comprehensive documentation of the notification system

#### ChallengeAnalyticsView (`Features/Challenges/ChallengeAnalyticsView.swift`)
- **Purpose**: Provides detailed analytics and insights for a specific challenge
- **Key Parameters**:
  - `challenge: Challenge` - The challenge to analyze
- **UI Sections**:
  - Challenge summary with completion percentage
  - Consistency score with visual indicator
  - Daily task completion chart
  - Streak information
  - Detailed statistics
- **Key Features**:
  - Dynamic consistency score calculation based on task completion
  - Visual representation of daily task completion patterns
  - Streak tracking with current and best streak display
  - Detailed statistics on task completion rates
- **Color Implementation**:
  - Uses `DesignSystem.Colors` for consistent theming
  - Implements dynamic gradients for consistency score visualization:
    - Low scores (< 40%): Accent to neonOrange gradient
    - Medium scores (40-70%): neonOrange to neonGreen gradient
    - High scores (≥ 70%): neonGreen to primaryAction gradient
- **Recent Changes**:
  - Replaced hardcoded colors with DesignSystem color references
  - Enhanced visual appeal with futuristic glass UI design
  - Removed unnecessary legends for cleaner visualization
  - Improved gradient implementations for better data representation

## Core Features

### Challenge Management
Users can create, edit, and manage challenges with customizable:
- Duration (start and end dates)
- Task types and frequencies
- Progress tracking metrics

### Daily Task Tracking
- Daily view of tasks that need to be completed
- Task completion tracking with status updates
- Streak tracking for consistent task completion

### Progress Analytics
- Visual representations of progress over time
- Detailed analytics for each challenge
- Consistency scoring and performance metrics

### Photo Capture
- Ability to capture and store photos related to challenges
- Photo gallery view for reviewing progress visually
- Photo detail view with metadata and notes

## Technical Implementation

### SwiftData Integration
- Uses SwiftData for persistent storage of challenges, tasks, and photos
- Implements proper relationships between models
- Handles data migrations and schema updates

### Notification System
- Local notifications for task reminders
- Customizable notification settings
- Background scheduling of notifications

### Design System
- Consistent color palette and typography
- Reusable UI components
- Accessibility considerations

## Future Enhancements
- Social sharing capabilities
- Cloud sync across devices
- Advanced analytics and insights
- Gamification elements
- AI-powered recommendations

## Development Guidelines
- Follow Swift style guide and naming conventions
- Use SwiftUI best practices for view composition
- Implement proper error handling and logging
- Write unit tests for core functionality
- Document public APIs and complex logic

## Data Models

### Challenge (`Core/Models/Challenge.swift`)
- **Properties**:
  - `id: UUID` - Unique identifier
  - `name: String` - Challenge name
  - `type: ChallengeType` - Type of challenge (fitness, nutrition, etc.)
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
- **Relationships**:
  - One-to-many with Task
  - One-to-many with ProgressPhoto

### Task (`Core/Models/Task.swift`)
- **Properties**:
  - `id: UUID` - Unique identifier
  - `name: String` - Task name
  - `taskDescription: String` - Description of the task
  - `type: TaskType` - Type of task
  - `frequency: TaskFrequency` - How often the task repeats
  - `timeOfDayMinutes: Int?` - Time of day in minutes from midnight
  - `durationMinutes: Int?` - Duration in minutes
  - `targetValue: Double?` - Target value (e.g., pages to read)
  - `targetUnit: String?` - Unit for target value
  - `scheduledTime: Date?` - When the task should be performed
  - `challenge: Challenge?` - Associated challenge
  - `isCompleted: Bool` - Whether the task is completed
- **Relationships**:
  - Many-to-one with Challenge
  - One-to-many with DailyTask

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
  - `completionTime: Date?` - When the task was completed
- **Methods**:
  - `complete(actualValue:notes:)` - Marks task as completed
  - `markInProgress(notes:)` - Marks task as in progress
  - `markMissed(notes:)` - Marks task as missed
  - `markFailed(notes:)` - Marks task as failed
  - `reset()` - Resets task to not started
- **Relationships**:
  - Many-to-one with Task
  - Many-to-one with Challenge

### ProgressPhoto (`Core/Models/ProgressPhoto.swift`)
- **Properties**:
  - `id: UUID` - Unique identifier
  - `challenge: Challenge?` - Associated challenge
  - `date: Date` - When the photo was taken
  - `angle: PhotoAngle` - Angle of the photo (front, leftSide, rightSide, back)
  - `fileURL: URL` - File location
  - `notes: String?` - Optional notes
  - `isBlurred: Bool` - Whether the photo is blurred for privacy
  - `createdAt: Date` - Creation date
  - `updatedAt: Date` - Last update date
- **Relationships**:
  - Many-to-one with Challenge

### PhotoAngle (enum in `Core/Models/ProgressPhoto.swift`)
- **Cases**:
  - `front` - Front view
  - `leftSide` - Left side view
  - `rightSide` - Right side view
  - `back` - Back view
- **Properties**:
  - `description: String` - Human-readable description
  - `icon: String` - System icon name (updated to use more appropriate figure-based icons)

### ProgressPhotoService (class in `Core/Models/ProgressPhoto.swift`)
- **Key Methods**:
  - `savePhoto(image:challengeId:angle:) -> URL?` - Saves a photo to the app's storage
  - `loadPhoto(from:) -> UIImage?` - Loads a photo from storage
  - `deletePhoto(at:) -> Bool` - Deletes a photo from storage
  - `blurPhoto(image:radius:) -> UIImage?` - Applies a blur effect for privacy
  - `savePhotoToLibrary(image:completion:)` - Saves a photo to the user's photo library

## Feature Modules

### Challenges Module

#### ChallengesView (`Features/Challenges/ChallengesView.swift`)
- **Purpose**: Main view for managing challenges
- **Key State Variables**:
  - `@Query private var challenges: [Challenge]` - All challenges
  - `@State private var activeChallenges: [Challenge]` - Currently active challenges
  - `@State private var showingAddChallenge: Bool` - Controls new challenge sheet
  - `@State private var selectedCategory: ChallengeCategory` - Selected category filter
- **Key Methods**:
  - `stopChallenge(name: String, type: ChallengeType)` - Stops a challenge by name and type
  - `isChallengeActive(name: String, type: ChallengeType) -> Bool` - Checks if a challenge is active
  - `createChallenge(...)` - Creates a new challenge
  - `filterChallenges()` - Filters challenges based on status and category
- **UI Sections**:
  - Active challenges section
  - Upcoming challenges section
  - Completed challenges section
  - Challenge selection view
  - Empty state view

#### ChallengeDetailView (`Features/Challenges/ChallengeDetailView.swift`)
- **Purpose**: Shows details for a specific challenge
- **Key Parameters**:
  - `challenge: Challenge` - The challenge to display
- **UI Sections**:
  - Custom navigation bar with challenge name and done button
  - Challenge info header with progress ring
  - Tab-based interface (Overview, Tasks, Analytics)
  - Task cards with icons and descriptions
- **Recent Changes**:
  - Updated to use custom navigation bar instead of standard navigation
  - Applied glass design to match app's visual style
  - Improved tab selector with better visual feedback
  - Enhanced layout with proper spacing and padding

#### ChallengeDetailSheet (`Features/Challenges/ChallengesView.swift`)
- **Purpose**: Shows details for a challenge before starting it
- **Key Parameters**:
  - `challenge: Challenge` - The challenge to display
  - `onStart: () -> Void` - Callback when starting the challenge
- **UI Sections**:
  - Challenge header
  - Challenge description
  - Daily tasks
  - Benefits
  - Action button
- **Recent Changes**:
  - Updated navigation bar to use "Done" button instead of "Cancel" for consistency
  - Improved presentation with overlay instead of sheet for better reliability

### Daily Tasks Module

#### TodayView (`Features/DailyTasks/TodayView.swift`)
- **Purpose**: Shows and manages tasks for the current day
- **Key State Variables**:
  - `@Query private var allChallenges: [Challenge]` - All challenges
  - `@Query private var allDailyTasks: [DailyTask]` - All daily tasks
  - `@State private var activeSheet: SheetType?` - Controls which sheet is shown
  - `@State private var tasksManager: DailyTasksManager?` - Manager for daily tasks
- **Key Computed Properties**:
  - `dailyTasks: [DailyTask]` - Tasks for today
  - `sortedDailyTasks: [DailyTask]` - Sorted tasks for today
  - `activeChallenges: [Challenge]` - Currently active challenges
- **Key Methods**:
  - `completeTask(dailyTask:)` - Marks a task as completed
  - `missTask(dailyTask:)` - Marks a task as missed
  - `resetTask(dailyTask:)` - Resets a task to pending
- **UI Sections**:
  - Header with date and greeting
  - Daily progress summary
  - Active challenges section
  - Today's tasks section
  - Empty state view

#### TaskDetailView (`Features/DailyTasks/TodayView.swift`)
- **Purpose**: Shows details for a specific daily task
- **Key Parameters**:
  - `task: DailyTask` - The task to display
  - `tasksManager: DailyTasksManager?` - Manager for daily tasks
- **Key State Variables**:
  - `@State private var notes: String` - Notes for the task
  - `@State private var actualValue: String` - Actual value achieved
  - `@State private var selectedStatus: TaskCompletionStatus?` - Selected status
- **Key Methods**:
  - `saveNotes()` - Saves notes to the task
  - `updateTaskStatus()` - Updates the task status
- **UI Sections**:
  - Task header
  - Task details
  - Task status
  - Notes section
  - Action buttons

#### DailyTasksManager (`Features/DailyTasks/DailyTasksManager.swift`)
- **Purpose**: Manages the creation and updating of daily tasks
- **Key Methods**:
  - `createDailyTasksIfNeeded()` - Creates daily tasks for active challenges
  - `createDailyTask(for:on:)` - Creates a daily task for a specific task and date
  - `completeTask(_:actualValue:notes:)` - Marks a task as completed
  - `markTaskInProgress(_:notes:)` - Marks a task as in progress
  - `markTaskMissed(_:notes:)` - Marks a task as missed
  - `markTaskFailed(_:notes:)` - Marks a task as failed
  - `resetTask(_:)` - Resets a task to not started
  - `updateChallengeProgress(for:)` - Updates challenge progress

### Notification System

#### NotificationManager (`Core/Services/NotificationManager.swift`)
- **Purpose**: Manages app notifications with intelligent scheduling based on challenge and task types
- **Key Properties**:
  - `@Published var isAuthorized: Bool` - Whether notifications are authorized
- **Key Methods**:
  - `requestAuthorization()` - Requests notification permission from the user
  - `scheduleNotificationsForChallenge(_ challenge: Challenge)` - Schedules notifications for a challenge
  - `removeNotificationsForChallenge(_ challenge: Challenge)` - Removes notifications for a challenge
- **Challenge-Specific Notification Logic**:
  - **75 Hard Challenge**:
    - Morning workout reminder at 6:00 AM
    - Evening workout reminder at 5:00 PM
    - Water reminders every 2 hours from 8 AM to 8 PM
    - Reading reminder at 9:00 PM
    - Progress photo reminder at 8:00 AM
  - **Water Fasting Challenge**:
    - Hydration reminders every hour from 8 AM to 8 PM
    - Fasting milestone notifications at key intervals (12h, 16h, 20h, 24h, 36h, 48h, 60h, 72h)
    - Weight tracking reminder at 7:00 AM
  - **Habit Builder Challenge**:
    - Morning habit reminder at 7:30 AM
    - Midday check-in at 12:30 PM
    - Evening habit reminder at 7:00 PM
    - Daily reflection reminder at 9:00 PM
  - **Custom Challenges**:
    - Notifications scheduled based on task types and scheduled times
- **Task-Specific Notification Logic**:
  - **Workout Tasks**: Scheduled at task's time or defaults to 6 AM/5 PM
  - **Water Tasks**: Reminders every 2 hours from 8 AM to 8 PM
  - **Reading Tasks**: Evening reminder at 9:00 PM
  - **Nutrition Tasks**: Meal reminders at 7 AM (breakfast), 12 PM (lunch), 6 PM (dinner)
  - **Fasting Tasks**: Start and end reminders based on fasting window
  - **Habit Tasks**: Morning (7:30 AM), midday (12:30 PM), and evening (7:00 PM) reminders
  - **Weight Tasks**: Morning reminder at 7:00 AM
  - **Photo Tasks**: Morning reminder at 8:00 AM
  - **Meditation Tasks**: Morning reminder at 7:00 AM or at scheduled time
  - **Sleep Tasks**: Bedtime reminder at 10:00 PM
  - **Custom Tasks**: Scheduled at task's time or defaults to noon

### Progress Module

#### ProgressTrackingView (`Features/Progress/ProgressTrackingView.swift`)
- **Purpose**: Shows progress for active challenges
- **Key State Variables**:
  - `@Query(sort: \Challenge.startDate) private var challenges: [Challenge]` - All challenges
  - `@Query(sort: \DailyTask.date) private var dailyTasks: [DailyTask]` - All daily tasks
  - `@State private var selectedTimeFrame: TimeFrame` - Selected time frame
- **Key Computed Properties**:
  - `activeChallenge: Challenge?` - Returns the first active challenge
- **Key Methods**:
  - `getCurrentStreak() -> Int` - Calculates current streak
  - `getBestStreak() -> Int` - Calculates best streak historically
  - `getTrendData() -> [ProgressDataPoint]` - Generates trend chart data
  - `getChartData() -> [(date: Date, completed: Int, missed: Int)]` - Generates task completion data
  - `getTaskCompletionStats(for: Challenge) -> (completed: Int, total: Int, completionRate: Double)` - Gets task completion stats
- **UI Components**:
  - Time frame selector
  - Challenge progress summary
  - Overall progress summary
  - Task completion chart
  - Trend chart
  - Streak tracking card

### Photos Module

#### PhotosView (`Features/Photos/PhotosView.swift`)
- **Purpose**: Shows and manages progress photos
- **Key State Variables**:
  - `@Query private var photos: [ProgressPhoto]` - All progress photos
  - `@State private var selectedChallenge: Challenge?` - Selected challenge for filtering
  - `@State private var selectedAngle: PhotoAngle = .front` - Selected photo angle
  - `@State private var showingPhotoSessionSheet = false` - Controls photo session sheet
- **Key Methods**:
  - `hasPhotoForToday(angle: PhotoAngle) -> Bool` - Checks if there's a photo for today for a specific angle
  - `savePhoto(image: UIImage)` - Saves a photo to the database (updated to fix duplication issue)
- **UI Components**:
  - Challenge selector
  - Photo capture section
  - Photo gallery
  - Comparison tools section
- **Recent Changes**:
  - Fixed photo duplication issue by improving duplicate detection logic
  - Updated to replace existing photos for the same day and angle instead of creating duplicates

#### PhotoSessionView (`Features/Photos/PhotoSessionView.swift`)
- **Purpose**: Guides the user through capturing photos from all 4 angles
- **Key State Variables**:
  - `@State private var currentAngleIndex = 0` - Current angle being captured
  - `@State private var capturedImages: [PhotoAngle: UIImage] = [:]` - Captured images for each angle
  - `@State private var showingCameraView = false` - Controls camera view
  - `@State private var showingPhotoLibrary = false` - Controls photo library picker
- **Key Methods**:
  - `getInstructionsForAngle(_ angle: PhotoAngle) -> String` - Gets instructions for a specific angle
  - `saveAllPhotos()` - Saves all captured photos to the database
- **UI Components**:
  - Progress indicator
  - Angle instructions
  - Image preview
  - Capture buttons
  - Navigation buttons
- **Important Implementation Details**:
  - Creates a binding for `currentAngle` to pass to `CameraView` and `PhotoPicker`
  - Uses a sheet to present `CameraView` and `PhotoPicker`

#### CameraView (`Features/Photos/CameraView.swift`)
- **Purpose**: Custom camera interface for taking progress photos
- **Key Parameters**:
  - `selectedChallenge: Challenge?` - Challenge to associate with the photo
  - `selectedAngle: Binding<PhotoAngle>` - Angle being captured
  - `onPhotoTaken: (UIImage) -> Void` - Callback when a photo is taken
- **Key State Variables**:
  - `@StateObject private var cameraController = CameraController()` - Controller for camera operations
  - `@State private var showingCameraPermissionAlert = false` - Controls camera permission alert
  - `@State private var showingCountdown = false` - Controls countdown timer
  - `@State private var countdown = 3` - Countdown value
  - `@State private var flashMode: AVCaptureDevice.FlashMode = .off` - Flash mode
  - `@State private var isFrontCamera = false` - Whether front camera is active
  - `@State private var cameraInitialized = false` - Whether camera is initialized
- **Key Methods**:
  - `toggleFlash()` - Toggles flash mode
  - `startCountdown()` - Starts countdown timer
  - `capturePhoto()` - Captures a photo
  - `silhouetteShape(for:in:) -> some Shape` - Creates silhouette shape for positioning
- **UI Components**:
  - Camera preview
  - Silhouette overlay
  - Camera controls (close, flash, capture, timer, switch camera)
  - Angle indicator
- **Important Implementation Details**:
  - Uses `AVFoundation` for camera access
  - Initializes camera in `onAppear`
  - Handles camera permissions
  - Provides visual guidance with silhouette overlay

#### CameraController (class in `Features/Photos/CameraView.swift`)
- **Purpose**: Manages camera operations
- **Key Properties**:
  - `captureSession: AVCaptureSession` - Session for capturing photos
  - `previewLayer: AVCaptureVideoPreviewLayer` - Layer for displaying camera preview
- **Key Methods**:
  - `checkAuthorization(completion:)` - Checks camera authorization
  - `setupCaptureSession()` - Sets up the capture session
  - `switchCamera()` - Switches between front and back camera
  - `setFlashMode(_:)` - Sets the flash mode
  - `capturePhoto(completion:)` - Captures a photo
- **Important Implementation Details**:
  - Initializes camera session on background thread
  - Handles camera device selection
  - Configures photo output
  - Implements `AVCapturePhotoCaptureDelegate` for photo capture

#### PhotoPicker (`Features/Photos/PhotoPicker.swift`)
- **Purpose**: Interface for selecting photos from the photo library
- **Key Parameters**:
  - `selectedChallenge: Challenge?` - Challenge to associate with the photo
  - `selectedAngle: Binding<PhotoAngle>` - Angle being captured
  - `onPhotoSelected: (UIImage) -> Void` - Callback when a photo is selected
- **Key State Variables**:
  - `@State private var selectedItem: PhotosPickerItem?` - Selected photo item
  - `@State private var selectedImage: UIImage?` - Selected image
- **Key Methods**:
  - `loadTransferable(from:)` - Loads the selected image
- **UI Components**:
  - Angle selector
  - Photo picker
  - Selected image preview
  - Action buttons

#### PhotoDetailView (`Features/Photos/PhotoDetailView.swift`)
- **Purpose**: Detailed view for a single photo
- **Key Parameters**:
  - `photo: ProgressPhoto` - The photo to display
  - `photoService: ProgressPhotoService` - Service for photo operations
- **Key State Variables**:
  - `@State private var image: UIImage?` - The loaded image
  - `@State private var isBlurred: Bool` - Whether the image is blurred
  - `@State private var notes: String` - Notes for the photo
- **Key Methods**:
  - `loadImage()` - Loads the photo image
  - `saveChanges()` - Saves changes to the photo
  - `deletePhoto()` - Deletes the photo
- **UI Components**:
  - Photo display
  - Metadata display (date, angle, challenge)
  - Notes editor
  - Privacy toggle
  - Action buttons (share, delete)
- **Important Implementation Details**:
  - Initializes state from photo properties
  - Saves changes in `saveChanges()` method
  - Called when "Save" button is tapped or when dismissing the view

## UI Components

### CTButton (`UI/Components/CTButton.swift`)
- **Purpose**: Reusable button component with customizable appearance
- **Key Parameters**:
  - `title: String` - Button title
  - `icon: String?` - Optional icon name
  - `style: CTButtonStyle` - Button style
  - `size: CTButtonSize` - Button size
  - `action: () -> Void` - Callback when button is tapped
- **Styles**:
  - `.primary` - Primary action button
  - `.secondary` - Secondary action button
  - `.tertiary` - Tertiary action button
  - `.success` - Success action button
  - `.danger` - Danger action button
  - `.glass` - Glass-style button
  - `.regularMaterial`, `.thinMaterial`, `.ultraThinMaterial` - Material-style buttons
- **Recent Changes**:
  - Updated all button styles to use a glass design with appropriate opacity
  - Applied ultraThinMaterial background to all buttons for consistent glass effect

### CTChallengeCard (`UI/Components/CTCard.swift`)
- **Purpose**: Card component for displaying challenge information
- **Key Parameters**:
  - `title: String` - Challenge title
  - `description: String` - Challenge description
  - `progress: Double` - Challenge progress
  - `image: String?` - Optional image name
  - `style: CTCardStyle` - Card style
  - `onTap: () -> Void` - Callback when card is tapped
- **UI Components**:
  - Header with image (if available)
  - Title and description
  - Progress indicator
- **Important Implementation Details**:
  - Uses `CTCard` as base component
  - Displays progress differently based on whether image is present

### CTProgressChart (`UI/Components/CTProgressChart.swift`)
- **Purpose**: Custom chart component for visualizing progress
- **Key Parameters**:
  - `data: [ProgressDataPoint]` - Data points for the chart
  - `chartType: ChartType` - Type of chart to display
  - `title: String` - Chart title
  - `subtitle: String?` - Optional subtitle
  - `showLegend: Bool` - Whether to show the legend
- **Chart Types**:
  - `.bar` - Bar chart for daily values
  - `.line` - Line chart for trends
  - `.area` - Area chart for cumulative data
  - `.pie` - Pie chart for category distribution
  - `.progress` - Circular progress indicator
- **Color Implementation**:
  - Uses `DesignSystem.Colors` for consistent app-wide theming
  - Implements dynamic gradients based on chart type and data values
  - Supports both light and dark mode with appropriate color adjustments
  - Uses neon accent colors for highlighting important data points
- **Recent Changes**:
  - Replaced hardcoded colors with DesignSystem color references
  - Enhanced visual appeal with futuristic glass UI design
  - Improved gradient implementations for better data visualization
  - Optimized for consistency with the app's overall design language

### MainTabView (`App/MainTabView.swift`)
- **Purpose**: Main tab view for the app
- **Tabs**:
  - Today - Shows daily tasks and active challenges
  - Challenges - Shows and manages challenges
  - Progress - Shows progress tracking
  - Photos - Shows and manages progress photos
  - Settings - Shows app settings
- **Recent Changes**:
  - Updated tab bar to use glass design with blur effect
  - Customized tab bar appearance for normal and selected states
  - Applied consistent design language across the app

## Settings and Logging

### SettingsView (`Features/Settings/SettingsView.swift`)
- **Purpose**: Shows app settings
- **Sections**:
  - Profile - User profile information
  - Appearance - App appearance settings
  - Notifications - Notification settings
  - Logging - Log viewing and detailed logging toggle
  - About - App information and privacy policy
- **Recent Changes**:
  - Added Logging section with View Logs link and Detailed Logging toggle
  - Applied glass design to all settings sections

### LogViewerView (`Features/Settings/SettingsView.swift`)
- **Purpose**: Shows app logs
- **Features**:
  - Filtering logs by category and level
  - Searching logs
  - Sharing logs
- **Recent Changes**:
  - Applied glass design to log viewer
  - Enhanced visual hierarchy with styled section headers

## Photo Angle Icons

### PhotoAngle Icons (`Core/Models/ProgressPhoto.swift`)
- **Purpose**: Icons for different photo angles
- **Icons**:
  - Front: "figure.stand" - Standing figure icon
  - Left Side: "figure.walk.motion" - Walking figure in motion
  - Right Side: "figure.walk" - Walking figure
  - Back: "figure.stand.line.dotted.figure.stand" - Two figures standing
- **Recent Changes**:
  - Updated icons to use more appropriate figure-based icons instead of generic person icons

## Recent Changes

### UI Improvements
- Applied glass design to all buttons for consistent appearance
- Updated tab bar to use glass design with blur effect
- Fixed cancel button in challenge detail sheet
- Updated photo angle icons to be more appropriate
- Added logging section to settings view
- Improved ChallengeDetailView with custom navigation bar and consistent styling
- Enhanced challenge detail presentation with overlay approach for better reliability
- Updated chart components with futuristic glass UI design that aligns with app theme
- Improved progress visualization with theme-consistent color gradients
- Enhanced ChallengeAnalyticsView with app theme colors for better visual consistency
- Optimized CTProgressChart component to use DesignSystem colors instead of hardcoded values

### Notification System
- Implemented intelligent notification scheduling based on challenge and task types
- Created challenge-specific notification patterns for different challenge types
- Added task-specific notification timing based on task type and scheduled time
- Implemented milestone notifications for fasting challenges
- Added support for both repeating daily notifications and one-time event notifications

### Bug Fixes
- Fixed photo duplication issue by improving duplicate detection
- Fixed settings display issues
- Resolved challenge detail loading issues with improved presentation approach

### Documentation Updates
- Updated PROJECT_DOCUMENTATION.md with recent changes
- Added information about glass UI design
- Added details about photo angle icons
- Added information about tab bar styling
- Added comprehensive documentation of the notification system 