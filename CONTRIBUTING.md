# Contributing to Ultimate

First off, thank you for considering contributing to Ultimate! It's people like you that make Ultimate such a great tool for building life-changing habits.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [How Can I Contribute?](#how-can-i-contribute)
4. [Development Setup](#development-setup)
5. [Pull Request Process](#pull-request-process)
6. [Style Guidelines](#style-guidelines)
7. [Commit Guidelines](#commit-guidelines)
8. [Testing Guidelines](#testing-guidelines)
9. [Documentation Guidelines](#documentation-guidelines)
10. [Community](#community)

---

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

---

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Xcode 15.0 or later**
- **iOS 17.0+ SDK**
- **Swift 5.9 or later**
- **macOS 14.0 (Sonoma) or later**
- **Git** installed and configured

### Fork and Clone

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Ultimate.git
   cd Ultimate
   ```
3. **Add the upstream repository**:
   ```bash
   git remote add upstream https://github.com/sanchaygumber/Ultimate.git
   ```

### Build the Project

1. Open `Ultimate.xcodeproj` in Xcode
2. Select your target device or simulator
3. Update the Development Team in project settings:
   - Select the Ultimate target
   - Go to "Signing & Capabilities"
   - Change "Team" to your Apple Developer account
4. Build and run (⌘R)

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/sanchaygumber/Ultimate/issues) to avoid duplicates.

When creating a bug report, include:

- **Clear and descriptive title**
- **Detailed steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Screenshots** (if applicable)
- **Environment details**:
  - iOS version
  - Device model
  - App version
  - Xcode version (for build issues)

**Template:**
```markdown
## Bug Description
A clear description of what the bug is.

## Steps to Reproduce
1. Go to '...'
2. Tap on '...'
3. Scroll down to '...'
4. See error

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Screenshots
If applicable, add screenshots.

## Environment
- iOS Version: 17.2
- Device: iPhone 14 Pro
- App Version: 1.0.0
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear and descriptive title**
- **Detailed description** of the proposed feature
- **Use case**: Why is this enhancement useful?
- **Mockups or examples** (if applicable)
- **Alternatives considered**

**Template:**
```markdown
## Feature Description
A clear description of the feature.

## Use Case
Who would benefit and why?

## Proposed Solution
How should this feature work?

## Alternatives Considered
What other approaches did you consider?

## Additional Context
Any other relevant information.
```

### Good First Issues

Looking for a place to start? Check out issues labeled:
- `good first issue` - Great for newcomers
- `help wanted` - We need community help
- `documentation` - Improve our docs
- `bug` - Fix existing issues

---

## Development Setup

### Project Structure

```
Ultimate/
├── Features/          # Feature-based organization
├── Core/              # Core business logic
│   ├── Models/        # Data models
│   ├── Services/      # Business services
│   └── Data/          # Data layer
├── UI/                # Reusable UI components
└── Tests/             # Unit and UI tests
```

### Key Technologies

- **SwiftUI**: UI framework
- **SwiftData**: Data persistence
- **HealthKit**: Fitness integration
- **UserNotifications**: Notification system
- **Combine**: Reactive programming

### Architecture

Ultimate follows MVVM (Model-View-ViewModel) architecture. Read [`ARCHITECTURE.md`](ARCHITECTURE.md) for detailed information.

### Branch Strategy

- **`main`**: Production-ready code
- **`develop`**: Integration branch for features
- **`feature/*`**: New features
- **`bugfix/*`**: Bug fixes
- **`hotfix/*`**: Urgent production fixes
- **`docs/*`**: Documentation updates

### Workflow

1. Create a new branch from `develop`:
   ```bash
   git checkout develop
   git pull upstream develop
   git checkout -b feature/your-feature-name
   ```

2. Make your changes

3. Commit following our [commit guidelines](#commit-guidelines)

4. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

5. Create a Pull Request to `develop` branch

---

## Pull Request Process

### Before Submitting

- [ ] Code compiles without errors
- [ ] All tests pass
- [ ] New tests added for new features
- [ ] Code follows style guidelines
- [ ] Documentation updated (if needed)
- [ ] No linter warnings
- [ ] Screenshots included (for UI changes)

### PR Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issue
Closes #(issue number)

## Changes Made
- Change 1
- Change 2
- Change 3

## Screenshots
(if applicable)

## Testing
- [ ] Unit tests pass
- [ ] UI tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added to complex code
- [ ] Documentation updated
- [ ] No new warnings
```

### Review Process

1. **Automated Checks**: CI/CD will run tests
2. **Code Review**: Maintainer will review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, your PR will be merged
5. **Credit**: You'll be added to contributors

---

## Style Guidelines

### Swift Code Style

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

#### Key Points

**Naming:**
```swift
// Good
func calculateConsistencyScore() -> Int
var currentStreak: Int
let dailyTasks: [DailyTask]

// Bad
func calc() -> Int
var streak: Int
let tasks: [DailyTask]
```

**Spacing:**
```swift
// Good
if condition {
    doSomething()
} else {
    doSomethingElse()
}

// Bad
if condition{
    doSomething()
}else{
    doSomethingElse()
}
```

**Constants:**
```swift
// Good
enum Constants {
    static let maxChallenges = 10
    static let defaultDuration = 30
}

// Bad
let MAX_CHALLENGES = 10
var defaultDuration = 30
```

**Comments:**
```swift
// Good
/// Calculates the consistency score based on task completion history
/// - Parameter days: Number of days to analyze
/// - Returns: Consistency score from 0-100
func calculateConsistencyScore(days: Int) -> Int {
    // Implementation
}

// Bad
// calculate score
func calcScore(_ d: Int) -> Int {
    // stuff
}
```

### SwiftUI Views

```swift
// Good structure
struct MyView: View {
    // MARK: - Properties
    @State private var isLoading = false
    
    // MARK: - Body
    var body: some View {
        content
    }
    
    // MARK: - Subviews
    private var content: some View {
        VStack {
            // ...
        }
    }
}
```

### Use MARK Comments

```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Body
// MARK: - Subviews
// MARK: - Methods
// MARK: - Helper Functions
```

---

## Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/).

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples

```bash
# Feature
feat(challenges): add 31 Modified challenge template

# Bug fix
fix(photos): resolve photo save issue on iOS 17

# Documentation
docs(readme): update installation instructions

# Refactor
refactor(services): improve notification scheduling logic

# Test
test(analytics): add unit tests for consistency score

# Multiple lines
feat(tracking): add duration-based task tracking

- Add duration measurement type
- Update DailyTask model
- Create duration input UI
- Add tests

Closes #42
```

### Commit Message Rules

- Use present tense ("add feature" not "added feature")
- Use imperative mood ("move cursor to..." not "moves cursor to...")
- Limit first line to 72 characters
- Reference issues and PRs when relevant
- Explain **what** and **why**, not **how**

---

## Testing Guidelines

### Unit Tests

Write unit tests for:
- Model methods
- Service logic
- Utility functions
- Computed properties

**Location**: `UltimateTests/`

**Example**:
```swift
@testable import Ultimate
import XCTest

final class ChallengeTests: XCTestCase {
    func testChallengeProgressCalculation() {
        // Given
        let challenge = Challenge(/* ... */)
        
        // When
        let progress = challenge.progress
        
        // Then
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }
}
```

### UI Tests

Write UI tests for:
- Critical user flows
- Navigation
- Form validation
- Error handling

**Location**: `UltimateUITests/`

### Test Requirements

- All new features must include tests
- Maintain >80% code coverage
- Tests must be deterministic
- Tests should be fast (<1s each)

### Running Tests

```bash
# Run all tests
⌘U in Xcode

# Run specific test
⌘U on specific test method

# Command line
xcodebuild test -scheme Ultimate -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## Documentation Guidelines

### Code Documentation

Use Swift documentation format:

```swift
/// Brief description of the function
///
/// More detailed explanation if needed. Can span
/// multiple lines.
///
/// - Parameters:
///   - param1: Description of param1
///   - param2: Description of param2
/// - Returns: Description of return value
/// - Throws: Description of errors that can be thrown
func myFunction(param1: String, param2: Int) throws -> Bool {
    // Implementation
}
```

### README Updates

When adding features:
- Update feature list in README
- Add screenshots (if UI feature)
- Update installation instructions (if needed)

### Documentation Files

- **ARCHITECTURE.md**: Technical architecture details
- **FEATURES.md**: Feature documentation with code references
- **CONTRIBUTING.md**: This file
- **API.md**: API documentation (future)

---

## Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General discussions and questions
- **Pull Requests**: Code contributions and reviews

### Getting Help

- Check existing documentation
- Search closed issues
- Ask in GitHub Discussions
- Tag maintainers for urgent issues

### Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in the app (future feature)

---

## Development Tips

### Debugging

```swift
// Use Logger utility
Logger.info("User started challenge", category: .challenges)
Logger.error("Failed to save photo", category: .photos)
```

### Testing on Device

For features requiring:
- HealthKit: Test on physical device
- Camera: Test on physical device
- Notifications: Test in various states

### Performance

- Use Instruments to profile
- Test with large data sets
- Monitor memory usage
- Check battery impact

---

## Questions?

- **Found a bug?** [Open an issue](https://github.com/sanchaygumber/Ultimate/issues/new)
- **Have a question?** [Start a discussion](https://github.com/sanchaygumber/Ultimate/discussions)
- **Want to chat?** Comment on relevant issues

---

## Attribution

By contributing to Ultimate, you agree that your contributions will be licensed under the Apache-2.0 license.

Please ensure you have the right to contribute the code/documentation and that your contributions do not violate any third-party rights.

---

## Thank You!

Your contributions make Ultimate better for everyone. Whether it's fixing a typo, adding a feature, or helping others in discussions - every contribution matters.

Happy coding! 🚀

---

**Last Updated:** January 2025  
**Maintainer:** Sanchay Gumber  
**License:** Apache-2.0

