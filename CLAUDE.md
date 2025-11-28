# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a tailscale-containers project that builds custom Tailscale container images with different configurations. The project uses Nix flakes to build reproducible container images with Tailscale binaries from nixpkgs.

### Container Images

1. **tailscale-userspace**: Runs Tailscale in userspace networking mode without requiring elevated privileges
   - Built with Nix from nixpkgs
   - Can act as SOCKS5 proxy (port 1055) and HTTP proxy (port 1056)
   - Can function as subnet router or exit node
   - Supports ephemeral nodes (mem:) or persistent state (/app/states)
   - Includes: bash, coreutils, curl, wget, iputils
   - Entrypoint: tailscale-userspace/entrypoint.sh

2. **tailscale-derp**: Custom DERP relay server
   - Built with Nix from nixpkgs
   - Provides STUN service (port 3478/udp) and HTTPS relay (port 443)
   - Supports Let's Encrypt automatic certificate provisioning
   - Includes: bash, coreutils, cacert
   - Entrypoint: tailscale-derp/entrypoint.sh

## Build Commands

### Using Just (Recommended)
The project includes a justfile for convenient building and loading:

```bash
# List all available commands
just

# Build and load tailscale-userspace into Docker
just load-userspace

# Build and load tailscale-derp into Docker
just load-derp

# Build and load all images
just load-all

# Just build without loading
just build-userspace
just build-derp
just build-all

# Check flake validity
just check

# Clean build artifacts
just clean
```

### Using Nix Flakes Directly
```bash
# Build tailscale-userspace image
nix build .#tailscale-userspace
docker load < result

# Build tailscale-derp image
nix build .#tailscale-derp
docker load < result

# Validate flake
nix flake check

# Show available packages
nix flake show
```

### Running with Docker Compose
After building images with Nix, you can run them using Docker Compose:

```bash
# Run services
just run-userspace
just run-derp

# Or use docker compose directly
docker compose up tailscale-userspace
docker compose up tailscale-derp
```

## Configuration

Configuration is done via environment variables in `.env` file:

```bash
# Copy sample environment file
cp env.sample .env

# Edit configuration
vim .env
```

### Required Variables (Both Services)
- `TAILSCALE_AUTH_KEY`: Authentication key for Tailscale network
- `TAILSCALE_HOSTNAME`: Hostname for the Tailscale node
- `TAILSCALE_OPT`: Additional Tailscale options (e.g., --login-server for custom control plane)

### tailscale-userspace Specific
- `TAILSCALED_STATE_ARG`: State storage ("mem:" for ephemeral, "/app/states" for persistent)
- `TAILSCALED_OPT`: Additional tailscaled options (proxy servers, routing options)

### tailscale-derp Specific
- `DERP_DOMAIN`: Domain name for DERP server
- `DERP_VERIFY_CLIENTS`: Whether to verify Tailscale clients (true/false)
- `DERP_CERT_MODE`: Certificate mode (default: letsencrypt)
- `DERP_CERT_DIR`: Certificate directory (default: /app/certs)

## Architecture Details

### Build System
The project uses Nix flakes to build container images:

- Uses Tailscale binaries from nixpkgs instead of building from source
- Helper function `buildTailscaleContainer` creates images with:
  - Tailscale package from nixpkgs
  - Bash and coreutils for script execution
  - Entrypoint scripts from repository
  - Service-specific dependencies (curl/wget/iputils for userspace, cacert for derp)
- Both containers built independently using the same helper
- Reproducible builds across platforms
- Images are tagged with the Tailscale version from nixpkgs

### Entrypoint Scripts
Both service containers use bash entrypoint scripts that:
1. Start tailscaled daemon in background with trap handlers for graceful shutdown
2. Wait for daemon to be ready (retry loop with 0.1s sleep)
3. Run `tailscale up` with auth key and configuration
4. For derp: Start derper server in foreground
5. For userspace: Display status and wait for daemon
6. Wait for background process and handle signals (SIGTERM, SIGINT)

The Nix build includes these scripts via `pkgs.writeScriptBin`, making them executable at `/bin/entrypoint.sh`.


## Nix Flake Structure

The flake.nix uses a helper function approach for building containers:

**Supported Systems:**
- x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin

**Helper Function: `buildTailscaleContainer`**
- Parameters:
  - `pkgs`: Nixpkgs instance
  - `name`: Container image name
  - `entrypoint`: Path to entrypoint script
  - `extraContents`: Additional packages (optional)
- Uses `pkgs.dockerTools.buildLayeredImage` for efficient layering
- Automatically includes: tailscale, bash, coreutils, entrypoint script
- Creates `/app` working directory and `/tmp` with proper permissions
- Uses fakechroot for user/directory setup without root

**Available Packages:**
- `tailscale-userspace`: Includes curl, wget, iputils
- `tailscale-derp`: Includes cacert for TLS certificate validation

**Key Implementation Details:**
- Entrypoint scripts read via `builtins.readFile` and wrapped with `writeScriptBin`
- PATH set to `/usr/bin:/bin` for binary discovery
- Layer-based approach reduces image size and improves caching

## Development Notes

**Tailscale Versions:**
- Uses Tailscale version from nixpkgs (FlakeHub stable branch)
- Check current version: `just versions`
- Container images are tagged with the Tailscale version

**Runtime Requirements:**
- Privileged mode required for tailscale-userspace (specified in docker-compose.yml)
- Volume mounts:
  - tailscale-userspace: ./data:/app for state persistence
  - tailscale-derp: ./cert:/app/certs for certificate storage

**Development Tips:**
- Commented entrypoint overrides in docker-compose.yml for debugging (sleep infinity)
- Use `just check` to validate flake before building
- Nix builds are reproducible and cacheable across machines
- To update Tailscale in Nix builds: `nix flake update` (updates nixpkgs input)
