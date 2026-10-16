#!/bin/bash
# =============================================================================
# Android Test Execution with Comprehensive Reporting
# Handles unit tests, instrumentation tests, and test reporting
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOG_FILE="${ANDROID_CI_LOGS:-./android/ci/logs/test.log}"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Default configuration
TEST_VARIANT="${TEST_VARIANT:-debug}"
TEST_TYPE="${TEST_TYPE:-all}"  # all, unit, instrumented
TEST_REPORTS_DIR="${ANDROID_CI_ARTIFACTS:-./android/ci/artifacts}/test-reports"
TEST_TIMEOUT="${TEST_TIMEOUT:-300}"  # 5 minutes default timeout

# Create reports directory
mkdir -p "$TEST_REPORTS_DIR"

# ---------------------------------------------------------------------------
# 1. Test Configuration
# ---------------------------------------------------------------------------
log "Starting test execution for variant: $TEST_VARIANT"

TEST_CMD="./android/gradlew"

if [[ "$TEST_TYPE" == "unit" ]] || [[ "$TEST_TYPE" == "all" ]]; then
    log "Running unit tests..."
    TEST_CMD="$TEST_CMD testDebugUnitTest --tests '*'"
elif [[ "$TEST_TYPE" == "instrumented" ]] || [[ "$TEST_TYPE" == "all" ]]; then
    log "Running instrumentation tests..."
    # Check for connected devices
    DEVICE_COUNT=$(adb devices 2>/dev/null | tail -n +2 | wc -l)
    if [[ "$DEVICE_COUNT" -eq 0 ]]; then
        log "${YELLOW}WARNING: No devices connected for instrumentation tests${NC}"
        log "Skipping instrumentation tests"
        TEST_TYPE="unit"
    else
        TEST_CMD="$TEST_CMD connectedDebugAndroidTest"
    fi
fi

# Add timeout and test reporting options
TEST_CMD="$TEST_CMD --max-workers=4 --parallel"

# ---------------------------------------------------------------------------
# 2. Execute Tests
# ---------------------------------------------------------------------------
log "Executing: $TEST_CMD"
START_TIME=$(date +%s)

# Run tests with retry logic for flaky tests
MAX_RETRIES=2
ATTEMPT=0
TEST_RESULT=1

while [[ $ATTEMPT -lt $MAX_RETRIES ]] && [[ $TEST_RESULT -ne 0 ]]; do
    if [[ $ATTEMPT -gt 0 ]]; then
        log "${YELLOW}Retrying tests (attempt $((ATTEMPT+1))/$MAX_RETRIES)${NC}"
    fi
    
    # Run the tests
    if $TEST_CMD --tests "*" --test-timeout=${TEST_TIMEOUT}s; then
        TEST_RESULT=0
    else
        TEST_RESULT=$?
        ATTEMPT=$((ATTEMPT + 1))
        if [[ $ATTEMPT -lt $MAX_RETRIES ]]; then
            sleep 5  # Brief pause before retry
        fi
    fi
done

TEST_TIME=$(( $(date +%s) - START_TIME ))

if [[ $TEST_RESULT -ne 0 ]]; then
    log "${RED}ERROR: Tests failed after $MAX_RETRIES attempts${NC}"
    # Copy test reports for debugging
    cp -r android/app/build/test-results/* "$TEST_REPORTS_DIR/" 2>/dev/null || true
    cp -r android/app/build/reports/tests/* "$TEST_REPORTS_DIR/" 2>/dev/null || true
    exit $TEST_RESULT
fi

log "${GREEN}✓ Tests completed successfully in ${TEST_TIME}s${NC}"

# ---------------------------------------------------------------------------
# 3. Post-test artifact collection
# ---------------------------------------------------------------------------
log "Collecting test reports..."

# Copy unit test results
if [[ "$TEST_TYPE" == "unit" ]] || [[ "$TEST_TYPE" == "all" ]]; then
    if [[ -d "android/app/build/test-results/testDebugUnitTest" ]]; then
        mkdir -p "$TEST_REPORTS_DIR/unit"
        cp -r android/app/build/test-results/testDebugUnitTest/* "$TEST_REPORTS_DIR/unit/" || true
        log "${GREEN}✓ Unit test reports collected${NC}"
    fi
fi

# Copy instrumentation test results
if [[ "$TEST_TYPE" == "instrumented" ]] || [[ "$TEST_TYPE" == "all" ]]; then
    if [[ -d "android/app/build/test-results/connectedAndroidTest" ]]; then
        mkdir -p "$TEST_REPORTS_DIR/instrumented"
        cp -r android/app/build/test-results/connectedAndroidTest/* "$TEST_REPORTS_DIR/instrumented/" || true
        log "${GREEN}✓ Instrumentation test reports collected${NC}"
    fi
fi

# Copy test reports (HTML/JUnit)
mkdir -p "$TEST_REPORTS_DIR/junit"
cp -r android/app/build/reports/tests/* "$TEST_REPORTS_DIR/junit/" 2>/dev/null || true
cp -r android/app/build/test-results/* "$TEST_REPORTS_DIR/junit/" 2>/dev/null || true

# Generate test summary
generate_test_summary() {
    cat > "$TEST_REPORTS_DIR/SUMMARY.md" << EOF
# Test Execution Summary

**Timestamp**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Variant**: $TEST_VARIANT
**Test Type**: $TEST_TYPE
**Execution Time**: ${TEST_TIME}s
**Result**: PASSED

## Test Coverage
- Unit Tests: $(find "$TEST_REPORTS_DIR/unit" -name "*.xml" 2>/dev/null | wc -l) test suites
- Instrumented Tests: $(find "$TEST_REPORTS_DIR/instrumented" -name "*.xml" 2>/dev/null | wc -l) test suites

## Reports
- JUnit XML: $TEST_REPORTS_DIR/junit/
- HTML Reports: $TEST_REPORTS_DIR/
EOF
}

generate_test_summary
log "${GREEN}✓ Test summary generated: ${TEST_REPORTS_DIR}/SUMMARY.md${NC}"

# ---------------------------------------------------------------------------
# 4. Final Status
# ---------------------------------------------------------------------------
echo ""
log "=== Test Summary ==="
log "Variant: $TEST_VARIANT"
log "Type: $TEST_TYPE"
log "Execution Time: ${TEST_TIME}s"
log "Reports: $TEST_REPORTS_DIR"
log "Result: PASSED"
log "===================="

exit 0
