{ pkgs, lib, ... }: {

  programs.rofi = {
    enable  = true;
    package = pkgs.rofi-wayland;   # rofi is X11; rofi-wayland is the actual Wayland build
    theme   = lib.mkForce ./dotfiles/rofi/ukiyo.rasi;

    extraConfig = {
      # combi merges drun + power-menu into one list — type "kit" for kitty, "shut" for shutdown
      modi              = "combi,window";
      combi-modi        = "drun,power-menu:rofi-power-menu";
      show-icons        = true;
      drun-display-format = "{name}";
      kb-primary-paste  = "Control+V,Shift+Insert";
      kb-secondary-paste = "Control+v,Insert";
    };
  };

  home.packages = [ pkgs.rofi-power-menu ];

  # KDE keybind: System Settings → Shortcuts → Custom Shortcuts
  #   Alt+Space  →  rofi -show combi
}
