# CodeQL Security Scanning Setup

This document explains the CodeQL Advanced security scanning configuration for the neuanfang-umzugshelfer project.

## Overview

The repository uses GitHub's CodeQL Advanced security scanning with a custom configuration optimized for Swift/iOS development.

**Configuration Files:**
- `.github/workflows/codeql.yml` - Main workflow
- `.github/codeql/codeql-config.yml` - CodeQL configuration

## Features

### Swift/iOS Optimized
- Configured specifically for Swift language analysis
- Uses macOS runners for proper Xcode/Swift compilation
- Includes proper build steps for iOS projects

### Security-Focused
- Uses security-extended and security-and-quality query suites
- Filters for error, warning, and recommendation severity levels
- Excludes test files and generated content from analysis

## Workflow Triggers

- **Push**: Runs on `main` and `develop` branches
- **Pull Request**: Runs on PRs targeting `main`
- **Schedule**: Daily runs at 02:00 UTC (can be disabled to reduce notifications)

## Analysis Scope

- **Included**: All Swift files in `neuanfang-umzugshelfer/` directory
- **Excluded**: Test files, preview content, build artifacts, generated files

## Repository Settings

To avoid conflicts with GitHub's default CodeQL setup:

**Option 1 (Recommended):** Disable default setup
1. Go to repository Settings → Security & analysis
2. Under "Code scanning", disable "Default setup"
3. The advanced workflow will handle all CodeQL analysis

**Option 2:** Keep default setup enabled for other languages (if needed)
- Default setup can handle JavaScript, Python, etc.
- Advanced workflow handles Swift-specific analysis

## Viewing Results

Security findings are available in:
- **Security tab** → Code scanning alerts
- **Pull Request checks** (for PR-triggered scans)

## Troubleshooting

### SARIF Upload Conflicts
If you see: "CodeQL analyses from advanced configurations cannot be processed when the default setup is enabled"
- **Solution:** Disable default CodeQL setup in repository settings

### Analysis Failures
1. Check Xcode setup step for macOS runner issues
2. Verify Swift build succeeds locally
3. Review workflow logs for specific errors

### Reducing Notifications
If daily runs create too many notifications, edit `.github/workflows/codeql.yml` and comment out the schedule trigger.

## Benefits

- **Continuous Security Monitoring**: Automated vulnerability detection
- **PR Security Checks**: Prevents introduction of security issues
- **Swift-Specific Analysis**: Tailored for iOS/macOS development
- **Comprehensive Coverage**: Uses extended security query suite

---

For more information about GitHub workflows, see [`docs/GITHUB_WORKFLOWS.md`](docs/GITHUB_WORKFLOWS.md).