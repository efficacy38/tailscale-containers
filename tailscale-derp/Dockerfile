FROM ubuntu:20.04

WORKDIR /app

ENV DERP_DOMAIN your-hostname.com
ENV DERP_CERT_MODE letsencrypt
ENV DERP_CERT_DIR /app/certs
ENV DERP_ADDR :443
ENV DERP_STUN true
ENV DERP_HTTP_PORT 80
ENV DERP_VERIFY_CLIENTS false

COPY --from=tailscale-base /go/bin/derper /go/bin/tailscale /go/bin/tailscaled /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

