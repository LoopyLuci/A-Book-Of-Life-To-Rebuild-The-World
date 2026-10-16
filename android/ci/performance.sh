#!/bin/bash
# =============================================================================
# Performance Monitoring for Android CI/CD
# Monitors app performance, device health, and system metrics
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOG_FILE="${ANDROID_CI_LOGS:-./android/ci/logs/performance.log}"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Default configuration
APP_PACKAGE="${APP_PACKAGE:-org.abookoflife.app}"
PERFORMANCE_DIR="${ANDROID_CI_LOGS:-./android/ci/logs}/performance"
MONITOR_DURATION="${MONITOR_DURATION:-300}"  # 5 minutes
SAMPLING_INTERVAL="${SAMPLING_INTERVAL:-30}"  # 30 seconds

# Create performance directory
mkdir -p "$PERFORMANCE_DIR"

# ---------------------------------------------------------------------------
# 1. Start Performance Monitoring
# ---------------------------------------------------------------------------
log "Starting performance monitoring for ${MONITOR_DURATION}s..."

# Initialize metrics file
METRICS_FILE="$PERFORMANCE_DIR/performance-$(date +%Y%m%d-%H%M%S).csv"

echo "timestamp,app_memory,system_memory,battery_level,storage_free,network_rx,network_tx" > "$METRICS_FILE"

# ---------------------------------------------------------------------------
# 2. Continuous Monitoring
# ---------------------------------------------------------------------------
START_TIME=$(date +%s)
END_TIME=$((START_TIME + MONITOR_DURATION))

log "Monitoring metrics at ${SAMPLING_INTERVAL}s intervals..."

while [[ $(date +%s) -lt $END_TIME ]]; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get memory metrics
    APP_MEMORY_KB=$(adb shell dumpsys meminfo "$APP_PACKAGE" | grep "Native Heap" | awk '{print $2}' 2>/dev/null || echo "0")
    SYSTEM_MEMORY_KB=$(adb shell cat /proc/meminfo 2>/dev/null | grep MemTotal | awk '{print $2}')
    
    # Get battery metrics
    BATTERY_LEVEL=$(adb shell dumpsys battery | grep level | awk '{print $2}' 2>/dev/null || echo "0")
    
    # Get storage metrics
    STORAGE_FREE_KB=$(adb shell df -k /data | tail -1 | awk '{print $4}' 2>/dev/null || echo "0")
    
    # Get network metrics
    NETWORK_RX_KB=$(adb shell cat /proc/net/dev 2>/dev/null | grep "eth0" | awk '{print $2}' | sed 's/://g' || echo "0")
    NETWORK_TX_KB=$(adb shell cat /proc/net/dev 2>/dev/null | grep "eth0" | awk '{print $10}' | sed 's/://g' || echo "0")
    
    # Write metrics
    echo "${TIMESTAMP},${APP_MEMORY_KB},${SYSTEM_MEMORY_KB},${BATTERY_LEVEL},${STORAGE_FREE_KB},${NETWORK_RX_KB},${NETWORK_TX_KB}" >> "$METRICS_FILE"
    
    log "Metrics collected: App Memory=${APP_MEMORY_KB}KB, Battery=${BATTERY_LEVEL}%, Storage=${STORAGE_FREE_KB}KB"
    
    sleep $SAMPLING_INTERVAL
done

# ---------------------------------------------------------------------------
# 3. Performance Analysis
# ---------------------------------------------------------------------------
log "Analyzing performance metrics..."

# Parse and analyze metrics
ANALYSIS_FILE="$PERFORMANCE_DIR/performance-analysis-$(date +%Y%m%d-%H%M%S).txt"

# Calculate averages
TOTAL_RECORDS=$(wc -l < "$METRICS_FILE")
if [[ $TOTAL_RECORDS -gt 0 ]]; then
    TOTAL_RECORDS=$((TOTAL_RECORDS - 1))  # Subtract header
    if [[ $TOTAL_RECORDS -gt 0 ]]; then
        AVG_APP_MEMORY=$(awk -F',' 'NR>1 {sum+=$2} END {if(NR>1) print int(sum/NR)}' "$METRICS_FILE")
        AVG_BATTERY=$(awk -F',' 'NR>1 {sum+=$4} END {if(NR>1) print int(sum/NR)}' "$METRICS_FILE")
        AVG_STORAGE=$(awk -F',' 'NR>1 {sum+=$5} END {if(NR>1) print int(sum/NR)}' "$METRICS_FILE")
        
        cat > "$ANALYSIS_FILE" << EOF
Performance Analysis Summary
===========================
Collected Metrics: $TOTAL_RECORDS samples
Monitoring Duration: ${MONITOR_DURATION}s
Average Sampling: ${SAMPLING_INTERVAL}s

Memory Usage:
- Average App Memory: ${AVG_APP_MEMORY} KB
- Average System Memory: $(awk -F',' 'NR>1 {sum+=$3} END {if(NR>1) print int(sum/NR)}' "$METRICS_FILE") KB

Battery Health:
- Average Battery Level: ${AVG_BATTERY}%
- Starting Battery: $(awk -F',' 'NR==2 {print $4}' "$METRICS_FILE")%
- Ending Battery: $(tail -1 "$METRICS_FILE" | cut -d',' -f4)%n

Storage Usage:
- Average Free Storage: ${AVG_STORAGE} KB

Network Activity:
- Average Network RX: $(awk -F',' 'NR>1 {sum+=$6} END {if(NR>1) print int(sum/NR)}' "$METRICS_FILE") KB
- Average Network TX: $(awk -F',' 'NR>1 {sum+=$7} END {if(NR>1) print int(sum/NR)}' "$METRICS_FILE") KB
EOF
        
        log "Performance analysis saved: $ANALYSIS_FILE"
    fi
fi

# ---------------------------------------------------------------------------
# 4. Performance Report
# ---------------------------------------------------------------------------
echo ""
log "=== Performance Monitoring Summary ==="
log "Duration: ${MONITOR_DURATION}s"
log "Samples: $TOTAL_RECORDS"
log "Data File: $METRICS_FILE"
log "Analysis File: $ANALYSIS_FILE"
log "Status: COMPLETED"
log "===================================="

exit 0
