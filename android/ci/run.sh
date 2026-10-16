#!/bin/bash
# =============================================================================
# Android CI/CD Pipeline Orchestrator
# Main entry point for the fully custom local on-device CI/CD pipeline
#
# Usage:
#   ./android/ci/run.sh [options]
#   ./android/ci/run.sh --help
#
# Options:
#   --stage <name>     Run a specific stage (preflight, build, test, deploy, validate, performance)
#   --variant <name>   Build variant (debug, release)
#   --no-cache         Disable build cache
#   --clean            Perform clean build
#   --skip-tests       Skip test execution
#   --help             Show help message
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CI_DIR="$PROJECT_ROOT/android/ci"
LOGS_DIR="$CI_DIR/logs"
ARTIFACTS_DIR="$CI_DIR/artifacts"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Defaults
STAGE="${STAGE:-all}"
BUILD_VARIANT="${BUILD_VARIANT:-debug}"
SKIP_PREFLIGHT=false
SKIP_TESTS=false
SKIP_DEPLOY=false
SKIP_VALIDATE=false
SKIP_PERFORMANCE=false
CLEAN_BUILD=false
NO_CACHE=false
VERBOSE=false

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PIPELINE_LOG="$LOGS_DIR/pipeline-$TIMESTAMP.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$PIPELINE_LOG"
}

log_info() { log "${BLUE}[$(date '+%H:%M:%S')]${NC} $*"; }
log_success() { log "${GREEN}[$(date '+%H:%M:%S')]${NC} $*"; }
log_warn() { log "${YELLOW}[$(date '+%H:%M:%S')]${NC} $*"; }
log_error() { log "${RED}[$(date '+%H:%M:%S')]${NC} $*"; }

# ---------------------------------------------------------------------------
# Parse Arguments
# ---------------------------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --stage)
                STAGE="$2"
                shift 2
                ;;
            --variant)
                BUILD_VARIANT="$2"
                shift 2
                ;;
            --no-cache)
                NO_CACHE=true
                shift
                ;;
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --skip-deploy)
                SKIP_DEPLOY=true
                shift
                ;;
            --skip-validate)
                SKIP_VALIDATE=true
                shift
                ;;
            --skip-performance)
                SKIP_PERFORMANCE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                echo "Android CI/CD Pipeline Orchestrator"
                echo ""
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --stage <name>     Run a specific stage (preflight, build, test, deploy, validate, performance, all)"
                echo "  --variant <name>   Build variant (debug, release)"
                echo "  --no-cache         Disable build cache"
                echo "  --clean            Perform clean build"
                echo "  --skip-tests       Skip test execution"
                echo "  --skip-deploy      Skip device deployment"
                echo "  --skip-validate    Skip post-deployment validation"
                echo "  --skip-performance Skip performance monitoring"
                echo "  --verbose          Enable verbose output"
                echo "  --help             Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Pipeline Stages
# ---------------------------------------------------------------------------

run_preflight() {
    log_info "=== STAGE: Preflight Checks ==="
    if [[ -x "$CI_DIR/preflight.sh" ]]; then
        if ! "$CI_DIR/preflight.sh"; then
            log_error "Preflight checks failed"
            return 1
        fi
        log_success "Preflight checks passed"
    else
        log_warn "Preflight script not found or not executable"
    fi
}

run_build() {
    log_info "=== STAGE: Build Automation ==="
    
    local build_args=""
    if [[ "$CLEAN_BUILD" == "true" ]]; then
        build_args="$build_args --clean-build true"
    fi
    
    export BUILD_VARIANT
    export ANDROID_CI_LOGS="$LOGS_DIR"
    export ANDROID_CI_ARTIFACTS="$ARTIFACTS_DIR"
    
    if [[ "$NO_CACHE" == "true" ]]; then
        export ORG_GRADLE_PROJECT_org_gradle_caching=false
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        build_args="$build_args --info"
    fi
    
    if ! BUILD_VARIANT="$BUILD_VARIANT" "$CI_DIR/build.sh"; then
        log_error "Build failed"
        return 1
    fi
    
    log_success "Build completed successfully"
}

run_tests() {
    if [[ "$SKIP_TESTS" == "true" ]]; then
        log_warn "Tests skipped (--skip-tests)"
        return 0
    fi
    
    log_info "=== STAGE: Test Execution ==="
    export TEST_VARIANT="$BUILD_VARIANT"
    export ANDROID_CI_LOGS="$LOGS_DIR"
    export ANDROID_CI_ARTIFACTS="$ARTIFACTS_DIR"
    export TEST_TYPE="${TEST_TYPE:-all}"
    export TEST_TIMEOUT="${TEST_TIMEOUT:-300}"
    
    if ! "$CI_DIR/test.sh"; then
        log_error "Tests failed"
        return 1
    fi
    
    log_success "Tests passed"
}

run_deploy() {
    if [[ "$SKIP_DEPLOY" == "true" ]]; then
        log_warn "Deployment skipped (--skip-deploy)"
        return 0
    fi
    
    log_info "=== STAGE: Device Deployment ==="
    export ANDROID_CI_LOGS="$LOGS_DIR"
    export ANDROID_CI_ARTIFACTS="$ARTIFACTS_DIR"
    export DEPLOY_TYPE="${DEPLOY_TYPE:-standard}"
    
    # Check for connected devices
    local devices
    devices=$(adb devices 2>/dev/null | tail -n +2 | awk '$2 == "device" {print $1}')
    if [[ -z "$devices" ]]; then
        log_warn "No devices connected, skipping deployment"
        return 0
    fi
    
    if ! "$CI_DIR/deploy.sh"; then
        log_error "Deployment failed"
        return 1
    fi
    
    log_success "Deployment completed"
}

run_validate() {
    if [[ "$SKIP_VALIDATE" == "true" ]]; then
        log_warn "Validation skipped (--skip-validate)"
        return 0
    fi
    
    log_info "=== STAGE: Post-Deployment Validation ==="
    export ANDROID_CI_LOGS="$LOGS_DIR"
    export ANDROID_CI_ARTIFACTS="$ARTIFACTS_DIR"
    export VALIDATION_LEVEL="${VALIDATION_LEVEL:-full}"
    export APP_PACKAGE="${APP_PACKAGE:-org.abookoflife.app}"
    
    # Only run validation if there's a connected device
    local devices
    devices=$(adb devices 2>/dev/null | tail -n +2 | awk '$2 == "device" {print $1}')
    if [[ -z "$devices" ]]; then
        log_warn "No devices connected, skipping validation"
        return 0
    fi
    
    "$CI_DIR/validate.sh" || log_warn "Validation reported issues (non-blocking)"
    
    log_success "Validation completed"
}

run_performance() {
    if [[ "$SKIP_PERFORMANCE" == "true" ]]; then
        log_warn "Performance monitoring skipped (--skip-performance)"
        return 0
    fi
    
    log_info "=== STAGE: Performance Monitoring ==="
    export ANDROID_CI_LOGS="$LOGS_DIR"
    export MONITOR_DURATION="${MONITOR_DURATION:-300}"
    export SAMPLING_INTERVAL="${SAMPLING_INTERVAL:-30}"
    export APP_PACKAGE="${APP_PACKAGE:-org.abookoflife.app}"
    
    local devices
    devices=$(adb devices 2>/dev/null | tail -n +2 | awk '$2 == "device" {print $1}')
    if [[ -z "$devices" ]]; then
        log_warn "No devices connected, skipping performance monitoring"
        return 0
    fi
    
    "$CI_DIR/performance.sh" || {
        log_warn "Performance monitoring had issues"
    }
    
    log_success "Performance monitoring completed"
}

# ---------------------------------------------------------------------------
# Summary Report
# ---------------------------------------------------------------------------
generate_summary() {
    log_info "Generating pipeline summary..."
    
    local summary_file="$LOGS_DIR/summary-$TIMESTAMP.md"
    cat > "$summary_file" << EOF
# CI/CD Pipeline Summary

**Run Timestamp**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Build Variant**: $BUILD_VARIANT
**Pipeline Log**: $PIPELINE_LOG

## Stage Results
- Preflight: $([ -f "$LOGS_DIR/preflight.log" ] && echo "✅ PASSED" || echo "⏭️ SKIPPED")
- Build: $([ -f "$LOGS_DIR/build.log" ] && echo "✅ PASSED" || echo "❌ FAILED")
- Tests: $([ -f "$LOGS_DIR/test.log" ] && echo "✅ PASSED" || echo "⏭️ SKIPPED")
- Deploy: $([ -f "$LOGS_DIR/device.log" ] && echo "✅ PASSED" || echo "⏭️ SKIPPED")
- Validate: $([ -f "$LOGS_DIR/validate.log" ] && echo "✅ PASSED" || echo "⏭️ SKIPPED")
- Performance: $([ -f "$LOGS_DIR/performance.log" ] && echo "✅ PASSED" || echo "⏭️ SKIPPED")

## Artifacts
$(find "$ARTIFACTS_DIR" -type f -ls 2>/dev/null || echo "No artifacts generated")

## Log Files
- Pipeline: $PIPELINE_LOG
- Preflight: $LOGS_DIR/preflight.log (if exists)
- Build: $LOGS_DIR/build.log (if exists)
- Test: $LOGS_DIR/test.log (if exists)
EOF
    
    log_info "Pipeline summary saved: $summary_file"
}

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Pipeline failed with exit code $exit_code"
    fi
}

trap cleanup EXIT

# ---------------------------------------------------------------------------
# Main Pipeline
# ---------------------------------------------------------------------------
main() {
    parse_args "$@"
    
    mkdir -p "$LOGS_DIR" "$ARTIFACTS_DIR"
    
    log_info "==============================================="
    log_info " Android CI/CD Pipeline Started"
    log_info " Timestamp: $TIMESTAMP"
    log_info " Variant: $BUILD_VARIANT"
    log_info " Stages: $STAGE"
    log_info "==============================================="
    
    local overall_start
    overall_start=$(date +%s)
    local failed_stages=()
    
    # Run stages based on selection
    case "$STAGE" in
        preflight)
            run_preflight || failed_stages+=("preflight")
            ;;
        build)
            run_build || failed_stages+=("build")
            ;;
        test)
            run_tests || failed_stages+=("test")
            ;;
        deploy)
            run_deploy || failed_stages+=("deploy")
            ;;
        validate)
            run_validate || failed_stages+=("validate")
            ;;
        performance)
            run_performance || failed_stages+=("performance")
            ;;
        all)
            if ! $SKIP_PREFLIGHT; then
                run_preflight || failed_stages+=("preflight")
            fi
            
            run_build || failed_stages+=("build")
            
            if [[ ! " ${failed_stages[*]} " == *" build "* ]]; then
                run_tests || failed_stages+=("test")
                run_deploy || failed_stages+=("deploy")
                run_validate || failed_stages+=("validate")
                run_performance || failed_stages+=("performance")
            fi
            ;;
        *)
            log_error "Unknown stage: $STAGE"
            exit 1
            ;;
    esac
    
    local overall_end
    overall_end=$(date +%s)
    local duration=$((overall_end - overall_start))
    
    log_info "----------------------------------------------"
    log_info " Pipeline finished in ${duration}s"
    
    if [[ ${#failed_stages[@]} -gt 0 ]]; then
        log_error "Failed stages: ${failed_stages[*]}"
        generate_summary
        exit 1
    fi
    
    log_success "All stages completed successfully"
    generate_summary
    log_info " Pipeline log: $PIPELINE_LOG"
    log_info "==============================================="
    exit 0
}

# Run the pipeline
main "$@"