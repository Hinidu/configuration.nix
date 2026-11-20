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
    # (modules/encrypted-disk.nix)
    disko = {
      url = "github:nix-community/disko/v1.13.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Declarative Flatpak apps and remotes (VK Calls on vk-laptop); the tag is
    # spelled out, as the repo also has a v0.8.0 maintenance branch, which a
    # bare v0.8.0 resolves to
    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=refs/tags/v0.8.0";
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
        vk-laptop = host "vk-laptop";
      };
    };
}
