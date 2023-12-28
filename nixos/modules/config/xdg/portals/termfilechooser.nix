{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.xdg.portal.termfilechooser;
  package = pkgs.xdg-desktop-portal-termfilechooser;
  settingsFormat = pkgs.formats.ini { };
  configFile = settingsFormat.generate "xdg-desktop-portal-termfilechooser.ini" cfg.settings;
in
{
  meta = {
    maintainers = with maintainers; [ soispha ];
  };

  options.xdg.portal.termfilechooser = {
    enable = mkEnableOption (lib.mdDoc ''
      Desktop portal for wlroots-based desktops

      This will add the `xdg-desktop-portal-termfilechooser` package into
      the {option}`xdg.portal.extraPortals` option, and provide the
      configuration file
    '');

    settings = mkOption {
      description = lib.mdDoc ''
        Configuration for `xdg-desktop-portal-termfilechooser`.

        See `xdg-desktop-portal-termfilechooser(5)` for supported
        values.
      '';

      type = types.submodule {
        freeformType = settingsFormat.type;
      };

      default = { };

      # Example taken from the manpage
      example = literalExpression ''
        {
          screencast = {
            output_name = "HDMI-A-1";
            max_fps = 30;
            exec_before = "disable_notifications.sh";
            exec_after = "enable_notifications.sh";
            chooser_type = "simple";
            chooser_cmd = "''${pkgs.slurp}/bin/slurp -f %o -or";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [ package ];
    };

    systemd.user.services.xdg-desktop-portal-termfilechooser.serviceConfig.ExecStart = [
      # Empty ExecStart value to override the field
      ""
      "${package}/libexec/xdg-desktop-portal-termfilechooser --config=${configFile}"
    ];
  };
}

