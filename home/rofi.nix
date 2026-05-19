{ pkgs, ... }: {

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;  # Wayland-native version

    # Stylix themes Rofi automatically.
    # Only add non-colour config here.
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      drun-display-format = "{name}";
      display-drun = "Apps";
      display-run = "Run";
      display-window = "Windows";
      kb-primary-paste = "Control+V,Shift+Insert";
      kb-secondary-paste = "Control+v,Insert";
    };
  };

  # Bind Rofi to Super+Space via your desktop environment's keybinding settings.
  # In KDE: System Settings → Shortcuts → Custom Shortcuts
  # Command: rofi -show drun
}
