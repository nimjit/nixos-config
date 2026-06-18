{ ... }: {

  # ── focus-by-position KWin script ────────────────────────────────────────────
  # Script is packaged as a system derivation in modules/common.nix so KWin
  # discovers it at startup via the system XDG data path (same as Krohnkite).
  # Enable once after first install:
  #   kwriteconfig6 --file kwinrc --group Plugins --key focus-by-positionEnabled true
  #   qdbus org.kde.KWin /KWin reconfigure

}
