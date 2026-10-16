#!/bin/bash
# =============================================================================
# Android Build Automation with Caching & Incremental Builds
# Handles build process, signing, and artifact management
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOG_FILE="${ANDROID_CI_LOGS:-./android/ci/logs/build.log}"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Default configuration
BUILD_VARIANT="${BUILD_VARIANT:-debug}"
BUILD_ARTIFACTS_DIR="${ANDROID_CI_ARTIFACTS:-./android/ci/artifacts}"
BUILD_TYPE="apk"  # Can be apk, aab, bundle
SIGNING_CONFIG="${SIGNING_CONFIG:-debug}"  # debug, release, or custom

# Create artifacts directory
mkdir -p "$BUILD_ARTIFACTS_DIR"

# ---------------------------------------------------------------------------
# 1. Clean Build if needed
# ---------------------------------------------------------------------------
if [[ "${CLEAN_BUILD:-false}" == "true" ]]; then
    log "Performing clean build (--clean)"
    ./android/gradlew clean
fi

# ---------------------------------------------------------------------------
# 2. Configure Gradle caching
# ---------------------------------------------------------------------------
log "Configuring Gradle caching..."

# Check if we have Gradle cache directory
mkdir -p "$HOME/.gradle/caches"

# Configure Gradle properties for better caching
cat > gradle.properties << EOF
org.gradle.daemon=true
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
EOF

# ---------------------------------------------------------------------------
# 3. Build Configuration
# ---------------------------------------------------------------------------
log "Starting build process for variant: $BUILD_VARIANT"

BUILD_CMD="./android/gradlew"
if [[ "$BUILD_VARIANT" == "debug" ]]; then
    BUILD_CMD="$BUILD_CMD assembleDebug"
elif [[ "$BUILD_VARIANT" == "release" ]]; then
    BUILD_CMD="$BUILD_CMD assembleRelease"
else
    BUILD_CMD="$BUILD_CMD assemble$BUILD_VARIANT"
fi

# Add build type if specified
if [[ "$BUILD_TYPE" == "aab" ]]; then
    BUILD_CMD="${BUILD_CMD/assemble/bundle}"
elif [[ "$BUILD_TYPE" == "bundle" ]]; then
    BUILD_CMD="${BUILD_CMD/assemble/bundle}"
fi

# Add signing configuration for release builds
if [[ "$BUILD_VARIANT" == "release" ]]; then
    if [[ -z "$KEYSTORE_PATH" ]] || [[ -z "$KEYSTORE_PASSWORD" ]] || [[ -z "$KEY_ALIAS" ]] || [[ -z "$KEY_PASSWORD" ]]; then
        log "${YELLOW}WARNING: Release build requested but no signing credentials provided (using debug signing)${NC}"
    else
        BUILD_CMD="$BUILD_CMD -Pandroid.injected.signing.store.file=$KEYSTORE_PATH"
        BUILD_CMD="$BUILD_CMD -Pandroid.injected.signing.store.password=$KEYSTORE_PASSWORD"
        BUILD_CMD="$BUILD_CMD -Pandroid.injected.signing.key.alias=$KEY_ALIAS"
        BUILD_CMD="$BUILD_CMD -Pandroid.injected.signing.key.password=$KEY_PASSWORD"
    fi
fi

# ---------------------------------------------------------------------------
# 4. Execute Build
# ---------------------------------------------------------------------------
log "Executing: $BUILD_CMD"
START_TIME=$(date +%s)

if ! $BUILD_CMD --build-cache --parallel --configure-on-demand; then
    log "${RED}ERROR: Build failed${NC}"
    # Capture build logs for debugging
    cp -r android/app/build/outputs/logs/* "$BUILD_ARTIFACTS_DIR/" 2>/dev/null || true
    exit 1
fi

BUILD_TIME=$(( $(date +%s) - START_TIME ))
log "${GREEN}✓ Build completed successfully in ${BUILD_TIME}s${NC}"

# ---------------------------------------------------------------------------
# 5. Post-build artifact collection
# ---------------------------------------------------------------------------
log "Collecting build artifacts..."

# Find generated APK/AAB files
if [[ "$BUILD_VARIANT" == "debug" ]]; then
    APK_PATTERN="android/app/build/outputs/apk/debug/app-debug.apk"
    AAB_PATTERN="android/app/build/outputs/bundle/debug/app-debug.aab"
elif [[ "$BUILD_VARIANT" == "release" ]]; then
    APK_PATTERN="android/app/build/outputs/apk/release/app-release.apk"
    AAB_PATTERN="android/app/build/outputs/bundle/release/app-release.aab"
else
    APK_PATTERN="android/app/build/outputs/apk/*/${BUILD_VARIANT}/app-${BUILD_VARIANT}.apk"
    AAB_PATTERN="android/app/build/outputs/bundle/*/${BUILD_VARIANT}/app-${BUILD_VARIANT}.aab"
fi

# Copy artifacts to artifacts directory
if [[ "$BUILD_TYPE" == "aab" ]] || [[ "$BUILD_TYPE" == "bundle" ]]; then
    if [[ -f "$AAB_PATTERN" ]]; then
        cp "$AAB_PATTERN" "$BUILD_ARTIFACTS_DIR/app-${BUILD_VARIANT}.aab"
        log "${GREEN}✓ AAB artifact copied: ${BUILD_ARTIFACTS_DIR}/app-${BUILD_VARIANT}.aab${NC}"
    else
        log "${YELLOW}WARNING: AAB artifact not found at $AAB_PATTERN${NC}"
    fi
else
    if [[ -f "$APK_PATTERN" ]]; then
        cp "$APK_PATTERN" "$BUILD_ARTIFACTS_DIR/app-${BUILD_VARIANT}.apk"
        log "${GREEN}✓ APK artifact copied: ${BUILD_ARTIFACTS_DIR}/app-${BUILD_VARIANT}.apk${NC}"
    else
        log "${YELLOW}WARNING: APK artifact not found at $APK_PATTERN${NC}"
    fi
fi

# Copy build logs and reports
mkdir -p "$BUILD_ARTIFACTS_DIR/reports"
cp -r android/app/build/reports/* "$BUILD_ARTIFACTS_DIR/reports/" 2>/dev/null || true
cp -r android/app/build/outputs/logs/* "$BUILD_ARTIFACTS_DIR/" 2>/dev/null || true

# ---------------------------------------------------------------------------
# 6. Final Status
# ---------------------------------------------------------------------------
echo ""
log "=== Build Summary ==="
log "Variant: $BUILD_VARIANT"
log "Build Type: $BUILD_TYPE"
log "Build Time: ${BUILD_TIME}s"
log "Artifacts: $BUILD_ARTIFACTS_DIR"
log "Signing: $SIGNING_CONFIG"
log "Cache: Enabled"
log "====================="

exit 0
