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

## Key facts

- **Home Manager is integrated as a NixOS module** (not standalone). Rebuild with `sudo nixos-rebuild switch`.
- Files in `~/.config` that are symlinks to `/nix/store/...` are **read-only** — edit their source in `home/`.
- KDE/Plasma config files in `~/.config` (kwinrc, kdeglobals, etc.) are **not** managed by Home Manager and can be edited directly, but won't be reproducible without declaring them.
- `/etc/nixos` is now owned by `thijmen:users` so no `sudo` is needed for editing or git.
- `sudo` is still required to run `nixos-rebuild switch`.
- Theme is managed globally by [Stylix](https://github.com/danth/stylix) — `modules/stylix.nix`.

## Workflow

1. Edit `.nix` files here
2. `nh os switch /etc/nixos -H desktop` (or use the `rebuild` alias)
3. `git add`, `git commit`, `git push`

## Open Issues / TODO

- `rebuild` alias hardcodes `-H desktop` — `$(hostname)` expansion fails in zsh alias context. Should be made hostname-aware once the root cause is understood.
- Netrw sidebar workflow being migrated to yazi-based workflow. Netrw config is retained in `init.lua` for Windows compatibility but is no longer the primary navigation method on Linux.
- Obsidian vault has a redundant double-folder: `Obsidian/Rennaissance_Vault_Structure/` — consider flattening.
- Python path in nvim (`vim.g.python_path`) is hardcoded to `/run/current-system/sw/bin/python3`. Should eventually be generalised (e.g. respect virtual envs or `NVIM_PYTHON` env var that is already set).
