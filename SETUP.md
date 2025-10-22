# Setup Guide for Ultimate

This guide will help you set up the Ultimate project for development on your local machine.

## Prerequisites

Before you begin, ensure you have installed:

- **Xcode 15.0 or later**
- **macOS 14.0 (Sonoma) or later**
- **iOS 17.0+ SDK**
- **Git**

## Step 1: Clone the Repository

```bash
git clone https://github.com/sanchaygumber/Ultimate.git
cd Ultimate
```

## Step 2: Open the Project

```bash
open Ultimate.xcodeproj
```

## Step 3: Configure Development Team

⚠️ **Important**: Before building, you must configure your Apple Developer Team ID.

### Option A: Using Xcode UI (Recommended)

1. **Open the project** in Xcode
2. **Select the "Ultimate" project** in the navigator (blue icon at top)
3. **Select the "Ultimate" target** in the main panel
4. **Go to "Signing & Capabilities" tab**
5. **In "Team" dropdown**, select your Apple Developer account
   - If you don't see your account, click "Add Account..." and sign in
   - For personal projects, you can use a free Apple ID

### Option B: Manual Configuration

The project file contains a placeholder Development Team ID: `VBHQTVJ6PT`

**To replace it:**

1. Find your Team ID:
   - Open Xcode
   - Go to Xcode → Settings → Accounts
   - Select your Apple ID
   - View the Team ID next to your account name

2. Replace in `project.pbxproj`:
   ```
   Find: DEVELOPMENT_TEAM = VBHQTVJ6PT;
   Replace with: DEVELOPMENT_TEAM = YOUR_TEAM_ID;
   ```

**Note**: You may need to change this in two places (Debug and Release configurations).

## Step 4: Configure Bundle Identifier (Optional)

If you want to use your own bundle identifier:

1. **In Xcode**, select the Ultimate target
2. **Go to "General" tab**
3. **Change "Bundle Identifier"** from `SaGu.Ultimate` to your own
   - Example: `com.yourname.Ultimate`

### Why Change Bundle Identifier?

- Required for App Store distribution
- Recommended for personal builds
- Avoids conflicts with other developers

**Default Bundle Identifiers:**
- App: `SaGu.Ultimate`
- Tests: `SaGu.UltimateTests`
- UI Tests: `SaGu.UltimateUITests`

## Step 5: Build the Project

### For Simulator

1. **Select a simulator** from the device menu (e.g., "iPhone 15 Pro")
2. **Press ⌘R** or click the Run button
3. The app will build and launch in the simulator

### For Physical Device

1. **Connect your iOS device** via USB
2. **Select your device** from the device menu
3. **Trust the developer certificate** when prompted on device
4. **Press ⌘R** to build and run

**First Time Setup:**
- You may see: "Could not launch [app] - verify the Developer App certificate"
- On your iOS device: Settings → General → VPN & Device Management
- Trust your developer certificate

## Step 6: Verify Installation

After building, verify that:

- [ ] App launches without crashes
- [ ] Navigation between tabs works
- [ ] Can create a new challenge
- [ ] Can view Today's tasks
- [ ] No console errors (minor warnings are OK)

## Troubleshooting

### Error: "No accounts with App Store Connect access"

**Solution**: You need a free Apple Developer account
1. Go to Xcode → Settings → Accounts
2. Click "+" to add your Apple ID
3. Sign in with your Apple ID
4. Select your account as the Team

### Error: "Failed to register bundle identifier"

**Solution**: Change the bundle identifier
1. Go to target General settings
2. Change Bundle Identifier to something unique
3. Example: `com.yourname.Ultimate`

### Error: "Provisioning profile doesn't include device"

**Solution**: Add device to provisioning profile
1. This error occurs on physical devices
2. Xcode will usually fix this automatically
3. Click "Try Again" when prompted
4. Or change to "Automatically manage signing"

### Error: "Command CompileSwiftSources failed"

**Solution**: Clean and rebuild
```bash
# In Xcode
Product → Clean Build Folder (⇧⌘K)
Product → Build (⌘B)
```

### Simulator Not Showing Up

**Solution**: Reset simulator list
```bash
# In Terminal
killall Simulator
xcrun simctl delete unavailable
```

Then restart Xcode

### Build Hangs or Freezes

**Solution**: 
1. Quit Xcode
2. Delete Derived Data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Restart Xcode and rebuild

## Optional: Configure Entitlements

### HealthKit

The app includes HealthKit entitlements but they're optional.

**File**: `Ultimate/Ultimate.entitlements`

```xml
<key>com.apple.developer.healthkit</key>
<true/>
```

**To disable HealthKit:**
1. Remove the entitlement from the file
2. App will still work, but automatic workout tracking will be unavailable

### Push Notifications

The app is configured for local notifications only (no push notifications).

## Testing

### Run Unit Tests

```bash
# In Xcode
Product → Test (⌘U)

# Or command line
xcodebuild test -scheme Ultimate \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Run Specific Test

1. Open a test file (e.g., `NotificationManagerTests.swift`)
2. Click the diamond icon next to test method
3. Or press ⌘U with cursor in test method

## Development Workflow

### Recommended Workflow

1. **Create a branch** for your feature
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes** in Xcode

3. **Test your changes**
   - Run unit tests (⌘U)
   - Test in simulator
   - Test on physical device (if needed)

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add my feature"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/my-feature
   ```

### Code Style

- Follow Swift API Design Guidelines
- Use `// MARK:` comments to organize code
- Add documentation comments for public APIs
- Run SwiftLint (if available)

## Project Configuration Summary

### Key Settings

| Setting | Value |
|---------|-------|
| **Deployment Target** | iOS 18.2 (can be changed to 17.0) |
| **Swift Version** | 5.9 |
| **Bundle ID** | `SaGu.Ultimate` (change for your build) |
| **Team** | Set to your team |

### Capabilities Required

- ✅ **HealthKit** (optional, for workout tracking)
- ✅ **Push Notifications** (for local notifications)
- ✅ **Background Modes** (for background task generation)

### Info.plist Descriptions

The following privacy descriptions are included:

```
NSHealthShareUsageDescription
NSHealthUpdateUsageDescription  
NSCameraUsageDescription
NSPhotoLibraryUsageDescription
NSFaceIDUsageDescription
```

These can be customized in `Ultimate/AppInfo.plist`.

## Deployment Target

The project is configured for iOS 18.2 but can run on iOS 17.0+.

**To change deployment target:**

1. Select Ultimate target
2. Go to General tab
3. Change "Minimum Deployments" to `17.0`

**In project.pbxproj:**
```
Find: IPHONEOS_DEPLOYMENT_TARGET = 18.2;
Replace: IPHONEOS_DEPLOYMENT_TARGET = 17.0;
```

## Supported Devices

- ✅ iPhone (iOS 17.0+)
- ✅ iPad (iOS 17.0+) - UI optimized for iPhone but works on iPad
- ✅ iOS Simulator

## Next Steps

After setup:

1. **Read the documentation**
   - [ARCHITECTURE.md](ARCHITECTURE.md) - Understand the codebase
   - [FEATURES.md](FEATURES.md) - Learn about features
   - [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines

2. **Explore the code**
   - Start with `UltimateApp.swift`
   - Check out feature modules in `Features/`
   - Review the design system in `UI/`

3. **Make your first contribution**
   - Look for `good first issue` labels
   - Fix a bug or add a small feature
   - Improve documentation

## Getting Help

- **Documentation Issues**: [Open an issue](https://github.com/sanchaygumber/Ultimate/issues)
- **Setup Problems**: [Start a discussion](https://github.com/sanchaygumber/Ultimate/discussions)
- **General Questions**: Check existing issues and discussions

## Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Xcode Help](https://help.apple.com/xcode/)

---

**Happy Coding! 🚀**

If you encounter any issues with this setup guide, please open an issue or submit a PR to improve it.

---

**Last Updated:** January 2025  
**Maintained by:** Sanchay Gumber  
**License:** Apache-2.0

