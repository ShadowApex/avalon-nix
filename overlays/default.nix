final: prev:
let
  avalon-mtp = final.callPackage ../pkgs/by-name/av/avalon-mtp/package.nix { };
  avalon-mmproj = final.callPackage ../pkgs/by-name/av/avalon-mmproj/package.nix { };
in
{
  avalon = final.callPackage ../pkgs/by-name/av/avalon/package.nix { };
  avalon-mtp = avalon-mtp;
  avalon-mmproj = avalon-mmproj;
  # The projector is not passed in here: images are the service's choice (services.avalon.vision.enable takes
  # avalon-mmproj directly), and a consumer that wants it inside the model directory can override
  # avalon-model with mmprojPackage = pkgs.avalon-mmproj.
  avalon-model = final.callPackage ../pkgs/by-name/av/avalon-model/package.nix {
    mtpPackage = avalon-mtp;
  };
}
