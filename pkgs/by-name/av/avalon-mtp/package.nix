# Avalon's MTP draft head: the small draft model (a cut LM head over the 65k frequent tokens) that the
# server shares the main model's expert cache with. Pinned to the same Hugging Face revision as
# avalon-model, by the file's LFS SHA-256. Qwen Community License, so unfree.

{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  revision = "372fe3a4e572c5ba75a90e579de0695633d083a8"; # HF main, 2026-10-23
  file = {
    name = "MTP/mtp-Qwen3.8-Flash-Next-shared-IQ3K-IQ4NL-FR65k.gguf";
    hash = "sha256-VESMSxZABXVtJNKt/xaK6I0nDDY2N6uEs+DA9cfOBX0=";
  };
in

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "avalon-mtp";
  version = "iq3k-iq4nl-fr65k";

  src = fetchurl {
    url = "https://huggingface.co/freriadoc/Qwen3.8-Flash-Next-Avalon-GGUF/resolve/${revision}/${file.name}";
    hash = file.hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    ln -s $src $out/${baseNameOf file.name}
    runHook postInstall
  '';

  meta = {
    description = "MTP draft head for the Avalon IQ3_KS hybrid quantization of Qwen3.8-Flash-Next";
    homepage = "https://huggingface.co/freriadoc/Qwen3.8-Flash-Next-Avalon-GGUF";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.linux;
    unrestricted = true;
  };
})
