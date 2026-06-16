# NixOS Config — Context for Claude Code

## What this repo is

A NixOS flake-based system configuration for user `thijmen` (GitHub: nimjit).
Remote: `https://github.com/nimjit/nixos-config`
Tracks `nixpkgs` and `home-manager` on `release-26.05` (stable).

## Directory structure

```
/etc/nixos/
├── flake.nix              # entry point; defines 3 hosts, wires home-manager + stylix
├── flake.lock
├── modules/
│   ├── common.nix         # shared NixOS config (locale, packages, nix settings)
│   ├── stylix.nix         # theming via stylix
│   ├── syncthing.nix      # syncthing service
│   ├── tailscale.nix      # tailscale VPN
│   └── flake-update.nix   # automated flake input updates
├── hosts/
│   ├── desktop/           # nixos-desktop — main machine
│   ├── laptop/            # laptop
│   └── usb/               # portable USB install
├── home/
│   ├── default.nix        # Home Manager root: imports all home modules, git, direnv, XDG
│   ├── neovim.nix
│   ├── kitty.nix
│   ├── zsh.nix
│   ├── rofi.nix
│   ├── yazi.nix
│   ├── mpv.nix
│   ├── firefox.nix
│   ├── autostart.nix      # disabled (commented out in default.nix)
│   ├── email.nix
│   └── dotfiles/          # static dotfiles copied/linked by home-manager
└── themes/
    └── ukiyo.nix          # color theme
```

## HARD RESTRICTIONS — read before doing anything

**`hosts/desktop/default.nix` is off-limits.** The user has explicitly disallowed edits to this file. Before suggesting any change to it — even a "safe" one — you must stop and tell the user:

> "You have disallowed edits to `hosts/desktop/default.nix`. Do you want to grant permission for this specific change?"

Do not edit the file, do not include it in a plan, do not suggest it as part of a larger task, until the user explicitly says yes for that specific change.

## Key facts

- **Home Manager is integrated as a NixOS module** (not standalone). Rebuild with `sudo nixos-rebuild switch`.
- Files in `~/.config` that are symlinks to `/nix/store/...` are **read-only** — edit their source in `home/`.
- KDE/Plasma config files in `~/.config` (kwinrc, kdeglobals, etc.) are **not** managed by Home Manager and can be edited directly, but won't be reproducible without declaring them.
- `/etc/nixos` is now owned by `thijmen:users` so no `sudo` is needed for editing or git.
- `sudo` is still required to run `nixos-rebuild switch`.
- Theme is managed globally by [Stylix](https://github.com/danth/stylix) — `modules/stylix.nix`. But some apps use their own overrides.

## Workflow

1. Edit `.nix` files here
2. Commit the changes: `git add`, `git commit` with a descriptive message
3. Rebuild: `sudo nixos-rebuild switch --flake /etc/nixos#desktop` (or use the `rebuild` alias)
4. After a successful rebuild, append a row to `generations.md`:
   `| <gen> | <date> <time> | <short-hash> | <what this generation adds> |`
   Get the current gen number from `ls /nix/var/nix/profiles/system` (it's a symlink like `system-98-link`).
5. `git push`

**Keep commits and rebuilds aligned where possible** — ideally one commit per rebuild so `generations.md` stays readable. If you do multiple commits before rebuilding, that's fine; just use the most recent commit hash in the log row.

**Before each rebuild, leave a one-line comment** in the relevant `.nix` file (or the commit message) saying what this generation adds. This helps if the user wants to rebuild manually and know what they're applying.

## Open Issues / TODO

- `rebuild` alias hardcodes `-H desktop` — `$(hostname)` expansion fails in zsh alias context. Should be made hostname-aware once the root cause is understood.
- Netrw sidebar workflow being migrated to yazi-based workflow. Netrw config is retained in `init.lua` for Windows compatibility but is no longer the primary navigation method on Linux.
- Obsidian vault has a redundant double-folder: `Obsidian/Rennaissance_Vault_Structure/` — consider flattening.
- Emacs runs slow at full window size; works fine at 100% display scaling. After exam, plan to investigate further — see `plans/emacs.md`.
- Python path in nvim (`vim.g.python_path`) is hardcoded to `/run/current-system/sw/bin/python3`. Should eventually be generalised (e.g. respect virtual envs or `NVIM_PYTHON` env var that is already set).
- `yt-feed` mpv playback fails with "importing the supplied dmabufs failed" on NVIDIA — `--hwdec=no` was added but videos still do not play. Root cause unknown; needs further investigation.

### Larger projects

- **Snowflake visualisers**: `vault_snowflake.py` (personal), `uni_snowflake.py` (uni),
  `nixos_snowflake.py` (this repo) — run with `python3 <script>` to regenerate HTML.
- **Window manager switch** (KDE → Sway): full step plan in `plans/window-manager.md`.
  Key open item: test Nvidia legacy_535 + Wayland (`WLR_RENDERER=vulkan`).
  Strategy: keep KDE, add sway as parallel SDDM session, test before removing KDE.
- **Emacs setup**: full step plan in `plans/emacs.md`.
- **Ereader export**: automate typst/markdown → PDF → ereader transfer. Plan in `plans/ereader-export.md`.
- **Dashboard graphs**: render weight log and other vault data as inline graphs in the neovim dashboard. Plan in `plans/dashboard-graphs.md`.

### CLI migration

- **nchat**: Replace WhatsApp Web browser tab with `nchat` (in nixpkgs, uses whatsmeow). Gives desktop notifications without keeping a browser tab open. Add to packages + make a `messages()` workflow function.
- **New tab page**: Tabliss (extension) as new tab breaks Tridactyl — Firefox security prevents extensions injecting into `moz-extension://` pages. Fix: replace Tabliss with a self-hosted `file://` or `localhost` HTML page. Tridactyl works on those. Rebuild whatever Tabliss shows (links, clock) in plain HTML.
- **lastpass-cli**: Add `lastpass-cli` to packages. Use `lpass` in terminal for credential access without a browser tab. Write a small rofi script for system-wide password copy via keyboard shortcut. Keep LastPass Firefox extension for browser autofill — same vault, no migration.
- **calcurse + Google Calendar**: Add `calcurse` to packages and sync it with Google Calendar via CalDAV (`calcurse-caldav`). Google Calendar's CalDAV URL: `https://www.google.com/calendar/dav/<calendar_id>/events/`. Requires an app password (Google account → Security → App passwords). Gives a terminal calendar without keeping a browser tab open.
