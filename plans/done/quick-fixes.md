# Quick Fixes & Small Additions

A collection of small improvements that can each be implemented in one session.
Roughly ordered by ease.

---

## 1. nchat desktop notifications

### Status: needs restart

`notify-send` IS in PATH and works. `ui.conf` is already fully configured:

```
desktop_notify_enabled=1
desktop_notify_inactive=1
desktop_notify_active_noncurrent=1
desktop_notify_command=          ← empty = auto-detect notify-send
```

The most likely reason notifications aren't firing: nchat was launched before the
`libnotify` rebuild and hasn't been restarted since. It probes for `notify-send`
at startup.

**Fix:** close the messages kitty tab and reopen with `messages()`. If notifications
still don't fire after restart, set `desktop_notify_command=notify-send` explicitly
in `~/.config/nchat/ui.conf` (it falls back to `command 'notify-send'` string search
which may differ by PATH at startup).

**No file changes needed** — this is a runtime-only issue.

---

## 2. Kitty: disable default ctrl+shift+[] window cycling

### Current state

`ctrl+shift+hjkl` → `neighboring_window` is configured and works. But kitty's built-in
`ctrl+shift+[` / `ctrl+shift+]` (cycle through all windows linearly) are still active
as defaults, which is confusing alongside the directional bindings.

### Fix

Add no-op overrides in `home/kitty.nix`:

```nix
"ctrl+shift+]" = "no_op";
"ctrl+shift+[" = "no_op";
```

**File:** `home/kitty.nix`

---

## 3. Rofi improvements

### 3a. Bigger icons

`element-icon { size: 20px; }` in `ukiyo.rasi`. Change to `28px` for a more
comfortable icon size at 4K scale 1.2.

### 3b. Hide mode prefixes

In combi mode rofi prepends `[drun]` / `[window]` labels before each entry.
Two config keys suppress this:

```nix
display-drun   = "";
display-window = "";
display-combi  = "";
```

`drun-display-format = "{name}"` is already set (removes app category suffix).

**File:** `home/rofi.nix` (extraConfig) + `home/dotfiles/rofi/ukiyo.rasi` (icon size)

---

## 4. Rofi + LastPass password picker

A rofi script that fuzzy-picks a LastPass entry and copies its password to clipboard.

### Script (`home/dotfiles/lpass-rofi.sh`)

```bash
#!/usr/bin/env bash
# lpass-rofi: fuzzy-pick a LastPass entry and copy its password
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

### Wiring

- Make executable: `chmod +x` via `home.file` with `executable = true`
- Add shortcut in KDE: System Settings → Shortcuts → Custom Shortcuts → `lpass-rofi.sh`
  bound to `Super+P`
- In Sway (when migrated): `"${mod}+p" = "exec lpass-rofi.sh"`
- Requires being logged in: `lpass login tidemanus@gmail.com` once per session
  (lpass stays logged in for the session by default)

**Files:** `home/default.nix` (add file entry), `home/sway.nix` (future keybind)

---

## 5. rmpc tab navigation: Tab → Ctrl+HL

rmpc uses RON config format. Default tab navigation:

```
"<Tab>":   NextTab
"<S-Tab>": PreviousTab
```

### Fix

Generate `~/.config/rmpc/config.ron` via home-manager `home.file` with the keybinds
section remapped:

```ron
"<C-l>": NextTab,
"<C-h>": PreviousTab,
```

Keep `gt`/`gT` and number shortcuts (`1`–`7`) as secondary bindings.

**Note:** `<C-h>` sends the same byte as Backspace in some terminals. Test in kitty
first. If it conflicts, fall back to `<C-Right>` / `<C-Left>` instead.

**File:** `home/default.nix` — add `home.file.".config/rmpc/config.ron"`

---

## 6. nchat vim-style keybindings

### Limitation

nchat does not have modal editing. There is no "normal mode" vs "insert mode" concept
— all letter keypresses go to the compose field regardless of focus. You cannot bind
bare `j`/`k` to navigation without breaking typing.

### What IS achievable

Remap ctrl-variants to vim-adjacent positions in `~/.config/nchat/key.conf`:

| Action          | Current       | Target      |
|-----------------|---------------|-------------|
| Next chat       | `KEY_CTRLJ`   | keep        |
| Prev chat       | `KEY_CTRLK`   | keep        |
| Toggle list     | `KEY_CTRLH`   | keep (vim-ish) |
| Down (messages) | `KEY_DOWN`    | add `KEY_CTRLJ` alias? |
| Up (messages)   | `KEY_UP`      | add `KEY_CTRLU` alias? |
| Send message    | `KEY_CTRLX`   | consider `KEY_RETURN` |
| Quit            | `KEY_CTRLQ`   | keep (`:q` muscle memory) |

The compose/navigation split is effectively:
- Navigate chats: `Ctrl+J` / `Ctrl+K`
- Toggle chat list: `Ctrl+H`
- Typing in the compose field is always active (no mode switch needed)
- `Ctrl+X` or `Enter` to send

### "Compose mode" workaround

nchat's UI has a text entry at the bottom that always receives input. What the user
can control is the *focus* of the message list pane (scroll j/k) vs the compose
field. The `next_chat`/`prev_chat` actions switch which chat is active.

For a cleaner modal feel, consider: does nchat have a `focus_compose` action?
Check `nchat --help` or the full key action list via `toggle_help` (Ctrl+G in nchat).

**File:** `~/.config/nchat/key.conf` — edit directly (not managed by home-manager;
nchat modifies this file at runtime)

---

## 7. Waybar in KDE

Use waybar in KDE for familiarity before fully switching to Sway.

### Challenges

- `sway/workspaces` module doesn't work in KDE — need a custom module using `qdbus`
  to read KDE virtual desktop state
- Mako notifications: currently only started in Sway's `startup` block. Need a
  separate KDE autostart entry.

### Virtual desktops via qdbus

```bash
# Get current desktop (0-indexed)
qdbus org.kde.KWin /KWin currentDesktop
# Get desktop names
qdbus org.kde.KWin /KWin desktopName 1
```

Waybar custom module with a polling script can show 1/2/3/4 with the active one
highlighted. Clicking switches desktop via `qdbus org.kde.KWin /KWin setCurrentDesktop N`.

### Mako in KDE

Add mako to KDE autostart. In `home/default.nix` (or a new `home/autostart.nix`):

```nix
xdg.configFile."autostart/mako.desktop".text = ''
  [Desktop Entry]
  Type=Application
  Name=Mako
  Exec=mako
  X-KDE-AutostartScript=true
'';
```

Then mako notifications fire in both KDE and Sway sessions.

### Notification width matching Waybar

Mako's `width` and `anchor` need to align with the waybar bar width and position.
Since the bar is ~400px wide and centered, mako should anchor top-center:

```nix
settings = {
  anchor = "top-center";
  width  = 400;
  margin = "36,0,0,0";  # 36px top margin clears the waybar height
};
```

### Separate waybar config for KDE

The sway waybar config uses `sway/workspaces` — that module fails outside Sway.
Best approach: two separate waybar setting blocks (one for sway, one for KDE) wired
via a conditional, or simply launch a different waybar config file from KDE autostart:

```bash
waybar --config ~/.config/waybar/kde-config.json --style ~/.config/waybar/style.css
```

**Files to change:**
- `home/waybar.nix` — add second settings block or parameterise
- `home/mako.nix` — add `anchor = "top-center"`, adjust width/margin
- `home/default.nix` — add KDE autostart entries for waybar + mako

**This item needs a design decision:** single waybar.nix with two config blocks,
or a separate `home/waybar-kde.nix` imported conditionally. Discuss before implementing.

---

## 8. Keybinding cheatsheet maintenance

The `<leader>/` popup in `init.lua` lines 318–380 lists all custom bindings. It must
be updated whenever a new keybinding is added. Current bindings represented:

- `<leader>/` help, `<leader>s` search, `<leader>m` music, `<leader>gu/gs` git
- `<leader>tp/ta` typst, `<leader>z` PDF, `<leader>d` dashboard
- `gf` wikilink, `:DailyNote`, `:LogWeight`
- `vault-work / uni-work / nixos-work / today / messages / music / cal` shell functions

**Rule:** when implementing any item from this plan that adds a keybinding, update the
cheatsheet in the same commit.

---

## Implementation order (suggested)

| # | Item | Effort | Rebuild needed |
|---|------|--------|----------------|
| 1 | nchat notifications | 0 min | No — restart nchat |
| 2 | Kitty disable ctrl+shift+[] | 5 min | Yes |
| 3 | Rofi icon size + prefix hide | 10 min | Yes |
| 4 | rmpc ctrl+hl tab switch | 15 min | Yes (home.file) |
| 5 | Rofi + LastPass script | 20 min | Yes |
| 6 | nchat keybindings | 20 min | No — edit key.conf directly |
| 7 | Waybar in KDE | 45 min | Yes |
