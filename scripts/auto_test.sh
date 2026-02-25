#!/bin/bash

# Product Toolkit Automated Test Runner
# Self-iterating test mechanism for Web platforms with agent-browser integration

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PTK_DIR="$PROJECT_ROOT/.ptk"
STATE_DIR="$PTK_DIR/state"
EVIDENCE_DIR="$PTK_DIR/evidence"
MAX_ITERATIONS=3

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Automated test runner for Product Toolkit - Web Testing

OPTIONS:
    -v, --version VERSION     Product version (required)
    -f, --feature FEATURE     Feature name (e.g., 电商收藏功能)
    -t, --type TYPE          Test type: smoke|regression|full (default: full)
    -i, --iterations N       Max iterations (default: 3)
    --test-file PATH         Custom test case file path
    --dry-run               Show what would be executed
    -h, --help              Show this help

EXAMPLES:
    $(basename "$0") -v v1.0.0 -f 电商收藏功能
    $(basename "$0") -v v1.0.0 -f 登录功能 -t smoke
    $(basename "$0") -v v1.0.0 -f 用户中心 --dry-run

EOF
    exit 1
}

# Parse arguments
VERSION=""
FEATURE=""
TEST_TYPE="full"
TEST_FILE=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -f|--feature)
            FEATURE="$2"
            shift 2
            ;;
        -t|--type)
            TEST_TYPE="$2"
            shift 2
            ;;
        -i|--iterations)
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        --test-file)
            TEST_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$VERSION" ]]; then
    echo -e "${RED}Error: Version is required (use -v or --version)${NC}"
    usage
fi

if [[ -z "$FEATURE" ]]; then
    echo -e "${RED}Error: Feature is required (use -f or --feature)${NC}"
    usage
fi

# Create directories
mkdir -p "$STATE_DIR"
mkdir -p "$EVIDENCE_DIR/$VERSION/$FEATURE"

# Test case file location
if [[ -z "$TEST_FILE" ]]; then
    TEST_FILE="$PROJECT_ROOT/docs/product/$VERSION/qa/test-cases/${FEATURE}.md"
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Product Toolkit Automated Test Runner${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${CYAN}Version:${NC}    $VERSION"
echo -e "${CYAN}Feature:${NC}   $FEATURE"
echo -e "${CYAN}Test Type:${NC} $TEST_TYPE"
echo -e "${CYAN}Iterations:${NC} $MAX_ITERATIONS"
echo -e "${CYAN}Test File:${NC} $TEST_FILE"
echo ""

# Function: Check if test case file exists
check_test_file() {
    if [[ ! -f "$TEST_FILE" ]]; then
        echo -e "${YELLOW}Warning: Test file not found: $TEST_FILE${NC}"
        # Try alternative locations
        local alt_paths=(
            "$PROJECT_ROOT/docs/product/test-cases/${FEATURE}.md"
            "$PROJECT_ROOT/docs/product/$VERSION/test-cases/${FEATURE}.md"
        )
        for alt_path in "${alt_paths[@]}"; do
            if [[ -f "$alt_path" ]]; then
                TEST_FILE="$alt_path"
                echo -e "${GREEN}Found test file at: $TEST_FILE${NC}"
                return 0
            fi
        done
        return 1
    fi
    echo -e "${GREEN}Found test file: $TEST_FILE${NC}"
    return 0
}

# Function: Parse test cases from markdown file
parse_test_cases() {
    local test_file=$1
    local test_type=$2

    echo -e "${CYAN}Parsing test cases from: $test_file${NC}"

    # Extract test cases by type
    case $test_type in
        smoke)
            grep -A 20 "### 冒烟测试" "$test_file" 2>/dev/null || echo "No smoke tests found"
            ;;
        regression)
            grep -A 20 "### 回归测试" "$test_file" 2>/dev/null || echo "No regression tests found"
            ;;
        full)
            cat "$test_file" 2>/dev/null || echo "Test file not found"
            ;;
    esac
}

# Function: Extract test steps from markdown
extract_test_steps() {
    local test_file=$1
    local test_id=$2

    # Extract specific test case
    sed -n "/${test_id}:/,/---/p" "$test_file" 2>/dev/null || echo ""
}

# Function: Run Web test using agent-browser
run_web_test() {
    local test_case=$1
    local iteration=$2

    echo ""
    echo -e "${YELLOW}--- Running Web test (Iteration $iteration/$MAX_ITERATIONS) ---${NC}"

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would execute Web test for: $test_case"
        echo "[DRY RUN] Would use agent-browser with:"
        echo "  - Test case: $test_case"
        echo "  - Screenshot dir: $EVIDENCE_DIR/$VERSION/$FEATURE/screenshots/"
        echo "  - Console log: $EVIDENCE_DIR/$VERSION/$FEATURE/console.log"
        return 0
    fi

    # Check if agent-browser is available
    if command -v agent-browser &> /dev/null; then
        echo "Using agent-browser for Web testing..."
        agent-browser \
            --test-case "$test_case" \
            --screenshot-dir "$EVIDENCE_DIR/$VERSION/$FEATURE/screenshots/" \
            --console-log "$EVIDENCE_DIR/$VERSION/$FEATURE/console.log" \
            --report "$EVIDENCE_DIR/$VERSION/$FEATURE/report.json" \
            2>&1 || return 1
    elif command -v npx &> /dev/null; then
        echo "Using npx browser-use for Web testing..."
        npx browser-use --test-case "$test_case" \
            --output-dir "$EVIDENCE_DIR/$VERSION/$FEATURE/" \
            2>&1 || return 1
    else
        echo -e "${YELLOW}Warning: agent-browser or browser-use not found${NC}"
        echo "Installing browser-use..."
        npm install -g browser-use 2>/dev/null || {
            echo -e "${RED}Failed to install browser-use${NC}"
            return 1
        }
    fi

    return 0
}

# Function: Run smoke tests only
run_smoke_tests() {
    local iteration=$1

    echo -e "${CYAN}Running SMOKE tests (P0 - must pass)${NC}"

    # Extract smoke test cases
    local smoke_cases=$(grep -E "^#### SM" "$TEST_FILE" 2>/dev/null | head -10 || echo "")

    if [[ -z "$smoke_cases" ]]; then
        echo -e "${YELLOW}No smoke tests found in test file${NC}"
        return 0
    fi

    local passed=0
    local failed=0

    while IFS= read -r test_case; do
        if [[ -z "$test_case" ]]; then
            continue
        fi

        local test_id=$(echo "$test_case" | sed 's/.*SMK-\([0-9]*\).*/\1/')
        echo -e "${CYAN}Running: SMOKE-${test_id}${NC}"

        if run_web_test "SMOKE-${test_id}" "$iteration"; then
            ((passed++))
            echo -e "${GREEN}✓ SMOKE-${test_id} PASSED${NC}"
        else
            ((failed++))
            echo -e "${RED}✗ SMOKE-${test_id} FAILED${NC}"
        fi
    done <<< "$smoke_cases"

    echo ""
    echo "Smoke Test Results: $passed passed, $failed failed"

    if [[ $failed -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Function: Run all tests
run_all_tests() {
    local iteration=$1

    echo -e "${CYAN}Running FULL test suite${NC}"

    # Extract all test cases
    local test_cases=$(grep -E "^#### (SMK|TC)-" "$TEST_FILE" 2>/dev/null || echo "")

    if [[ -z "$test_cases" ]]; then
        echo -e "${YELLOW}No test cases found in test file${NC}"
        return 0
    fi

    local passed=0
    local failed=0
    local blocked=0

    while IFS= read -r test_case; do
        if [[ -z "$test_case" ]]; then
            continue
        fi

        echo -e "${CYAN}Running: $test_case${NC}"

        if run_web_test "$test_case" "$iteration"; then
            ((passed++))
            echo -e "${GREEN}✓ $test_case PASSED${NC}"
        else
            ((failed++))
            echo -e "${RED}✗ $test_case FAILED${NC}"
        fi
    done <<< "$test_cases"

    echo ""
    echo "Test Results: $passed passed, $failed failed"

    if [[ $failed -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Function: Update test progress
update_test_progress() {
    local version=$1
    local feature=$2
    local status=$3
    local passed=$4
    local failed=$5

    local progress_file="$STATE_DIR/test-progress.json"

    # Create or update progress
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [[ -f "$progress_file" ]]; then
        # Update existing
        local temp_file=$(mktemp)
        jq --arg v "$version" --arg f "$feature" --arg s "$status" \
           --argjson p "$passed" --argjson f "$failed" --arg t "$timestamp" \
           '.versions[] | select(.version==$v) | .test_cases += [{"feature": $f, "status": $s, "passed": $p, "failed": $f, "timestamp": $t}]' \
           "$progress_file" > "$temp_file" || echo "{}"
        mv "$temp_file" "$progress_file"
    else
        # Create new
        cat > "$progress_file" << EOF
{
  "project": "product-toolkit",
  "versions": [
    {
      "version": "$version",
      "test_cases": [
        {
          "feature": "$feature",
          "status": "$status",
          "passed": $passed,
          "failed": $failed,
          "timestamp": "$timestamp"
        }
      ]
    }
  ]
}
EOF
    fi

    echo -e "${CYAN}Test progress updated: $progress_file${NC}"
}

# Function: Generate test report
generate_report() {
    local version=$1
    local feature=$2
    local passed=$3
    local failed=$4

    local total=$((passed + failed))
    local coverage=0

    if [[ $total -gt 0 ]]; then
        coverage=$((passed * 100 / total))
    fi

    cat << EOF

========================================
Test Report: $version - $feature
========================================
Test Type:     $TEST_TYPE
Total:         $total
Passed:        $passed
Failed:        $failed
Coverage:      ${coverage}%
Evidence Dir:  $EVIDENCE_DIR/$version/$feature/

EOF

    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    else
        echo -e "${RED}✗ $failed TEST(S) FAILED${NC}"
        echo ""
        echo "Review evidence in: $EVIDENCE_DIR/$version/$feature/"
    fi
}

# Main test loop
run_tests() {
    local iteration=1
    local test_passed=false
    local total_passed=0
    local total_failed=0

    # Check test file
    if ! check_test_file; then
        echo -e "${RED}Error: Test file not found${NC}"
        exit 1
    fi

    while [[ $iteration -le $MAX_ITERATIONS ]]; do
        echo ""
        echo -e "${BLUE}=== Iteration $iteration/$MAX_ITERATIONS ===${NC}"

        local iteration_passed=0
        local iteration_failed=0

        # Run tests based on type
        case $TEST_TYPE in
            smoke)
                if run_smoke_tests "$iteration"; then
                    iteration_passed=1
                else
                    iteration_failed=1
                fi
                ;;
            regression|full)
                if run_all_tests "$iteration"; then
                    iteration_passed=1
                else
                    iteration_failed=1
                fi
                ;;
        esac

        # Check results
        if [[ $iteration_failed -eq 0 ]]; then
            test_passed=true
            total_passed=$((total_passed + iteration_passed))
            echo -e "${GREEN}Iteration $iteration PASSED${NC}"

            # If smoke tests pass, can stop early
            if [[ "$TEST_TYPE" == "smoke" ]]; then
                break
            fi
        else
            total_failed=$((total_failed + iteration_failed))
            echo -e "${RED}Iteration $iteration FAILED${NC}"

            # Try to fix and re-test (placeholder for auto-fix)
            if [[ $iteration -lt $MAX_ITERATIONS ]]; then
                echo -e "${YELLOW}Test failed, will retry...${NC}"
            fi
        fi

        iteration=$((iteration + 1))
    done

    # Update progress
    if [[ "$test_passed" == true ]]; then
        update_test_progress "$VERSION" "$FEATURE" "passed" "$total_passed" "$total_failed"
    else
        update_test_progress "$VERSION" "$FEATURE" "failed" "$total_passed" "$total_failed"
    fi

    # Generate report
    generate_report "$VERSION" "$FEATURE" "$total_passed" "$total_failed"
}

# Run
run_tests
