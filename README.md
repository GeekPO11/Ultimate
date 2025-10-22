# Ultimate: Premium Fitness & Habit Tracking App

<p align="center">
  <img src="Assets/app-icon.png" alt="Ultimate App Icon" width="200" height="200">
</p>

<p align="center">
  <strong>Transform your life through structured challenges and consistent habit tracking</strong>
</p>

<p align="center">
  <a href="https://github.com/sanchaygumber/Ultimate/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg" alt="License">
  </a>
  <a href="https://doi.org/10.6084/m9.figshare.30418693">
    <img src="https://img.shields.io/badge/DOI-10.6084%2Fm9.figshare.30418693-blue.svg" alt="DOI">
  </a>
  <a href="https://swift.org">
    <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift">
  </a>
  <a href="https://developer.apple.com/ios/">
    <img src="https://img.shields.io/badge/iOS-17.0+-success.svg" alt="iOS">
  </a>
  <a href="https://github.com/sanchaygumber/Ultimate/issues">
    <img src="https://img.shields.io/github/issues/sanchaygumber/Ultimate" alt="Issues">
  </a>
  <a href="https://github.com/sanchaygumber/Ultimate/stargazers">
    <img src="https://img.shields.io/github/stars/sanchaygumber/Ultimate" alt="Stars">
  </a>
  <a href="https://github.com/sanchaygumber/Ultimate/network/members">
    <img src="https://img.shields.io/github/forks/sanchaygumber/Ultimate" alt="Forks">
  </a>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

---

## 📖 About

**Ultimate** is a comprehensive, privacy-first iOS application designed to help users build life-changing habits through structured challenges, intelligent tracking, and beautiful visualizations. Built entirely with SwiftUI and SwiftData, Ultimate provides a modern, native iOS experience with a stunning visionOS-inspired interface.

### 🎯 Philosophy

> "Success is the product of daily habits—not once-in-a-lifetime transformations."

Ultimate embodies this philosophy by making habit formation:
- **Structured**: Pre-built challenge templates like 75 Hard
- **Flexible**: Support for any habit type with multiple measurement methods
- **Visual**: Beautiful progress charts and photo tracking
- **Private**: All data stays on your device
- **Intelligent**: HealthKit integration for automatic tracking

### 🏆 What Makes Ultimate Different

| Feature | Most Apps | Ultimate |
|---------|-----------|----------|
| **Data Privacy** | Cloud storage, accounts required | 100% on-device, no accounts |
| **Tracking Types** | Binary (done/not done) | Binary, Quantity, Duration, Checklist |
| **Photo Progress** | Third-party integration | Native, integrated photo tracking |
| **Challenges** | DIY setup | Pre-built templates + custom |
| **Design** | Standard iOS | visionOS-inspired glass morphism |
| **Fitness Integration** | Manual only | Automatic with HealthKit |
| **Cost** | Subscription or ads | Free & Open Source |

---

## ✨ Features

### 🏋️ Challenge Management
- **Pre-built Templates**
  - 75 Hard Challenge (5 tasks, 75 days, no exceptions)
  - Water Fasting (customizable fasting protocols)
  - 31 Modified (beginner-friendly habit building)
- **Custom Challenges**: Create any challenge with flexible parameters
- **Multiple Active Challenges**: Track several challenges simultaneously
- **Progress Tracking**: Real-time completion percentages and statistics

### 📋 Comprehensive Task Tracking
- **Binary Tracking**: Simple yes/no completion ✓
- **Quantity Tracking**: Measure with units (e.g., 8 glasses of water) 💧
- **Duration Tracking**: Time-based tasks (e.g., 45 minutes of reading) ⏱️
- **Checklist Tracking**: Multi-item tasks (e.g., morning routine) ☑️

### 📊 Advanced Analytics
- **Completion Rate**: Overall and per-challenge statistics
- **Consistency Score**: Intelligent scoring algorithm (0-100)
- **Streak Tracking**: Current streak, longest streak, total days
- **Visual Charts**: Bar charts, line charts, area charts
- **Time Periods**: Last 7 days, 30 days, or all time
- **Task Breakdown**: Analysis by task type and frequency

### 📸 Progress Photo Tracking
- **Multiple Angles**: Front, side, back views
- **Photo Sessions**: Guided capture process
- **Timeline View**: Chronological photo gallery
- **Comparison Tools**: Side-by-side before/after
- **Privacy Features**: Optional blurring, local storage only
- **Native Camera**: Integrated camera with grid overlay

### 🔔 Smart Notifications
- **Task Reminders**: Customizable notification times
- **Morning Summary**: Daily task overview
- **Evening Reminders**: Complete remaining tasks
- **Actionable Notifications**: Mark complete from notification
- **Quiet Hours**: Do not disturb periods
- **Streak Milestones**: Celebrate achievements

### 💪 HealthKit Integration
- **Automatic Workout Detection**: Auto-complete workout tasks
- **Exercise Minutes**: Track daily and weekly totals
- **Background Monitoring**: Works when app is closed
- **Privacy Respected**: Optional, read-only access
- **Multiple Workout Types**: All workout types supported

### 🎨 Beautiful Design
- **visionOS-Inspired**: Modern glass morphism aesthetic
- **Smooth Animations**: Spring-based, natural animations
- **Dark Mode**: Optimized for light and dark appearance
- **Dynamic Type**: Full accessibility support
- **Custom Components**: Professional UI component library

---

## 📱 Screenshots

<p align="center">
  <img src="Assets/screenshots/challenges-view.png" alt="Challenges View" width="200">
  <img src="Assets/screenshots/today-view.png" alt="Today View" width="200">
  <img src="Assets/screenshots/progress-view.png" alt="Progress Analytics" width="200">
  <img src="Assets/screenshots/photos-view.png" alt="Photo Tracking" width="200">
</p>

> **Note**: Screenshots will be added as the project develops

---

## 🚀 Installation

### Requirements

- **Xcode**: 15.0 or later
- **iOS**: 17.0 or later
- **Swift**: 5.9 or later
- **macOS**: 14.0 (Sonoma) or later

### Option 1: Clone and Build

```bash
# Clone the repository
git clone https://github.com/sanchaygumber/Ultimate.git
cd Ultimate

# Open in Xcode
open Ultimate.xcodeproj

# Build and run
# Press ⌘R or click the Run button
```

### Option 2: Download Release

1. Go to [Releases](https://github.com/sanchaygumber/Ultimate/releases)
2. Download the latest release
3. Open in Xcode
4. Build for your device

### Configuration

Before building, you'll need to:

1. **Update Development Team**:
   - Select the Ultimate target
   - Go to "Signing & Capabilities"
   - Change "Team" to your Apple Developer account

2. **Update Bundle Identifier** (optional):
   - Change `SaGu.Ultimate` to your own identifier
   - Example: `com.yourname.Ultimate`

3. **Build and Run**:
   - Select your target device or simulator
   - Press ⌘R to build and run

---

## 📚 Documentation

### Comprehensive Guides

- **[Architecture](ARCHITECTURE.md)** - Technical architecture and design patterns
- **[Product Vision](PRODUCT_VISION.md)** - Product strategy and roadmap
- **[Features](FEATURES.md)** - Detailed feature documentation with code references
- **[Contributing](CONTRIBUTING.md)** - How to contribute to the project
- **[Code of Conduct](CODE_OF_CONDUCT.md)** - Community guidelines
- **[Security](SECURITY.md)** - Security policies and vulnerability reporting

### Quick Links

- [Project Structure](#project-structure)
- [Technology Stack](#technology-stack)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Deployment](#deployment)

---

## 🏗️ Project Structure

```
Ultimate/
├── Features/                    # Feature-based organization
│   ├── Challenges/             # Challenge management
│   ├── DailyTasks/             # Task tracking
│   ├── Photos/                 # Progress photo tracking
│   ├── Progress/               # Analytics and statistics
│   ├── Settings/               # App settings
│   └── Notifications/          # Notification management
├── Core/                       # Core business logic
│   ├── Models/                 # SwiftData models
│   │   ├── Challenge.swift
│   │   ├── Task.swift
│   │   ├── DailyTask.swift
│   │   ├── User.swift
│   │   └── ProgressPhoto.swift
│   ├── Services/               # Business logic services
│   │   ├── ChallengeService.swift
│   │   ├── DailyTaskManager.swift
│   │   ├── NotificationManager.swift
│   │   └── HealthKitService.swift
│   └── Utilities/              # Helper utilities
├── UI/                         # Reusable UI components
│   ├── Components/             # Custom components
│   ├── Modifiers/              # View modifiers
│   └── Styles/                 # Design system
├── Tests/                      # Unit and integration tests
└── UltimateApp.swift           # App entry point
```

---

## 🛠️ Technology Stack

### Core Technologies

- **[SwiftUI](https://developer.apple.com/xcode/swiftui/)**: Modern declarative UI framework
- **[SwiftData](https://developer.apple.com/xcode/swiftdata/)**: Apple's persistence framework
- **[HealthKit](https://developer.apple.com/healthkit/)**: Fitness and health data integration
- **[UserNotifications](https://developer.apple.com/documentation/usernotifications)**: Local notifications
- **[Combine](https://developer.apple.com/documentation/combine)**: Reactive programming
- **[PhotoKit](https://developer.apple.com/documentation/photokit)**: Photo library access
- **[AVFoundation](https://developer.apple.com/av-foundation/)**: Camera capture

### Architecture

- **Pattern**: MVVM (Model-View-ViewModel)
- **Data Flow**: Unidirectional data flow
- **Dependency Management**: Swift Package Manager (no external dependencies)
- **Testing**: XCTest framework

---

## 🧪 Testing

### Run Tests

```bash
# Run all tests
xcodebuild test -scheme Ultimate -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Or in Xcode: ⌘U
```

### Test Coverage

- **Unit Tests**: ~80% coverage
- **Integration Tests**: ~60% coverage
- **UI Tests**: ~40% coverage

### Test Files

```
Tests/
├── UltimateTests/
│   ├── ChallengeAnalyticsTests.swift
│   ├── NotificationManagerTests.swift
│   └── DataLayerIntegrationTests.swift
└── UltimateUITests/
    ├── UltimateUITests.swift
    └── GlassMorphismUITests.swift
```

---

## 🤝 Contributing

We welcome contributions! Whether it's:
- 🐛 **Bug fixes**
- ✨ **New features**
- 📝 **Documentation improvements**
- 🧪 **Tests**
- 💡 **Ideas and suggestions**

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Commit your changes** (`git commit -m 'feat: add amazing feature'`)
5. **Push to the branch** (`git push origin feature/amazing-feature`)
6. **Open a Pull Request**

Read our [Contributing Guide](CONTRIBUTING.md) for detailed information.

### Good First Issues

Looking to contribute but not sure where to start? Check out issues labeled:
- [`good first issue`](https://github.com/sanchaygumber/Ultimate/labels/good%20first%20issue)
- [`help wanted`](https://github.com/sanchaygumber/Ultimate/labels/help%20wanted)
- [`documentation`](https://github.com/sanchaygumber/Ultimate/labels/documentation)

---

## 🗺️ Roadmap

### Version 1.1 (Q2 2025)
- [ ] Widget extensions (Home Screen, Lock Screen)
- [ ] Siri Shortcuts integration
- [ ] Enhanced photo editing tools
- [ ] Export progress reports (PDF)
- [ ] iPad optimization

### Version 2.0 (Q3 2025)
- [ ] CloudKit sync (optional)
- [ ] Family sharing
- [ ] Challenge templates marketplace
- [ ] Advanced analytics with ML insights

### Version 3.0 (Q4 2025)
- [ ] watchOS companion app
- [ ] Mac Catalyst version
- [ ] API for third-party integrations
- [ ] Community challenges

See [PRODUCT_VISION.md](PRODUCT_VISION.md) for detailed roadmap.

---

## 📊 Project Stats

![GitHub code size](https://img.shields.io/github/languages/code-size/sanchaygumber/Ultimate)
![Lines of code](https://img.shields.io/tokei/lines/github/sanchaygumber/Ultimate)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/sanchaygumber/Ultimate)
![GitHub last commit](https://img.shields.io/github/last-commit/sanchaygumber/Ultimate)

**Lines of Code**: ~9,500  
**Files**: ~80  
**Languages**: Swift 100%  
**Tests**: ~1,500 lines

---

## 🙏 Acknowledgments

### Inspiration

- **75 Hard Challenge** by Andy Frisella - Inspiration for structured challenges
- **Apple visionOS** - Design language inspiration
- **Atomic Habits** by James Clear - Habit formation principles

### Open Source Community

Special thanks to the open-source community for tools, libraries, and inspiration that made this project possible.

---

## 📄 License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

```
Copyright 2025 Sanchay Gumber

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

### Why Apache 2.0?

- ✅ **Free to use**: Use in personal or commercial projects
- ✅ **Modify freely**: Change and adapt as needed
- ✅ **Patent grant**: Express patent license
- ✅ **Attribution required**: Credit the original author
- ✅ **Open source friendly**: Compatible with most licenses

---

## 📞 Contact & Support

### Get Help

- **📖 Documentation**: Check our [comprehensive docs](ARCHITECTURE.md)
- **🐛 Bug Reports**: [Open an issue](https://github.com/sanchaygumber/Ultimate/issues/new)
- **💡 Feature Requests**: [Start a discussion](https://github.com/sanchaygumber/Ultimate/discussions)
- **❓ Questions**: [GitHub Discussions](https://github.com/sanchaygumber/Ultimate/discussions)

### Stay Updated

- ⭐ **Star this repo** to show support
- 👁️ **Watch** for updates and releases
- 🍴 **Fork** to contribute
- 📢 **Share** with friends and colleagues

---

## 🎯 Citation

If you use Ultimate in your research or project, please cite:

```bibtex
@software{Ultimate_2025,
  author = {Gumber, Sanchay},
  title = {Ultimate: Premium Fitness & Habit Tracking App},
  year = {2025},
  url = {https://github.com/sanchaygumber/Ultimate},
  license = {Apache-2.0}
}
```

Or use the [CITATION.cff](CITATION.cff) file for automatic citation generation.

---

## 💝 Support the Project

Ultimate is free and open source. If you find it useful:

- ⭐ **Star the repository**
- 🐛 **Report bugs and suggest features**
- 💻 **Contribute code**
- 📖 **Improve documentation**
- 🗣️ **Share with others**

Your support helps make Ultimate better for everyone!

---

## 📈 Stats

<p align="center">
  <img src="https://repobeats.axiom.co/api/embed/YOUR_REPO_ID.svg" alt="Repobeats analytics" />
</p>

---

<p align="center">
  <strong>Made with ❤️ by <a href="https://github.com/sanchaygumber">Sanchay Gumber</a></strong>
</p>

<p align="center">
  <sub>Built with SwiftUI • Powered by SwiftData • Inspired by visionOS</sub>
</p>

<p align="center">
  <a href="#top">Back to top ⬆️</a>
</p>
