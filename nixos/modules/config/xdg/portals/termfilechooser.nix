{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.xdg.portal.termfilechooser;
  package = pkgs.xdg-desktop-portal-termfilechooser;
  settingsFormat = pkgs.formats.ini {};
  configFile = settingsFormat.generate "xdg-desktop-portal-termfilechooser.ini" cfg.settings;
in {
  meta = {
    maintainers = with maintainers; [soispha];
  };

  options.xdg.portal.termfilechooser = {
    enable = mkEnableOption (lib.mdDoc ''
      Desktop portal for wlroots-based desktops

      This will add the `xdg-desktop-portal-termfilechooser` package into
      the {option}`xdg.portal.extraPortals` option, and provide the
      configuration file
    '');

    logLevel = mkOption {
      description = lib.mdDoc ''
        Which log level to use
      '';
      type = types.enum ["QUIET" "ERROR" "WARN" "INFO" "DEBUG" "TRACE"];
      default = "ERROR";
    };

    settings = mkOption {
      description = lib.mdDoc ''
        Configuration for `xdg-desktop-portal-termfilechooser`.

        See `xdg-desktop-portal-termfilechooser(5)` for supported
        values.
      '';

      type = types.submodule {
        freeformType = settingsFormat.type;
      };

      default = {};

      # Example taken from the manpage
      example = literalExpression ''
        {
          filechooser = {
            # Beware that the script will be executed from a systemd service, thus, none
            # of your enviroment variables will be set including PATH
            cmd = ./your/command/ranger-wrapper.sh;
            default_dir = "/tmp";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [package];
    };

    systemd.user.services.xdg-desktop-portal-termfilechooser = {
      overrideStrategy = "asDropinIfExists";

      # override default exec start
      serviceConfig.ExecStart = [
        # Empty ExecStart value to override the field
        ""
        "${package}/libexec/xdg-desktop-portal-termfilechooser --config=${configFile} --loglevel=${cfg.logLevel}"
      ];
    };
  };
}
