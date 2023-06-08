{
  description = "Nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, nixos-hardware, agenix }:
    let
      version-suffix = nixpkgs.rev or (builtins.toString nixpkgs.lastModified);
      pkgsFor = system: import nixpkgs {
        inherit system;
      };
      mkSystem = system: hostname: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          # Enable home-manager
          home-manager.nixosModules.home-manager

          # Set global home-manager options
          ({
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          })

          agenix.nixosModules.age

          # Load the config for our current machine
          (./. + "/machines/${hostname}")
        ];
      };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = pkgsFor system;
        in
        {
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [ nixpkgs-fmt nixos-rebuild agenix.packages.${system}.agenix ];
          };
        }) // rec {
      nixosConfigurations = {
        frigo = mkSystem "aarch64-linux" "frigo";
      };
      images.frigo = nixosConfigurations.frigo.config.system.build.sdImage;
    };
}
