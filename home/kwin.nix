{ ... }: {

  # ── focus-by-position KWin script ────────────────────────────────────────────
  # Script is packaged as a system derivation in modules/common.nix so KWin
  # discovers it at startup via the system XDG data path (same as Krohnkite).
  # Enable once after first install:
  #   kwriteconfig6 --file kwinrc --group Plugins --key focus-by-positionEnabled true
  #   qdbus org.kde.KWin /KWin reconfigure

  # ── Restore Klassy after Stylix resets it ────────────────────────────────────
  # Stylix's stylix-activate-kde.desktop runs at KDE autostart Phase 2 and
  # resets the window decoration to Breeze. KDE runs Phase 2 entries in
  # alphabetical filename order, so "zzz-..." fires after "stylix-...".
  # The 3 s sleep covers any remaining race; qdbus reconfigure applies it live.
  xdg.configFile."autostart/zzz-kwin-restore-klassy.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Restore Klassy window decoration
    Exec=sh -c "sleep 3 && kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.klassy && kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Klassy && qdbus org.kde.KWin /KWin reconfigure"
    Hidden=false
    X-KDE-AutostartScript=true
  '';

}
