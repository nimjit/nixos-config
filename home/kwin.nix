{ ... }: {

  # ── focus-by-position KWin script ────────────────────────────────────────────
  # Alt+H/J/K/L focuses the 1st/2nd/3rd/4th window sorted by screen position.
  # Enable after rebuild: kwriteconfig6 --file kwinrc --group Plugins --key focus-by-positionEnabled true
  #                       qdbus6 org.kde.KWin /KWin reconfigure

  xdg.dataFile."kwin/scripts/focus-by-position/metadata.json".text = ''
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
  '';

  xdg.dataFile."kwin/scripts/focus-by-position/contents/code/main.js".source =
    ./dotfiles/kwin/focus-by-position.js;

}
