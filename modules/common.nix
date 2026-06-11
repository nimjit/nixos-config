{ pkgs, username, ... }: {

  # ── Nix settings ──────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # ── Allow unfree packages ─────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  # ── Locale and timezone ───────────────────────────────────────────────────
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
  };
  # ── Networking ────────────────────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # ── System packages ───────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    curl
    wget
    ripgrep       # fast grep; used by neovim too
    fd            # fast find
    unzip
    zip
    khal          # terminal calendar (multi-calendar, ikhal TUI)
    vdirsyncer    # syncs Google Calendar collections to local filesystem
    ghostscript   # required by ImageMagick (used by image.nvim)
    poppler-utils # pdftoppm + pdfinfo — terminal PDF rendering
    btop          # system monitor
    fastfetch     # system info (replaces neofetch)
    nh
    bat
    eza
    zoxide

    # Applications
    obsidian
    discord
    firefox
    neovim
    mpv
    kitty
    yazi          # file manager: vim keys + mouse support + image preview
    qbittorrent
    zathura       # PDF viewer; themed by Stylix automatically
    thunderbird   # email client; connects to Outlook via IMAP
    calcurse

    # AI
    claude-code

    # CLI tools
    nchat          # WhatsApp in terminal (desktop notifications, no browser tab)
    lastpass-cli   # lpass CLI — same vault as LastPass extension
    libnotify      # provides notify-send; nchat auto-detects it for desktop notifications
    fortune        # random quote for the zsh greeting

    # Media
    spotify
    mpc            # CLI control for MPD (mpc toggle, mpc next, etc.)
    rmpc           # TUI music client with album art via kitty graphics protocol

    # Wayland / sway tools
    grim                  # Wayland screenshot
    slurp                 # region selector for grim
    wl-clipboard          # wl-copy / wl-paste
    wlsunset              # time-based night colour
    brightnessctl         # brightness keys
    playerctl             # media keys
    networkmanagerapplet  # nm-applet tray icon
    polkit_gnome          # GUI privilege dialogs
    xdg-desktop-portal-wlr # screen sharing from Firefox / Wayland apps

    # Theming tools
    nwg-look      # GTK theme tweaker

    # Emacs dependencies
    tinymist   # Typst LSP (used by typst-ts-mode via eglot)
    enchant_2   # spell-check backend for jinx
    (hunspellWithDicts [ hunspellDicts.en_US hunspellDicts.nl_NL ])

    # Languages
      # Python
    (python3.withPackages (ps: with ps; [
      numpy
      matplotlib
      tqdm
      ipython
    ]))
      # Rust
    rustup        # installs cargo, rustc, rust-analyzer
      # Typst
    typst

    # Tools
    direnv        # per-project environments
    wmctrl
    xdotool
  ];
  # ── Obsidian ──────────────────────────────────────────────────────────────
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # ── Steam ─────────────────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # ── Fonts ─────────────────────────────────────────────────────────────────
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
      corefonts            # Microsoft fonts (for documents)
      cm_unicode
    ];

    # Custom font (CMU Typewriter — if you have the .ttf files)
    # Place .ttf files in themes/fonts/ and uncomment:
    # packages = fonts.packages ++ [
    #   (pkgs.stdenvNoCC.mkDerivation {
    #     name = "cmu-typewriter";
    #     src = ../themes/fonts;
    #     installPhase = ''
    #       mkdir -p $out/share/fonts/truetype
    #       cp *.ttf $out/share/fonts/truetype/
    #     '';
    #   })
    # ];

    fontconfig.defaultFonts = {
      serif = [ "CMU Typewriter Text" "Noto Serif" ];
      sansSerif = [ "JetBrainsMono Nerd Font" "Noto Sans" ];
      monospace = [ "JetBrainsMono Nerd Font Mono" ];
    };
  };

  # ── Auto-update service ───────────────────────────────────────────────────
  # Pulls latest config from GitHub and rebuilds on boot and daily.
  # Requires the config to be cloned at /etc/nixos.
  # (On first install it won't exist yet; the service will fail silently
  #  until you clone the repo there, which the install guide covers.)

  systemd.services.nixos-autoupdate = {
    description = "Pull latest NixOS config and rebuild";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "nixos-autoupdate" ''
        set -e
        CONFIG_DIR="/etc/nixos"
        if [ ! -d "$CONFIG_DIR/.git" ]; then
          echo "Config dir is not a git repo; skipping update"
          exit 0
        fi
        cd "$CONFIG_DIR"
        ${pkgs.git}/bin/git pull --ff-only origin main || {
          echo "Git pull failed; skipping rebuild"
          exit 0
        }
        /run/current-system/sw/bin/nixos-rebuild switch --flake ".#$(hostname)" \
          && echo "Rebuild succeeded" \
          || echo "Rebuild failed; system unchanged"
      '';
    };
  };

  systemd.timers.nixos-autoupdate = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";      # run 5 min after boot
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30min";
    };
  };

  # ── Health check service ──────────────────────────────────────────────────
  systemd.services.nixos-health = {
    description = "NixOS system health check";
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "nixos-health" ''
        echo "====== NixOS Health Check ======"
        echo ""
        echo "-- Failed services --"
        systemctl --failed --no-legend || true
        echo ""
        echo "-- Disk usage --"
        df -h / /boot
        echo ""
        echo "-- Nix store size --"
        du -sh /nix/store 2>/dev/null || true
        echo ""
        echo "-- Recent generations --"
        /run/current-system/sw/bin/nixos-rebuild list-generations 2>/dev/null | tail -5 || true
        echo ""
        echo "-- Syncthing status --"
        systemctl is-active syncthing 2>/dev/null || echo "syncthing not running"
        echo ""
        echo "=============================="
      '';
    };
  };

  # Run health check on boot; view with: journalctl -u nixos-health
  systemd.timers.nixos-health = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      Persistent = false;
    };
  };

  # ── Shell ─────────────────────────────────────────────────────────────────
programs.zsh.enable = true;
users.users.${username}.shell = pkgs.zsh;
}
