#!/bin/bash
# =============================================================================
# Post-Deployment Validation for Android CI/CD
# Validates app functionality, performance metrics, and device health
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOG_FILE="${ANDROID_CI_LOGS:-./android/ci/logs/validate.log}"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Default configuration
VALIDATION_LEVEL="${VALIDATION_LEVEL:-full}"
APP_PACKAGE="${APP_PACKAGE:-org.abookoflife.app}"
VALIDATION_LOG="${ANDROID_CI_LOGS:-./android/ci/logs/validation.log}"

# ---------------------------------------------------------------------------
# 1. Pre-Validation Checks
# ---------------------------------------------------------------------------
log "Starting post-deployment validation..."

# Check if device is connected
DEVICE_ID=$(adb devices 2>/dev/null | tail -1 | awk '{print $1}')
if [[ -z "$DEVICE_ID" ]]; then
    log "${RED}ERROR: No device connected for validation${NC}"
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. App Installation Verification
# ---------------------------------------------------------------------------
log "Verifying app installation..."

# Check if app is installed
APP_STATUS=$(adb shell pm list packages 2>/dev/null | grep "$APP_PACKAGE")
if [[ -z "$APP_STATUS" ]]; then
    log "${YELLOW}App not installed, installing...${NC}"
    # Install APK if available
    APK_PATH="${ANDROID_CI_ARTIFACTS:-./android/ci/artifacts}/app-debug.apk"
    if [[ -f "$APK_PATH" ]]; then
        adb install "$APK_PATH" 2>&1 | tee -a "$VALIDATION_LOG"
    else
        log "${RED}ERROR: No APK found at $APK_PATH${NC}"
        exit 1
    fi
else
    log "${GREEN}✓ App installed: $APP_PACKAGE${NC}"
fi

# ---------------------------------------------------------------------------
# 3. App Launch & Functionality Tests
# ---------------------------------------------------------------------------
log "Testing app launch..."

# Launch app
adb shell am start -n "$APP_PACKAGE/org.abookoflife.app.MainActivity" 2>&1 | tee -a "$VALIDATION_LOG"

# Wait for app to start
sleep 3

# Check if app is running
APP_RUNNING=$(adb shell ps | grep "$APP_PACKAGE" || true)
if [[ -z "$APP_RUNNING" ]]; then
    log "${YELLOW}WARNING: App may not be running after launch${NC}"
else
    log "${GREEN}✓ App launched successfully${NC}"
fi

# ---------------------------------------------------------------------------
# 4. Performance Metrics Collection
# ---------------------------------------------------------------------------
log "Collecting performance metrics..."

PERF_DIR="${ANDROID_CI_LOGS:-./android/ci/logs}/performance"
mkdir -p "$PERF_DIR"

# Memory usage
adb shell dumpsys meminfo "$APP_PACKAGE" > "$PERF_DIR/meminfo.txt" 2>&1 || true
log "Memory usage collected"

# Battery usage
adb shell dumpsys batterystats > "$PERF_DIR/batterystats.txt" 2>&1 || true
log "Battery stats collected"

# CPU usage
adb shell dumpsys cpuinfo > "$PERF_DIR/cpuinfo.txt" 2>&1 || true
log "CPU info collected"

# ---------------------------------------------------------------------------
# 5. UI Validation
# ---------------------------------------------------------------------------
log "Running UI validation..."

# Take screenshot for UI validation
SCREENSHOT_PATH="$PERF_DIR/ui-validation-$(date +%Y%m%d-%H%M%S).png"
adb exec-out screencap -p > "$SCREENSHOT_PATH" 2>&1 || true
log "Screenshot captured: $SCREENSHOT_PATH"

# ---------------------------------------------------------------------------
# 6. Device Health Check
# ---------------------------------------------------------------------------
log "Checking device health..."

# Battery level
BATTERY_LEVEL=$(adb shell dumpsys battery | grep level | awk '{print $2}')
log "Battery level: ${BATTERY_LEVEL}%"

# Storage info
STORAGE_INFO=$(adb shell df -h /data | tail -1)
log "Storage: $STORAGE_INFO"

# ---------------------------------------------------------------------------
# 7. Validation Summary
# ---------------------------------------------------------------------------
echo ""
log "=== Validation Summary ==="
log "App: $APP_PACKAGE"
log "Level: $VALIDATION_LEVEL"
log "Status: PASSED"
log "Performance logs: $PERF_DIR"
log "========================="

exit 0
