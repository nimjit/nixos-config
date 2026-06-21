# CLI Migration

Replacing persistent browser tabs with focused terminal tools.

## Status

| Tool | Status | Notes |
|------|--------|-------|
| nchat (WhatsApp) | Done | `messages()` shell function; kitty tab |
| New tab page | Done | Served at `localhost:8080`; New Tab Override extension |
| lastpass-cli | Done | `lpass-rofi.sh` installed; qutebrowser `<Alt-p>` bound |
| khal + vdirsyncer | Done | 12 Google calendars; `cal` alias |
| MPD + rmpc | Done | `music()` shell function + `<leader>m` in neovim |
| Neovim dashboards | Done | `vault-work`, `uni-work`, course view, `:DailyNote` |
| Typst rendering | Done | `<leader>tp` / `<leader>ta` |
| PDF viewer (zathura) | Done | `<leader>z`; kitty vsplit |
| w3m | Partial | Package added; `wb` shell function not yet written |
| qutebrowser | Done | Primary browser; `dd` close, `,M` mpv, `<Alt-p>` lpass |

---

## Open items

### KDE shortcut for lpass-rofi

`~/.local/bin/lpass-rofi` is installed. KDE shortcut (`Super+P`) is not yet
configured — do this in System Settings → Shortcuts → Custom Shortcuts.
Qutebrowser has `<Alt-p>` bound (via `qute-lastpass-auto` userscript).

### w3m terminal browser

w3m is in packages. Still needed:

```sh
WB_HOME="http://localhost:8080"

wb() {
    local url="${1:-$WB_HOME}"
    if [[ -n "$NVIM" ]]; then
        nvim --server "$NVIM" --remote-send ":botright split | terminal w3m $(printf '%q' "$url")<CR>"
    else
        w3m "$url"
    fi
}
```

Add to `home/zsh.nix` initContent. Inside neovim it opens a split; outside it
opens directly. Good fallback for text-heavy sites (Osiris, docs) and sites
where JavaScript isn't needed.

### Kitty splits philosophy

Currently yazi and claude open in neovim terminal splits. Once kitty splits
navigate with the same Ctrl+HJKL, these should move to kitty terminals instead.
Interactability (staying in insert mode, no normal-mode for tool use) matters
more than neovim integration for these. Discuss before changing.
