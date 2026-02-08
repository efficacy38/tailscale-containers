# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Builds two Tailscale container images using Nix flakes with binaries from nixpkgs. Images are published to `ghcr.io/efficacy38/` via GitHub Actions.

- **tailscale-userspace**: Userspace networking proxy (SOCKS5 on 1055, HTTP on 1056). Can serve as subnet router or exit node. Includes curl, wget, iputils.
- **tailscale-derp**: Custom DERP relay server (STUN on 3478/udp, HTTPS on 443) with Let's Encrypt support. Includes cacert and the `derper` binary from `pkgs.tailscale.derper`.

## Build Commands

All commands use `just` (see `justfile`):

```bash
just                    # List all recipes
just build-userspace    # Build Nix image (output: ./result)
just build-derp
just build-all
just load-userspace     # Build + docker load
just load-derp
just load-all
just run-userspace      # docker compose up tailscale-userspace
just run-derp
just check              # nix flake check
just update             # nix flake update (bumps Tailscale version)
just versions           # Show Tailscale version from nixpkgs
just info               # nix flake show
just clean              # rm -f result
```

Or use Nix directly: `nix build .#tailscale-userspace && docker load < result`

## Configuration

Copy `env.sample` to `.env`. Key variables:

| Variable | Service | Description |
|---|---|---|
| `TAILSCALE_AUTH_KEY` | Both | Auth key for Tailscale network |
| `TAILSCALE_HOSTNAME` | Both | Node hostname |
| `TAILSCALE_LOGIN_SERVER` | Both | Custom login server URL (e.g., Headscale) |
| `TAILSCALE_ADVERTISE_EXIT_NODE` | Both | Advertise as exit node (`true`/`false`) |
| `TAILSCALE_ADVERTISE_ROUTES` | Both | Subnet routes to advertise (comma-separated CIDRs) |
| `TAILSCALE_ACCEPT_ROUTES` | Both | Accept routes from other nodes (`true`/`false`) |
| `TAILSCALE_ACCEPT_DNS` | Both | Accept DNS from Tailscale (`true`/`false`) |
| `TAILSCALE_EXTRA_ARGS` | Both | Extra `tailscale up` flags (escape hatch) |
| `TAILSCALED_STATE_ARG` | Both | `"mem:"` (ephemeral) or `"/app/states"` (persistent) |
| `TAILSCALED_SOCKS5_SERVER` | userspace | SOCKS5 proxy listen address (e.g., `0.0.0.0:1055`) |
| `TAILSCALED_HTTP_PROXY` | userspace | HTTP proxy listen address (e.g., `0.0.0.0:1056`) |
| `TAILSCALED_EXTRA_ARGS` | Both | Extra `tailscaled` flags (escape hatch) |
| `DERP_DOMAIN` | derp | Domain name for DERP server |
| `DERP_VERIFY_CLIENTS` | derp | Verify Tailscale clients (`true`/`false`) |
| `DERP_CERT_MODE` | derp | Certificate mode (default: letsencrypt) |
| `DERP_CERT_DIR` | derp | Certificate directory (default: /app/certs) |

## Architecture

### Nix Build (`flake.nix`)

A single helper function `buildTailscaleContainer` builds both images using `dockerTools.buildLayeredImage`:
- Takes `pkgs`, `name`, `entrypoint` (path to shell script), `extraContents` (additional packages)
- Reads entrypoint scripts via `builtins.readFile`, wraps with `pkgs.writeScriptBin`
- Images tagged with `pkgs.tailscale.version`
- Supported systems: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
- Nixpkgs sourced from FlakeHub stable

### Entrypoint Scripts

Both `tailscale-*/entrypoint.sh` scripts follow the same pattern:
1. Start `tailscaled --tun=userspace-networking` in background, capture PID
2. Trap SIGTERM/SIGINT to forward to daemon
3. Retry `tailscale up` with auth key until daemon is ready (0.1s sleep loop)
4. **userspace**: Print status, `wait $PID`
5. **derp**: Launch `derper` in foreground, then `wait $PID`

### CI/CD (`.github/workflows/build-containers.yaml`)

- **Triggers**: Push to `main`, tags `v*.*.*`, PRs to `main`
- Builds both images in parallel jobs using Nix (with DeterminateSystems cache)
- Pushes versioned tag via `skopeo` to GHCR; also pushes `latest` on main branch
- Version extracted with `nix eval --raw .#<package>.imageTag`

### Runtime

- `docker-compose.yml` defines both services, reading from `.env`
- userspace: privileged mode, volume `./data:/app`
- derp: ports 80/443/3478, volume `./cert:/app/certs`
- Debugging: uncomment `entrypoint: sleep infinity` in docker-compose.yml

## Updating Tailscale Version

Run `just update` (runs `nix flake update`) to bump nixpkgs, which updates the Tailscale version. Check with `just versions`.
