#!/bin/bash
set -ue
trap 'kill -TERM $PID' TERM INT
echo "Starting Tailscale daemon"
# -state=mem: will logout and remove ephemeral node from network immediately after ending.
tailscaled --tun=userspace-networking --state=${TAILSCALED_STATE_ARG} ${TAILSCALED_OPT} &
PID=$!
until tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="${TAILSCALE_HOSTNAME}" ${TAILSCALE_OPT}; do
    sleep 0.1
done
tailscale status

# exit if tailscaled exit
wait ${PID}

