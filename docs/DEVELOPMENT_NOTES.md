# Development Notes

This document contains historical notes and implementation details for reference.

## CloudKit Container Configuration

The CloudKit container ID "iCloud.com.neuanfang.umzugshelfer" has been externalized to `neuanfang-umzugshelfer/Resources/Config.plist` and is managed through `ConfigurationManager.swift`.

**Implementation:**
- Centralized configuration management
- Type-safe access to settings
- Performance-optimized caching
- Graceful fallback handling

**Files:**
- `neuanfang-umzugshelfer/Resources/Config.plist` - Central configuration
- `neuanfang-umzugshelfer/Services/ConfigurationManager.swift` - Configuration manager
- `neuanfang-umzugshelfer/Services/CloudKitService.swift` - Uses configuration
- `neuanfang-umzugshelfer/Models/CoreData/PersistenceController.swift` - Uses configuration

## CodeQL Security Scanning

The project uses GitHub's CodeQL Advanced security scanning with a custom configuration optimized for Swift/iOS development.

**Configuration:**
- `.github/workflows/codeql.yml` - Main workflow
- `.github/codeql/codeql-config.yml` - CodeQL configuration
- Runs on push to main, PRs, and daily at 02:00 UTC

**Note:** If you experience conflicts with GitHub's default CodeQL setup, disable the default setup in repository settings and rely on the advanced configuration.

## Project Structure

```
neuanfang-umzugshelfer/
├── App/                          # App Lifecycle
├── Models/
│   ├── CoreData/                 # Entities + PersistenceController
│   └── ViewModels/               # Observable ViewModels
├── Views/
│   ├── LiquidGlass/              # Design System (do not modify)
│   ├── Rooms/                    # Room views
│   ├── Boxes/                    # Box views
│   ├── Items/                    # Item views
│   ├── Timeline/                 # Timeline views
│   ├── Settings/                 # Settings views
│   └── Shared/                   # Reusable components
├── Services/                     # Business logic
└── Resources/                    # Assets & configs
```

## Liquid Glass Design System

The project uses a proprietary "Liquid Glass Design System 2.0" for UI. Always use the provided modifiers:

```swift
// Base styles
.liquidGlass(.floating)    // For cards and panels
.liquidGlass(.toolbar)     // For navigation
.liquidGlass(.overlay)     // For modals
.liquidGlass(.adaptive)    // Adaptive to context
.liquidGlass(.dynamic)     // Dynamic adjustments

// Add depth
.glassDepth(.elevated)     // Slightly elevated
.glassDepth(.floating)     // Floating
.glassDepth(.modal)        // Highest level

// Interactivity
.interactiveGlass()        // For tappable elements
.morphingTransition()      // Fluid transitions
.contextualGlow()          // Contextual glow effects
.paralaxGlass()            // Parallax effects
```

## Core Data Encryption

All Core Data stores use file-level encryption with protection level "complete" to ensure data security.

See `neuanfang-umzugshelfer/CoreDataEncryptionValidation.md` for validation details.

## Input Validation

Comprehensive input validation is implemented throughout the app to prevent security issues and data corruption.

See `neuanfang-umzugshelfer/INPUT_VALIDATION_DOCUMENTATION.md` for details.

## Known Issues and Solutions

### Notification Issues

The app previously had issues with constant notifications due to:
1. Unmanaged timer in voice recognition
2. Frequent CloudKit sync operations  
3. Multiple debounced input validations
4. GitHub workflow notifications (daily CodeQL runs)

**Solutions implemented:**
- Timer cleanup in voice recognition service
- CloudKit sync throttling (30 second minimum interval)
- Consolidated input validation publishers
- Optimized GitHub workflows (removed daily schedule, consolidated workflows)

### Xcode File Management

When adding new files to the Xcode project, always:
1. Use Xcode's "Add Files" dialog
2. Ensure "Copy items if needed" is UNCHECKED if files are already in project directory
3. Ensure target membership is correctly set
4. Clean build folder after adding files

Do NOT manually edit `project.pbxproj` as it can lead to project corruption.

---

*Last Updated: October 17, 2025*
