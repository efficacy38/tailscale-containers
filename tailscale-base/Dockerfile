FROM golang:latest as builder
WORKDIR /app

ARG VER=v1.64.2

# build tailscale binaries
RUN CGO_ENABLED=0 go install tailscale.com/cmd/derper@${VER}
RUN CGO_ENABLED=0 go install tailscale.com/cmd/tailscale@${VER}
RUN CGO_ENABLED=0 go install tailscale.com/cmd/tailscaled@${VER}
