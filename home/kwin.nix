{ ... }: {

  # ── focus-by-position KWin script ────────────────────────────────────────────
  # Alt+H/J/K/L focuses the 1st/2nd/3rd/4th window sorted by screen position.
  # The script is loaded via autostart because KWin 6 doesn't reliably auto-load
  # user scripts from ~/.local/share/kwin/scripts/ even when Enabled=true in kwinrc.

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

  # Load the script at login (KWin 6 doesn't auto-load user scripts reliably)
  xdg.configFile."autostart/load-focus-by-position.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Load focus-by-position KWin script
    Exec=qdbus org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript /home/thijmen/.local/share/kwin/scripts/focus-by-position/contents/code/main.js focus-by-position
    X-KDE-autostart-phase=2
  '';

}
