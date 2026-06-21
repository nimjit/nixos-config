{ pkgs, config, ... }: {

  imports = [
    ./neovim.nix
    ./firefox.nix
    ./kitty.nix
    ./yazi.nix
    ./mpv.nix
    ./zsh.nix
    ./rofi.nix
    ./nchat.nix
    ./btop.nix
    ./emacs.nix
    ./mpd.nix
    ./zathura.nix
    ./khal.nix
    ./mako.nix
    ./qutebrowser.nix
    ./kwin.nix
    ./git.nix
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

  # ── New tab page server ───────────────────────────────────────────────────
  # Serves ~/.config/newtab/index.html at http://localhost:8080
  # Set that URL in "New Tab Override" extension in Firefox.
  systemd.user.services.newtab-server = {
    Unit.Description = "Local new tab page server";
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8080 --directory %h/.config/newtab --bind 127.0.0.1";
      Restart = "on-failure";
    };
  };

 # ── lpass-rofi password picker ────────────────────────────────────────────
  home.file.".local/bin/lpass-rofi" = {
    source     = ./dotfiles/lpass-rofi.sh;
    executable = true;
  };

  # ── YouTube TUI ───────────────────────────────────────────────────────────
  home.file.".local/bin/yt-feed" = {
    source     = ./dotfiles/yt-feed.py;
    executable = true;
  };

  # ── vim-kitty-navigator kitten ────────────────────────────────────────────
  home.file.".config/kitty/pass_keys.py".source = ./dotfiles/kitty/pass_keys.py;

  # ── rmpc keybindings ─────────────────────────────────────────────────────
  home.file.".config/rmpc/config.ron".source = ./dotfiles/rmpc/config.ron;

  # ── Snowflake regeneration ────────────────────────────────────────────────
  # Runs the three snowflake Python scripts 2 min after login to keep HTML fresh.
  systemd.user.services.snowflake-regen = {
    Unit.Description = "Regenerate snowflake HTML visualizations";
    Service = {
      Type      = "oneshot";
      ExecStart = pkgs.writeShellScript "snowflake-regen" ''
        python3 /etc/nixos/nixos_snowflake.py
        python3 /home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/vault_snowflake.py
        python3 /home/thijmen/Documents/BACKUP/Uni/Obsidian/uni_snowflake.py
      '';
    };
  };

  systemd.user.timers.snowflake-regen = {
    Unit.Description  = "Regenerate snowflakes 2 min after login";
    Timer.OnStartupSec = "2min";
    Install.WantedBy  = [ "timers.target" ];
  };

 # ── Warnings? ─────────────────────────────────────────────────────────────
  programs.neovim.withRuby = false;
  programs.neovim.withPython3 = false;
  programs.firefox.configPath = "${config.xdg.configHome}/mozilla/firefox";

}
