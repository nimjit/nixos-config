# Notifications, Launcher & Cheatsheet

## nchat desktop notifications

**Status: working.** `libnotify` is in packages (provides `notify-send`). nchat
auto-detects it at startup. Fires whenever a message arrives in a non-focused chat
while nchat is running in the `messages` kitty tab.

If notifications stop working: close the messages tab and reopen with `messages()`.
nchat probes for `notify-send` at startup, not at runtime.

## Rofi app launcher

**Status: working.** `home/rofi.nix` configures drun/window/combi modes.

- `Alt+Space` — opens rofi (KDE shortcut, configured in System Settings)
- `Super+W` — window switcher rofi mode

Password picker: `<Super+P>` → `lpass-rofi.sh` (KDE shortcut not yet configured —
do this in System Settings → Shortcuts → Custom Shortcuts).

## Keybinding cheatsheet

**Status: done.** `<leader>/` in neovim shows a floating help popup listing all
custom bindings. Defined in `home/dotfiles/neovim/init.lua`.

When adding new bindings: update the cheatsheet in the same commit.

## Terminal status bar

**Status: not built.** Deferred when Sway was the plan (Waybar would handle it).
Sway is now binned. tmux or a custom kitty tab bar are options if this is still
wanted — neither has been pursued. Low priority.
