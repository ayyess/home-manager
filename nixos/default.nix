{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.home-manager;

  hmModule = types.submodule (
    import ../modules/modules.nix {
      inherit lib pkgs;
      nixosSubmodule = true;
    }
  );

  activateUser = username: usercfg: ''
    echo Activating home-manager configuration for ${username}
    ${pkgs.su}/bin/su -l -c ${usercfg.home.activationPackage}/activate ${username}
  '';

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
    systemd.services.home-manager = {
      description = "Activate Home Manager environments";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
      };

      script = concatStringsSep "\n" (mapAttrsToList activateUser cfg.users);
    };
  };
}
