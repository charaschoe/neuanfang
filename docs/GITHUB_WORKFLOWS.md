# GitHub Workflows Documentation

## Overview

The repository uses GitHub Actions for continuous integration and security scanning.

## Active Workflows

### CodeQL Security Scanning
**File:** `.github/workflows/codeql.yml`

**Purpose:** Automated security analysis for Swift code

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests targeting `main`
- Daily schedule at 02:00 UTC (can be disabled if too noisy)

**Configuration:**
- Uses macOS-15 runner for Swift compilation
- Custom configuration: `.github/codeql/codeql-config.yml`
- Analyzes Swift code with security-focused query suites
- Uploads results to GitHub Security tab

**Permissions:**
- `security-events: write` - Upload SARIF results
- `actions: read` - Workflow execution
- `contents: read` - Repository access

### Xcode Build
**File:** `.github/workflows/objective-c-xcode.yml`

**Purpose:** Build verification for iOS app

**Triggers:**
- Push to branches
- Pull requests

**Configuration:**
- Builds iOS app using Xcode
- Verifies compilation succeeds
- Runs on macOS runner

## Reducing Notification Noise

If you're receiving too many notifications from GitHub Actions:

### Option 1: Disable Daily CodeQL Runs
Edit `.github/workflows/codeql.yml` and comment out the schedule trigger:

```yaml
on:
  push:
    branches: ["main", "develop"]
  pull_request:
    branches: ["main"]
  # schedule:  # COMMENTED OUT TO REDUCE NOTIFICATIONS
  #   - cron: '0 2 * * *'
```

### Option 2: Consolidate Workflows
Merge CodeQL and Xcode build into a single workflow to reduce duplicate runs.

### Option 3: Adjust GitHub Notification Settings
1. Go to repository Settings → Notifications
2. Customize which workflow events trigger notifications
3. Consider disabling notifications for successful workflow runs

## Monitoring Results

### Security Findings
View in: Repository → Security tab → Code scanning alerts

### Workflow Status
View in: Repository → Actions tab

### Build Artifacts
Downloaded from: Actions → Workflow run → Artifacts section

## Troubleshooting

### SARIF Upload Conflicts
If you see: "CodeQL analyses from advanced configurations cannot be processed when the default setup is enabled"

**Solution:**
1. Go to repository Settings → Security & analysis
2. Disable "Default setup" under Code scanning
3. The advanced workflow will handle all analysis

### Build Failures
1. Check Xcode setup step for macOS runner issues
2. Verify Swift build succeeds locally
3. Review workflow logs for specific errors

### Performance Issues
1. Adjust `timeout-minutes` in workflow file
2. Modify `paths-ignore` to exclude unnecessary files
3. Consider reducing query scope in CodeQL configuration

---

*Last Updated: October 17, 2025*
