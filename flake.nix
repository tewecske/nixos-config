{
  description = "tewe nix config";

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    # substituters will be appended to the default substituters when fetching packages
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # Server (tewenixsrv) builds against stable.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Dev environment (home-manager, standalone) builds against unstable, as
    # does cloudflared (modules/cloudflared.nix wants a recent release).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    opencode = {
      url = "github:anomalyco/opencode/v1.18.21";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Wraps nix-built programs so they can find OpenGL. On a foreign distro
    # (Ubuntu/WSL) nix's loader never searches /usr/lib/x86_64-linux-gnu, so
    # LWJGL/libGDX apps fail with "GLX: Failed to load GLX" without this.
    nixGL = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    sops-nix = {
      type = "github";
      owner = "Mic92";
      repo = "sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Provides nixosModules.default (services.gathedge) plus the overlay supplying
    # pkgs.gathedge-backend / pkgs.gathedge-web. Following nixpkgs matters: the module only
    # contributes overlays, so the packages build against the pin here, and the fixed-output
    # hashes in the app repo were computed against this same 26.05.
    gathedge = {
      url = "github:tewecske/gathedge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      opencode,
      nixGL,
      claude-code-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      username = "tewe";

      # Canonical checkout path on every machine. The out-of-store dotfile
      # symlinks and the `hm` wrapper point at this, so it must match where the
      # repo actually lives.
      repoName = "nixos-config";

      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      # Every host = common.nix + one host file, built against unstable.
      # `system` defaults to x86_64-linux; pass aarch64-linux for ARM hosts.
      mkHome =
        {
          hostModule,
          system ? "x86_64-linux",
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit
              system
              opencode
              nixGL
              claude-code-nix
              repoName
              ;
          };
          modules = [
            ./home/common.nix
            hostModule
          ];
        };

      # Shared across NixOS hosts (only tewenixsrv today): sops wiring.
      commonModules = [
        inputs.sops-nix.nixosModules.sops
        {
          config.sops.defaultSopsFile = ./secrets.yaml;
          config.sops.defaultSopsFormat = "yaml";
          # TODO: fix this
          config.sops.age.keyFile = "/home/tewe/.config/sops/age/keys.txt";
        }
      ];
    in
    {
      nixosConfigurations.tewenixsrv = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit username inputs;
          pkgs-unstable = pkgs-unstable;
        };
        modules = commonModules ++ [
          ./hosts/tewenixsrv
          ./users/tewe/nixos.nix
        ];
      };

      homeConfigurations = {
        "tewe@wsl" = mkHome { hostModule = ./home/wsl.nix; };
        "tewe@ubuntu" = mkHome { hostModule = ./home/ubuntu.nix; };
        "tewe@ubuntu-arm" = mkHome {
          hostModule = ./home/ubuntu-arm.nix;
          system = "aarch64-linux";
        };
        "tewe@fedora" = mkHome { hostModule = ./home/fedora.nix; };
        "tewe@nixos" = mkHome { hostModule = ./home/nixos.nix; };
      };

      # So `nix run .#home-manager -- switch --flake .#tewe@wsl` works
      # without home-manager being installed first.
      packages.${system}.home-manager = home-manager.packages.${system}.home-manager;

      # `nix fmt`
      formatter.${system} = pkgs-unstable.nixfmt-tree;
    };
}
