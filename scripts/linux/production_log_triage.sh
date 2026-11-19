#!/usr/bin/env bash
# Production log triage helper - read-only.
# Usage: bash production_log_triage.sh <log_file> [lookback_minutes]
# Requires: bash, grep, awk, date
# Does not restart services, modify logs, or expose environment variables.

set -Eeuo pipefail

usage() {
  echo "Usage: $0 <log_file> [lookback_minutes]" >&2
  exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage
LOG_FILE=$1
LOOKBACK_MINUTES=${2:-60}

[[ -f "$LOG_FILE" && -r "$LOG_FILE" ]] || {
  echo "ERROR: log file does not exist or is not readable: $LOG_FILE" >&2
  exit 2
}
[[ "$LOOKBACK_MINUTES" =~ ^[0-9]+$ ]] || usage
(( LOOKBACK_MINUTES > 0 )) || usage

# This script expects timestamps at the beginning of each log line in either
# YYYY-MM-DD HH:MM:SS or YYYY-MM-DDTHH:MM:SS format. Lines without a matching
# timestamp are still included in severity counts, but not time-filtered.
CUTOFF_TEXT=$(date -d "-$LOOKBACK_MINUTES minutes" '+%Y-%m-%d %H:%M:%S' 2>/dev/null) || {
  echo "ERROR: GNU-compatible date is required for lookback filtering." >&2
  exit 2
}

echo "=== Production Log Triage ==="
echo "File: $LOG_FILE"
echo "Lookback: $LOOKBACK_MINUTES minutes"
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

# Severity summary across the complete file. Case-insensitive matching.
awk '
{ line=tolower($0) }
 line ~ /fatal|critical/ { fatal++ }
 line ~ /error|ora-[0-9]{5}|exception/ { error++ }
 line ~ /warn(ing)?/ { warning++ }
END {
  printf "Fatal/Critical lines : %d\n", fatal
  printf "Error/Oracle lines   : %d\n", error
  printf "Warning lines        : %d\n", warning
}' "$LOG_FILE"

echo
echo "=== Recent error and warning lines (timestamp-filtered where parseable) ==="
awk -v cutoff="$CUTOFF_TEXT" '
{
  line = tolower($0)
  severity = (line ~ /fatal|critical|error|ora-[0-9]{5}|exception|warn(ing)?/)
  if (!severity) next

  timestamp = substr($0, 1, 19)
  gsub(/T/, " ", timestamp)
  command = "date -d \"" timestamp "\" +%s 2>/dev/null"
  parsed = (timestamp ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$/)
  if (parsed) {
    command | getline epoch
    close(command)
    if (epoch != "" && epoch < cutoff) next
  }
  print
}' "$LOG_FILE" | tail -n 100

echo
echo "=== Triage reminders ==="
echo "1. Correlate the timestamp with scheduler, deployment, and dependency events."
echo "2. Check whether the error is isolated or repeated across job/run IDs."
echo "3. Confirm business impact and SLA before assigning severity."
echo "4. Do not restart or rerun until partial-load state and idempotency are checked."
echo "5. Capture evidence and obtain the required approval before recovery."
