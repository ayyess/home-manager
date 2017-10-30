{ config, lib, pkgs, utils, ... }:

with lib;

let

  cfg = config.home-manager;

  hmModule = types.submodule (
    import ../modules/modules.nix {
      inherit lib pkgs;
      nixosSubmodule = true;
    }
  );

in

{
  options = {
    home-manager.users = mkOption {
      type = types.attrsOf hmModule;
      default = {};
      description = ''
        Per-user Home Manager configuration.
      '';
    };
  };

  config = mkIf (cfg.users != {}) {
    systemd.services = mapAttrs' (username: usercfg:
      nameValuePair ("home-manager-${utils.escapeSystemdPath username}") {
        description = "Home Manager environment for ${username}";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          User = username;

          # The activation script is run by a login shell to make sure
          # that the user is given a sane Nix environment.
          ExecStart = pkgs.writeScript "activate-${username}" ''
            #! ${pkgs.stdenv.shell} -el
            echo Activating home-manager configuration for ${username}
            exec ${usercfg.home.activationPackage}/activate
          '';
        };
      }
    ) cfg.users;
  };
}
