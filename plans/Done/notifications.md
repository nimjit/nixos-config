# Notifications, Launcher & Cheatsheet

## nchat desktop notifications

**Status: working.** `libnotify` is in packages (provides `notify-send`). nchat
auto-detects it at startup. Fires whenever a message arrives in a non-focused chat
while nchat is running in the `messages` kitty tab.

The relevant settings in `~/.config/nchat/ui.conf` (already configured):

```
desktop_notify_enabled=1
desktop_notify_inactive=1
desktop_notify_active_noncurrent=1
desktop_notify_command=          ← empty = auto-detect notify-send
```

nchat detects `notify-send` at startup, not at runtime. If notifications stop
working, the most likely cause is that nchat was launched before `libnotify`
was in PATH. Fix: close the messages tab and reopen with `messages()`.

The debug log confirms what was happening before `libnotify` was added:
```
WARN | command 'notify-send' not found  (uimodel.cpp:3126)
```

If notifications still don't fire after restarting: set
`desktop_notify_command=notify-send` explicitly in ui.conf to bypass the
auto-detection heuristic.

---

## Rofi app launcher

**Status: working.** `home/rofi.nix` configures drun / window / combi modes.

| Shortcut | Action |
|----------|--------|
| `Alt+Space` | rofi drun (app launcher) — configured in KDE System Settings → Shortcuts |
| `Super+W` | rofi window switcher |
| `Super+P` | lpass-rofi password picker — **KDE shortcut not yet configured** |

To set the `Super+P` shortcut: System Settings → Shortcuts → Custom Shortcuts →
add entry pointing to `~/.local/bin/lpass-rofi`.

**Why Rofi over KRunner**: custom modes (the password picker needs a scriptable
custom mode), and the config transfers unchanged to a future Sway setup if needed.

---

## Keybinding cheatsheet

**Status: done.** `<leader>/` in neovim shows a floating help popup listing all
custom bindings grouped by category. Defined in `home/dotfiles/neovim/init.lua`.

When adding new bindings: update the cheatsheet in the same commit.

---

## Terminal status bar

**Status: not built.** Was deferred for Waybar (Sway migration). Sway is now
binned. Options if this is ever wanted:

- **tmux status bar** — `status-right = "#(mpc current)"` etc., refresh every 1s. Adds
  tmux as a layer; existing `Ctrl+HJKL` panel navigation would need adjustment.
- **kitty tab bar (custom)** — Python script, shows arbitrary text per tab.
  Less flexible but no new process manager.

Low priority since the greeting and rmpc/nchat are already the main status surfaces.
