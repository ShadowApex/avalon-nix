# Avalon's model payload: the IQ3_KS hybrid shards of Qwen3.8-Flash-Next, the expert ranking the cache
# prefills from (the server reads moe-cache-ranking.bin next to the model), and the license.
#
# The GGUF files carry the Qwen Community License, so this package is unfree and needs
# nixpkgs.config.allowUnfree = true in the consuming configuration.
#
# ~88 GiB of downloads; building it alone (nix build .#avalon-model) is how to warm the cache before
# switching a machine over. Nothing is fetched at build time: each file is pinned to the HF revision by
# its LFS SHA-256, so a bump re-pins the hashes. The output symlinks its files into the store rather
# than copying them.

{
  lib,
  stdenvNoCC,
  fetchurl,
  mtpPackage ? null,
}:

let
  revision = "372fe3a4e572c5ba75a90e579de0695633d083a8"; # HF main, 2026-10-23
  baseUrl = "https://huggingface.co/freriadoc/Qwen3.8-Flash-Next-Avalon-GGUF/resolve/${revision}";

  files = [
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00001-of-00033.gguf";
      hash = "sha256-0w2sYjR7BCcoHuCUXpVmDxg4c+l4RF/H6xokkXVi5a8=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00002-of-00033.gguf";
      hash = "sha256-x1IITYFkSBGAgaDLV8irIFY7qgyWdc+ZbcygD9qxBqg=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00003-of-00033.gguf";
      hash = "sha256-SBNh8fkKoTPv4gEVpV3OlFDXpP9gjae1NCDR1uZ3Kb4=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00004-of-00033.gguf";
      hash = "sha256-gS1e+mRsMrfNKmUrZ+XI+YibBRZowRY2txT1aarL5tU=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00005-of-00033.gguf";
      hash = "sha256-dSZSe9TExapgm16pT7DZNKfdkDIqBw63k2SxoNS1Yow=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00006-of-00033.gguf";
      hash = "sha256-v9jpYp2QWHq2ZqnZFdr5/gh5H+AUnz6iXFtYnCth2oY=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00007-of-00033.gguf";
      hash = "sha256-rWtJesoe7fg30C4Mf5CZ6vngJdRJ2gsRS/WOoPBub40=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00008-of-00033.gguf";
      hash = "sha256-aTLU/geHUtxU8MAqO2OqtEbRCIOFdv1GaFxH+7imqC4=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00009-of-00033.gguf";
      hash = "sha256-y8gRwD3m0aBDpO/oruejtnOeplzL2z7GPHumMShR4Ic=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00010-of-00033.gguf";
      hash = "sha256-Nm961DWoVf5hh7RV4PiGIPWMfvEOOQ8cgwJApSbNOog=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00011-of-00033.gguf";
      hash = "sha256-yBOVOnJdluTGw+s5mkGsxLsWyNrGjXREtav42j/n3FA=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00012-of-00033.gguf";
      hash = "sha256-ZGfJqiguLSrw0toAJuWqU1uLrySc1YCdI9cQYZIPhHA=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00013-of-00033.gguf";
      hash = "sha256-TyJZkj8wdhF2GXVtEtN5cQjiIGKPdIVSsLkIU5bowVU=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00014-of-00033.gguf";
      hash = "sha256-+4XYYeu1e8mpryzfpeAOx3dHdpUlavm/BiIKwGvQUtc=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00015-of-00033.gguf";
      hash = "sha256-/qfGlw5Mqx5O6aCLfH8pQs+GkWZ2xW3TY7ZNF8Q8V3M=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00016-of-00033.gguf";
      hash = "sha256-2ER9qtsvXV3UMK9cSkoWBN0IFQlqkRjMH06zf/R9CV4=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00017-of-00033.gguf";
      hash = "sha256-ihyjjrr+bd6Z/riHc8+QFXVNyZ4sSK5+vwjtdE7LmhU=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00018-of-00033.gguf";
      hash = "sha256-9alS5tZFL9QrrbONEqb/OlqK0X7Hf3JksvKaCtsw/4M=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00019-of-00033.gguf";
      hash = "sha256-gdW4jWPbnOE+qh7GutjxgnoZH3Tza8pnc1FpdyGc2Xs=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00020-of-00033.gguf";
      hash = "sha256-zXCJefUbzhCSARVPy9mgydb3a2tqBMmsMKXlRSc50Bw=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00021-of-00033.gguf";
      hash = "sha256-RovKTQKiTESld8Aak7ykDV9o72MVr06lXUsTEAjX7OQ=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00022-of-00033.gguf";
      hash = "sha256-RDwCZaaoNLQ5QYBgRQfw6hLzLgVKn1KnJPfpPbnaZFE=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00023-of-00033.gguf";
      hash = "sha256-rnA6afIj/kryu7TpWop5Uk1iwc0GPZzjzNeoE2BEtX0=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00024-of-00033.gguf";
      hash = "sha256-MsnKzN8I0csDn4D9f/6JwVS+SEBEh7j4qJeVnWgbuG4=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00025-of-00033.gguf";
      hash = "sha256-FYLtyrIJWUqny9vS8WV76X3qv9FHDTRNkAzc0rgwbYM=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00026-of-00033.gguf";
      hash = "sha256-Ykt6NVg+u5ZyW9y5xoFY2BudarVt3FCgKJXyBYqvSX0=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00027-of-00033.gguf";
      hash = "sha256-6oQQO0lvDtvgu2oWx8Yhws80PPYFiSTEqh6V1rDtVfw=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00028-of-00033.gguf";
      hash = "sha256-BuW9+CGwmStTf0ZkFu189+j4ZTAGKnBGCGxTzy1Rrok=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00029-of-00033.gguf";
      hash = "sha256-GiFWI4rP/LQKa0/H7lbfSLfZCpweu0DTnIj3iwgZQvU=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00030-of-00033.gguf";
      hash = "sha256-IU+xtdfFKjBmer/g1j88viOvMUBSHYzgEOM8267KOZ4=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00031-of-00033.gguf";
      hash = "sha256-5wAaqL0vkNgI1jUJ0Ifod70B1C1wZRzuqqLbLuaQet0=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00032-of-00033.gguf";
      hash = "sha256-DN52Vazsk5tpbLqo4WmEaIDKIeZhtKtM+l/4UQWh/sE=";
    }
    {
      name = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00033-of-00033.gguf";
      hash = "sha256-7vteb6lVnMf6cCJIWFIbgiyx9r/kg26i1kFrVr7KZfY=";
    }
    {
      name = "moe-cache-ranking.bin";
      hash = "sha256-TUcb0Pc+oVFaXj22lDUqxYSruUl/XAt96303nCyTrpA=";
    }
    {
      name = "LICENSE";
      hash = "sha256-oNxCJWCEH9aOBtl0kH+LTHCbykSmfarStShDe99nbAg=";
    }
  ];
in

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "avalon-model";
  version = "iq3ks";

  srcs = map (
    f:
    fetchurl {
      url = "${baseUrl}/${f.name}";
      hash = f.hash;
    }
  ) files;

  dontUnpack = true;

  # The store paths carry a hash prefix, so each file is linked under its own name: llama.cpp resolves
  # the split shards by exact sibling names, and the ranking is read next to the model.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
  ''
  + lib.concatStringsSep "\n" (
    lib.zipListsWith (f: path: "ln -s ${path} $out/${f.name}") files finalAttrs.srcs
    ++ lib.optionals (mtpPackage != null) [
      "mkdir -p $out/MTP"
      "ln -s ${mtpPackage}/mtp-Qwen3.8-Flash-Next-shared-IQ3K-IQ4NL-FR65k.gguf $out/MTP/"
    ]
  )
  + "\nrunHook postInstall\n";

  meta = {
    description = "Qwen3.8-Flash-Next in the Avalon IQ3_KS hybrid quantization, with its MoE expert ranking";
    homepage = "https://huggingface.co/freriadoc/Qwen3.8-Flash-Next-Avalon-GGUF";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.linux;
    unrestricted = true;
  };
})
