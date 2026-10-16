#!/bin/bash
# =============================================================================
# Utility Functions for Android CI/CD Pipeline
# Shared functions used across all CI/CD scripts
# =============================================================================

# Exit if any command fails
set -euo pipefail

# ---------------------------------------------------------------------------
# 1. Logging Functions
# ---------------------------------------------------------------------------
log_info() {
    local message="$1"
    echo -e "[\e[34mINFO\e[0m] $(date '+%Y-%m-%d %H:%M:%S') $message"
}

log_warn() {
    local message="$1"
    echo -e "[\e[33mWARN\e[0m] $(date '+%Y-%m-%d %H:%M:%S') $message" >&2
}

log_error() {
    local message="$1"
    echo -e "[\e[31mERROR\e[0m] $(date '+%Y-%m-%d %H:%M:%S') $message" >&2
}

log_success() {
    local message="$1"
    echo -e "[\e[32mSUCCESS\e[0m] $(date '+%Y-%m-%d %H:%M:%S') $message"
}

# ---------------------------------------------------------------------------
# 2. Device Detection Functions
# ---------------------------------------------------------------------------
get_connected_devices() {
    adb devices 2>/dev/null | tail -n +2 | awk '$2 == "device" {print $1}'
}

is_device_connected() {
    local device_count
    device_count=$(get_connected_devices | wc -l)
    [[ $device_count -gt 0 ]]
}

wait_for_device() {
    local timeout="${1:-30}"
    local start_time
    start_time=$(date +%s)
    
    while [[ $(date +%s) -lt $((start_time + timeout)) ]]; do
        if is_device_connected; then
            log_info "Device connected"
            return 0
        fi
        sleep 1
    done
    
    log_error "Timeout waiting for device connection (${timeout}s)"
    return 1
}

# ---------------------------------------------------------------------------
# 3. Build & Deployment Functions
# ---------------------------------------------------------------------------
get_build_artifact() {
    local variant="${1:-debug}"
    local build_type="${2:-apk}"
    
    if [[ "$build_type" == "aab" ]] || [[ "$build_type" == "bundle" ]]; then
        echo "android/app/build/outputs/bundle/${variant}/app-${variant}.aab"
    else
        echo "android/app/build/outputs/apk/${variant}/app-${variant}.apk"
    fi
}

get_latest_build_artifact() {
    local pattern="${1}"
    ls -1t $pattern 2>/dev/null | head -1
}

verify_signature() {
    local apk_path="$1"
    if [[ -f "$apk_path" ]]; then
        log_info "Verifying APK signature..."
        # Use apksigner if available
        if command -v apksigner >/dev/null 2>&1; then
            apksigner verify "$apk_path" 2>&1
            return $?
        else
            log_warn "apksigner not found, skipping signature verification"
            return 0
        fi
    else
        log_error "APK not found: $apk_path"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# 4. Test Functions
# ---------------------------------------------------------------------------
run_unit_tests() {
    local test_pattern="${1:-'*'}"
    log_info "Running unit tests with pattern: $test_pattern"
    ./android/gradlew testDebugUnitTest --tests "$test_pattern"
}

run_instrumentation_tests() {
    local test_pattern="${1:-'*'}"
    log_info "Running instrumentation tests with pattern: $test_pattern"
    ./android/gradlew connectedDebugAndroidTest --tests "$test_pattern"
}

run_ui_tests() {
    log_info "Running UI tests (not implemented - placeholder)"
    # Would use Espresso or UIAutomator in a real implementation
    return 0
}

# ---------------------------------------------------------------------------
# 5. Configuration Functions
# ---------------------------------------------------------------------------
load_config() {
    local config_file="${1:-./android/ci/config.yaml}"
    if [[ -f "$config_file" ]]; then
        log_info "Loading configuration from: $config_file"
        # Simple YAML parsing for basic key:value pairs
        while IFS=':' read -r key value; do
            # Trim whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            # Skip comments and empty lines
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$value" ]] && continue
            # Export as environment variable
            export "${key^^}"="$value"
        done < <(grep -v '^[[:space:]]*#' "$config_file" | grep -v '^[[:space:]]*$')
    else
        log_warn "Configuration file not found: $config_file"
    fi
}

# ---------------------------------------------------------------------------
# 6. Artifact Management Functions
# ---------------------------------------------------------------------------
archive_artifact() {
    local source_path="$1"
    local artifact_name="$2"
    local archive_dir="${3:-./android/ci/artifacts}"
    
    mkdir -p "$archive_dir"
    if [[ -f "$source_path" ]]; then
        cp "$source_path" "${archive_dir}/${artifact_name}"
        log_success "Archived artifact: ${artifact_name}"
    else
        log_error "Source artifact not found: $source_path"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# 7. Health Check Functions
# ---------------------------------------------------------------------------
check_environment() {
    local checks=("java" "gradle" "adb" "fastboot" "git" "python3")
    local failed=0
    
    log_info "Checking environment prerequisites..."
    for cmd in "${checks[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Missing required command: $cmd"
            ((failed++))
        fi
    done
    
    return $failed
}

check_disk_space() {
    local min_gb="${1:-5}"
    local available_gb
    available_gb=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    
    if [[ $available_gb -lt $min_gb ]]; then
        log_warn "Low disk space: ${available_gb}GB available (minimum ${min_gb}GB required)"
        return 1
    fi
    
    log_info "Disk space OK: ${available_gb}GB available"
    return 0
}

# ---------------------------------------------------------------------------
# 8. Retry Logic
# ---------------------------------------------------------------------------
retry_command() {
    local max_attempts="${1:-3}"
    local delay="${2:-5}"
    local command="${@:3}"
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Executing command (attempt $attempt/$max_attempts): $command"
        if eval "$command"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Command failed, retrying in ${delay}s..."
            sleep $delay
        fi
        
        ((attempt++))
    done
    
    log_error "Command failed after $max_attempts attempts"
    return 1
}

# ---------------------------------------------------------------------------
# 9. Cleanup Functions
# ---------------------------------------------------------------------------
cleanup_old_artifacts() {
    local artifact_dir="${1:-./android/ci/artifacts}"
    local max_age_days="${2:-7}"
    
    log_info "Cleaning up artifacts older than $max_age_days days from $artifact_dir"
    find "$artifact_dir" -type f -mtime +"$max_age_days" -delete
    log_success "Old artifacts cleaned up"
}

# ---------------------------------------------------------------------------
# 10. Exit Handler
# ---------------------------------------------------------------------------
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Pipeline exited with code $exit_code"
    else
        log_info "Pipeline completed successfully"
    fi
    
    # Optional: Add any cleanup tasks here
    return $exit_code
}

trap cleanup_on_exit EXIT

# Make functions available to sourced scripts
export -f log_info log_warn log_error log_success
export -f get_connected_devices is_device_connected wait_for_device
export -f get_build_artifact get_latest_build_artifact verify_signature
export -f run_unit_tests run_instrumentation_tests run_ui_tests
export -f load_config archive_artifact check_environment check_disk_space
export -f retry_command cleanup_old_artifacts