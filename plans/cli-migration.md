# CLI Migration

Replacing persistent browser tabs with focused terminal tools.

## Status

| Tool | Status | Notes |
|------|--------|-------|
| nchat (WhatsApp) | ✓ Done | `messages()` shell function; kitty tab |
| New tab page | ✓ Done | Served at `localhost:8080`; New Tab Override extension |
| lastpass-cli | ✓ Done | `LPASS_CLIPBOARD_COMMAND=wl-copy` set; no rofi script yet |
| khal + vdirsyncer | ✓ Done | 12 Google calendars; `cal` alias; look needs polish → see `theme-workflow.md` |
| MPD + rmpc | ✓ Done | `music()` shell function + `<leader>m` in neovim |
| Neovim dashboards | ✓ Done | `vault-work`, `uni-work`, course view, `:DailyNote` |
| Typst rendering | ✓ Done | `<leader>tp` / `<leader>ta`; math blocks supported |
| PDF/image viewer | ✓ Done | `<leader>z`; kitty vsplit with pre-rendered pages |

## Remaining open items

### Rofi password picker (lastpass-cli)

A rofi script for system-wide password copy via keyboard shortcut. Not yet written.

```bash
# lpass-rofi: fuzzy-pick a LastPass entry and copy its password
entries=$(lpass ls --long 2>/dev/null)
selected=$(echo "$entries" | rofi -dmenu -p "Password:" -i -format 'i')
name=$(echo "$entries" | sed -n "$((selected+1))p" | sed 's/ \[id:.*\]//')
lpass show --clip "$name" && notify-send "LastPass" "Copied: $name" --expire-time=3000
```

Add keyboard shortcut in KDE or Sway (`Super+P`). Depends on `wl-clipboard`.

### vdirsyncer: architecture notes

Google's CalDAV discovery only returns owned calendars. Shared calendars need
explicit pairs with hardcoded CalDAV URLs.

`~/.config/vdirsyncer/config` is NOT in git — it contains OAuth credentials and is
modified by `vdirsyncer discover`. Replicate manually on new machines.

Calendars syncing (12 total): Work, Sport, Fun, Semi-productive, Mindfulness,
Feestdagen (owned); D&D in Space, Lisan Shared 2, Lisan + Thijmen (writer access);
Bolk: Algemeen, TU Delft timetable (reader access); one unknown shared calendar.

### nchat keybindings

nchat ships with arrow-key defaults. Remap to vim keys in `~/.config/nchat/ui.conf`:
`ctrl+h/l` to move between panes, `j/k` to scroll, `i` for compose, `Escape` for
normal mode, `:q` to quit.
