#!/usr/bin/env bash
#
# probe_medusa_api.sh
#
# Probes a set of Medusa API endpoints with curl, records the HTTP status
# code for each, and prints a summary table.
#
# Usage:
#   ./probe_medusa_api.sh [BASE_URL]
#
# Example:
#   ./probe_medusa_api.sh http://localhost:9000
#
# If BASE_URL is omitted, it defaults to http://localhost:9000.
# You can also set it via the MEDUSA_BASE_URL environment variable.
#
# Optional: set MEDUSA_API_TOKEN to send an Authorization: Bearer header
# (useful for /admin endpoints that require auth).

set -uo pipefail

BASE_URL="${1:-${MEDUSA_BASE_URL:-http://localhost:9000}}"
BASE_URL="${BASE_URL%/}"  # strip trailing slash if present

# Endpoints to probe
ENDPOINTS=(
  "/health"
  "/store/products"
  "/store/carts"
  "/store/customers"
  "/store/orders"
  "/admin/products"
)

# Timeout settings (seconds)
CONNECT_TIMEOUT=5
MAX_TIME=15
MEDUSA_PUBLISHABLE_KEY="pk_21f0a6a3478f8b346c835c4cf820691b8481f9118bcc3060edf5a2cc8d21d52c"

# Curl auth header (optional)
AUTH_HEADER=()
if [[ -n "${MEDUSA_API_TOKEN:-}" ]]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${MEDUSA_API_TOKEN}")
fi
if [[ -n "${MEDUSA_PUBLISHABLE_KEY:-}" ]]; then
  AUTH_HEADER+=(-H "x-publishable-api-key: ${MEDUSA_PUBLISHABLE_KEY}")
fi
# Arrays to hold results
declare -a RESULT_ENDPOINT
declare -a RESULT_STATUS
declare -a RESULT_TIME
declare -a RESULT_NOTE

echo "Probing Medusa API at: ${BASE_URL}"
echo "----------------------------------------"

for endpoint in "${ENDPOINTS[@]}"; do
  url="${BASE_URL}${endpoint}"

  # -s: silent, -o /dev/null: discard body, -w: print status code and time
  # --connect-timeout / --max-time: avoid hanging on unreachable hosts
  response=$(curl -s -o /dev/null \
    --connect-timeout "${CONNECT_TIMEOUT}" \
    --max-time "${MAX_TIME}" \
    -w "%{http_code} %{time_total}" \
    "${AUTH_HEADER[@]}" \
    "${url}")
  curl_exit=$?

  if [[ $curl_exit -ne 0 ]]; then
    status="ERR"
    time_total="-"
    note="curl exit code ${curl_exit} (connection failed / timeout)"
  else
    status=$(echo "$response" | awk '{print $1}')
    time_total=$(echo "$response" | awk '{print $2}')

    case "$status" in
      2*) note="OK" ;;
      3*) note="Redirect" ;;
      401) note="Unauthorized (auth required)" ;;
      403) note="Forbidden" ;;
      404) note="Not Found" ;;
      4*) note="Client Error" ;;
      5*) note="Server Error" ;;
      *)  note="Unknown" ;;
    esac
  fi

  RESULT_ENDPOINT+=("$endpoint")
  RESULT_STATUS+=("$status")
  RESULT_TIME+=("${time_total}s")
  RESULT_NOTE+=("$note")
done

# Print summary table
printf "\n%-22s %-8s %-10s %-30s\n" "ENDPOINT" "STATUS" "TIME" "NOTE"
printf "%-22s %-8s %-10s %-30s\n" "--------" "------" "----" "----"
for i in "${!RESULT_ENDPOINT[@]}"; do
  printf "%-22s %-8s %-10s %-30s\n" \
    "${RESULT_ENDPOINT[$i]}" \
    "${RESULT_STATUS[$i]}" \
    "${RESULT_TIME[$i]}" \
    "${RESULT_NOTE[$i]}"
done

echo ""
