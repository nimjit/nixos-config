# Emacs Setup Plan

---

## ── IMPLEMENTATION LOG (written 2026-06-08) ──────────────────────────────────

This section documents everything that happened during the initial implementation
session. It is written for Claude's future self. Read this before touching anything.

---

### What was built

A complete Emacs configuration replacing Obsidian, covering:

- **Evil + general.el SPC leader** — vim keybindings everywhere, comma local leader
- **Literate config** — `config.org` tangled to `~/.cache/emacs/config.el` by `init.el` on startup; re-tangles automatically when config.org is newer than the cached .el
- **Standalone ukiyo theme** — `ukiyo-theme.el` in `~/.config/emacs/themes/`; loaded manually because Stylix cannot inject themes when `init.el` is overridden
- **607 vault notes converted** — pure Python script at `/home/thijmen/convert_vaults.py`; personal (446) + uni (161) notes in `~/org/`
- **org-roam DB** — 607 nodes, autosync enabled; `org-roam-directory` = `~/org/`
- **Dashboard** — `~/org/dashboard.org` with live `#+begin_src emacs-lisp :results value raw` blocks using `org-ql-select`
- **GPU rendering fix** — `KWIN_DRM_DEVICES` env var pointing KWin at the Nvidia card
- **All packages declared in Nix** — `home/emacs.nix`; packages come from Nix, ELPA disabled

---

### File map (what is where)

```
/etc/nixos/
  home/
    emacs.nix                          -- Nix package list + xdg file sources
    dotfiles/emacs/
      early-init.el                    -- UI disable, GC threshold
      init.el                          -- tangle-on-demand bootstrap (NO byte-compile)
      config.org                       -- full literate config (the canonical source)
      ukiyo-theme.el                   -- standalone theme converted from ukiyo.nix palette
      elfeed.org                       -- RSS feed list (stub; YouTube channels not yet added)
  modules/
    common.nix                         -- added: tinymist, enchant2, hunspellWithDicts
  hosts/desktop/default.nix            -- GPU fix: KWIN_DRM_DEVICES
  plans/emacs.md                       -- this file

/home/thijmen/
  convert_vaults.py                    -- vault conversion script (already ran; 607 notes out)
  org/
    dashboard.org                      -- main dashboard (opens at startup)
    inbox.org
    agenda.org
    daily/                             -- org-roam dailies
    personal/                          -- converted personal vault
    uni/                               -- converted uni vault
    knowledge/                         -- symlinked? check
```

---

### Architecture decisions made (irreversible or load-bearing)

**1. No byte-compilation of config.el — ever.**

`spc!` is defined at runtime by `(general-create-definer spc! ...)`. The byte-compiler
doesn't see this macro definition, so any call to `spc!` in a byte-compiled file
produces "Invalid function: spc!" at load time. `init.el` was briefly changed to
byte-compile after tangling. This broke everything. Reverted.
`init.el` must always just call `(load-file el)` — never `(byte-compile-file ...)`.

**2. init.el is sourced via `xdg.configFile."emacs/init.el".source` — this bypasses Stylix.**

When you set `xdg.configFile."emacs/init.el".source = ./dotfiles/emacs/init.el`,
home-manager uses your file verbatim instead of generating one. Stylix's emacs target
works by injecting `(load-theme ...)` into the home-manager *generated* init.el.
Since we override init.el entirely, Stylix injection never fires.
Fix: standalone `ukiyo-theme.el` in `themes/` subdirectory, loaded manually.
Do NOT attempt to re-enable `stylix.targets.emacs.enable`; it will conflict.

**3. org-roam-directory must be set BEFORE the use-package form.**

`org-roam` autoloads can trigger before use-package evaluates the `:custom` block.
If `org-roam-directory` is not set early, it defaults to `~/org-roam/` and the DB
returns 0 nodes even after `org-roam-db-sync`. The fix is an explicit `(setq
org-roam-directory ...)` immediately before the `use-package org-roam` form.
This line exists in config.org at line 400 — do not remove it.

**4. `:PROPERTIES:` drawer MUST come before `#+title:` in org files for org-id to work.**

`org-id-get` parses the first drawer it finds. If `#+title:` comes first, the
properties drawer is ignored and the node gets no ID. Tested with `org-id-get` on
a temp buffer — confirmed. The vault converter (`convert_vaults.py`) was fixed to
place `:PROPERTIES:` + `:ID:` first, then `#+title:`. All 607 notes follow this
convention. Do not reformat org file headers without preserving this order.

**5. `:keymaps '(normal visual motion)` — NOT `'override`, NOT including `emacs` state.**

The original plan used `'(normal visual emacs)`. This caused SPC to fire in insert
state (briefly) and conflicted with evil-collection's emacs-state buffers (e.g.
magit). The working value is `'(normal visual motion)`. Do not add `emacs` back.

---

### Every bug hit and its fix

#### Bug: "Key sequence SPC f f starts with non-prefix key SPC"

**Cause**: Evil binds SPC to `evil-forward-char` in `evil-motion-state-map` before
general.el gets a chance to claim it as a prefix. The binding order matters.

**Fix** (already in config.org, Evil Mode section):
```elisp
:config
(evil-mode 1)
(define-key evil-motion-state-map (kbd "SPC") nil)
(define-key evil-normal-state-map (kbd "SPC") nil)
```
These two lines MUST appear inside evil's `:config`, AFTER `(evil-mode 1)`.
Three fix iterations were needed before landing on this. Do not move or remove them.

Also: `(setq evil-want-keybinding nil)` must be in evil's `:init` (before evil loads),
not in `:config`. It is already there. Do not reorder.

#### Bug: "Key sequence SPC m n starts with non-prefix key SPC m"

**Cause**: The music pause keybinding was `"m " 'emms-pause` — the space character
in the key string makes SPC-m itself non-prefix.

**Fix**: Changed to `"mt" 'emms-pause`. Already corrected in config.org.

#### Bug: ", t a starts with non-prefix key , t"

**Cause**: Binding `"t" 'org-transclusion-mode` directly AND using `"ta"`, `"td"`,
`"tr"` as sub-keys. You cannot bind a key and use it as a prefix simultaneously.

**Fix**: Changed the toggle to `"tt"` (not `"t"`). Already in config.org.

#### Bug: "Unable to find theme file for 'base16-ukiyo'"

**Cause**: Stylix generates a `base16-ukiyo` theme via home-manager's init.el
injection. Our custom `init.el` bypasses this injection entirely.

**Fix**: Standalone `ukiyo-theme.el` built from the ukiyo.nix palette values, placed
in `~/.config/emacs/themes/`. Loaded via:
```elisp
(add-to-list 'custom-theme-load-path (expand-file-name "themes" user-emacs-directory))
(load-theme 'ukiyo t)
```
The user rejected the fallback (modus-vivendi-tinted). The current ukiyo-theme.el
covers: default faces, cursor, region, mode-line, font-lock, org headings 1–8, org
blocks/code/tags/todo, search, completions, parens, magit diffs, vertico, which-key,
dired, marginalia, elfeed. It is in `home/dotfiles/emacs/ukiyo-theme.el`.

#### Bug: `undefined variable 'citar-org'` during nixos-rebuild

**Cause**: `citar-org` is not a separate package in nixpkgs; it is included inside
the `citar` package. The plan listed it as a separate package.

**Fix**: Removed `citar-org` from the extraPackages list in `home/emacs.nix`.
The `citar` package itself provides citar-org functionality.

#### Bug: org-roam `(org-roam-node-list)` returns 0 nodes

Two separate root causes:

**Cause 1**: `org-roam-directory` defaulting to `~/org-roam/` (see architecture
decision #3 above). Fix: early `(setq org-roam-directory ...)`.

**Cause 2**: `:PROPERTIES:` drawer after `#+title:` (see architecture decision #4).
All 607 converted notes had title first. Fix: restructured `convert_vaults.py`
`build_org_file()` to emit `:PROPERTIES:` before `#+title:`. Re-ran conversion.
After both fixes: `(org-roam-db-clear-all)` + `(org-roam-db-sync)` → 607 nodes.

#### Bug: `#+BEGIN: org-ql-block` produces "void-function org-dblock-write:org-ql-block"

**Cause**: `org-ql-block` is not a dynamic block handler — it exists only as an
org-agenda custom command type. `org-dblock-write:org-ql-block` does not exist.
Verified with `(all-completions "org-dblock-write:" obarray #'fboundp)` — only
`clocktable` and `columnview` exist in this Emacs/org-ql version.

**Fix**: All dashboard "dynamic blocks" replaced with:
```org
#+begin_src emacs-lisp :results value raw :exports results
(org-ql-select FILES QUERY :action '(...))
#+end_src
```
Refresh any block with `C-c C-c` on its `#+begin_src` line (not `C-c C-x C-u`).
The dashboard at `~/org/dashboard.org` already uses this pattern.

#### Bug: "Invalid function: spc!" after byte-compilation

**Cause**: Added byte-compilation to init.el: `(byte-compile-file el)`. The
byte-compiler resolves `spc!` as an undefined function because `general-create-definer`
runs at load time, not compile time.

**Fix**: Reverted init.el to the simple tangle-and-load version. Do not byte-compile.
User also needed to run `rm ~/.cache/emacs/config.el` after every config.org change
during debugging — this forces re-tangle. Without deleting the cached file, old broken
configs kept loading. The re-tangle check compares mtime, so editing config.org in
place (not via symlink replacement) does trigger retangle; but during a NixOS rebuild
the symlink target changes and the mtime comparison may need the cache cleared manually.

#### Bug: System crash after GPU PRIME fix

**Cause**: Added `hardware.nvidia.prime.reverseSync.enable = true` to try fixing
the 20Hz rendering lag. The GTX 1060 uses the `legacy_535` driver which does NOT
support PRIME reverse sync. The system crashed on rebuild.

**Fix**: User rolled back to the previous NixOS generation. Removed reverseSync.

**The correct GPU fix** (already in `hosts/desktop/default.nix`):
```nix
environment.variables.KWIN_DRM_DEVICES = "/dev/dri/by-path/pci-0000:01:00.0-card";
systemd.services.display-manager.after = [ "dev-dri-card2.device" ];
systemd.services.display-manager.wants = [ "dev-dri-card2.device" ];
```
This forces KWin to use the Nvidia card directly (Nvidia = card2, PCI:1:0:0).
The 20Hz lag was caused by KWin rendering on Intel then failing the PRIME copy path.

**CRITICAL: do NOT add `hardware.nvidia.prime.reverseSync.enable = true`.**
It crashes the `legacy_535` driver on GTX 1060. The only safe fix is the env var above.

#### Bug: Vault conversion — tags lost (ToNote disappeared from org-ql results)

**Cause**: The converter stripped `tags: ...` YAML frontmatter lines before extracting
inline `#Tag` Obsidian tags. So `#ToNote` appeared after the `tags:` line was stripped,
giving nothing to extract.

**Fix**: `extract_inline_tags()` now runs BEFORE `strip_zoottelkeeper()` and
`strip_frontmatter_line()`. Order matters. Already fixed in `convert_vaults.py`.

#### Bug: Vault conversion — Bruno Latour classified as personal contact

**Cause**: Famous/notable people use the same template as personal contacts, with all
personal fields (phone, email, city, birthday, occupation, context) present but empty.
`is_personal_person()` checked for key existence, not non-empty values.

**Fix**: `is_personal_person()` now checks `bool(frontmatter.get(key, '').strip())`
for at least one personal key having a non-empty value. Already fixed in `convert_vaults.py`.

#### Performance: Emacs is slow in large windows on 4K

**Symptom**: Cursor movement is sluggish in large Emacs windows (and in Obsidian). Small
windows are smooth. Firefox is smooth at any size. Scaling with window WIDTH, not height.

**Root cause**: `emacs-pgtk` renders all buffer content via **Cairo on the CPU**.
At 3840×2160 (4K) the Cairo surface is ~33MB. Every cursor move, mode line update,
or cursor blink forces Cairo to rasterize glyphs into that surface. More pixels = more
CPU work. This is structural to how pgtk Emacs works — there is no GPU-accelerated text
renderer.

Firefox avoids this entirely via WebRender (GPU-native compositing).
Obsidian (Electron) has the same issue for the same reason.

**Things tried and ruled out:**
- `GDK_SCALE=1 emacs` — no effect; on Wayland, KWin communicates scale via the Wayland
  protocol and GTK4 ignores `GDK_SCALE` in favour of that, so Emacs still renders at 4K
- `__EGL_VENDOR_LIBRARY_FILENAMES=.../10_nvidia.json emacs` — no effect; the bottleneck
  is Cairo CPU rasterization, not the GPU texture upload path
- Disabling EMMS mode-line — no effect; mode line redraws were not the bottleneck
- `(emms-playing-time-mode -1)` — no effect for same reason

**NOT tried / future options:**
- Reduce KDE display scale from 200% to 150% — would give ~44% fewer pixels, affects
  whole desktop, probably the most impactful option if the performance becomes intolerable
- Wait for GPU-accelerated Emacs text rendering — experimental patches exist, nothing
  in mainline Emacs yet
- Switch to `emacs` (non-pgtk, X11/XWayland) — might benefit from Nvidia XRender
  acceleration, untested; would lose native Wayland features

**Current decision**: Leave it. Use Emacs in a non-maximized window at a comfortable
size. Revisit if fractional scaling or a GPU-accelerated Emacs build becomes available.

**`(blink-cursor-mode -1)` is already in config.org** — eliminates timer-driven redraws
even when idle. Small improvement, zero cost.

---

### GPU hardware facts (desktop machine)

```
card0  = simple-framebuffer (boot framebuffer — not a real GPU)
card1  = Intel iGPU, PCI:0:2:0, vendor 0x8086
         /dev/dri/by-path/pci-0000:00:02.0-card
card2  = Nvidia GTX 1060, PCI:1:0:0, vendor 0x10de
         /dev/dri/by-path/pci-0000:01:00.0-card
```

Monitors are connected to the Nvidia card. KWin default was using Intel for rendering
then copying via PRIME offload path — this failed ("couldn't find dev node for drm
device") and caused the compositor to drop events ("Key repeat discarded").
`KWIN_DRM_DEVICES` bypasses Intel entirely.

Driver: `config.boot.kernelPackages.nvidiaPackages.legacy_535` (GTX 1060 max).
Do not upgrade to a non-legacy driver — GTX 1060 is not supported.

---

### What was observed to NOT work yet (as of end of session)

**olivetti, mixed-pitch, org-modern, org-superstar hooks not firing:**
These packages are all declared with `:hook (org-mode . ...)`. When tested in a live
org buffer after startup, these modes showed as `nil`. The packages load (no errors at
startup) but the hooks may not be triggering. Possible causes:
- org-mode itself not loading early enough for hooks to register
- `use-package :hook` fires at package load time, but org may be loaded before the
  use-package forms evaluate (org ships with Emacs)
- Try: add `(require 'org)` before the appearance use-package blocks, or switch to
  `(add-hook 'org-mode-hook ...)` forms explicitly instead of `:hook`

**Dashboard blocks not tested interactively:**
The `~/org/dashboard.org` file was written and committed. The emacsclient calls during
the session timed out because Emacs was initializing. The blocks (`C-c C-c` to refresh)
have not been confirmed working. When testing: make sure `org-babel-load-languages`
includes `emacs-lisp`, and `org-confirm-babel-evaluate` is nil. Both are set in config.org.

**Perspectives not tested:**
`perspective.el` is declared and `perspective-personal` / `perspective-uni` functions
are defined. The startup hook calls `perspective-personal` on startup. Not confirmed
that it opens the correct dashboard.

**org-gcal warning on startup:**
`org-gcal` prints a warning about missing `client-id`/`client-secret`. This is harmless
until credentials are configured. The `auth-source-pick-first-password` calls return
nil when `~/.authinfo.gpg` doesn't exist. To suppress until credentials are ready,
wrap the config in a condition: `(when (file-exists-p "~/.authinfo.gpg") ...)`.

**EMMS library not scanned:**
`M-x emms-add-directory-tree` on `/home/thijmen/Documents/BACKUP/Music Library/` has
not been run. The library is empty. EMMS player is configured and mpv backend set up,
but no tracks visible until the scan.

**ox-typst availability:**
The config has ox-typst commented out. Need to check: `nix search nixpkgs#emacs-packages.ox-typst`.
If it exists in nixpkgs 26.05, uncomment the `(with-eval-after-load 'ox (require 'ox-typst))` line
and add `ox-typst` to `home/emacs.nix` extraPackages. If not in nixpkgs, leave commented.

---

### Current working state (confirmed)

- Emacs launches without errors
- ukiyo theme loads (dark background, correct palette colors)
- Evil mode active — hjkl, dd, yy, /, visual mode all work
- SPC leader shows which-key hints
- `SPC f f` opens find-file, `SPC g g` opens magit, `SPC b b` opens consult-buffer
- org-roam DB has 607 nodes (verified with `(length (org-roam-node-list))`)
- `SPC n f` finds org-roam nodes with completion
- dashboard.org opens at startup (via `initial-buffer-choice`)
- org-gcal warning on startup (harmless)

---

### TODO for next session (priority order)

**1. Fix org-mode appearance hooks** — `olivetti-mode`, `mixed-pitch-mode`, `org-modern-mode`
and `org-superstar-mode` are not activating in org buffers. These are the biggest
daily-experience improvements. Debugging approach: open an org buffer, run `M-x olivetti-mode`
manually to confirm the package works, then trace why the hook isn't firing.
Fix candidates: explicit `(add-hook 'org-mode-hook #'olivetti-mode)` outside use-package,
or add `:defer nil` to force eager loading.

**2. Test dashboard C-c C-c blocks** — open `~/org/dashboard.org`, place cursor on
a `#+begin_src emacs-lisp` line, press `C-c C-c`. Should produce a table below the block.
If it asks to confirm evaluation, check `org-confirm-babel-evaluate` is nil.

**3. Test capture templates** — `SPC n c` should show the capture menu with all templates
(pc, pe, pb, pp, pk, pf, uc, ul, ua, i). Create a test concept note and a test inbox entry.

**4. Test daily note** — `SPC n d` should open or create today's daily in `~/org/daily/`.

**5. Check keybinding parity with neovim** — read `/etc/nixos/home/dotfiles/neovim/init.lua`
and compare SPC bindings. Add any missing ones to config.org.

**6. Set up org-gcal credentials** — follow the one-time setup in the Google Calendar
section of config.org (or in Phase 3d of this plan below). Until done, the startup
warning will persist and `SPC a` will not show Google Calendar events.

**7. Scan EMMS library** — `M-x emms-add-directory-tree` on the Music Library path.
Then add `(emms-cache-enable)` to the EMMS block in config.org so the scan persists
across restarts.

**8. Check ox-typst** — `nix search nixpkgs#emacs-packages.ox-typst` and decide.

**9. Perspective-personal startup** — confirm the startup hook opens the personal
dashboard in the "personal" perspective correctly. If it's opening dashboard.org but
not switching to the personal perspective, the `perspective-personal` function call in
the startup hook may be running before persp-mode initializes.

**10. Verify GPU fix applied** — the KWIN_DRM_DEVICES fix was in the last rebuild before
the session ended. Confirm 60Hz rendering is now stable (no 20Hz cursor lag). If lag
persists, check `journalctl -b | grep -i "key repeat discarded"`.

---

### How to apply changes going forward

```bash
# Edit config.org
# Then rebuild and force re-tangle:
rebuild && rm -f ~/.cache/emacs/config.el (done by user, because it requires root access)
# Then restart Emacs (or eval-buffer the tangled file)
```

If only changing keybindings or small elisp:
```bash
rm -f ~/.cache/emacs/config.el
# Restart Emacs — init.el will re-tangle on next startup
```

If changing `home/emacs.nix` (adding/removing packages) or any `.nix` file:
```bash
rebuild   # alias for: nh os switch /etc/nixos -H desktop
```

---

## ── ORIGINAL PLAN (written before implementation) ──────────────────────────────

## What I found in your vaults

### Personal vault structure
```
Renaissance_Vault_Structure/
  Concepts/      physics (Landau-level notes), philosophy, humanities (~150 files)
  Knowledge/     subdirs: Physics, Philosophy, Mathematics, Languages, etc.
  Essays/        written essays (Capitalism, Art, etc.)
  Sources/       Books/, Papers/, Youtube/
  People/        person notes with template
  Dailies/       YYYY-MM-DD.md format
  Templates/     Books (book template), People.md
  Misc/          scratch
```

### Uni vault structure
```
Uni/
  Classes/       one file per class, contains dataview tables of lectures + assignments
  Lecture/       one file per lecture (frontmatter: class, date, lecture_number)
  Assignments/   one file per assignment (frontmatter: class, grade, deadline)
  Summary/       final summary per class
  Lecture MOC/   map of content per class
  Thesis/
  Uni MOC.md     master overview: all classes, upcoming deadlines
  2026-XX-XX.md  loose session notes at root (no dailies folder)
```

### Plugin → Emacs package mapping

| Obsidian plugin        | Emacs equivalent              | Notes                                          |
|------------------------|-------------------------------|------------------------------------------------|
| dataview               | org-ql                        | query language for org files                   |
| templater-obsidian     | org-capture + org-roam captu  | `<% tp.file.title %>` → `${title}`             |
| typst-mate             | custom org-typst-preview-mode | cursor-away → SVG render; cursor-in → source   |
| rss-dashboard          | elfeed + elfeed-tube          | YouTube via RSS; `mpv` on play                 |
| obsidian-day-planner   | org-agenda time-grid          | built-in; visual scheduling                    |
| obsidian-git           | magit                         | much better                                    |
| calendar               | org-gcal + org-agenda         | two-way Google Calendar sync                   |
| zoottelkeeper          | not needed                    | org-roam handles backlinks automatically       |
| folder-note-plugin     | dired + org-roam              | folder browsing via dired sidebar              |
| waypoint               | org-roam MOC pattern          | manual but cleaner                             |
| inline-math            | org-typst-preview-mode        | same as typst-mate — see Phase 3b              |
| markdown-table-editor  | org-table                     | built-in, excellent                            |
| vim-yank-highlight     | evil-goggles                  | highlights evil operations                     |
| cycle-through-panes    | evil window + perspective     | `SPC w hjkl` + perspective workspaces         |
| quickadd               | org-capture                   | same concept                                   |
| extended-graph         | org-roam-ui                   | browser-based graph view                       |
| obsidian-charts        | org-plot                      | gnuplot backend                                |
| obsidian-regex-replace | query-replace-regexp          | built-in: `M-%`                                |
| settings-search        | which-key + `M-x`             | `M-x` is already a fuzzy command search        |
| chronos                | custom D3.js timeline script  | Python script → HTML timeline; much better     |
| music-player (Misc)    | EMMS + mpv                    | sidebar browser, FLAC/MP3, SPC m m to toggle   |

---

## Design decisions (from answers)

- **Typst math inline rendered**: `org-typst-preview-mode` renders `$...$` fragments
  as inline SVG by calling `typst compile --format svg` — same feel as typst-mate.
  Cursor leaves fragment → renders. Cursor enters → shows source. Toggle with `SPC t p`.
  No LaTeX anywhere: the Typst CLI (already installed) does all rendering.
- **Music player in Emacs**: `emms` backed by mpv browses the local FLAC library at
  `/home/thijmen/Documents/BACKUP/Music Library/`. Sidebar toggles with `SPC t s` or
  `SPC m m`.
- **Separate contexts via perspectives**: you open two Obsidian vaults (personal + uni).
  In Emacs: `perspective.el` creates named workspaces with separate buffer lists.
  Each perspective opens to its own dashboard org file.
- **Navigate by folders**: you browse folder structure, not search/graph. Emacs
  provides `dired` (built-in file browser with evil bindings) and `dired-sidebar`
  (persistent sidebar). This replaces the Obsidian file tree.
- **Backlinks are low priority**: you almost never use the backlinks panel — don't
  clutter the UI with it. Include `SPC n b` to toggle it, but keep it hidden by default.
- **Single-pane focus**: olivetti + no sidebar by default. Split only when needed
  (lecture on left, summary on right for the transclusion workflow).
- **Unified org-roam database**: one database spanning `~/org/`. Perspectives handle
  the separation, not separate databases.
- **PDF viewing in Emacs**: `pdf-tools` for viewing lecture slides + papers. No
  annotation-to-notes linking needed — just viewing.
- **Google Calendar sync**: `org-gcal` replaces calcurse. Two-way sync.
- **Spell check**: English + Dutch. `jinx` with both dictionaries.
- **Keybindings match Neovim**: SPC ff, SPC gg, SPC bb etc. should be identical
  to neovim where they overlap. Check `home/dotfiles/neovim/init.lua` when writing
  the final config.
- **Complete beginner**: config should work out of the box. Keep `use-package` blocks
  well-commented so they can be understood when the user explores later.
- **Migration first, then switch**: run pandoc conversion on both vaults, verify
  org-roam DB, then switch — keep Obsidian running until satisfied.

---

## Directory structure

```
~/org/
  personal/
    concepts/       atomic concept notes (replaces Concepts/)
    knowledge/
      physics/      larger reference docs (replaces Knowledge/Physics/)
      philosophy/   (replaces Knowledge/Philosophy/)
      mathematics/  (etc.)
      languages/
      meta/
    essays/         replaces Essays/
    sources/
      books/        replaces Sources/Books/  (library.bib covers metadata)
      papers/       replaces Sources/Papers/
      youtube/      replaces Sources/Youtube/
    people/         replaces People/
    misc/
  uni/
    classes/        one .org file per class (replaces Classes/)
    lectures/       one .org file per lecture (replaces Lecture/)
    assignments/    one .org file per assignment OR single assignments.org
    summary/        replaces Summary/
    thesis/
  daily/            org-roam-dailies (shared across contexts)
  library.bib       single BibTeX file for all books + papers (Syncthing-synced)
  inbox.org         quick capture — process regularly
  agenda.org        scheduled items and global TODOs
```

---

## Phase 1 — Nix setup

### `home/emacs.nix` — new file
```nix
{ pkgs, ... }: {
  programs.emacs = {
    enable  = true;
    package = pkgs.emacs-pgtk;  # Wayland-native: important for sway later
    extraPackages = epkgs: with epkgs; [
      # ── Evil ─────────────────────────────────────────────────────────────
      evil
      evil-collection    # evil in every buffer (magit, dired, org, etc.)
      evil-surround      # cs, ds, ys surround motions
      evil-commentary    # gc to comment
      evil-goggles       # flash highlighting on yank/delete/paste
      general            # SPC-leader keybinding framework

      # ── UI ───────────────────────────────────────────────────────────────
      which-key
      vertico            # vertical minibuffer completion
      marginalia         # annotations in completion (file size, doc strings)
      consult            # enhanced commands: consult-line, consult-grep, etc.
      orderless          # fuzzy/space-separated matching
      embark             # action menu on any completion candidate
      embark-consult

      # ── Navigation ───────────────────────────────────────────────────────
      avy                # jump to char/word/line (like easy-motion)
      projectile         # project-aware commands

      # ── Git ──────────────────────────────────────────────────────────────
      magit
      diff-hl            # gutter diff indicators

      # ── Org ──────────────────────────────────────────────────────────────
      org-roam           # zettelkasten, backlinks, graph
      org-roam-ui        # browser graph view (localhost)
      org-ql             # query language (replaces dataview)
      org-superstar      # prettier headings
      org-modern         # cleaner org rendering (tables, tags, todo)
      org-transclusion   # embed sections from other org files (lecture → summary)

      # ── Citations / library ──────────────────────────────────────────────
      citar              # citation management (books + papers, .bib backend)
      # NOTE: citar-org is NOT a separate package — it is included inside citar
      org-roam-bibtex    # link bibtex entries to org-roam notes

      # ── Reading / RSS ────────────────────────────────────────────────────
      elfeed
      elfeed-org         # manage feed list in an org file
      elfeed-tube        # YouTube in elfeed (plays via mpv)

      # ── Typst ────────────────────────────────────────────────────────────
      typst-ts-mode      # tree-sitter major mode for .typ files
      # ox-typst         # org→Typst exporter — check if in nixpkgs 26.05; may need overlay

      # ── Context workspaces ───────────────────────────────────────────────
      perspective        # named workspaces (personal / uni), separate buffer lists

      # ── File browsing ────────────────────────────────────────────────────
      dired-sidebar      # persistent file tree sidebar (replaces Obsidian file tree)

      # ── PDF viewing ──────────────────────────────────────────────────────
      pdf-tools          # view PDFs inside Emacs (lecture slides, papers)

      # ── Calendar ─────────────────────────────────────────────────────────
      org-gcal           # two-way Google Calendar sync

      # ── Writing / appearance ─────────────────────────────────────────────
      mixed-pitch        # variable font for org prose, mono for code
      olivetti           # centered writing mode
      jinx               # fast spell checking (English + Dutch)

      # ── Code / LSP ───────────────────────────────────────────────────────
      # eglot is built-in (Emacs 29+)
      treesit-auto       # auto tree-sitter grammars

      # ── Misc ─────────────────────────────────────────────────────────────
      markdown-mode
      vterm              # fast terminal (for quick commands without leaving Emacs)
    ];
  };

  xdg.configFile."emacs/init.el".source       = ./dotfiles/emacs/init.el;
  xdg.configFile."emacs/early-init.el".source = ./dotfiles/emacs/early-init.el;
  xdg.configFile."emacs/config.org".source    = ./dotfiles/emacs/config.org;
  xdg.configFile."emacs/elfeed.org".source    = ./dotfiles/emacs/elfeed.org;
  xdg.configFile."emacs/themes/ukiyo-theme.el".source = ./dotfiles/emacs/ukiyo-theme.el;
}
```

### Add to `modules/common.nix` packages:
```nix
tinymist   # Typst LSP (used by typst-ts-mode via eglot)
enchant2   # spell-check backend for jinx
(hunspellWithDicts [ hunspellDicts.en_US hunspellDicts.nl_NL ])
```

### Add to `home/default.nix` imports:
```nix
./emacs.nix
```

---

## Phase 2 — `early-init.el`

### `home/dotfiles/emacs/early-init.el`
```elisp
(setq inhibit-startup-screen t)
(push '(menu-bar-lines  . 0) default-frame-alist)
(push '(tool-bar-lines  . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(internal-border-width . 0) default-frame-alist)
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
  (lambda () (setq gc-cons-threshold (* 16 1024 1024))))
```

---

## Phase 3 — `init.el` — core config

### 3a: Evil mode
```elisp
(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)   ; MUST be before evil-collection, in :init
  (setq evil-undo-system 'undo-redo)
  (setq evil-want-C-u-scroll t)     ; C-u scrolls (like vim)
  (setq evil-search-module 'evil-search)
  :config
  (evil-mode 1)
  ;; CRITICAL: unbind SPC from evil-motion-state before general claims it
  (define-key evil-motion-state-map (kbd "SPC") nil)
  (define-key evil-normal-state-map (kbd "SPC") nil))

(use-package evil-collection
  :after evil
  :config (evil-collection-init))

(use-package evil-goggles
  :after evil
  :config
  (evil-goggles-mode)
  (evil-goggles-use-diff-faces))
```

### 3b: SPC leader (general.el)
```elisp
;; CRITICAL: :keymaps must be '(normal visual motion), NOT '(normal visual emacs)
;; Adding 'emacs causes conflicts with evil-collection's emacs-state buffers
(use-package general
  :after evil
  :config
  (general-create-definer spc!
    :keymaps '(normal visual motion)
    :prefix "SPC"
    :global-prefix "C-SPC")
  (general-create-definer local!
    :keymaps '(normal visual)
    :prefix ","))
```

### 3c: Completion
```elisp
(use-package vertico  :init (vertico-mode))
(use-package marginalia :init (marginalia-mode))
(use-package orderless
  :custom (completion-styles '(orderless basic)))
(use-package consult
  :bind ([remap switch-to-buffer] . consult-buffer))
(use-package embark
  :bind ("C-." . embark-act))
(use-package embark-consult :after (embark consult))
(use-package which-key
  :init (which-key-mode)
  :custom (which-key-idle-delay 0.4))
```

### 3d: Appearance
```elisp
;; Standalone ukiyo theme (Stylix injection disabled — see architecture decisions)
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes" user-emacs-directory))
(load-theme 'ukiyo t)

;; Line numbers in code modes, not in org/prose
(add-hook 'prog-mode-hook 'display-line-numbers-mode)

;; Variable pitch in org, mono in code blocks
;; NOTE: if mixed-pitch-mode doesn't activate, try explicit (add-hook ...) form
(use-package mixed-pitch :hook (org-mode . mixed-pitch-mode))

;; Centered writing
(use-package olivetti
  :custom (olivetti-body-width 90)
  :hook (org-mode . olivetti-mode))

;; Prettier org
(use-package org-superstar :hook (org-mode . org-superstar-mode))
(use-package org-modern
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda)))
```

---

## Phase 3b — Typst math in org-mode

Math in org notes stays as plain Typst syntax — no rendering, no LaTeX, no engine.
You write exactly what you already write in typst-mate:

```org
The Schrödinger equation: $i hbar diff/(diff t) Psi = hat(H) Psi$

For display math, just use a typst code block in the export:
$integral_0^1 f(x) d x = F(1) - F(0)$

Cases: $cases(a "if" x > 0, b "otherwise")$
Dirac notation: $braket(psi, phi)$
```

This is **readable plain text** in org-mode. No rendering in the editor — you
already know the Typst syntax well enough to read it. When you want pretty output,
export to Typst via ox-typst.

### ox-typst export

`ox-typst` is an org-mode exporter backend that outputs `.typ` files. It handles
the Typst math syntax you're already writing:

```elisp
;; org → Typst export
;; ox-typst adds C-c C-e t t (export to .typ file) and C-c C-e t p (compile to PDF)
(with-eval-after-load 'ox
  (require 'ox-typst))
```

**Check availability in nixpkgs 26.05**: `ox-typst` may not be packaged yet.
To check: `nix search nixpkgs ox-typst`. If not found, install via `straight.el`
or add an overlay fetching from GitHub (`emacsmirror/ox-typst` or similar).
Fallback: `nix shell nixpkgs#emacs-packages.ox-typst` to test before committing.

### Typst-ts-mode for standalone .typ files

Dedicated `.typ` files (summaries exported to PDF, thesis chapters) get full
tree-sitter highlighting, tinymist LSP, and compile-on-save:

```elisp
(use-package typst-ts-mode
  :mode "\\.typ\\'"
  :custom
  (typst-ts-mode-watch-options "--open")  ; open PDF on first compile
  :config
  ;; Compile current .typ file: SPC m c
  (general-def :states '(normal) :keymaps 'typst-ts-mode-map
    "SPC m c" 'typst-ts-compile
    "SPC m w" 'typst-ts-mode-watch-toggle))
```

The LSP (tinymist) is already in `modules/common.nix` from Phase 1. Eglot picks it
up automatically when you open a `.typ` file.

---

## Phase 3b-2 — Snowflake visualizations

You have three snowflake HTML visualizations of your config/vault structures.
Emacs provides keybindings to open them in a browser and to regenerate them.

```elisp
(defun open-personal-snowflake ()
  (interactive)
  (browse-url "file:///home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/vault_snowflake.html"))

(defun open-uni-snowflake ()
  (interactive)
  (browse-url "file:///home/thijmen/Documents/BACKUP/Uni/Obsidian/Uni/uni_snowflake.html"))

(defun open-nixos-snowflake ()
  (interactive)
  (browse-url "file:///etc/nixos/nixos_snowflake.html"))

(defun regenerate-snowflakes ()
  (interactive)
  (async-shell-command
    (concat "python3 /home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/vault_snowflake.py && "
            "python3 /home/thijmen/Documents/BACKUP/Uni/Obsidian/uni_snowflake.py && "
            "python3 /etc/nixos/nixos_snowflake.py")
    "*snowflake-regen*"))

(spc!
  "o v" 'open-personal-snowflake   ; SPC o v → personal vault snowflake
  "o u" 'open-uni-snowflake        ; SPC o u → uni vault snowflake
  "o n" 'open-nixos-snowflake      ; SPC o n → nixos config snowflake
  "o V" 'regenerate-snowflakes)    ; SPC o V → regenerate all three
```

---

## Phase 3c — Context workspaces (replaces separate Obsidian vaults)

You work in two separate Obsidian vaults. In Emacs, `perspective.el` creates named
workspaces (perspectives) with completely separate buffer lists. Switching perspective
feels like switching to a different app context — same Emacs instance, different "space".

```elisp
(use-package perspective
  :custom
  (persp-mode-prefix-key (kbd "C-c C-p"))
  (persp-initial-frame-name "personal")
  :init (persp-mode))
```

### Two perspectives: personal and uni

```elisp
;; Open personal dashboard when switching to "personal" perspective
;; Open uni dashboard when switching to "uni" perspective

(defun perspective-personal ()
  "Switch to personal perspective and open dashboard."
  (interactive)
  (persp-switch "personal")
  (find-file "~/org/personal/dashboard.org"))

(defun perspective-uni ()
  "Switch to uni perspective and open dashboard."
  (interactive)
  (persp-switch "uni")
  (find-file "~/org/uni/dashboard.org"))
```

### SPC keybindings for perspectives:
```elisp
(spc!
  "TAB"   '(:ignore t :wk "workspace")
  "TAB p" 'perspective-personal     ; SPC TAB p → personal
  "TAB u" 'perspective-uni          ; SPC TAB u → uni
  "TAB TAB" 'persp-switch           ; SPC TAB TAB → pick any perspective
  "TAB d" 'persp-kill               ; SPC TAB d → close perspective
  "TAB r" 'persp-rename)            ; SPC TAB r → rename
```

### Dashboard files

`~/org/personal/dashboard.org`:
```org
#+title: Personal
#+STARTUP: content

* Recent
# org-ql block showing recent personal notes
#+begin_src emacs-lisp :results value raw :exports results
(let* ((files (org-roam-list-files))
       (results (org-ql-select files '(ts :from -7)
                  :action '(list (org-get-heading t t t t) (buffer-file-name)))))
  ...)
#+end_src
```

Note: `#+BEGIN: org-ql-block` does NOT work — use `#+begin_src emacs-lisp` with
`org-ql-select` instead. The `org-dblock-write:org-ql-block` function does not exist.

---

## Phase 3d — Google Calendar sync (replaces calcurse)

`org-gcal` syncs between org-agenda and Google Calendar. Setup requires a Google
Cloud OAuth2 project — similar to what calcurse-caldav needed.

```elisp
(use-package org-gcal
  :config
  (setq org-gcal-client-id
    (auth-source-pick-first-password :host "org-gcal" :user "client-id"))
  (setq org-gcal-client-secret
    (auth-source-pick-first-password :host "org-gcal" :user "client-secret"))
  (setq org-gcal-fetch-file-alist
   '(("tidemanus@gmail.com" . "~/org/gcal.org")))
  (add-hook 'org-agenda-mode-hook 'org-gcal-fetch))
```

**Important**: `org-gcal-client-id` and `org-gcal-client-secret` must NOT be in
git. Store them in `~/.authinfo.gpg` (encrypted) and reference via `auth-source`.

**Setup steps** (one-time, after rebuild):
1. Create a Google Cloud project → enable Calendar API → create OAuth2 credentials
2. Download `credentials.json` → extract client_id and client_secret
3. Write to `~/.authinfo` (then encrypt to `.gpg`):
   ```
   machine org-gcal login client-id password YOUR_CLIENT_ID
   machine org-gcal login client-secret password YOUR_CLIENT_SECRET
   ```
4. Encrypt: `gpg --symmetric ~/.authinfo` → saves as `~/.authinfo.gpg`
5. Run `M-x org-gcal-fetch` — browser opens for OAuth approval
6. Events appear in `~/org/gcal.org`, visible in org-agenda

---

## Phase 3e — PDF viewing (pdf-tools)

```elisp
(use-package pdf-tools
  :magic ("%PDF" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  :hook (pdf-view-mode . (lambda ()
    (display-line-numbers-mode -1)
    (olivetti-mode -1))))  ; no centering in PDF view

;; Evil bindings for PDF navigation
(evil-define-key 'normal pdf-view-mode-map
  "j"   'pdf-view-next-line-or-next-page
  "k"   'pdf-view-previous-line-or-previous-page
  "J"   'pdf-view-next-page
  "K"   'pdf-view-previous-page
  "gg"  'pdf-view-first-page
  "G"   'pdf-view-last-page
  "+"   'pdf-view-enlarge
  "-"   'pdf-view-shrink
  "H"   'pdf-view-fit-height-to-window
  "W"   'pdf-view-fit-width-to-window)
```

**Note**: pdf-tools requires a native compiled component. With nix this is handled
automatically — the `pdf-tools` package in nixpkgs includes the compiled `epdfinfo`
binary. No `pdf-tools-install` call needed at runtime; remove it if nixpkgs handles
compilation.

---

## Phase 3f — File browsing sidebar (replaces Obsidian file tree)

Since you navigate primarily by folder structure, a persistent sidebar is important.
`dired-sidebar` gives you an always-visible file tree.

```elisp
(use-package dired-sidebar
  :commands dired-sidebar-toggle-sidebar
  :custom
  (dired-sidebar-width 30)
  (dired-sidebar-use-term-integration t)
  :config
  (evil-define-key 'normal dired-sidebar-mode-map
    "h"  'dired-sidebar-up-directory
    "l"  'dired-sidebar-find-file
    "j"  'next-line
    "k"  'previous-line
    "RET" 'dired-sidebar-find-file
    "q"  'dired-sidebar-hide-sidebar))
```

SPC binding:
```elisp
"e"  'dired-sidebar-toggle-sidebar  ; SPC e → toggle file tree
```

The sidebar root changes automatically to match the current `org-roam-directory`
or project. In "personal" perspective it shows `~/org/personal/`; in "uni"
perspective it shows `~/org/uni/`.

---

## Phase 4 — Org-roam (replaces Obsidian backlinks + folder structure)

### Core setup
```elisp
;; MUST set this before the use-package form — autoloads can trigger early
(setq org-roam-directory (expand-file-name "~/org"))

(use-package org-roam
  :custom
  (org-roam-directory (expand-file-name "~/org"))
  (org-roam-dailies-directory "daily/")
  (org-roam-db-location "~/.local/share/org-roam/org-roam.db")
  :config
  (org-roam-db-autosync-mode))
```

### Capture templates (replaces Templater folder templates)
```elisp
(setq org-roam-capture-templates
  '(;; Personal: concept note (replaces Concepts/ + Knowledge/)
    ("c" "concept" plain
     "* ${title}\n\n%?"
     :target (file+head "personal/concepts/${slug}.org"
                        "#+title: ${title}\n#+filetags: :concept:\n")
     :unnarrowed t)
    ;; ... (full templates in config.org Org Capture Templates section)
    ))
```

### Daily notes (replaces personal Dailies/ and uni loose session notes)
```elisp
(setq org-roam-dailies-capture-templates
  '(("d" "daily" entry "* %<%H:%M> %?"
     :target (file+head "%<%Y-%m-%d>.org"
                        "#+title: %<%Y-%m-%d>\n#+filetags: :daily:\n"))))
```

---

## Phase 5 — Org-ql (replaces Dataview)

### IMPORTANT: org-ql dynamic blocks do NOT exist

The syntax `#+BEGIN: org-ql-block ...` in org files calls a dynamic block handler
`org-dblock-write:org-ql-block` which does not exist. This produces a void-function
error. The `org-ql-block` function is only for org-agenda custom commands.

**Always use this pattern instead:**
```org
#+begin_src emacs-lisp :results value raw :exports results
(org-ql-select FILES QUERY :action '(list (org-get-heading t t t t) ...))
#+end_src
```
Refresh with `C-c C-c` on the `#+begin_src` line.

### Core setup
```elisp
(use-package org-ql
  :after org)
```

### Replacing the key Dataview queries:

**All uni classes** (replaces `table year, Q from "Classes"`):
```elisp
(org-ql-search "~/org/uni/classes/"
  '(tags "class")
  :sort '(property "year"))
```

**Upcoming deadlines** (replaces `where !grade and date > today`):
```elisp
(add-to-list 'org-agenda-custom-commands
  '("ud" "Upcoming deadlines"
    ((org-ql-block '(and (tags "assignment")
                         (not (property "grade"))
                         (deadline :from today))
                   ((org-ql-block-header "Assignments due")
                    (org-agenda-files '("~/org/uni/assignments/")))))))
```

---

## Phase 6 — Typst setup (replaces typst-mate)

```elisp
(use-package typst-ts-mode
  :custom
  (typst-ts-mode-watch-options "--open")  ; auto-open PDF on watch
  :hook
  (typst-ts-mode . eglot-ensure))  ; LSP via tinymist

;; Tinymist (Typst LSP) is in common.nix packages
;; eglot picks it up automatically for typst-ts-mode
```

**Workflow for Typst files:**
1. Open `.typ` file in Emacs → typst-ts-mode activates
2. `M-x typst-ts-mode-watch-start` → typst compiles on save, PDF auto-refreshes
3. Or: use a split window — left: `.typ` file, right: PDF in zathura

---

## Phase 7 — Elfeed + YouTube (replaces RSS dashboard)

### Setup
```elisp
(use-package elfeed
  :custom
  (elfeed-db-directory "~/.local/share/elfeed")
  :bind ("C-x w" . elfeed))

(use-package elfeed-org
  :after elfeed
  :config
  (elfeed-org)
  :custom
  (rmh-elfeed-org-files '("~/.config/emacs/elfeed.org")))

(use-package elfeed-tube
  :after elfeed
  :config (elfeed-tube-setup)
  :bind (:map elfeed-show-mode-map
         ("F" . elfeed-tube-fetch)
         ([remap save-buffer] . elfeed-tube-save)
         :map elfeed-search-mode-map
         ("F" . elfeed-tube-fetch)
         ([remap save-buffer] . elfeed-tube-save)))
```

### `home/dotfiles/emacs/elfeed.org` — feed list
```org
* Feeds
** [[https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID][Channel Name]]  :elfeed:
** [[https://example.com/rss][Some RSS Feed]]  :elfeed:
```
Add your YouTube channels by replacing `CHANNEL_ID`.

**elfeed-tube workflow:**
- `F` on a YouTube entry → fetches transcript + description
- `C-c C-o` → open in mpv directly from elfeed
- Better than Obsidian rss-dashboard because you can read, queue, and play without leaving Emacs.

---

## Phase 8 — Lecture → Summary → Knowledge workflow

This is your core study workflow: write per-lecture notes, combine them into a class
summary, then extract the understanding into your personal knowledge vault.
`org-transclusion` is built for exactly this.

### How org-transclusion works

A transclusion is a live embed of content from another file. You write:
```org
#+transclude: [[file:../lectures/aQM-lecture-01.org::*Notes]] :level 2
```
And Emacs renders the "Notes" section of that lecture file inline in your summary.
When you edit the transclusion, you're editing the source lecture file. When you
update the source, the summary updates on next refresh.

### Setup
```elisp
(use-package org-transclusion
  :after org
  :config
  (setq org-transclusion-add-all-on-activate t))

;; Comma leader: "tt" toggles transclusion mode (NOT "t" alone — that blocks sub-keys)
(with-eval-after-load 'org
  (local! :keymaps 'org-mode-map
    "tt" 'org-transclusion-mode   ; IMPORTANT: "tt" not "t"
    "ta" 'org-transclusion-add
    "td" 'org-transclusion-remove
    "tr" 'org-transclusion-refresh))
```

### SPC keybindings for this workflow
```elisp
;; Add to SPC n (notes) prefix:
"nt" 'org-transclusion-add          ; add a transclusion at point
"nT" 'org-transclusion-add-all      ; render all transclusions in buffer
"nR" 'org-transclusion-refresh-all  ; refresh after source changes
```

---

## Phase 9 — Book library (replaces Obsidian Canvas book grid)

```elisp
(use-package citar
  :custom
  (citar-bibliography '("~/org/library.bib"))
  (citar-notes-paths '("~/org/personal/sources/books/"
                       "~/org/personal/sources/papers/"))
  (citar-open-always-create-notes t))

;; NOTE: citar-org is NOT a separate nixpkgs package; it is bundled inside citar.
;; Do NOT add citar-org to extraPackages in emacs.nix.

(use-package org-roam-bibtex
  :after (org-roam citar)
  :config (org-roam-bibtex-mode))
```

### YouTube RSS feed generation

Export your YouTube subscriptions via Google Takeout (takeout.google.com →
select only "YouTube and YouTube Music" → "subscriptions"). You get a
`subscriptions.csv`. Convert to elfeed.org format:

```bash
#!/usr/bin/env bash
echo "* YouTube"
tail -n +2 subscriptions.csv | while IFS=, read -r id url name; do
  clean="${name//\"/}"
  echo "** [[$url][$clean]]  :elfeed:youtube:"
done
```

Run once, paste output into `home/dotfiles/emacs/elfeed.org`.

---

## Phase 11 — File tree for class pages (replaces dataviewjs)

The dataviewjs filesystem tree was nice-to-have. Replace with a simple function:

```elisp
(defun uni-open-class-files ()
  "Open dired on the uni master folder for the current class."
  (interactive)
  (let ((class-name (org-entry-get nil "class" t)))
    (if class-name
        (dired (concat "/home/thijmen/Documents/BACKUP/Uni/Master/" class-name))
      (dired "/home/thijmen/Documents/BACKUP/Uni/Master/"))))
```

Add to SPC bindings when in org-mode class files:
```elisp
"SPC m f" 'uni-open-class-files
```

---

## Phase 12 — Day planning (replaces day-planner)

For uni: the org-agenda time-grid shows your schedule for today with time blocks.

```elisp
(setq org-agenda-time-grid
  '((daily today require-timed)
    (800 1000 1200 1400 1600 1800 2000)
    "......"
    "────────────────"))

;; Schedule assignments: add SCHEDULED: <date time> to any assignment TODO
;; They then appear in org-agenda time-grid
```

For deeper time-blocking, `org-timeblock` creates a visual block schedule.
Check if `pkgs.emacsPackages.org-timeblock` exists in nixpkgs 26.05; if not, skip.

---

## Phase 13 — Conversion: Markdown → Org

**Actual approach used**: Pure Python (not pandoc — not installed on the system).
Conversion script: `/home/thijmen/convert_vaults.py`. Already ran; 607 notes in `~/org/`.

**Critical converter facts:**
- `extract_inline_tags()` MUST run BEFORE `strip_zoottelkeeper()` — otherwise tags are lost
- `:PROPERTIES:` + `:ID:` MUST come before `#+title:` — otherwise org-id-get returns nil
- `is_personal_person()` checks for non-empty values, not just key presence
- Personal contacts → `people/personal/`, famous/notable → `people/notable/`
- WikiLinks: `[[Title]]` → `[[file:~/org/path.org][alias]]`
- Dataview blocks → `# [org-ql query goes here]` (comment placeholder)

If conversion needs to be re-run:
```bash
python3 /home/thijmen/convert_vaults.py
# Then in Emacs:
# M-x org-roam-db-clear-all
# M-x org-roam-db-sync
```

---

## Phase 14 — Testing checklist

After rebuild:

**Core:**
- [ ] `emacs` launches, ukiyo theme applied (dark background)
- [ ] Evil mode: hjkl movement, `dd`, `yy`, `/` search, `SPC` opens which-key
- [ ] `SPC n f` finds org-roam nodes (should show ~607)
- [ ] `SPC g g` opens magit
- [ ] `SPC a` opens org-agenda

**Appearance hooks (currently suspect — verify these):**
- [ ] `olivetti-mode` active in org buffers (text should be centered)
- [ ] `mixed-pitch-mode` active (serif for prose, mono for code blocks)
- [ ] `org-modern-mode` active (modern table borders, prettier tags)
- [ ] `org-superstar-mode` active (custom heading bullets)

**Notes:**
- [ ] `SPC n c` opens capture menu, templates listed (pc/pe/pb/pp/pk/pf/uc/ul/ua/i)
- [ ] Create a new lecture note — frontmatter properties populated
- [ ] `SPC n d` creates/opens today's daily note
- [ ] `SPC n b` shows backlinks panel

**Dashboard:**
- [ ] dashboard.org opens on startup
- [ ] `C-c C-c` on a `#+begin_src emacs-lisp` block executes and produces a table
- [ ] Birthdays, Work Queue, Open Tasks, Recent Notes sections all populate

**Typst:**
- [ ] Open a `.typ` file → typst-ts-mode activates, syntax highlighting works
- [ ] eglot connects to tinymist (check with `M-x eglot`)
- [ ] `typst-ts-mode-watch-start` compiles and opens PDF

**Elfeed:**
- [ ] `SPC r` opens elfeed
- [ ] Feeds load from elfeed.org
- [ ] YouTube entry: `F` fetches description
- [ ] Playing video: `C-c C-o` launches mpv

**Day planning:**
- [ ] `SPC a d` shows dashboard agenda
- [ ] Upcoming assignments appear in deadline section
- [ ] SCHEDULED items appear in time-grid

**Math rendering:**
- [ ] Enable `org-typst-preview-mode` in an org buffer with `$...$` math
- [ ] Moving cursor away from fragment → renders as SVG overlay
- [ ] Moving cursor into fragment → shows source
- [ ] `SPC t P` renders all fragments in buffer

**Workspaces:**
- [ ] `SPC TAB p` switches to personal perspective, opens personal/dashboard.org
- [ ] `SPC TAB u` switches to uni perspective, opens uni/dashboard.org
- [ ] Buffer lists are separate between perspectives

**PDF:**
- [ ] Open a `.pdf` file — pdf-view-mode activates
- [ ] `j/k` scroll, `J/K` change pages, `H/W` fit to window

**Calendar:**
- [ ] `M-x org-gcal-fetch` opens browser for OAuth (first time only)
- [ ] After auth: events appear in `~/org/gcal.org`
- [ ] Events visible in `SPC a` org-agenda

**Music:**
- [ ] `M-x emms-add-directory-tree` scans Music Library
- [ ] `SPC m m` opens EMMS sidebar
- [ ] `SPC m t` toggles play/pause

---

## Remaining open questions

- [ ] **org-mode appearance hooks**: olivetti, mixed-pitch, org-modern, org-superstar
      not confirmed firing. Debug by opening org buffer and checking `M-x describe-mode`.
- [ ] **ox-typst**: check `nix search nixpkgs#emacs-packages.ox-typst`. If available,
      add to emacs.nix and uncomment the `(with-eval-after-load 'ox ...)` line in config.org.
- [ ] **org-gcal credentials**: you'll need to create a Google Cloud project and enable
      the Calendar API. Credentials go in `~/.authinfo.gpg`, NOT in the nix config.
- [ ] **EMMS library scan**: first-time setup requires `M-x emms-add-directory-tree`.
      Add `(emms-cache-enable)` to config.org to persist across restarts.
- [ ] **Neovim vs Emacs for code**: start with coexistence. If Emacs eglot + Python
      feels good after a month of use, consider switching fully. No need to decide now.
- [ ] **SPC keybinding parity**: before finalizing config.org, read
      `home/dotfiles/neovim/init.lua` and map identical SPC bindings in Emacs.
- [ ] **Perspective startup**: confirm the startup hook correctly opens the personal
      perspective + dashboard. May need `run-with-idle-timer` wrapping if persp-mode
      hasn't fully initialized when the hook fires.
- [ ] **Thesis**: capture template is included. Becomes active when thesis work starts.
- [ ] **YouTube RSS**: add channels to elfeed.org (Google Takeout → subscriptions.csv).
