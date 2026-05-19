{ pkgs, config, ... }: {

  imports = [
    ./neovim.nix
    ./firefox.nix
    ./kitty.nix
    ./yazi.nix
    ./mpv.nix
    ./zsh.nix
    ./rofi.nix
  ];

  # ── Home basics ───────────────────────────────────────────────────────────
  home.username = "thijmen";       # keep in sync with flake.nix
  home.homeDirectory = "/home/thijmen";
  home.stateVersion = "25.05";

  # ── XDG dirs ──────────────────────────────────────────────────────────────
  xdg.enable = true;

  # ── userChrome.css ────────────────────────────────────────────────────────
  # Declared in firefox.nix; the file lives at home/dotfiles/userChrome.css

  # ── Direnv ────────────────────────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ── Git ───────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user.name = "nimjit";
      user.email = "tidemanus@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = false;
    };
    extraConfig = {
      credential.helper = "store";
    };
  };


 # ── Warnings? ─────────────────────────────────────────────────────────────
  gtk.gtk4.theme = null;
  programs.neovim.withRuby = false;
  programs.neovim.withPython3 = false;
  programs.firefox.configPath = "${config.xdg.configHome}/mozilla/firefox";



}
