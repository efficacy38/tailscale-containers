FROM ubuntu:20.04

WORKDIR /app

COPY --from=tailscale-base /go/bin/tailscale /go/bin/tailscaled /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

