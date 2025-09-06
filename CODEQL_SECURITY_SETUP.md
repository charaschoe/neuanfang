# CodeQL Security Scanning Setup

This document explains the CodeQL Advanced security scanning configuration for the neuanfang-umzugshelfer project and how it resolves common conflicts with GitHub's default CodeQL setup.

## Problem Solved

This configuration addresses the following common CodeQL error:
```
"Code Scanning could not process the submitted SARIF file: CodeQL analyses from advanced configurations cannot be processed when the default setup is enabled"
```

## Root Cause Analysis

The error occurs when:
1. GitHub's default CodeQL setup is enabled in repository settings
2. A custom advanced CodeQL workflow is also present
3. Both systems try to upload SARIF results, causing a conflict

## Solution Implemented

Our CodeQL Advanced workflow (`/.github/workflows/codeql.yml`) implements several strategies to prevent conflicts:

### 1. Explicit Configuration Management
- Uses external configuration file (`.github/codeql/codeql-config.yml`)
- Explicitly defines analysis scope and query filters
- Prevents automatic conflicts with default setup

### 2. Swift/iOS Optimized Setup
- Configured specifically for Swift language analysis
- Uses macOS runners for proper Xcode/Swift compilation
- Includes proper build steps for iOS projects

### 3. Conflict Prevention Mechanisms
- Uses `upload: true` and `wait-for-processing: true` parameters
- Implements proper categorization with `/language:swift`
- Uses advanced query suites that complement (don't replace) default scanning

### 4. Security-Focused Configuration
- Includes security-extended and security-and-quality query suites
- Filters for error, warning, and recommendation severity levels
- Excludes test files and generated content from analysis

## File Structure

```
.github/
├── workflows/
│   ├── codeql.yml                 # Main CodeQL Advanced workflow
│   └── objective-c-xcode.yml      # Existing Xcode build workflow
└── codeql/
    └── codeql-config.yml          # CodeQL configuration file
```

## Configuration Details

### Workflow Triggers
- **Push**: Runs on `main` and `develop` branches
- **Pull Request**: Runs on PRs targeting `main`
- **Schedule**: Daily runs at 02:00 UTC for regular security scanning

### Security Permissions
- `security-events: write` - Required for uploading SARIF results
- `actions: read` - Required for workflow execution
- `contents: read` - Required for repository access

### Analysis Scope
- **Included**: All Swift files in `neuanfang-umzugshelfer/` directory
- **Excluded**: Test files, preview content, build artifacts, generated files

## Repository Settings Configuration

To ensure this advanced configuration works properly:

### Option 1: Disable Default CodeQL Setup (Recommended)
1. Go to repository Settings > Security & analysis
2. Under "Code scanning", disable "Default setup"
3. The advanced workflow will handle all CodeQL analysis

### Option 2: Compatible Coexistence
If you prefer to keep default setup enabled:
1. Ensure default setup is configured for different languages (e.g., JavaScript, Python)
2. The advanced workflow handles Swift-specific analysis
3. Different language configurations can coexist without conflicts

## Workflow Execution

The workflow performs these steps:
1. **Checkout**: Gets repository code
2. **Initialize CodeQL**: Sets up analysis with custom configuration
3. **Setup Xcode**: Configures Swift/iOS build environment
4. **Build Project**: Compiles Swift code for analysis
5. **Perform Analysis**: Runs CodeQL security analysis
6. **Upload Results**: Submits findings to GitHub Security tab

## Monitoring and Results

Security findings will be available in:
- **Security tab** > Code scanning alerts
- **Pull Request checks** (for PR-triggered scans)
- **Workflow artifacts** (detailed reports)

## Troubleshooting

### If you see SARIF upload conflicts:
1. Check if default CodeQL setup is enabled in repository settings
2. Verify the workflow is using the correct configuration file
3. Ensure proper permissions are set in the workflow

### If analysis fails:
1. Check Xcode setup step for macOS runner issues
2. Verify Swift build succeeds independently
3. Review CodeQL initialization logs for configuration errors

### For performance issues:
1. Adjust `timeout-minutes` if builds take longer
2. Modify `paths-ignore` to exclude more files if needed
3. Consider reducing query scope in configuration file

## Maintenance

### Updating Queries
Edit `.github/codeql/codeql-config.yml` to:
- Add new query filters
- Exclude specific rule IDs
- Modify analysis paths

### Updating Workflow
The workflow automatically uses latest stable versions of:
- `github/codeql-action` (v3)
- `actions/checkout` (v4)
- `maxim-lobanov/setup-xcode` (v1)

## Security Benefits

This setup provides:
- **Continuous Security Monitoring**: Daily scans detect new vulnerabilities
- **PR Security Checks**: Prevents introduction of security issues
- **Comprehensive Analysis**: Uses extended security query suite
- **Swift-Specific Rules**: Tailored for iOS/macOS development security patterns

## Integration with Development Workflow

The CodeQL analysis integrates seamlessly with existing development practices:
- Runs alongside existing Xcode build workflow
- Provides security feedback in pull requests
- Maintains separate artifact storage for detailed analysis reports
- Supports both automated and manual workflow triggers