# Avalon: Qwen3.8-Flash-Next on one AMD GPU

[Avalon](https://github.com/freriadoc/Avalon) is a llama.cpp fork that serves
`Qwen3.8-Flash-Next-Avalon-GGUF` on a single AMD card: the full model is memory-mapped from RAM and
only a subset of its experts is resident on the GPU. This flake packages it for NixOS - the HIP
engine, the quantized weights, the MTP draft head, and a service unit.

Everything is pinned: the engine to the commit `2d16e18` of the fork, the weights to the Hugging Face
revision `372fe3a4`, each file with its own hash. Nothing is downloaded at build time except those
pinned files, and the compile itself needs no network.

## Hardware

| | Minimum |
|---|---|
| GPU | RDNA3 with 20 GB+ of VRAM, offline (upstream measures gfx1100, the RX 7900 XT/XTX), or a gfx1151 APU |
| RAM | 32 GB or more; 64 GB or more on a gfx1151 APU, whose GPU memory is system memory |
| Disk | ~98 GiB: the 89 GiB of weights plus the build |

`hipArchs` below decides which cards the compiled engine runs on. Upstream builds and measures
`gfx1100`/`gfx1101`/`gfx1102` and its `install.sh` refuses anything else; the default here adds
`gfx1151` (Ryzen AI MAX / Strix Halo, RDNA3.5), which the fork's own ROCm CI runs. Any
gfx9/gfx10/gfx11 ISA is accepted, but anything outside those four is unmeasured. Below 20 GB of VRAM
the 256k context with MTP may not fit - `services.avalon.maxContext = 65536;` is upstream's
suggestion.

Two things matter on a gfx1151 APU:

- batched inference can return wrong output while kernel launches are asynchronous, so set
  `services.avalon.launchBlocking = true;` (upstream's gfx1151 CI does the same). It serializes
  launches and costs throughput, which is why the module leaves it off.
- the card has no VRAM of its own: it maps system RAM through the GTT, ~50 % of RAM by default. AMD
  additionally requires kernel 6.18.4 or newer for KFD to set up its queues, and the pinned nixpkgs
  ships 6.18.59. Increase the mapped pool with
  `boot.kernelParams = [ "ttm.pages_limit=26214400" ]` (100 GiB in 4 KiB pages) if the GPU side needs
  more than that half.

The IQ3_KS quant holds a 262144-token context; above that its dequant scales overflow. The MTP draft
head proposes two tokens per step.

## Packages

```console
$ nix build .#avalon          # the engine: llama-server and its CLI tools
$ nix build .#avalon-mtp      # the shared MTP draft head, 1.4 GiB
$ nix build .#avalon-model    # the quantized model, 89 GiB, with the draft head in MTP/
```

`avalon-model` is the model's 33 shards, the expert ranking (`moe-cache-ranking.bin`) and the MTP
head, linked under their upstream names so llama.cpp can resolve the split model by loading the first
shard:

```console
$ nix build .#avalon-model
$ ./result/Qwen3.8-Flash-Next-Avalon-IQ3KS-00001-of-00033.gguf   # the file passed to -m
$ ./result/MTP/                                                  # the draft head passed to -md
```

Both weight packages carry `meta.unfree = true`: they are redistributable, not free. Building them
needs `allowUnfree`, which the flake's own package set already enables, so `nix build .#avalon-model`
works as-is. With the overlay (`overlays.default`) into your own nixpkgs, set
`nixpkgs.config.allowUnfree = true` yourself.

## Running it without NixOS

`llama-server` needs the launch flags upstream's `install.sh` writes into its launcher; the smallest
reproduction is:

```console
$ nix run .#avalon -- --help                    # the server binary on its own
$ nix shell .#avalon .#avalon-model --command llama-server \
    -m ./result/Qwen3.8-Flash-Next-Avalon-IQ3KS-00001-of-00033.gguf \
    -c 262144 -b 9536 -ub 9536 -fa on -ctk q8_0 -ctv q4_0 --jinja --parallel 1 \
    -md ./result/MTP/mtp-Qwen3.8-Flash-Next-shared-IQ3K-IQ4NL-FR65k.gguf \
    --spec-type draft-mtp --spec-draft-n-max 2 \
    -ubd 256 -ctkd q8_0 -ctvd q8_0 \
    --host 127.0.0.1 --port 8080
```

The first prompt loads the graph and fills the expert cache, which takes minutes on a small card -
`llama-server` prints nothing until it is ready. Server-side tools (`llama-bench`,
`llama-batched-bench`, `llama-fit-params`) are in the same output.

## NixOS

```nix
{ inputs, pkgs, ... }:
{
  nixpkgs.overlays = [ inputs.avalon.overlays.default ];
  nixpkgs.config.allowUnfree = true;

  services.avalon = {
    enable = true;
    # The card's own ISA; the default builds the three desktop RDNA3 ISAs upstream tests plus gfx1151.
    hipArchs = [ "gfx1151" ];
    launchBlocking = true;  # correct output on gfx1151; leave off on a discrete card
    openFirewall = false;   # the server binds 127.0.0.1:8080
  };
}
```

The unit runs `llama-server` as the `avalon` user from `/var/lib/avalon`, with `render` and `video`
groups, `/dev/kfd` and `/dev/dri` allowed, `LimitMEMLOCK=infinity` (ROCm pins the resident experts),
and no start timeout. Its command line is the launcher flags above; `extraArgs` appends to it and
`env` covers the engine's tuning switches, e.g.:

```nix
services.avalon = {
  extraArgs = [ "--no-tempcache" ];
  env = {
    AMD_P2U_WAIT_ENABLE = "1";
    HIPBLASLT_HEURISTICS_CACHE_CAPACITY = "3000";
  };
};
```

Options: `package`, `modelPackage`, `hipArchs`, `launchBlocking`, `maxContext`, `batchSize`,
`unifiedBatchSize`, `draftBatchSize`, `draftMax`, `cacheQuantK`, `cacheQuantV`, `draftCacheQuant`,
`modelFile`, `mtpFile`, `host`, `port`, `stateDir`, `user`, `group`, `extraArgs`, `env`,
`openFirewall`. Changing `hipArchs` rebuilds the engine.

To check the server answers:

```console
$ curl -s http://127.0.0.1:8080/v1/models | head
```

## Development

```console
$ nix flake show     # packages.avalon / avalon-model / avalon-mtp / default, nixosModules.avalon
$ nix flake check    # evaluates the outputs; it does not build the packages
$ nix build --impure -f tests/module.nix --no-link   # the module into a system toplevel
```

`tests/module.nix` evaluates the service into a bootable NixOS system, which is how to check the unit's
dir, groups, limits and command line; realising it fetches the pinned weights.

The engine builds with ROCm from nixpkgs (`rocmPackages.clang` and `rocmPackages.rocblas`); this tree
pins nixpkgs-unstable, which ships ROCm 7.2.4 - the version upstream tested. There is no prebuilt
cache: `nix build .#avalon` compiles HIP kernels for each of the chosen ISAs, roughly twenty minutes
for the default four on a 16-core machine.

To move the engine to a newer Avalon commit, change `revision` (and `shortRev`, which `version` is
derived from) in `pkgs/by-name/av/avalon/package.nix`; the build reports the new SRI hash on the first
attempt. To move the weights, change `revision` in `pkgs/by-name/av/avalon-model/package.nix` and
re-pin the files whose hashes the build reports.

## License

MIT for the engine (as upstream); Apache 2.0 for the quantized weights. The weights are redistributable
but not free, so they are marked `unfree` in the package metadata.
