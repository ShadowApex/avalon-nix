{
  description = "Avalon: Qwen3.8-Flash-Next served by a ROCm llama.cpp fork, packaged for NixOS";

  inputs.nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # The model and the draft head are unfree redistributable weights, so the flake's own package set
      # enables allowUnfree; consumers that only take the engine are unaffected.
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ (import ./overlays/default.nix) ];
        };
    in
    {
      packages = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          inherit (pkgs) avalon avalon-mtp avalon-model;
          default = pkgs.avalon;
        }
      );

      nixosModules.avalon = ./modules/services/avalon.nix;

      overlays.default = import ./overlays/default.nix;
    };

}
