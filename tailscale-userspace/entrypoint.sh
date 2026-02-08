#!/bin/bash
set -euo pipefail

# Defaults for optional variables
: "${TAILSCALED_STATE_ARG:=mem:}"
: "${TAILSCALE_EXTRA_ARGS:=}"
: "${TAILSCALED_EXTRA_ARGS:=}"

TAILSCALED_PID=

cleanup() {
    echo "Shutting down..."
    [ -n "$TAILSCALED_PID" ] && kill -TERM "$TAILSCALED_PID" 2>/dev/null
}
trap cleanup TERM INT

echo "Starting Tailscale daemon"

# Build tailscaled args
TAILSCALED_ARGS="--tun=userspace-networking --state=${TAILSCALED_STATE_ARG}"
[ -n "${TAILSCALED_SOCKS5_SERVER:-}" ] && TAILSCALED_ARGS+=" --socks5-server=${TAILSCALED_SOCKS5_SERVER}"
[ -n "${TAILSCALED_HTTP_PROXY:-}" ] && TAILSCALED_ARGS+=" --outbound-http-proxy-listen=${TAILSCALED_HTTP_PROXY}"

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

tailscale status

# exit if tailscaled exits
wait "$TAILSCALED_PID"
