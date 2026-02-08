#!/bin/bash
set -euo pipefail

# Defaults for optional variables
: "${DERP_CERT_MODE:=letsencrypt}"
: "${DERP_CERT_DIR:=/app/certs}"
: "${TAILSCALED_STATE_ARG:=mem:}"
: "${TAILSCALE_EXTRA_ARGS:=}"
: "${TAILSCALED_EXTRA_ARGS:=}"

TAILSCALED_PID=
DERPER_PID=

cleanup() {
    echo "Shutting down..."
    [ -n "$DERPER_PID" ] && kill -TERM "$DERPER_PID" 2>/dev/null
    [ -n "$TAILSCALED_PID" ] && kill -TERM "$TAILSCALED_PID" 2>/dev/null
}
trap cleanup TERM INT

echo "Starting Tailscale daemon"

# Build tailscaled args
TAILSCALED_ARGS="--tun=userspace-networking --state=${TAILSCALED_STATE_ARG}"

tailscaled ${TAILSCALED_ARGS} ${TAILSCALED_EXTRA_ARGS} &
TAILSCALED_PID=$!

# Build tailscale up args
TS_UP_ARGS="--authkey=${TAILSCALE_AUTH_KEY} --hostname=${TAILSCALE_HOSTNAME}"
[ -n "${TAILSCALE_LOGIN_SERVER:-}" ] && TS_UP_ARGS+=" --login-server=${TAILSCALE_LOGIN_SERVER}"
[ "${TAILSCALE_ADVERTISE_EXIT_NODE:-}" = "true" ] && TS_UP_ARGS+=" --advertise-exit-node"
[ -n "${TAILSCALE_ADVERTISE_ROUTES:-}" ] && TS_UP_ARGS+=" --advertise-routes=${TAILSCALE_ADVERTISE_ROUTES}"
[ "${TAILSCALE_ACCEPT_ROUTES:-}" = "true" ] && TS_UP_ARGS+=" --accept-routes"
[ -n "${TAILSCALE_ACCEPT_DNS:-}" ] && TS_UP_ARGS+=" --accept-dns=${TAILSCALE_ACCEPT_DNS}"

# connect to tailscale
until tailscale up ${TS_UP_ARGS} ${TAILSCALE_EXTRA_ARGS}; do
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
