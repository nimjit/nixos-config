# Quick Fixes Reference

## rmpc tab navigation

**Done.** `~/.config/rmpc/config.ron` is managed via `home.file` in `home/default.nix`.

Key remaps (from default `<Tab>` / `<S-Tab>`):

```ron
"<C-l>": NextTab,
"<C-h>": PreviousTab,
```

Also available: `gt` / `gT` (vim-style) and number keys `1`–`7` for direct tab jump.

Note: `<C-h>` sends the same byte as Backspace in some terminals — test in kitty
first. Fallback: `<C-Right>` / `<C-Left>`.

---

## Rofi + LastPass password picker

**Done.** `~/.local/bin/lpass-rofi` installed via `home.file` in `home/default.nix`
(with `executable = true`). Also available in qutebrowser via `<Alt-p>` →
`qute-lastpass-auto` userscript.

The script:

```bash
#!/usr/bin/env bash
set -euo pipefail

if ! lpass status -q 2>/dev/null; then
    notify-send "LastPass" "Not logged in. Run: lpass login <email>" --expire-time=4000
    exit 1
fi

entries=$(lpass ls --long 2>/dev/null) || exit 1
selected=$(echo "$entries" | rofi -dmenu -p " Password:" -i -format 'i' -no-custom)
[ -z "$selected" ] && exit 0

name=$(echo "$entries" | sed -n "$((selected+1))p" | sed 's/ \[id:.*\]//')
lpass show --clip "$name" && \
    notify-send "LastPass" "Copied: $name" --expire-time=3000
```

KDE keyboard shortcut (`Super+P`) not yet configured — do this in
System Settings → Shortcuts → Custom Shortcuts.

---

## nchat notifications

**Done.** `libnotify` in packages provides `notify-send`. nchat auto-detects it
at startup. See `notifications.md` for full detail.

---

## Kitty: disable Ctrl+Shift+[/]

**Not done.** kitty's default `ctrl+shift+[` / `ctrl+shift+]` (linear window
cycling) still active alongside the directional `ctrl+shift+hjkl` — confusing.

Fix in `home/kitty.nix`:

```nix
keybindings = {
  "ctrl+shift+]" = "no_op";
  "ctrl+shift+[" = "no_op";
};
```

---

## Rofi icon size and mode prefix cleanup

**Not done.** Two small cosmetic changes:

```nix
# home/dotfiles/rofi/ukiyo.rasi
# element-icon { size: 20px; }  →  size: 28px

# home/rofi.nix extraConfig
display-drun   = "";
display-window = "";
display-combi  = "";
```

The display-* lines remove the `[drun]` / `[window]` prefix labels in combi mode.
`drun-display-format = "{name}"` is already set (removes app category suffix).

---

## nchat vim-style keybindings

nchat has no modal editing — all keys go to the compose field. The existing
ctrl-bindings are already close enough:

| Action | Key |
|--------|-----|
| Next chat | `Ctrl+J` |
| Prev chat | `Ctrl+K` |
| Toggle chat list | `Ctrl+H` |
| Send message | `Ctrl+X` or `Enter` |
| Quit | `Ctrl+Q` |

Not worth further effort — the absence of a normal mode is a fundamental nchat
limitation, not a config problem.

---

## Waybar in KDE

Not building — Sway is binned. Status bar deferred indefinitely; see
`notifications.md` for alternatives.
