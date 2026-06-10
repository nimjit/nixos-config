# Notifications, Terminal Bar & Launcher

Three related quality-of-life upgrades: a persistent status bar in the terminal,
desktop notifications from terminal apps (especially nchat), and a keyboard-driven
app launcher / keybinding reference.

---

## 1. Terminal status bar (tmux or kitty tab bar)

A persistent line at the bottom (or top) of the terminal showing:
- Current time
- MPD track (via `mpc current`)
- Unread message count from nchat (if queryable)
- Virtual desktop indicator (KDE workspace number via `qdbus`)
- Battery percentage (laptop only)

### Options

**Option A — tmux status bar**

tmux has a built-in `status-right` / `status-left` with shell command interpolation
(`#(command)`). Refresh interval down to 1 second. Integrates naturally with the
existing multi-pane workflows.

Downside: adds tmux as a layer; existing kitty panel navigation (`<C-S-h/j/k/l>`)
would need adjustment.

**Option B — kitty tab bar**

kitty's `tab_bar_style` can be `custom` (Python script). Can show arbitrary text
per tab. No new process manager needed.

Downside: less flexible than tmux, tied to kitty version.

**Option C — waybar / eww (desktop bar)**

A full desktop widget bar. More powerful but heavier; better suited to the
KDE → Sway migration (see `window-manager.md`). Worth deferring until Sway.

**Recommendation:** Deferred — implement as Waybar when Sway is set up (see
`window-manager.md`). Setting up a status bar twice (once for KDE, once for Sway)
is wasteful; Waybar is already planned and will handle this cleanly.

---

## 2. nchat desktop notifications

nchat currently runs silently. Fixes needed:

### Problem

nchat fires no notifications because `notify-send` is not in PATH. nchat does
**not** have a `--background` flag — it is always interactive.

### Finding

`~/.config/nchat/ui.conf` already has notifications fully configured:

```
desktop_notify_enabled=1
desktop_notify_inactive=1
desktop_notify_active_noncurrent=1
```

The nchat log confirms it tried to fire a notification but failed:

```
WARN | command 'notify-send' not found  (uimodel.cpp:3126)
```

### Fix

Add `libnotify` to packages in `modules/common.nix`. That package provides
`notify-send`. nchat auto-detects it at runtime — no config change needed.
Notifications will fire whenever nchat is running (i.e. the `messages` kitty tab
is open) and a new message arrives in a non-focused chat.

---

## 3. Rofi app launcher with fuzzy search

**Why Rofi over KRunner?** Three reasons specific to this setup:
1. **Custom modes** — the password picker (`cli-migration.md`) needs a scriptable
   custom mode. KRunner has no equivalent API for this.
2. **Portability** — Rofi config transfers unchanged to Sway. KRunner is
   KDE-only and will not exist after the migration.
3. **Already configured** — `home/rofi.nix` already declares drun/run/window modes.
   KRunner would require starting from scratch on Sway.

If neither scripting nor Sway migration were planned, KRunner would be fine — it
is already there and zero effort. Given both are planned, Rofi is the right choice.

A keyboard shortcut (`Super+Space`) opens a rofi window to launch apps or run
shell commands. Already partially in scope from `cli-migration.md` (the password
picker uses rofi).

```nix
# home/rofi.nix — add a launcher mode
programs.rofi = {
  enable = true;
  # existing config...
};
```

Bind in KDE: System Settings → Shortcuts → Custom Shortcuts → `rofi -show drun`.
Bind in Sway (when migrated): `bindsym $mod+Space exec rofi -show drun`.

---

## 4. Keybinding reference / cheatsheet

A way to look up keybindings without leaving the keyboard.

### Option A — `<leader>?` popup (already exists)

`init.lua` already has `<leader>?` bound to a keybinding help popup. Extend it
to show all custom bindings grouped by category.

Current state: need to verify what `<leader>?` actually shows and whether it
covers the dashboard, wikilink, and media bindings added recently.

### Option B — `which-key` style floating window

Pressing `<leader>` with a short delay shows a floating window with all `<leader>`
sub-mappings. Implemented in pure Lua without a plugin:

```lua
-- after a 500ms delay on <leader>, show a formatted floating window
-- listing all vim.keymap bindings whose lhs starts with <leader>
```

### Option C — static cheatsheet in `$VAULT/Meta/Keybindings.md`

A markdown file listing all custom bindings. Open with `:e $VAULT/Meta/Keybindings.md`
or a dedicated alias. Low-tech but always accurate if kept updated.

**Recommendation:** extend the existing `<leader>?` popup (Option A) and rename
it to `<leader>/` (no shift required, same muscle-memory position on the keyboard).

**Implementation:** in `home/dotfiles/neovim/init.lua`, find the line that binds
`<leader>?` and change the lhs to `<leader>/`. Also update the keybind reference
in `README.md` under "Neovim workflows".

---

## Files to change

| File | Change |
|------|--------|
| `modules/common.nix` | Add `libnotify` to packages (fixes nchat notifications) |
| `home/rofi.nix` | Launcher mode config; declare `Super+Space` shortcut |
| `home/dotfiles/neovim/init.lua` | Rename `<leader>?` → `<leader>/`; extend binding list |
| `README.md` | Update keybind reference: `<leader>?` → `<leader>/` |

---

## Notes

- nchat notifications are unblocked by adding `libnotify` — no other changes needed
- Waybar is deferred to the Sway migration (see `window-manager.md`)
- `Super+Space` may conflict with KDE's default application launcher shortcut (KRunner) —
  disable the KDE shortcut first in System Settings → Shortcuts → KRunner
