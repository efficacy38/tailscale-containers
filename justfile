# Build and load Tailscale container images

# List available recipes
default:
    @just --list

# Build tailscale-userspace image with Nix
build-userspace:
    nix build .#tailscale-userspace

# Build tailscale-derp image with Nix
build-derp:
    nix build .#tailscale-derp

# Build all Nix images
build-all: build-userspace build-derp

# Load tailscale-userspace image into Docker
load-userspace: build-userspace
    docker load < result

# Load tailscale-derp image into Docker
load-derp: build-derp
    docker load < result

# Build and load all images into Docker
load-all: load-userspace load-derp

# Clean Nix build results
clean:
    rm -f result

# Build using docker-compose (legacy method)
docker-build:
    docker compose build

# Build specific service with docker-compose
docker-build-service service:
    docker compose build {{service}}

# Run tailscale-userspace with docker-compose
run-userspace:
    docker compose up tailscale-userspace

# Run tailscale-derp with docker-compose
run-derp:
    docker compose up tailscale-derp

# Check flake validity
check:
    nix flake check

# Update flake inputs
update:
    nix flake update

# Show flake info
info:
    nix flake show

# Show current versions of Tailscale binaries in nixpkgs
versions:
    @echo "Tailscale package version from nixpkgs:"
    @echo "  tailscale/tailscaled/derper: $(nix eval --raw nixpkgs#tailscale.version)"
