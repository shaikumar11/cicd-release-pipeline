#!/usr/bin/env bash
# Usage: healthcheck.sh <port> [retries] [delay_seconds]
# Exit 0 when /health returns HTTP 200, 1 otherwise.
set -euo pipefail
PORT="${1:?port required}"
RETRIES="${2:-10}"
DELAY="${3:-1}"
code=""

for i in $(seq 1 "$RETRIES"); do
  code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/health" || true)"
  if [ "$code" = "200" ]; then
    echo "healthy (attempt $i)"
    exit 0
  fi
  sleep "$DELAY"
done
echo "unhealthy after $RETRIES attempts (last status: ${code:-none})" >&2
exit 1
