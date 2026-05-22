{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, ... }:
  let
    system = "x86_64-linux";

    # Change "yourname" to your actual username throughout this repo
    username = "thijmen";

    commonModules = [
      ./modules/common.nix
      ./modules/stylix.nix
      ./modules/flake-update.nix
      home-manager.nixosModules.home-manager
      stylix.nixosModules.stylix
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        
        home-manager.users.${username} = import ./home/default.nix;
      }
    ];

  in {
    nixosConfigurations = {

      desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = commonModules ++ [
          ./hosts/desktop/default.nix
          ./modules/syncthing.nix
          ./modules/tailscale.nix
        ];
        specialArgs = { inherit username; };
      };

      laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = commonModules ++ [
          ./hosts/laptop/default.nix
          ./modules/syncthing.nix
          ./modules/tailscale.nix
        ];
        specialArgs = { inherit username; };
      };

      usb = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = commonModules ++ [
          ./hosts/usb/default.nix
          ./modules/syncthing.nix
          ./modules/tailscale.nix
        ];
        specialArgs = { inherit username; };
      };

    };
  };
}
