{ pkgs, ... }: {

  stylix = {
    enable = true;
    autoEnable = true;   # apply to all supported apps automatically

    # ── Colour scheme ─────────────────────────────────────────────────────
    # Uses your Ukiyo-derived palette from themes/ukiyo.nix.
    # To switch themes: change this one line and rebuild.
    base16Scheme = ../themes/ukiyo.nix;

    # Alternative: generate a palette from a wallpaper instead:
    # image = ../themes/wallpapers/your-wallpaper.jpg;
    # polarity = "dark";

    # ── Wallpaper ─────────────────────────────────────────────────────────
    # Stylix sets the wallpaper system-wide.
    # Add an image to themes/wallpapers/ and set the path here.
    # Until you add one, comment this out and set image above instead.
    image = ../themes/wallpapers/Pieter_Bruegel-Childrens_Games.jpg;

    # ── Fonts ─────────────────────────────────────────────────────────────
    fonts = {
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      sansSerif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = 13;
        applications = 11;
        desktop = 11;
        popups = 11;
      };
    };

    # ── Cursor ────────────────────────────────────────────────────────────
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    # ── Per-app overrides ─────────────────────────────────────────────────
    # Stylix themes most things automatically. Override specific apps here.
    # targets.firefox.enable = true;   # true by default
    targets.neovim.enable = false;     # hand-crafted Ukiyo.lua + init.lua overrides own the theme
    # targets.kitty.enable = true;     # true by default
    # targets.zathura.enable = true;   # true by default
  };
}
