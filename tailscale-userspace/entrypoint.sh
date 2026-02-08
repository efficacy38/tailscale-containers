#!/bin/bash
set -euo pipefail

# Defaults for optional variables
: "${TAILSCALE_OPT:=}"
: "${TAILSCALED_OPT:=}"
: "${TAILSCALED_STATE_ARG:=mem:}"

TAILSCALED_PID=

cleanup() {
    echo "Shutting down..."
    [ -n "$TAILSCALED_PID" ] && kill -TERM "$TAILSCALED_PID" 2>/dev/null
}
trap cleanup TERM INT

echo "Starting Tailscale daemon"
# -state=mem: will logout and remove ephemeral node from network immediately after ending.
tailscaled --tun=userspace-networking --state="${TAILSCALED_STATE_ARG}" ${TAILSCALED_OPT} &
TAILSCALED_PID=$!

# connect to tailscale
until tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="${TAILSCALE_HOSTNAME}" ${TAILSCALE_OPT}; do
    sleep 0.1
done

tailscale status

# exit if tailscaled exits
wait "$TAILSCALED_PID"
