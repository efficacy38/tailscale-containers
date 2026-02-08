#!/bin/bash
set -euo pipefail

# Defaults for optional variables
: "${DERP_CERT_MODE:=letsencrypt}"
: "${DERP_CERT_DIR:=/app/certs}"
: "${TAILSCALE_OPT:=}"
: "${TAILSCALED_STATE_ARG:=mem:}"

TAILSCALED_PID=
DERPER_PID=

cleanup() {
    echo "Shutting down..."
    [ -n "$DERPER_PID" ] && kill -TERM "$DERPER_PID" 2>/dev/null
    [ -n "$TAILSCALED_PID" ] && kill -TERM "$TAILSCALED_PID" 2>/dev/null
}
trap cleanup TERM INT

echo "Starting Tailscale daemon"
# -state=mem: will logout and remove ephemeral node from network immediately after ending.
tailscaled --tun=userspace-networking --state="${TAILSCALED_STATE_ARG}" &
TAILSCALED_PID=$!

# connect to tailscale
until tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="${TAILSCALE_HOSTNAME}" ${TAILSCALE_OPT}; do
    sleep 0.1
done

echo "Starting Tailscale DERP server"
derper -hostname="${DERP_DOMAIN}" \
    -certmode="${DERP_CERT_MODE}" \
    -certdir="${DERP_CERT_DIR}" \
    -verify-clients="${DERP_VERIFY_CLIENTS}" &
DERPER_PID=$!

# Exit when either process dies
wait -n "$TAILSCALED_PID" "$DERPER_PID"
EXIT_CODE=$?

echo "Process exited with code $EXIT_CODE, shutting down..."
cleanup
wait 2>/dev/null
exit "$EXIT_CODE"
