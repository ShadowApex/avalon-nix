final: prev:
let
  avalon-mtp = final.callPackage ../pkgs/by-name/av/avalon-mtp/package.nix { };
in
{
  avalon = final.callPackage ../pkgs/by-name/av/avalon/package.nix { };
  avalon-mtp = avalon-mtp;
  avalon-model = final.callPackage ../pkgs/by-name/av/avalon-model/package.nix {
    mtpPackage = avalon-mtp;
  };
}
