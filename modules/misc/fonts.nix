{config, pkgs, lib, ...}:

let
  cfg = config.fonts;
in

with lib;

{
  options = {
    fonts.fonts = mkOption {
      type = types.listOf types.package;
      default = [];
      example = literalExample "[ pkgs.dejavu_fonts ]";
      description = "List of fonts.";
    };
  };

  config = {
    home.packages = cfg.fonts;

    home.file."${config.xdg.cacheHome}/hm-fonts" = let
      getHash = drv: builtins.elemAt (builtins.match "${builtins.storeDir}/([a-z0-9]{32})-.*.drv" drv.drvPath) 0;
    in {
      text = concatMapStringsSep "\n" getHash cfg.fonts;
      onChange = ''
        echo "Caching fonts"
        $DRY_RUN_CMD fc-cache -f
      '';
    };
  };
}
