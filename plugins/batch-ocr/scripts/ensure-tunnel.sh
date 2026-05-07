#!/usr/bin/env bash
# ensure-tunnel — Establish or repair an SSH tunnel to a remote Ollama server.
#
# Usage:
#   ensure-tunnel.sh <local-port> <remote-host> <remote-port>
#
# Example:
#   ensure-tunnel.sh 11500 kyle 11434
#
# Behavior:
#   - Health-check via curl /api/tags (OK → return 0 silently)
#   - On failure: kill any stale ssh listening on local-port, re-establish tunnel
#   - Retry up to 3 times with 2s sleep between attempts
#   - Return 0 on success, 1 on permanent failure

set -u

LOCAL_PORT="${1:-11500}"
REMOTE_HOST="${2:-kyle}"
REMOTE_PORT="${3:-11434}"
MAX_RETRIES=3

health_check() {
    curl -s --max-time 3 "http://localhost:${LOCAL_PORT}/api/tags" >/dev/null 2>&1
}

establish_tunnel() {
    # Kill any stale ssh listening on local port
    local stale_pids
    stale_pids=$(lsof -ti:"${LOCAL_PORT}" 2>/dev/null || true)
    if [[ -n "$stale_pids" ]]; then
        echo "ensure-tunnel: killing stale processes on port ${LOCAL_PORT}: ${stale_pids}" >&2
        # shellcheck disable=SC2086
        kill ${stale_pids} 2>/dev/null || true
        sleep 1
    fi

    # Open new tunnel in background
    ssh -fN -L "${LOCAL_PORT}:localhost:${REMOTE_PORT}" "${REMOTE_HOST}" 2>/dev/null
    sleep 2
}

# Fast path: already healthy
health_check && exit 0

# Retry loop
for ((i = 1; i <= MAX_RETRIES; i++)); do
    echo "ensure-tunnel: attempt ${i}/${MAX_RETRIES} — establishing localhost:${LOCAL_PORT} → ${REMOTE_HOST}:${REMOTE_PORT}" >&2
    establish_tunnel
    if health_check; then
        echo "ensure-tunnel: tunnel up after attempt ${i}" >&2
        exit 0
    fi
done

echo "ensure-tunnel: FAILED to establish tunnel after ${MAX_RETRIES} attempts" >&2
exit 1
