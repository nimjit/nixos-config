# NixOS Config

A NixOS flake configuration for user `thijmen` (GitHub: nimjit).
Remote: `https://github.com/nimjit/nixos-config`
Tracks `nixpkgs` and `home-manager` on `release-26.05` (stable).

---

## Machines

| Hostname | Role | Notes |
|----------|------|-------|
| `nixos-desktop` | Main machine | Nvidia GTX 1060 + Intel iGPU; KDE Plasma 6 |
| `nixos-laptop` | Laptop | — |
| `nixos-usb` | Portable USB install | Carries a BACKUP data partition |

**GPU note (desktop):** The Nvidia legacy_535 driver requires specific boot config.
See comments in `hosts/desktop/default.nix` — do not change the DRI/KWIN settings
without reading them.

---

## HARD RESTRICTIONS — read before doing anything

**`hosts/desktop/default.nix` is off-limits.** The user has explicitly disallowed edits to this file. Before suggesting any change to it — even a "safe" one — you must stop and tell the user:

> "You have disallowed edits to `hosts/desktop/default.nix`. Do you want to grant permission for this specific change?"

Do not edit the file, do not include it in a plan, do not suggest it as part of a larger task, until the user explicitly says yes for that specific change.

---

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

---

## Theme

**Stylix** manages theming system-wide from `themes/ukiyo.nix` (a base16 palette).
Fonts, cursor, wallpaper, and per-app colours all derive from this single file.
To switch the system theme: change `base16Scheme` in `modules/stylix.nix` and rebuild.

**Neovim is the exception.** Stylix's neovim target injects `mini.base16` which
overrides everything, so neovim uses its own hand-crafted colorscheme instead:

- `home/dotfiles/neovim/colors/Ukiyo.lua` — the actual colorscheme
- `set_color_overrides()` in `init.lua` — markdown + syntax tweaks on top
- A `VimEnter` autocmd re-applies overrides after Stylix's mini.base16 runs

The neovim colorscheme must be updated separately from the Stylix palette.

---

## Design philosophy

**The terminal is the hub.** The appeal is cohesion: one kitty window, everything
reachable from zsh, consistent vim-style keys, automatic Ukiyo theming, and a
uniform mental model regardless of what's being done. GUIs are used when there is
no real terminal alternative (browser), not as a preference.

**Context switching** happens at two levels:
- KDE virtual desktops for major contexts (uni, personal, nixos, etc.)
- Kitty tabs within a context for related tools (e.g. editor + terminal + music)
- Each context has a named entry alias (`uni-work`, `vault-work`, `nixos-work`, …)

**Content routing** — where each type of content lives:

| Content | Tool | Notes |
|---------|------|-------|
| Video | mpv / yt-feed | yt-feed for YouTube feed; mpv for direct playback |
| Music | MPD + rmpc | Local library; rmpc is the TUI |
| Articles / newsletters | newsboat (planned) | RSS feeds; newsletters migrated here from email |
| Email | neomutt | Gmail working; nouwens.org planned |
| Calendar | khal / ikhal | 12 Google calendars via vdirsyncer |
| PDFs / ebooks | zathura | Stylix-themed; epub support planned |
| WhatsApp | nchat | Terminal client |
| Social media | phone | Intentionally not on the computer |
| Passwords | lpass CLI | Alt+P via lpass-rofi for quick access |

**UI conventions** — apply these when building any new terminal tool or config:
- Navigation: `j`/`k` up/down, `h`/`l` or `q` back/open, `g`/`G` first/last
- Help: `?` opens a personal cheatsheet (see neomutt, yt-feed pattern)
- Sidebar: `J`/`K` to move, `b` to toggle — for tools with a folder/category list
- Entry point alias in zsh that opens the tool in a kitty tab (see `music`, `messages`)
- Notification on relevant events via `notify-send` → mako

**Theming** — Stylix handles most apps automatically. Where it doesn't reach,
apply the Ukiyo base16 colours manually (see `home/dotfiles/khal/config [palette]`
for the reference approach). Never leave an app in default colours if it's part
of a daily workflow.

**Tool selection** — prefer a well-maintained existing tool over a custom one.
`yt-feed` is the exception: YouTube has no API, thumbnails need kitty icat, and
the card layout genuinely adds value. For text-based tools (newsboat, neomutt,
khal) the existing tool is almost always the right choice.

**Data** — strong preference for local storage and self-hosted services. Cloud is
acceptable where there is no realistic alternative (Gmail, Google Calendar for
shared calendars). Long-term direction: migrate email to `thijmen@nouwens.org`,
newsletters to RSS, calendars to a self-hosted CalDAV if feasible.

---

## Key applications

| App | Purpose | Config |
|-----|---------|--------|
| kitty | Terminal | `home/kitty.nix` |
| neovim | Editor + dashboard | `home/neovim.nix`, `home/dotfiles/neovim/` |
| zsh | Shell | `home/zsh.nix` |
| yazi | File manager | `home/yazi.nix` |
| qutebrowser | Primary browser | `home/qutebrowser.nix`, `~/.config/qutebrowser/theme.py` |
| firefox | Fallback browser | `home/firefox.nix` |
| zathura | PDF viewer | `home/zathura.nix` (Stylix-themed) |
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
| `8080` | New tab page | Systemd user service (`python3 -m http.server`); source at `~/.config/newtab/index.html`; Firefox "New Tab Override" extension points here |
| `8384` | Syncthing web UI | Add device IDs here when pairing new machines |

---

## Shell aliases and workflows

```
rebuild        nh os switch /etc/nixos -H desktop
update         git pull + rebuild
gc             delete generations older than 30 days
gens           list all generations
nixdiff        compare last two NixOS generations (nvd diff)

nixos          yazi /etc/nixos
backup         yazi ~/Documents/BACKUP
vault          yazi ~/...Obsidian/Renaissance_Vault_Structure/
uni            yazi ~/...Uni/Obsidian/Uni
cal            vdirsyncer sync && ikhal
today          nvim -c DailyNote
wb             w3m terminal browser (wb URL, or wb for localhost:8080)

uni-work       neovim → uni dashboard
uni-code       neovim → current coding project (g:uni_code_path)
vault-work     neovim → personal vault dashboard
nixos-work     neovim → /etc/nixos
messages       nchat in a kitty tab (focuses existing tab if open)
music          rmpc in a kitty tab (focuses existing tab if open)

cap "text"     append to today's daily note (uni vault)
capu "text"    append to today's daily note (personal vault)
```

---

## Neovim workflows

```
<leader>/      keybinding help popup
<leader>f      yazi file picker (split)
<leader>D      return to dashboard from any buffer
<leader>z      open PDF or image in a kitty vsplit panel
<leader>m      rmpc music player in a vsplit
<leader>tp     compile + render typst/math block under cursor
<leader>ta     render all typst blocks in buffer
<leader>r      run Python file
<leader>c      run cell (# %% marker)
<leader>s      vault content search (grep-based, no plugins)
<leader>B      show backlinks to current note
gf / <CR>      follow [[wikilink]] in markdown
:DailyNote     open or create today's daily note
:NewNote       create note from vault template

<C-h/j/k/l>    navigate neovim splits
<C-↑↓←→>       resize neovim splits
<C-S-h/j/k/l>  navigate kitty panels (e.g. PDF preview)
```

**Vaults:**
- Personal: `~/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure/`
- Uni: `~/Documents/BACKUP/Uni/Obsidian/Uni/`

**Qutebrowser:**
```
dd             close tab
<Alt-p>        LastPass autofill (qute-lastpass-auto userscript)
,M             open current URL in mpv
,m             hint links, open hinted URL in mpv
yt: query      YouTube search
nixosp: query  NixOS packages search
```

---

## Plans

Design notes, feature specs, and reference documentation live in `plans/`.
Split into three directories:

**`plans/Active/`** — work in progress. A plan here is being designed or partially
built. Read these before implementing anything in that area to avoid redundant work
or contradicting prior decisions.

**`plans/Done/`** — reference docs for shipped features. Not implementation plans —
descriptions of the current system: what was built, how to use it, what keybindings
it adds, technical gotchas, what to expect visually. These serve as the source of
truth for features that aren't obvious from reading the nix files alone.

**`plans/Binned/`** — shelved ideas, with .nix files stored alongside so nothing
is lost. Each .md file explains what the feature was and how to reactivate it.

### Workflow for plans

- **Starting a new feature**: create a file in `plans/Active/` with the design
- **After shipping**: move to `plans/Done/`, rewrite as a reference doc:
  focus on what was built, what it looks like, how to use it, keybindings
- **Shelving a feature**: move to `plans/Binned/` with a note on how to reactivate;
  if there are .nix files, move those there too

### Active plans

| File | Topic |
|------|-------|
| `emacs.md` | Fresh start: evil → markdown-mode → spell check |
| `email.md` | neomutt + Gmail; future: nouwens.org account, colours, notifications |
| `rss.md` | newsboat for newsletters/blogs; migration from Gmail subscriptions |
| `cli-migration.md` | w3m `wb` function, KDE lpass-rofi shortcut |

### Larger projects in progress

- **Snowflake visualisers**: three D3.js radial HTML visualizations regenerated on
  login via a systemd timer. See `plans/Done/snowflakes.md`.
- **Dashboard graphs**: weight chart done; neovim-native vault graph planned.
  See `plans/Done/dashboard-graphs.md`.

---

## Key facts (for making changes)

- **Home Manager is integrated as a NixOS module** (not standalone). Rebuild with `sudo nixos-rebuild switch`.
- Files in `~/.config` that are symlinks to `/nix/store/...` are **read-only** — edit their source in `home/`.
- KDE/Plasma config files in `~/.config` (kwinrc, kdeglobals, etc.) are **not** managed by Home Manager and can be edited directly, but won't be reproducible without declaring them.
- `/etc/nixos` is now owned by `thijmen:users` so no `sudo` is needed for editing or git.
- `sudo` is still required to run `nixos-rebuild switch`.
- `qutebrowser/theme.py` lives at `~/.config/qutebrowser/theme.py` (a live file, not in the nix store). Edit directly; reload with `:config-source` in qutebrowser — no rebuild needed.

---

## Workflow (making changes)

1. Edit `.nix` files here
2. Commit the changes: `git add`, `git commit` with a descriptive message
3. Rebuild: `sudo nixos-rebuild switch --flake /etc/nixos#desktop` (or use the `rebuild` alias)
4. After a successful rebuild, append a row to `generations.md`:
   `| <gen> | <date> <time> | <short-hash> | <what this generation adds> |`
   Get the current gen number from `ls /nix/var/nix/profiles/system` (it's a symlink like `system-98-link`).
5. `git push`

**Keep commits and rebuilds aligned where possible** — ideally one commit per rebuild so `generations.md` stays readable. If you do multiple commits before rebuilding, that's fine; just use the most recent commit hash in the log row.

---

## Maintenance

```bash
# Apply changes
rebuild

# Update all flake inputs (do monthly)
cd /etc/nixos && nix flake update && rebuild

# Clean old generations (keeps last 30 days)
gc

# Compare what changed between last two generations
nixdiff

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

## Open Issues / TODO

- `rebuild` alias hardcodes `-H desktop` — `$(hostname)` expansion fails in zsh alias context. Should be made hostname-aware once the root cause is understood.
- Netrw sidebar workflow being migrated to yazi-based workflow. Netrw config is retained in `init.lua` for Windows compatibility but is no longer the primary navigation method on Linux.
- Obsidian vault has a redundant double-folder: `Obsidian/Rennaissance_Vault_Structure/` — consider flattening.
- Python path in nvim (`vim.g.python_path`) is hardcoded to `/run/current-system/sw/bin/python3`. Should eventually be generalised.
- `yt-feed` mpv playback: fixed with `--gpu-api=opengl` in `play()`. Forces OpenGL texture upload instead of DMA-buf presentation path, which was failing on NVIDIA Wayland.
