{
  description = "NixOS configuration of hinidu's machines";

  # Versions are pinned in flake.lock; `nix flake update` moves them to the
  # latest commits of these branches
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      # Must be the release branch matching nixpkgs
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Partitions, encrypts and mounts disks from their description in Nix
    # (modules/encrypted-disk.nix); `latest` is its latest release
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Secure Boot with keys of our own (modules/secure-boot.nix)
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      # A host is computers/<name>/; nixos-rebuild picks the one named after
      # networking.hostName
      host = name: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./computers/${name} ];
      };
    in
    {
      nixosConfigurations = {
        hinidu-notebook = host "hinidu-notebook";
      };
    };
}
