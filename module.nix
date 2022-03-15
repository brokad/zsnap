{ lib, config, pkgs, ... }: {
  options.services.zsnap = with lib.options; {
    enable = mkEnableOption "zsnap";
    prune = mkEnableOption "pruning old snapshots";
    identityFile = mkOption {
      description = "path to identity file to use for ssh";
      type = lib.types.path;
    };
    sync = mkOption {
      description = "how to map local datasets with remote datasets";
      type = lib.types.listOf (lib.types.submodule {
        options = {
          source = mkOption {
            description = "source dataset";
            type = lib.types.str;
          };
          destination = mkOption {
            description = "destination dataset";
            type = lib.types.str;
          };
        };
      });
      example = [ {
        source = "pool0/root";
        destination = "gce0/root";
      } ];
      default = {};
    };
  };
  config = lib.mkIf config.services.zsnap.enable {
    systemd = {
      timers.zfs-auto-snapshot-sync = {
        description = "syncs and prunes zfs auto-snapshots";
        wantedBy = [ "basic.target" ];
        timerConfig = {
          OnCalendar = "hourly";
          Unit = "zfs-auto-snapshot-sync.service";
        };
      };
      services.zfs-auto-snapshot-sync = with config.services.zsnap; {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = let
            mkZsnapCmd = { source, destination }: let
              pruneFlag = if prune then "--prune" else "";
            in "${pkgs.zsnap}/bin/zsnap --identity-file=${identityFile} sync ${pruneFlag} ${source} ${destination}";
            mappingAsCmd = map mkZsnapCmd sync;
            runZsnap = pkgs.writeScript "runZsnap.sh"
              (lib.lists.foldl (st: new: "${st}\n${new}") "" mappingAsCmd);
          in "${pkgs.runtimeShell} ${runZsnap}";
        };
      };
    };
  };
}
