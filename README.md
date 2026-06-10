# nixos-config

NixOS flake configuration for user `thijmen`. Manages packages, theming, dotfiles,
and services declaratively across three machines.

---

## Machines

| Hostname | Role | Notes |
|----------|------|-------|
| `nixos-desktop` | Main machine | Nvidia GTX 1060 + Intel iGPU; KDE Plasma 6 |
| `nixos-laptop` | Laptop | — |
| `nixos-usb` | Portable USB install | Carries a BACKUP data partition |

**GPU note (desktop):** The Nvidia legacy_535 driver requires specific boot config.
See comments in `hosts/desktop/default.nix` — do not change the DRI/KWIN settings
without reading them. `hosts/desktop/default.nix` is off-limits without explicit
permission (see `CLAUDE.md`).

---

## Theme

**Stylix** manages theming system-wide from `themes/ukiyo.nix` (a base16 palette).
Fonts, cursor, wallpaper, and per-app colours all derive from this single file.

**Neovim is the exception.** Stylix's neovim target injects `mini.base16` which
overrides everything, so neovim uses its own hand-crafted colorscheme instead:
- `home/dotfiles/neovim/colors/Ukiyo.lua` — the actual colorscheme
- `set_color_overrides()` in `init.lua` — markdown + syntax tweaks on top
- A `VimEnter` autocmd re-applies overrides after Stylix's mini.base16 runs

To switch the system theme: change `base16Scheme` in `modules/stylix.nix` and
rebuild. The neovim colorscheme is independent and must be updated separately.

---

## Key applications

| App | Purpose | Config |
|-----|---------|--------|
| kitty | Terminal | `home/kitty.nix` |
| neovim | Editor + dashboard | `home/neovim.nix`, `home/dotfiles/neovim/` |
| zsh + starship | Shell | `home/zsh.nix` |
| yazi | File manager | `home/yazi.nix` |
| firefox + tridactyl | Browser | `home/firefox.nix` |
| zathura | PDF viewer | Stylix-themed |
| rmpc + MPD | Music | `home/mpd.nix`, `modules/common.nix` |
| khal + vdirsyncer | Calendar (12 Google calendars) | `home/dotfiles/khal/` |
| nchat | WhatsApp terminal client | `modules/common.nix` |
| lastpass-cli | Password manager CLI | `modules/common.nix` |
| syncthing | File sync | `modules/syncthing.nix` |
| tailscale | VPN | `modules/tailscale.nix` |

---

## Local services

| Port | Service | Notes |
|------|---------|-------|
| `8080` | New tab page | Served by a systemd user service (`python3 -m http.server`); source at `~/.config/newtab/index.html`; Firefox "New Tab Override" extension points here |
| `8384` | Syncthing web UI | Add device IDs here when pairing new machines |

---

## Shell aliases and workflows

```
rebuild        nh os switch /etc/nixos -H desktop
update         git pull + rebuild
gc             delete generations older than 30 days
gens           list all generations

nixos          yazi /etc/nixos
backup         yazi ~/Documents/BACKUP
vault          yazi ~/...Obsidian/Renaissance_Vault_Structure/
uni            yazi ~/...Uni/Obsidian/Uni
cal            vdirsyncer sync && ikhal
today          nvim -c DailyNote

uni-work       neovim → uni dashboard
uni-code       neovim → current coding project (g:uni_code_path)
vault-work     neovim → personal vault dashboard + Claude split
nixos-work     neovim → /etc/nixos + Claude split + terminal
messages       nchat in a kitty tab (focuses existing tab if open)
music          rmpc in a kitty tab (focuses existing tab if open)
```

---

## Neovim workflows

```
<leader>?      keybinding help popup
<leader>f      yazi file picker (split)
<leader>D      return to dashboard from any buffer
<leader>z      open PDF or image in a kitty vsplit panel
<leader>m      rmpc music player in a vsplit
<leader>tp     compile + render typst/math block under cursor
<leader>ta     render all typst blocks in buffer
<leader>r      run Python file
<leader>c      run cell (# %% marker)
<C-h/j/k/l>    navigate neovim splits
<C-↑↓←→>       resize neovim splits
<C-S-h/j/k/l>  navigate kitty panels (e.g. PDF preview)
```

**Vaults:**
- Personal: `~/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure/`
- Uni: `~/Documents/BACKUP/Uni/Obsidian/Uni/`

---

## Maintenance

```bash
# Apply changes
rebuild

# Update all flake inputs (do monthly)
cd /etc/nixos && nix flake update && rebuild

# Clean old generations
gc

# Roll back last change
sudo nixos-rebuild switch --rollback

# Check what's failing
systemctl --failed
journalctl -u <service> -n 50
```

**Syncthing** — add a new device at `http://localhost:8384`, then declare it in
`modules/syncthing.nix` and rebuild.

**vdirsyncer** — `~/.config/vdirsyncer/config` is NOT in git (contains OAuth tokens).
Replicate manually on new machines. Run `vdirsyncer discover` after adding a new
Google calendar.

---

## Plans

Open design/migration work lives in `plans/`:

| File | Topic |
|------|-------|
| `theme-workflow.md` | Ukiyo.nix palette update, khal look, zsh greeting |
| `cli-migration.md` | CLI tool status + remaining rofi/nchat items |
| `wikilinks.md` | `[[wikilink]]` jump, backlinks buffer, `[[` completion |
| `template-system.md` | `:NewNote` command using existing vault Templates/ |
| `vault-search.md` | `<leader>s` fuzzy content search across vault |
| `greeting-upgrade.md` | Live khal events + vault deadlines in zsh greeting |
| `quick-capture.md` | `cap` shell function to append to daily note |
| `notifications-bar.md` | Terminal status bar, nchat notifications, rofi launcher, keybinding reference |
| `window-manager.md` | KDE → Sway migration (not started) |
| `emacs.md` | Emacs setup (not started) |
| `snowflakes.md` | Vault/uni/nixos graph visualisers |
