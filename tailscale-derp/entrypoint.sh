#!/bin/bash
set -eu

trap 'kill -TERM $PID' TERM INT
echo "Starting Tailscale daemon"
# -state=mem: will logout and remove ephemeral node from network immediately after ending.
tailscaled --tun=userspace-networking ${TAILSCALED_STATE_ARG} &
PID=$!

# connect to tailscale
until tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="${TAILSCALE_HOSTNAME}" ${TAILSCALE_OPT}; do
    sleep 0.1
done

echo "Starting Tailscale DERP server"
derper -hostname="${DERP_DOMAIN}" \
    -certmode="${DERP_CERT_MODE}" \
    -certdir="${DERP_CERT_DIR}" \
    -verify-clients="${DERP_VERIFY_CLIENTS}"

# exit if tailscaled exit
wait ${PID}

