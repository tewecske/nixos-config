{
  description = "tewe nix config";

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    # substituers will be appended to the default substituters when fetching packages
    # nix com    extra-substituters = [munity's cache server
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      type = "github";
      owner = "Mic92";
      repo = "sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };

    tewenixhome = {
      url = "github:tewecske/tewenixhome";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
    let
      commonModules = [
        # import sops everywhere
        inputs.sops-nix.nixosModules.sops
        {
          # config.nix.generateRegistryFromInputs = true;
          config.home-manager.useGlobalPkgs = true;
          config.home-manager.useUserPackages = true;
          # Import custom home-manager modules (NixOS)
          # config.home-manager.sharedModules = import ./users/modules/modules.nix;

          config.sops.defaultSopsFile = ./secrets.yaml;
          config.sops.defaultSopsFormat = "yaml";
	  # TODO: fix this
	  config.sops.age.keyFile = "/home/tewe/.config/sops/age/keys.txt";
        }
      ];
    in
    {
    nixosConfigurations = {
      tewenixsrv = let
        username = "tewe";
      in
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
	  specialArgs = {
	    inherit username;
	    pkgs-unstable = import nixpkgs-unstable {
	      inherit system;
	    };
	    inherit inputs;
	  };
          modules = commonModules ++ [
            ./hosts/tewenixsrv
            ./users/${username}/nixos.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.users.${username} = import ./users/${username}/home.nix;
              home-manager.extraSpecialArgs = inputs // specialArgs;
            }
          ];
      };
      desktopgnome = let
        username = "tewe";
      in
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
	  specialArgs = {
	    inherit username;
	    pkgs-unstable = import nixpkgs-unstable {
	      inherit system;
	    };
	    inherit inputs;
	  };
          modules = commonModules ++ [
            ./hosts/desktopgnome
            ./users/${username}/nixos.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.users.${username} = import ./users/${username}/home.nix;
              home-manager.extraSpecialArgs = inputs // specialArgs;
            }
          ];
      };
      vmi3 = let
        username = "tewe";
      in
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
	  specialArgs = {
	    inherit username;
	    pkgs-unstable = import nixpkgs-unstable {
	      inherit system;
	    };
	    inherit inputs;
	  };
          modules = commonModules ++ [
            ./hosts/vmi3
            ./users/${username}/nixos.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.users.${username} = import ./users/${username}/home.nix;
              home-manager.extraSpecialArgs = inputs // specialArgs;
            }
          ];
      };
    };
  };
}
