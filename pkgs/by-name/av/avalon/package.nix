# Avalon: the llama.cpp fork that runs Qwen3.8-Flash-Next with the experts in system RAM (Linux, ROCm).
# The model and the MTP draft head are separate packages, and the flags the launcher passes are the
# NixOS module's business.
#
#   pkgs.callPackage ./package.nix { hipArchs = [ "gfx1100" "gfx1201" ]; }
#
# The kernels are tuned on a gfx1100 (RX 7900 XT); another RDNA3 target builds with the source's own
# warning. The default set adds gfx1151 (Ryzen AI MAX / Strix Halo, RDNA3.5): upstream's install.sh
# refuses APUs, but the fork's own ROCm CI runs gfx1151. The build needs no network: the UI is
# disabled rather than downloaded, and the fork vendors its httplib.

{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  openssl,
  rocmPackages,
  hipArchs ? [
    "gfx1100"
    "gfx1101"
    "gfx1102"
    "gfx1151"
  ],
}:

let
  inherit (lib)
    cmakeBool
    cmakeFeature
    optionals
    ;

  # The repository has no tags: pinned to the commit of 2026-10-31, whose CMakeLists.txt reports
  # 0.6.0-dev. A bump means re-pinning the unpacked archive's hash.
  version = "0.6.0-dev";
in

stdenv.mkDerivation (finalAttrs: {
  pname = "avalon";
  inherit version;

  src = fetchFromGitHub {
    owner = "freriadoc";
    repo = "Avalon";
    rev = "2d16e18cc6c65eea0401ca9610ea66f282a55ea0";
    hash = "sha256-0QwcyBmbnLuxksa/gENzLQ6c0EDFMTXtA1H3t7Gk0hY=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    openssl
  ]
  ++ optionals stdenv.hostPlatform.isLinux [
    rocmPackages.clr
    rocmPackages.hipblas
    rocmPackages.rocblas
  ];

  cmakeFlags = [
    (cmakeBool "LLAMA_BUILD_SERVER" true)
    (cmakeBool "LLAMA_BUILD_COMMON" true)
    # The server lives under tools/, so the tools tree has to be built; its other binaries come along
    # (llama-cli, quantize, gguf-split), and llama-server needs libllama-server-impl.so from the same tree.
    (cmakeBool "LLAMA_BUILD_TOOLS" true)
    (cmakeBool "LLAMA_BUILD_TESTS" false)
    (cmakeBool "LLAMA_BUILD_EXAMPLES" false)
    (cmakeBool "LLAMA_BUILD_APP" false)
    (cmakeBool "LLAMA_BUILD_UI" false)
    (cmakeBool "LLAMA_USE_PREBUILT_UI" false)
    (cmakeBool "LLAMA_OPENSSL" true)
    (cmakeBool "BUILD_SHARED_LIBS" true)
    (cmakeBool "CMAKE_SKIP_BUILD_RPATH" true)
    (cmakeBool "GGML_NATIVE" false)
    (cmakeBool "GGML_HIP" true)
    (cmakeFeature "CMAKE_HIP_COMPILER" "${rocmPackages.llvm.clang}/bin/clang")
    (cmakeFeature "CMAKE_HIP_ARCHITECTURES" (lib.concatStringsSep ";" hipArchs))
  ];

  # What ggml's HIP cmake reads to find the ROCm tree and the device bitcode.
  env = {
    ROCM_PATH = "${rocmPackages.clr}";
    HIP_DEVICE_LIB_PATH = "${rocmPackages.rocm-device-libs}/amdgcn/bitcode";
  };

  meta = {
    description = "Inference server for Qwen3.8-Flash-Next with the MoE experts in system RAM, on one AMD GPU (ROCm)";
    homepage = "https://github.com/freriadoc/Avalon";
    license = lib.licenses.mit;
    mainProgram = "llama-server";
    platforms = [ "x86_64-linux" ];
  };
})
