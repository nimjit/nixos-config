{ pkgs, config, ... }: {

  # Register the startup script as a KDE autostart entry.
  # KDE runs this after the desktop has fully loaded.
  xdg.configFile."autostart/startup.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Startup Script
    Exec=${config.home.homeDirectory}/.config/startup/startup.sh
    Hidden=false
    X-KDE-autostart-phase=2
  '';

  # The startup script itself
  xdg.configFile."startup/startup.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # ── Startup Script ───────────────────────────────────────────────────
      # Launches applications onto specific virtual desktops and monitors.
      # KDE virtual desktops are numbered from 1.
      # Monitors are identified by name (run `xrandr` to find yours).
      #
      # To modify: edit this file and re-login, or run it manually to test:
      #   ~/.config/startup/startup.sh
      #
      # Dependencies: wmctrl, xdotool (declared in modules/common.nix)
      # ─────────────────────────────────────────────────────────────────────

      # Wait for KDE to fully settle before launching anything.
      # Increase this if apps open on the wrong desktop.
      sleep 5

      # ── Helper functions ──────────────────────────────────────────────────

      # Switch to a virtual desktop (1-indexed)
      switch_desktop() {
        wmctrl -s $(( $1 - 1 ))
      }

      # Open a URL in a new firefox window and move it to a monitor.
      # Usage: open_firefox_window <url> [<url2> ...]
      # Moving to specific monitor is done via KWin rules or xdotool (see below).
      open_firefox_window() {
        firefox --new-window "$1" &
        sleep 1  # wait for window to open
        # Open additional tabs in the same window
        shift
        for url in "$@"; do
          firefox --new-tab "$url" &
          sleep 0.3
        done
      }

      # Move the most recently opened window to a virtual desktop (1-indexed)
      # and optionally to a position (for monitor placement).
      # Usage: move_last_window <desktop> <x_position>
      # x_position: 0 = left monitor, 3840 = right monitor (adjust for your resolution)
      move_last_window() {
        local desktop=$1
        local x_pos=$2
        local win_id=$(xdotool getactivewindow 2>/dev/null || xdotool search --sync --onlyvisible --name "" | tail -1)
        wmctrl -i -r "$win_id" -t $(( desktop - 1 ))
        if [ -n "$x_pos" ]; then
          wmctrl -i -r "$win_id" -e "0,$x_pos,0,-1,-1"
        fi
      }

      # ── Monitor layout ────────────────────────────────────────────────────
      # Left monitor:  x=0     (Philips, DisplayPort)
      # Right monitor: x=3840  (Dell, HDMI)
      # Run `xrandr` to confirm these values if windows appear on wrong monitor.
      LEFT=0
      RIGHT=3840

      # ── Desktop 1: Uni work ───────────────────────────────────────────────
      switch_desktop 1

      # Left monitor: Obsidian - Uni vault
      obsidian "obsidian://open?vault=Uni" &
      sleep 2
      move_last_window 1 $LEFT

      # Right monitor: Firefox - Brightspace
      open_firefox_window "https://brightspace.tudelft.nl"
      move_last_window 1 $RIGHT

      # Opened last so it ends up on top of the firefox window
      switch_desktop 1
      kitty --title "uni-coding" &
      sleep 1
      move_last_window 1 $RIGHT

      # ── Desktop 2: Personal ───────────────────────────────────────────────
      switch_desktop 2

      # Left monitor: Obsidian - Renaissance vault
      obsidian "obsidian://open?vault=Renaissance_Vault_Structure" &
      sleep 2
      move_last_window 2 $LEFT

      # Right monitor: Firefox - Personal (YouTube + WhatsApp)
      open_firefox_window "https://youtube.com" "https://web.whatsapp.com"
      move_last_window 2 $RIGHT

      # ── Desktop 3: Sync/Admin ─────────────────────────────────────────────
      switch_desktop 3

      # Left: Tailscale admin (not critical, comment out if not needed)
      open_firefox_window "https://login.tailscale.com/admin/machines"
      move_last_window 3 $RIGHT

      # Right: Syncthing web UI
      open_firefox_window "http://localhost:8384/"
      move_last_window 3 $RIGHT

      # ── Desktop 4: NixOS work ─────────────────────────────────────────────
      switch_desktop 4

      # Left monitor: Firefox - Claude
      # Note: this URL may expire; update it to https://claude.ai to get a fresh chat
      open_firefox_window "https://claude.ai"
      move_last_window 4 $LEFT

      # Left monitor: Kitty - nixos-issues.md
      kitty --title "nixos-issues" \
        nvim /home/thijmen/Documents/BACKUP/nixos-issues.md &
      sleep 1
      move_last_window 4 $LEFT

      # Left monitor: Kitty - NixOS config
      kitty --title "nixos-config" \
        cd /etc/nixos
        sudo -E nvim . &
      sleep 1
      move_last_window 4 $LEFT

      # ── Return to desktop 2 on login ──────────────────────────────────────
      switch_desktop 2

      echo "Startup complete"
    '';
  };
}
