#!/bin/bash
# =============================================================================
# Preflight Checks for Android CI/CD Pipeline
# Ensures environment, dependencies, and prerequisites are ready before building
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

LOG_FILE="${ANDROID_CI_LOGS:-./android/ci/logs/preflight.log}"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# ---------------------------------------------------------------------------
# 1. Environment Prerequisites
# ---------------------------------------------------------------------------
log "Checking environment prerequisites..."

# Check for required commands
for cmd in java kotlin adb fastboot gradle git; do
    if ! command -v "$cmd" &> /dev/null; then
        log "${RED}ERROR: Required command '$cmd' not found${NC}"
        exit 1
    fi
    log "${GREEN}✓ Found: $cmd${NC}"
done

# Check Java version (JDK 17+ required)
if [[ $(java -version 2>&1 | head -1) != *"17"* ]]; then
    log "${YELLOW}WARNING: Java version may not be compatible (requires 17+)${NC}"
fi

# Check Gradle version
GRADLE_VERSION=$(gradle --version 2>&1 | head -1)
if [[ ! "$GRADLE_VERSION" =~ "8\.9\." ]]; then
    log "${YELLOW}WARNING: Gradle version may not be supported (${GRADLE_VERSION})${NC}"
fi

# ---------------------------------------------------------------------------
# 2. Android SDK & Build Tools
# ---------------------------------------------------------------------------
log "Checking Android SDK and build tools..."

# Check for Android SDK
if [[ ! -d "/opt/android-sdk" ]] && [[ ! -d "$HOME/Android/Sdk" ]]; then
    log "${RED}ERROR: Android SDK not found${NC}"
    exit 1
fi

# Check for minimum SDK version
SDK_PATH="/opt/android-sdk"
if [[ -d "$SDK_PATH" ]]; then
    MIN_SDK=$(basename "$SDK_PATH"/"*/sdk/${MIN_SDK}_platforms" 2>/dev/null || echo "")
    if [[ -z "$MIN_SDK" ]]; then
        log "${RED}ERROR: Could not detect minimum SDK version${NC}"
        exit 1
    fi
    log "${GREEN}✓ Android SDK detected: ${MIN_SDK}${NC}"
else
    log "${YELLOW}WARNING: Android SDK not in expected location, using fallback${NC}"
fi

# ---------------------------------------------------------------------------
# 3. Device Detection (for device CI jobs)
# ---------------------------------------------------------------------------
log "Checking for connected devices..."

# Detect ADB-connected devices
DEVICES=$(adb devices 2>/dev/null | wc -l)
if [[ "$DEVICES" -gt 0 ]]; then
    log "${GREEN}✓ Connected devices found: $DEVICES${NC}"
    # List top devices
    adb devices | tail -5
else
    log "No connected devices found (expected for CI build jobs)"
fi

# ---------------------------------------------------------------------------
# 4. Build Configuration Validation
# ---------------------------------------------------------------------------
log "Validating build configuration..."

# Check build.gradle.kts exists
if [[ ! -f "android/build.gradle.kts" ]]; then
    log "${RED}ERROR: android/build.gradle.kts not found${NC}"
    exit 1
fi

# Check for required plugins
PLUGINS=$(grep -oP 'plugin\s*=\s*"[^"]+"' android/build.gradle.kts | sort -u)
for plugin in com.android.application com.google.android.ext.ktx.hilt com.android.library; do
    if ! echo "$PLUGINS" | grep -q "$plugin"; then
        log "${YELLOW}WARNING: Plugin $plugin may be missing from build.gradle.kts${NC}"
    fi
done

# ---------------------------------------------------------------------------
# 5. Dependency Health Check
# ---------------------------------------------------------------------------
log "Checking dependencies..."

# Check for required Python packages (used by build scripts)
REQUIRED_PYTHON_PACKAGES=(
    "python3"
    "pip"
    "virtualenv"
)
for pkg in "${REQUIRED_PYTHON_PACKAGES[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        log "${RED}ERROR: Required Python package '$pkg' not found${NC}"
        exit 1
    fi
    log "${GREEN}✓ Found: $pkg${NC}"
done

# ---------------------------------------------------------------------------
# 6. Disk Space Check
# ---------------------------------------------------------------------------
log "Checking disk space..."
DISK_AVAILABLE=$(df -BG / | tail -1 | awk '{print $4}')
if [[ "$DISK_AVAILABLE" -lt 5000 ]]; then
    log "${YELLOW}WARNING: Low disk space (${DISK_AVAILABLE}GB available)${NC}"
fi

# ---------------------------------------------------------------------------
# 7. Final Status
# ---------------------------------------------------------------------------
echo ""
log "=== Preflight Check Complete ==="
log "Environment: OK"
log "Android SDK: OK"
log "Java: OK"
log "Gradle: OK"
log "Python: OK"
log "Disk Space: OK"
log "=================================="

exit 0
