# The Avalon inference service: llama-server from the Avalon fork serving the pinned Qwen3.8-Flash-Next
# GGUF on an AMD card, with the launch flags upstream's install.sh hands the server.
#
#   services.avalon.enable = true;
#   services.avalon.hipArchs = [ "gfx1151" ];   # the card's ISA, which the engine is compiled for
#   services.avalon.launchBlocking = true;      # needed for correct output on that integrated RDNA3.5
#   services.avalon.vision.enable = true;       # images as well as text, with the shared Flash-Next projector
#
# The model is ~89 GiB of mmap'd GGUF, so the host wants 32 GB or more of RAM and the card RDNA3 with
# 20 GB or more of VRAM. On a gfx1151 APU that VRAM is system memory mapped through the GTT (about half
# of RAM by default), so such a host wants 64 GB of RAM or more.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.avalon;
  modelName = "Qwen3.8-Flash-Next-Avalon-IQ3KS-00001-of-00033.gguf";
  mtpName = "mtp-Qwen3.8-Flash-Next-shared-IQ3K-IQ4NL-FR65k.gguf";
  mmprojName = "mmproj-Qwen3.8-Flash-Next-BF16.gguf";
in
{
  options.services.avalon = {
    enable = lib.mkEnableOption "Avalon, the Qwen3.8-Flash-Next inference server on ROCm";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.avalon.override { inherit (cfg) hipArchs; };
      defaultText = lib.literalExpression "pkgs.avalon.override { inherit (cfg) hipArchs; }";
      description = "llama-server build to run; the default is compiled for {option}`services.avalon.hipArchs`";
    };

    modelPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.avalon-model;
      description = "The quantized model, whose first shard is opened by name and whose MTP/ directory
        holds the draft head";
    };

    hipArchs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "gfx1100"
        "gfx1101"
        "gfx1102"
        "gfx1151"
      ];
      example = [
        "gfx1151"
      ];
      description = "AMD GPU targets the engine is compiled for; every gfx9/gfx10/gfx11 ISA is accepted,
        and the card's own ISA is what runs best. The default is the three desktop RDNA3 ISAs upstream
        measures, plus gfx1151 (Ryzen AI MAX / Strix Halo, RDNA3.5), which upstream's installer refuses
        but its own CI runs";
    };

    launchBlocking = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Set {env}`HIP_LAUNCH_BLOCKING=1`, which serializes kernel launches. Integrated
        RDNA3.5 (gfx1151) can return incorrect output from batched inference with asynchronous
        launches - upstream's gfx1151 CI runs with it for that reason - so a gfx1151 host wants it on.
        It costs throughput, so it stays off on discrete cards";
    };

    maxContext = lib.mkOption {
      type = lib.types.int;
      default = 262144;
      description = "Context size (-c). 262144 is what upstream ships and what the IQ3_KS quant can fill;
        above that its dequant scales overflow";
    };

    batchSize = lib.mkOption {
      type = lib.types.int;
      default = 9536;
      description = "Logical batch size (-b)";
    };

    unifiedBatchSize = lib.mkOption {
      type = lib.types.int;
      default = 9536;
      description = "Unified batch size (-ub), the batch the unified KV cache works in";
    };

    draftBatchSize = lib.mkOption {
      type = lib.types.int;
      default = 256;
      description = "Batch size of the MTP draft (-ubd)";
    };

    draftMax = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Draft tokens accepted per step (--spec-draft-n-max)";
    };

    cacheQuantK = lib.mkOption {
      type = lib.types.str;
      default = "q8_0";
      description = "Key KV cache quantization (-ctk)";
    };

    cacheQuantV = lib.mkOption {
      type = lib.types.str;
      default = "q4_0";
      description = "Value KV cache quantization (-ctv)";
    };

    draftCacheQuant = lib.mkOption {
      type = lib.types.str;
      default = "q8_0";
      description = "The draft's KV cache quantization, applied to both cache types (-ctkd/-ctvd)";
    };

    modelFile = lib.mkOption {
      type = lib.types.str;
      default = modelName;
      description = "The file opened within {option}`services.avalon.modelPackage`; llama.cpp resolves the
        remaining shards beside it by name";
    };

    mtpFile = lib.mkOption {
      type = lib.types.str;
      default = mtpName;
      description = "The draft head within {option}`services.avalon.modelPackage`'s MTP/ directory";
    };

    vision.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Accept images as well as text, by giving the server {option}`services.avalon.vision.package` with `-mm`. The engine builds llama.cpp's mtmd library either way, so this costs no rebuild - only the encoder file and the flag";
    };

    vision.package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.avalon-mmproj;
      description = "The multimodal projector: the vision tower the Qwen3.8-Flash-Next line shares, 907 MB. It comes from ISTA's quantization, not from Avalon's, which publishes no projector";
    };

    vision.file = lib.mkOption {
      type = lib.types.str;
      default = mmprojName;
      description = "The projector within {option}`services.avalon.vision.package`";
    };

    vision.maxTokens = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 576;
      description = "Image tokens per picture (--image-max-tokens); the file decides when null. The encoder works at 768x768 with 16-pixel patches and a 2x2 merge, so a full-resolution picture is 576 tokens";
    };

    vision.offload = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Encode on the GPU (add {option}`--no-mmproj-offload` to the server when false). The tower wants ~0.9 GiB of VRAM on top of the context and the expert cache, so a 20 GB card may want it off; that encodes on the CPU, which is slower per picture";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address (--host)";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Bind port (--port)";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/avalon";
      description = "The server's working directory, where llama.cpp writes its caches; created by
        StateDirectory when left at the default";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "avalon";
      description = "Account the server runs as";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "avalon";
      description = "Group the server runs as";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--no-jinja"
        "--flash-attn"
        "hybrid"
      ];
      description = "Appended to the command line after the upstream flags";
    };

    env = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        AMD_P2U_WAIT_ENABLE = "1";
        HIPBLASLT_HEURISTICS_CACHE_CAPACITY = "3000";
      };
      description = "Process environment for the unit, for the engine's tuning switches";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open {option}`services.avalon.port` in the firewall";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.stateDir == "/var/lib/avalon" || cfg.stateDir == "/var/lib/${cfg.user}";
        message = "services.avalon.stateDir must be /var/lib/${cfg.user}, which StateDirectory creates";
      }
    ];

    users.users.${cfg.user} = {
      group = cfg.group;
      isSystemUser = true;
    };
    users.groups.${cfg.group} = { };

    systemd.services.avalon = {
      description = "Avalon model server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = cfg.user;
        WorkingDirectory = cfg.stateDir;
        # The first prompt loads the graph and fills the expert cache, which takes minutes on a small
        # card: nothing may time the start out.
        TimeoutStartSec = "infinity";
        ExecStart = lib.escapeShellArgs (
          [
            "${cfg.package}/bin/llama-server"
            "-m"
            "${cfg.modelPackage}/${cfg.modelFile}"
            "-c"
            (toString cfg.maxContext)
            "-b"
            (toString cfg.batchSize)
            "-ub"
            (toString cfg.unifiedBatchSize)
            "-fa"
            "on"
            "-ctk"
            cfg.cacheQuantK
            "-ctv"
            cfg.cacheQuantV
            "--jinja"
            "--parallel"
            "1"
            "-md"
            "${cfg.modelPackage}/MTP/${cfg.mtpFile}"
            "--spec-type"
            "draft-mtp"
            "--spec-draft-n-max"
            (toString cfg.draftMax)
            "-ubd"
            (toString cfg.draftBatchSize)
            "-ctkd"
            cfg.draftCacheQuant
            "-ctvd"
            cfg.draftCacheQuant
            "--host"
            cfg.host
            "--port"
            (toString cfg.port)
          ]
          ++ lib.optionals cfg.vision.enable (
            [
              "-mm"
              "${cfg.vision.package}/${cfg.vision.file}"
            ]
            ++ lib.optionals (cfg.vision.maxTokens != null) [
              "--image-max-tokens"
              (toString cfg.vision.maxTokens)
            ]
            ++ lib.optionals (!cfg.vision.offload) [
              "--no-mmproj-offload"
            ]
          )
          ++ cfg.extraArgs
        );
        # cfg.env wins, so the workaround can be overridden by hand.
        Environment = lib.mapAttrsToList (name: value: "${name}=${value}") (
          lib.optionalAttrs cfg.launchBlocking {
            HIP_LAUNCH_BLOCKING = "1";
          }
          // cfg.env
        );
        Restart = "on-failure";
        RestartSec = 10;
        # The card is reached through the kernel driver, so /dev/kfd and /dev/dri stay visible (no
        # PrivateDevices) and the unit needs these groups.
        SupplementaryGroups = [
          "render"
          "video"
        ];
        # ROCm pins the resident experts, and wants an unlimited memlock for that
        LimitMEMLOCK = "infinity";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [ cfg.stateDir ];
      };
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [ cfg.port ];
  };
}
