{
  description = "Avalon: Qwen3.8-Flash-Next served by a ROCm llama.cpp fork, packaged for NixOS";

  inputs.nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      # ROCm from nixpkgs and the AMD cards this targets are x86_64-linux. The model and the draft head
      # are unfree redistributable weights, so this package set enables allowUnfree; consumers that only
      # take the engine are unaffected.
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [ (import ./overlays/default.nix) ];
      };
    in
    {
      packages.x86_64-linux = {
        inherit (pkgs) avalon avalon-mtp avalon-model;
        default = pkgs.avalon;
      };

      nixosModules.avalon = ./modules/services/avalon.nix;

      overlays.default = import ./overlays/default.nix;
    };

}
