{ pkgs, config, ... }: {

  imports = [
    ./neovim.nix
    ./firefox.nix
    ./kitty.nix
    ./yazi.nix
    ./mpv.nix
    ./zsh.nix
    ./rofi.nix
    ./email.nix
  ];

  # ── Home basics ───────────────────────────────────────────────────────────
  home.username = "thijmen";       # keep in sync with flake.nix
  home.homeDirectory = "/home/thijmen";
  home.stateVersion = "24.11";

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
    userName = "nimjit";
    userEmail = "tidemanus@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };
}
