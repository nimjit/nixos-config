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
│   ├── git.nix            # git user config (split from default.nix)
│   └── dotfiles/          # static dotfiles copied/linked by home-manager
├── plans/
│   ├── Active/            # plans in progress
│   ├── Done/              # reference docs for shipped features
│   └── Binned/            # shelved plans (sway.nix, waybar.nix, window-manager.md)
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
- Python path in nvim (`vim.g.python_path`) is hardcoded to `/run/current-system/sw/bin/python3`. Should eventually be generalised (e.g. respect virtual envs or `NVIM_PYTHON` env var that is already set).
- `yt-feed` mpv playback: fixed with `--gpu-api=opengl` in `play()`. Forces OpenGL texture upload instead of DMA-buf presentation path, which was failing on NVIDIA Wayland.

### Active plans (see `plans/Active/`)

- **emacs.md** — fresh start, building from scratch: evil → markdown-mode → spell check → next pain point
- **email.md** — aerc to replace Thunderbird; Gmail + TU Delft OAuth2 via oauth2ms
- **cli-migration.md** — w3m `wb` shell function, KDE shortcut for lpass-rofi, kitty splits discussion
- **yazi.md** — file openers, keymaps, preview improvements
- **prompt.md** — starship or pure zsh prompt with Ukiyo palette

### Larger projects

- **Snowflake visualisers**: `vault_snowflake.py` (personal), `uni_snowflake.py` (uni),
  `nixos_snowflake.py` (this repo) — run with `python3 <script>` to regenerate HTML.
  See `plans/Done/snowflakes.md`.
- **Window manager switch** (KDE → Sway): **binned** — staying on KDE + Krohnkite.
  Config archived in `plans/Binned/`.
- **Dashboard graphs**: weight chart done; neovim-native vault graph planned.
  See `plans/Done/dashboard-graphs.md`.
