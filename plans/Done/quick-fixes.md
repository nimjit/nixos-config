# Quick Fixes Reference

## rmpc tab navigation

**Done.** `~/.config/rmpc/config.ron` is managed via `home.file` in `home/default.nix`.
`<C-h>` / `<C-l>` switch tabs. Also has `gt`/`gT` and number shortcuts `1`–`7`.

## Rofi + LastPass password picker

**Done.** `~/.local/bin/lpass-rofi` installed via `home.file` in `home/default.nix`
(with `executable = true`). Also available in qutebrowser via `<Alt-p>` →
`qute-lastpass-auto` userscript.

KDE keyboard shortcut (`Super+P` → `lpass-rofi.sh`) not yet configured —
do this in System Settings → Shortcuts → Custom Shortcuts.

## nchat notifications

**Done.** `libnotify` in packages. Restart nchat if notifications aren't firing.

## Kitty: disable Ctrl+Shift+[/]

**Not done.** Add to `home/kitty.nix`:

```nix
keybindings = {
  "ctrl+shift+]" = "no_op";
  "ctrl+shift+[" = "no_op";
};
```

## Rofi improvements

**Not done.** Two small changes:
- Increase icon size to 28px in `home/dotfiles/rofi/ukiyo.rasi`: `element-icon { size: 28px; }`
- Hide mode prefixes in `home/rofi.nix` extraConfig: `display-drun = ""; display-window = ""; display-combi = "";`

## nchat vim-style keybindings

nchat has no modal editing. Existing ctrl-bindings are close enough:
`Ctrl+J/K` navigate chats, `Ctrl+H` toggles chat list. Not worth further work.

## Waybar in KDE

Not building — Sway is binned.
