{ pkgs, ... }: {

  programs.rofi = {
    enable  = true;
    package = pkgs.rofi-wayland;   # rofi is X11; rofi-wayland is the actual Wayland build
    theme   = ./dotfiles/rofi/ukiyo.rasi;

    extraConfig = {
      modi               = "drun,run,window,power-menu:rofi-power-menu";
      show-icons         = true;
      drun-display-format = "{name}";
      display-drun       = "  Apps";
      display-run        = "  Run";
      display-window     = "  Windows";
      display-power-menu = "  Power";
      kb-primary-paste   = "Control+V,Shift+Insert";
      kb-secondary-paste = "Control+v,Insert";
    };
  };

  # rofi-power-menu: adds shutdown/reboot/suspend/lock as a rofi mode
  home.packages = [ pkgs.rofi-power-menu ];

  # Keybinds — set in KDE: System Settings → Shortcuts → Custom Shortcuts
  #   Alt+Space        → rofi -show drun        (app launcher)
  #   Alt+Shift+Space  → rofi -show power-menu  (shutdown / reboot / …)
}
