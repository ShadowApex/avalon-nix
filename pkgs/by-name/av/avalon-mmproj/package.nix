# Avalon's image encoder: the vision tower and its projector, the file llama.cpp's mtmd library reads to turn
# a picture into the rows the model places at the image tokens. Pinned by the file's LFS SHA-256, like the
# other weights. Qwen Community License, so unfree.
#
# The engine needs nothing added to build it: tools/server links mtmd, and the Avalon tree builds the tools,
# so llama-server already takes -mm and reports vision capabilities. Pictures are this file plus that flag.
#
# It comes from ISTA's GSQ-RCO repository rather than the Avalon one, which publishes no projector. The whole
# Qwen3.8-Flash-Next line shares this file: the tower and the merger come from the checkpoint both quants were
# made from, and its projection is 2560 wide, the embedding length of the qwen4exp architecture the Avalon
# quant uses. Strata, which serves the same line on the same tokens, pins the same file.
#
# 449M parameters in BF16, 907 MB: on the GPU it is ~0.9 GiB on top of what the context and the expert cache
# already hold, and services.avalon.vision.offload = false keeps it on the CPU instead.

{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  revision = "ed59f92082b1e93c0e96d60a8b11aab089b52f09"; # HF main, 2026-09-29
  file = {
    name = "mmproj-Qwen3.8-Flash-Next-BF16.gguf";
    hash = "sha256-sagiWXAoFqUzDXvXYHzZZ2sReA55/3NIwhED/zzkm9A=";
  };
in

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "avalon-mmproj";
  version = "bf16";

  src = fetchurl {
    url = "https://huggingface.co/ISTA-DASLab/Qwen3.8-Flash-Next-GSQ-RCO-GGUF/resolve/${revision}/${file.name}";
    hash = file.hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    ln -s $src $out/${file.name}
    runHook postInstall
  '';

  meta = {
    description = "Image encoder for Qwen3.8-Flash-Next, as a llama.cpp multimodal projector";
    homepage = "https://huggingface.co/ISTA-DASLab/Qwen3.8-Flash-Next-GSQ-RCO-GGUF";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    unrestricted = true;
  };
})
