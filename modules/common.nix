{ pkgs, username, ... }:

let
  # Packaged as a system derivation so KWin discovers it at startup the same
  # way it discovers Krohnkite — via the system XDG data path.
  kwinFocusByPosition = pkgs.runCommand "kwin-focus-by-position" {} ''
    mkdir -p $out/share/kwin/scripts/focus-by-position/contents/{code,ui}
    cp ${../home/dotfiles/kwin/focus-by-position.qml} \
       $out/share/kwin/scripts/focus-by-position/contents/ui/main.qml
    cp ${../home/dotfiles/kwin/focus-by-position.js} \
       $out/share/kwin/scripts/focus-by-position/contents/code/main.js
    cat > $out/share/kwin/scripts/focus-by-position/metadata.json << 'JSON'
    {
      "KPlugin": {
        "Authors": [{ "Name": "thijmen" }],
        "Description": "Focus windows by screen position (Alt+HJKL)",
        "Id": "focus-by-position",
        "License": "MIT",
        "Name": "Focus by Position",
        "Version": "1.0"
      },
      "X-Plasma-API-Minimum-Version": "6.0"
    }
    JSON
  '';
in

{

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
    # calcurse removed — using khal/ikhal instead

    # AI
    claude-code

    # Terminal tools
    wiki-tui   # Wikipedia TUI; K in neovim markdown opens vsplit
    yt-dlp     # YouTube downloader; used by mpv and the yt-feed TUI
    w3m        # text-mode browser; natural terminal theming; used for text-heavy sites

    # CLI tools
    nchat          # WhatsApp in terminal (desktop notifications, no browser tab)
    lastpass-cli   # lpass CLI — same vault as LastPass extension
    libnotify      # provides notify-send; nchat auto-detects it for desktop notifications
    dtach          # detach/reattach a process from its terminal; keeps nchat alive
    fortune        # random quote for the zsh greeting
    nvd            # diff two NixOS generations: what actually changed

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
      nbformat      # read/write Jupyter notebook files
      nbconvert     # ipynb → markdown/HTML conversion
    ]))
      # Rust
    rustup        # installs cargo, rustc, rust-analyzer
      # Typst
    typst
    pandoc          # document converter; used by ereader export and courseware pipeline

    # KDE tiling + decoration
    pkgs.kdePackages.krohnkite   # DWM-style dynamic tiling for KWin 6 (anametologin fork)
    pkgs.klassy                  # window decoration with coloured active border support
    kwinFocusByPosition          # Alt+HJKL positional window focus

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
  # Disabled on desktop — too risky (bad commit = broken boot, no notification).
  # Re-enable on the USB install where unattended self-updating makes sense.
  # To re-enable: uncomment both blocks below and set the correct hostname in
  # the ExecStart flake target.
  #
  # systemd.services.nixos-autoupdate = { ... };
  # systemd.timers.nixos-autoupdate   = { ... };

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
