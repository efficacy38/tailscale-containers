{
  description = "Tailscale container images built with Nix";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ ];
            };
          }
        );

      # Helper function to build Tailscale containers
      buildTailscaleContainer =
        {
          pkgs,
          name,
          entrypoint,
          extraContents ? [ ],
        }:
        let
          # Create a wrapper script that sources the entrypoint
          entrypointScript = pkgs.writeScriptBin "entrypoint.sh" (builtins.readFile entrypoint);
        in
        pkgs.dockerTools.buildLayeredImage {
          inherit name;
          tag = pkgs.tailscale.version;
          contents = [
            pkgs.tailscale
            pkgs.bash
            pkgs.coreutils
            entrypointScript
          ] ++ extraContents;
          extraCommands = ''
            mkdir -p usr/bin
            ln -s ${entrypointScript}/bin/entrypoint.sh entrypoint.sh
          '';
          config = {
            Entrypoint = [ "/entrypoint.sh" ];
            WorkingDir = "/app";
            Env = [
              "PATH=/usr/bin:/bin"
            ];
          };
        };
    in
    {
      packages = forEachSupportedSystem (
        { pkgs }:
        {
          # Build tailscale-userspace container
          # Usage: nix build .#tailscale-userspace && docker load < result
          tailscale-userspace = buildTailscaleContainer {
            inherit pkgs;
            name = "tailscale-userspace";
            entrypoint = ./tailscale-userspace/entrypoint.sh;
            extraContents = [
              pkgs.curl
              pkgs.wget
              pkgs.iputils
            ];
          };

          # Build tailscale-derp container
          # Usage: nix build .#tailscale-derp && docker load < result
          tailscale-derp = buildTailscaleContainer {
            inherit pkgs;
            name = "tailscale-derp";
            entrypoint = ./tailscale-derp/entrypoint.sh;
            extraContents = [
              pkgs.cacert
            ];
          };
        }
      );
    };
}
