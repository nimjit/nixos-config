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

**Recommendation:** Option A (tmux). Low weight, flexible, doesn't block Sway migration.
Start with time + MPD; add other widgets incrementally.

---

## 2. nchat desktop notifications

nchat currently runs silently. Fixes needed:

### Problem

nchat must be running as a persistent background process to receive messages and
fire notifications. Right now it only runs when the `messages` shell function is
called.

### Fix: systemd user service

```nix
# In home/default.nix or a new home/nchat.nix
systemd.user.services.nchat = {
  description = "nchat WhatsApp client (background)";
  wantedBy = [ "default.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.nchat}/bin/nchat --background";
    Restart = "on-failure";
  };
};
```

Check whether nchat supports a `--background` / headless mode that fires
`notify-send` on new messages. If not, an alternative is to poll the nchat log
file for new message lines and call `notify-send` from a wrapper script.

### notify-send integration

```bash
# wrapper: watch nchat log and fire desktop notifications
tail -F ~/.nchat/nchat.log | while read -r line; do
    echo "$line" | grep -q "msg received" && \
        notify-send "nchat" "$(echo "$line" | sed 's/.*from: //')"
done
```

This requires knowing nchat's log format — check `~/.nchat/` after a session.

---

## 3. Rofi app launcher with fuzzy search

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

**Recommendation:** extend the existing `<leader>?` popup (Option A) for neovim
bindings; add a rofi mode for shell/system shortcuts (Option B extension).

---

## Files to change

| File | Change |
|------|--------|
| `home/default.nix` or new `home/nchat.nix` | systemd user service for nchat background |
| `home/zsh.nix` | tmux session auto-start in `messages()` and `vault-work`/`uni-work` if using Option A |
| `home/rofi.nix` | launcher mode, `Super+Space` shortcut declaration |
| `home/dotfiles/neovim/init.lua` | Extend `<leader>?` to cover all custom bindings |
| `modules/common.nix` | Add `tmux` to packages if using Option A |

---

## Notes

- nchat's headless/notification mode: check `nchat --help` and GitHub issues —
  this is the most uncertain part; may require a patch or wrapper
- Waybar + eww are better deferred to the Sway migration (see `window-manager.md`)
  so the bar config doesn't have to be written twice
- `Super+Space` may conflict with KDE's default application launcher shortcut —
  disable the KDE shortcut first in System Settings
