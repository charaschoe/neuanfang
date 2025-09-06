#!/bin/bash

# CodeQL Setup Management Script
# Helps configure and troubleshoot CodeQL Advanced setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if required files exist
check_codeql_files() {
    print_header "Checking CodeQL Configuration Files"
    
    local all_good=true
    
    # Check workflow file
    if [[ -f "${REPO_ROOT}/.github/workflows/codeql.yml" ]]; then
        print_status "✓ CodeQL workflow file exists"
    else
        print_error "✗ CodeQL workflow file missing: .github/workflows/codeql.yml"
        all_good=false
    fi
    
    # Check configuration file
    if [[ -f "${REPO_ROOT}/.github/codeql/codeql-config.yml" ]]; then
        print_status "✓ CodeQL configuration file exists"
    else
        print_error "✗ CodeQL configuration file missing: .github/codeql/codeql-config.yml"
        all_good=false
    fi
    
    # Check documentation
    if [[ -f "${REPO_ROOT}/CODEQL_SECURITY_SETUP.md" ]]; then
        print_status "✓ CodeQL documentation exists"
    else
        print_warning "✗ CodeQL documentation missing: CODEQL_SECURITY_SETUP.md"
    fi
    
    if [[ "$all_good" == true ]]; then
        print_status "All required CodeQL files are present"
        return 0
    else
        print_error "Some required CodeQL files are missing"
        return 1
    fi
}

# Validate workflow syntax
validate_workflow() {
    print_header "Validating Workflow Syntax"
    
    local workflow_file="${REPO_ROOT}/.github/workflows/codeql.yml"
    
    if command -v yamllint >/dev/null 2>&1; then
        if yamllint "$workflow_file" >/dev/null 2>&1; then
            print_status "✓ Workflow YAML syntax is valid"
        else
            print_error "✗ Workflow YAML syntax errors detected"
            yamllint "$workflow_file"
            return 1
        fi
    else
        print_warning "yamllint not available, skipping syntax validation"
    fi
    
    # Basic checks
    if grep -q "github/codeql-action/init@v3" "$workflow_file"; then
        print_status "✓ Using correct CodeQL action version"
    else
        print_warning "CodeQL action version might be outdated"
    fi
    
    if grep -q "config-file: ./.github/codeql/codeql-config.yml" "$workflow_file"; then
        print_status "✓ External configuration file is referenced"
    else
        print_error "✗ External configuration file not properly referenced"
        return 1
    fi
}

# Check for potential conflicts
check_conflicts() {
    print_header "Checking for Potential Conflicts"
    
    # Check if there are multiple CodeQL workflows
    local codeql_workflows=$(find "${REPO_ROOT}/.github/workflows" -name "*.yml" -o -name "*.yaml" | xargs grep -l "codeql-action" 2>/dev/null | wc -l)
    
    if [[ $codeql_workflows -gt 1 ]]; then
        print_warning "Multiple CodeQL workflows detected. This might cause conflicts."
        find "${REPO_ROOT}/.github/workflows" -name "*.yml" -o -name "*.yaml" | xargs grep -l "codeql-action" 2>/dev/null
    else
        print_status "✓ No multiple CodeQL workflows detected"
    fi
    
    # Check for common conflicting patterns
    if grep -r "github/codeql-action" "${REPO_ROOT}/.github/workflows/" | grep -v "codeql.yml" >/dev/null 2>&1; then
        print_warning "CodeQL actions found in other workflows. Review for conflicts:"
        grep -r "github/codeql-action" "${REPO_ROOT}/.github/workflows/" | grep -v "codeql.yml" || true
    else
        print_status "✓ No conflicting CodeQL actions in other workflows"
    fi
}

# Generate GitHub repository settings instructions
generate_settings_instructions() {
    print_header "Repository Settings Configuration"
    
    cat << EOF

To complete the CodeQL setup and prevent conflicts:

1. DISABLE DEFAULT CODEQL SETUP (Recommended):
   • Go to: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')/settings/security_analysis
   • Under "Code scanning" → "Default setup"
   • Click "Disable" if currently enabled
   • This prevents conflicts with the advanced configuration

2. VERIFY PERMISSIONS:
   • Ensure "Security events" permission is enabled for Actions
   • Go to: Repository Settings → Actions → General
   • Under "Workflow permissions", ensure "Read and write permissions" is selected

3. MONITOR RESULTS:
   • View security findings: Repository → Security → Code scanning
   • Check workflow runs: Repository → Actions → CodeQL Advanced

EOF
}

# Main execution
main() {
    print_header "CodeQL Advanced Setup Validation"
    echo "Repository: $(basename "$REPO_ROOT")"
    echo "Script location: $SCRIPT_DIR"
    echo ""
    
    local exit_code=0
    
    # Run all checks
    check_codeql_files || exit_code=1
    echo ""
    
    validate_workflow || exit_code=1
    echo ""
    
    check_conflicts
    echo ""
    
    generate_settings_instructions
    
    if [[ $exit_code -eq 0 ]]; then
        print_status "✓ CodeQL Advanced setup validation completed successfully"
        print_status "Review the repository settings instructions above to complete setup"
    else
        print_error "✗ CodeQL Advanced setup has issues that need to be resolved"
    fi
    
    exit $exit_code
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi