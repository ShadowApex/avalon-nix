# The service module, evaluated into a bootable system: the smoke test for modules/services/avalon.nix.
#
#   nix build --impure -f tests/module.nix --no-link --print-out-paths
#
# Realising the toplevel fetches the pinned weights, ~91 GiB, and starts nothing.
let
  src = <nixpkgs>;
  pkgs = import src {
    config.allowUnfree = true;
    overlays = [ (import ../overlays/default.nix) ];
  };
in
(import (src + /nixos/lib/eval-config.nix) {
  inherit pkgs;
  system = "x86_64-linux";
  modules = [
    ../modules/services/avalon.nix
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      boot.loader.grub.enable = false;
      fileSystems."/".device = "/dev/root";
      fileSystems."/".fsType = "ext4";
      users.users.root.initialPassword = "test";
      services.avalon = {
        enable = true;
        hipArchs = [ "gfx1150" ];
        openFirewall = true;
        env.AMD_P2U_WAIT_ENABLE = "1";
        extraArgs = [ "--no-tempcache" ];
      };
    }
  ];
}).config.system.build.toplevel
