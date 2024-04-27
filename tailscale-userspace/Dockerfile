FROM ubuntu:20.04

WORKDIR /app

COPY --from=ghcr.io/efficacy38/tailscale-base /go/bin/tailscale /go/bin/tailscaled /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh
RUN apt-get update && \
  apt-get install -y curl wget iputils-ping && \
  apt-get clean

ENTRYPOINT ["/entrypoint.sh"]

