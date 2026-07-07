# Emacs — config plan

*Last updated: 2026-07-08*
*Config lives at `~/.config/emacs/config.org` (edit directly; saved → auto-retangles to `config.el`).*
*Nix packages: `home/emacs.nix`. Rebuild only when adding/removing packages.*

---

## Priorities

Ordered. Do these before anything else.

### 1. org/ migration

**Survey done 2026-07-08.** Work remaining: 10 missing personal dailies, wikilink repair across lecture/class files, org-ql dynamic blocks replacing dataview placeholders in class/MOC files, and updating the capture workflow text in class files.

---

#### Current conversion state

**Personal daily notes** (`~/org/daily/`)
- 80 source files; 70 converted. All converted except the 10 most recent:
  `2026-06-08`, `2026-06-10`, `2026-06-11`, `2026-06-12`, `2026-06-13`, `2026-06-14`, `2026-06-24`, `2026-06-25`, `2026-06-29`, `2026-07-06`
- Source: simple markdown — `# YYYY-MM-DD` title, then `## Schedule / ## ToDo / ## Inbox / ## Italian / ## Notes`. No dataview in modern notes.
- Org-roam capture template already matches this structure.

**Uni daily notes** (`~/org/uni/daily/`) — 4 files, all empty or near-empty. Delete these; they add nothing.

**Uni lecture notes** (`~/org/uni/lecture/`)
- All 77 source files converted. 83 files in org (6 extra: a `~` backup + a few course-level index files).
- **Wikilinks stripped.** `[[../Assignments/Name|text]]` → bare `text`. 0 org links remain. Needs a repair script.
- Math ($..$ Typst notation) preserved — typst-preview handles it.
- Courses: Advanced QM (12), Applications QM (5), C++ (7), Complex Analysis (14), Computational Physics (6), Continuum Physics (1), Engineering/Ethics (5), Fundamentals QI (9), Interpretation QM (2), Mesoscopic Physics (1), PDE (1), Quantum Computer Architecture (10).

**Uni class files** (`~/org/uni/classes/`) — 12/12 converted.
- Dataview blocks replaced with `* [org-ql query goes here]` — not real queries.
- "ctrl+n → Lecture" text preserved but points to Obsidian. Replace with org-roam capture note.
- Wikilinks to summaries stripped.

**Uni assignments** (`~/org/uni/assignments/`) — 19/22 converted.
- The 3 missing are Computational Physics project files that were copies of git repo code. Keep them as markdown; do not convert.

**Uni summary, thesis, concepts** — all complete (6/6, 3/3, 17/17).

**Uni MOC** (`~/org/uni/Uni MOC.org`) — converted; planning table is native org (good). Dataview blocks replaced with placeholders.

---

#### org-ql dynamic blocks (auto-render on file open)

`#+BEGIN: org-ql` is a standard org dynamic block. It does **not** auto-render by default. To make all dynamic blocks render when an org file is opened, add this to the org-ql config block in `config.org`:

```elisp
(add-hook 'org-mode-hook #'org-update-all-dblocks)
```

This fires `org-update-all-dblocks` on every org file open. For files with 1–3 blocks and a bounded search path it's fast. The `:files` parameter limits which files are queried — always set it to avoid scanning all of `org-agenda-files`.

---

**Block syntax** (the writer is `org-dblock-write:org-ql`; block name is `org-ql` not `org-ql-block`):

**1. Lecture list per class** (each `classes/*.org` file):
```org
#+BEGIN: org-ql :files (directory-files "~/org/uni/lecture/" t "\\.org$") :query (property "CLASS" "Advanced Quantum Mechanics") :columns (heading (property "LECTURE_NUMBER" "Lec") (property "DATE" "Date")) :sort (property "LECTURE_NUMBER")
#+END:
```

**2. Assignment list per class** (each `classes/*.org` file):
```org
#+BEGIN: org-ql :files (directory-files "~/org/uni/assignments/" t "\\.org$") :query (property "CLASS" "Advanced Quantum Mechanics") :columns (heading (property "DEADLINE" "Due") (property "GRADE" "Grade"))
#+END:
```

**3. All-classes table** (`Uni MOC.org`):
```org
#+BEGIN: org-ql :files (directory-files "~/org/uni/classes/" t "\\.org$") :query (level 1) :columns (heading (property "YEAR" "Year") (property "Q" "Q") (property "CODE" "Code"))  :sort (property "YEAR")
#+END:
```

**4. Active deadlines** (`Uni MOC.org`):
```org
#+BEGIN: org-ql :files "~/org/uni/" :query (and (deadline :to +60d) (not (done))) :columns (heading deadline (property "CLASS" "Class")) :sort deadline
#+END:
```

**5. Old Obsidian Tasks blocks** (`#+begin_src tasks`) in a few 2024-era daily notes — leave as-is. They render as an inert code block and the historical tasks are irrelevant.

**6. File tree (per class)** — the dataviewjs block that listed project files from `~/Documents/BACKUP/Uni/Master/<ClassName>/`. Replace with a plain dired link:
```org
[[file:~/Documents/BACKUP/Uni/Master/Advanced Quantum Mechanics/][Project files]]
```

---

#### Wikilink repair in lecture notes

All lecture files had their wikilinks stripped during conversion. A wikilink `[[../Assignments/Advanced QM Presentation|here]]` became `here`. The `[[#Section]]` internal links became one-word fragments like "quantization" instead of "Second quantization".

The repair strategy:
- Write a Python script that reads each `.org` file, looks up the linked note name via `org-roam`'s sqlite DB, and inserts `[[file:~/org/uni/path/to/Note.org][display text]]`.
- For `[[#Section]]` in-file links: convert to org `[[*Section Name]]` internal links.
- The script only needs to run once; after that, future edits stay in org.

Prerequisite: org-roam DB must be up to date (`M-x org-roam-db-sync`).

---

#### "Press n for new lecture" → org-roam capture

The class files say: *"Type ctrl+n → Lecture → [Class name] for a new lecture."*

Replace with:
```org
/Use =SPC n r c= then =l= (lecture) to add a new lecture for this class./
```

Also verify that the lecture capture template sets `:CLASS:` in the PROPERTIES drawer automatically — this is what the org-ql queries above rely on. Check the template in `config.org`; if it only prompts for the class name without inserting a `:CLASS:` property, add `":CLASS: %^{Class}"` to the template string.

---

#### Personal vault — on hold

`Knowledge/`, `Concepts/`, `Essays/`, `Sources/` in `~/org/` are skeleton or wikilink-stripped. **Do not migrate until:**

1. The wikilink repair script from the lecture notes is tested and generalised.
2. The dashboards (`my/vault-dashboard`) are updated to query PROPERTIES drawers instead of YAML frontmatter — `birthday:`, `tags:`, `date:` are currently read from frontmatter.

---

#### Step-by-step actions

1. Convert the 10 missing personal dailies:
   ```bash
   VAULT=~/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure
   for f in 2026-06-08 2026-06-10 2026-06-11 2026-06-12 2026-06-13 2026-06-14 2026-06-24 2026-06-25 2026-06-29 2026-07-06; do
     pandoc -f markdown -t org "$VAULT/Dailies/$f.md" -o ~/org/daily/$f.org
     sed -i "1s/^/#+title: $f\n#+filetags: :daily:\n\n/" ~/org/daily/$f.org
   done
   ```
2. Delete `~/org/uni/daily/` (4 empty files).
3. Add `(add-hook 'org-mode-hook #'org-update-all-dblocks)` to the org-ql config block in `config.org`.
4. Replace dataview placeholders in one class file first; verify the block renders correctly on open; then repeat for all 12.
5. Write the wikilink repair Python script. Test on one lecture file before bulk-running.
6. Update the "ctrl+n" prompts in class files.
7. Verify the lecture capture template inserts `:CLASS:` property.

---

### 2. mpv opens windowless

mpv plays audio but no video window. Was working; something broke. The `--gpu-api=opengl` flag in `my/yt--play` was the original fix for the NVIDIA Wayland DMA-buf path. Check that flag is still present in config.org and test whether it's still effective.

---

### 3. Weight graph readability

The vault dashboard weight chart is slightly wider than the olivetti body, DPI is too high (chart appears small), no horizontal grid lines, legend and axes are hard to read.

Fix in `my/dash--insert-weight-chart` (the matplotlib call):
- `dpi=80` (was higher)
- `ax.yaxis.grid(True, alpha=0.3)`
- Increase `fontsize` on tick labels
- Move legend inside

---

### 4. Side panels: left margin + posframe helper refactor

The right-side posframe agenda panel works (`SPC a s`). Two things left:

**a) Extract `my/posframe-toggle` helper** — the open/close/state-flag pattern should be a single reusable function. Do this when implementing the left panel so both get cleaned up together:

```elisp
(defun my/posframe-toggle (buf-or-name state-var show-fn)
  "Toggle a posframe. STATE-VAR is a symbol tracking visibility.
SHOW-FN is called with no args to show the frame."
  (if (symbol-value state-var)
      (progn
        (when-let ((buf (get-buffer buf-or-name)))
          (posframe-hide buf))
        (set state-var nil))
    (funcall show-fn)
    (set state-var t)))
```

**b) Left panel** — most useful option is a narrow posframe showing the next 7 days' deadlines/scheduled items via `org-ql`. Position at `x=0`. Binding: `SPC a d`. Same posframe approach as the right panel; position formula is symmetric.

---

### 5. wuzapi 404 (WhatsApp)

`my/wuzapi-create-user` returns 404. Almost certainly a token mismatch.
Debug: `cat ~/.local/share/wuzapi/.env` and compare the admin token to `my/wuzapi-admin` in config.org.

---

## Current state

### Core

| Feature | Status | Notes |
|---------|--------|-------|
| Evil + evil-collection + evil-goggles | ✅ | SPC leader via general.el |
| Ukiyo theme | ✅ | `~/.config/emacs/themes/ukiyo-theme.el`; palette corrected 2026-07-05 |
| Font | ✅ | CMU Typewriter Text 16pt |
| Auto-revert (inotify) | ✅ | No polling; buffers sync with external file changes |
| Server/daemon | ✅ | Systemd user service; `emacsclient -c` connects in ~100ms |
| which-key | ✅ | 0.4s delay |
| Completion stack | ✅ | vertico + marginalia + orderless + consult + embark |
| Avy + projectile | ✅ | `C-;` for char jump |
| Jinx spell check | ✅ | en_UK + nl_NL |
| Backup/lockfiles disabled | ✅ | No scattered `~` files |

### Notes / writing

| Feature | Status | Notes |
|---------|--------|-------|
| Org-mode | ✅ | todo keywords, agenda, babel, folding |
| Org-roam | ✅ | root `~/org/`; dailies `~/org/daily/` |
| Org-gcal | ✅ | 10 calendars → `~/org/calendars/`; all use `tidemanus@gmail.com` token; auto-syncs every 10min |
| Org capture templates | ✅ | Personal (concept, essay, book, paper, person ×2) + uni (class, lecture, assignment) + inbox |
| Org-ql / org-transclusion / org-modern | ✅ | loaded and configured |
| Citar + org-roam-bibtex | ✅ | BibTeX at `~/org/library.bib` |
| Typst math preview | ✅ | `$...$` inline SVG overlay; `SPC t p` toggle; auto-renders on org/markdown buffer load |
| Markdown reading mode | ✅ | `SPC t r`: hides markup, read-only, `q` exit |
| Magit + diff-hl | ✅ | `SPC g g`; gutter indicators in prog-mode |
| Daily note template | ✅ | Schedule/ToDo/Inbox/Italian/Notes; `#+created` timestamp header |

### Media

| Feature | Status | Notes |
|---------|--------|-------|
| elfeed + elfeed-org + elfeed-tube | ✅ | 55 feeds (40 YouTube); `~/.config/emacs/elfeed.org` |
| YouTube view (`my/yt-view`) | ✅ | Single-column; thumbnail + title/channel/date; `RET` mpv, `o` browser, `u` refresh |
| mpv playback | ❌ | Opens windowless (audio only); `--gpu-api=opengl` fix may need reinstating |
| Music (mpdel) | ✅ | `SPC m m` browser + cover art; `SPC m s` slim side player; `SPC m SPC` play/pause |
| Email (mu4e) | ✅ | 4 accounts synced; `mu init` done; `~/Mail/` populated |
| Calendar | ✅ | `SPC aa` org-agenda; `SPC as` posframe day panel; `SPC aw` calfw week grid |
| PDF tools | ✅ | evil keybindings (hjkl, H/W fit, +/- zoom) |

### Dashboard system

| Component | Status | Notes |
|-----------|--------|-------|
| `my/dashboard` (greeting) | ✅ | Date/weather/fortune; khal events; timetable; birthdays/deadlines/mail/messages; weight logging |
| Weight chart (async PNG) | ⚠️ | Shows on vault dashboard; readability issues (see priorities) |
| `my/vault-dashboard` | ✅ | Birthdays, recent folders, projects, daily notes, knowledge counts |
| `my/uni-dashboard` | ✅ | Deadlines, assignments, courses, planning table (native org table) |
| `my/uni-course-view` | ✅ | Per-course summary, assignments, lectures |
| `my/news-view` | ✅ | One headline per country from elfeed; `u` refreshes |
| `my/yt-view` | ✅ | See media table above |
| Right-side agenda panel | ✅ | `SPC as` posframe; left panel empty (see priorities) |
| Left-side panel | ❌ | Not yet implemented (see priorities) |
| Auto-open on new frame | ✅ | `server-after-make-frame-hook` |

### Workspaces

| Perspective | Binding | Opens |
|-------------|---------|-------|
| personal | `TAB p` | `my/vault-dashboard` |
| uni | `TAB u` | `my/uni-dashboard` |
| emacs-conf | `TAB e` | ghostel (claude) left + config.org right |
| nixos-conf | `TAB n` | dired + ghostel (claude) + magit |

### WhatsApp (wuzapi)

| Step | Status |
|------|--------|
| wuzapi user service | ✅ port 8089 |
| `my/wuzapi-create-user` | ❌ 404 error (token mismatch — see priorities) |
| `my/wuzapi-connect` | ✅ renders QR PNG |
| WhatsApp QR scanned | ❌ not yet done |
| Wasabi (conversation UI) | ❌ not packaged yet |

---

## Backlog

Items not urgent but worth doing eventually. Ordered roughly by effort.

### UI polish (small effort, visible payoff)

**ligature.el** — JetBrains Mono ships ligatures; Emacs needs explicit activation. Add `ligature` to `home/emacs.nix`:
```elisp
(use-package ligature
  :config
  (ligature-set-ligatures 'prog-mode
    '("->" "=>" "!=" ">=" "<=" "//" "/*" "*/" "..." "--" "==" "||" "&&"))
  (global-ligature-mode t))
```

**nerd-icons** (`nerd-icons` + `nerd-icons-dired`) — file-type icons in dired and the mode line. One `M-x nerd-icons-install-fonts` after adding the package.

**indent-bars** — vertical indent guides in code and org. Lightweight.

**rainbow-delimiters** — color-coded bracket depth in elisp. Useful when editing config.org.

**Line numbers in org** — add `(add-hook 'org-mode-hook #'display-line-numbers-mode)`. Low cost.

**doom-modeline** — polished mode line; respects theme colours. Pulls in nerd-icons as soft dep (can disable icons). Worth trying:
```elisp
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 22)
  (doom-modeline-icon nil)
  (doom-modeline-buffer-file-name-style 'truncate-from-project))
```

**centaur-tabs** — tab bar scoped per perspective. Worth trying once doom-modeline is settled:
```elisp
(use-package centaur-tabs
  :demand t
  :custom
  (centaur-tabs-style "bar")
  (centaur-tabs-height 28)
  (centaur-tabs-set-icons nil)
  :config
  (centaur-tabs-mode t)
  (centaur-tabs-group-by-projectile-project))
```

**solaire-mode** — makes file buffers slightly lighter/darker than special buffers. May fight Stylix; test before committing.

---

### ESC / leader key escape

When a leader key (SPC, C-, M-) is pressed accidentally, Emacs waits for completion and ESC doesn't abort it cleanly — requires pressing ESC twice. This is an evil + which-key interaction. Investigate `(setq evil-escape-key-sequence ...)` or a `keyboard-quit` binding on single ESC in normal state.

---

### YouTube mpv inside Emacs

Currently `RET` in yt-view opens mpv as a separate OS window. Goal: open it in an Emacs side window. Options: ghostel (already installed), or a posframe showing an mpv embed. Longer project; requires understanding how ghostel handles mpv passthrough.

---

### mu4e quality of life

After `mu init` is done and mu4e is in daily use:
- `mu4e-contexts` for per-account switching (`SPC e c`)
- `h` binding in headers mode (back/prev-unread)
- HTML rendering via w3m
- Persistent sidebar per account
- Verify nouwens-lindemans.nl mbsync config (`ls ~/Mail/Lindemans/INBOX/`)

---

### Wasabi (WhatsApp conversation UI)

`codeberg.org/vifon/wasabi` — native Emacs buffer UI on top of wuzapi. Not in nixpkgs; needs a `trivialBuild` derivation in `home/emacs.nix`. Prerequisite: wuzapi 404 fixed + QR scanned.

---

### Music view in Emacs

A text-based MPD frontend similar to yt-view. The MPD backend (mpd + rmpc) stays unchanged. Desired: artist → album → tracks browser, playlists, inline cover art, random toggle. Two-column layout with `mpc` CLI calls. Roughly 200–300 lines; design as a separate session after smaller items are done.

---

### Key repeat rate

The perceived snappiness gap between Emacs and kitty/neovim is mostly the system keyboard repeat rate. KDE → System Settings → Input Devices → Keyboard → Delay / Rate.

---

### Graph views

The snowflake visualizers and dashboard graphs are slightly out of date. Currently static PNGs generated by a systemd timer. Improve matplotlib charts for readability (same direction as the weight chart fix).

---

### Inspirations to investigate

- **Vulpea** — adds obsidian-style features to org-roam (daily note metadata, tags, links). Worth reading the source for ideas.
- **Obsidian.el** — wikilink jumping and backlinks. Unclear what it adds if obsidian isn't used alongside; may be worth cherry-picking a function or two.
- **Nicholas Rougier's work** — consistently polished Emacs UIs; good source for layout and rendering ideas.
- **Lichess.el** — fun, no priority.

---

## Reference

### config.org conventions

**Tangle:** `org-babel-load-file` is called from `init.el`; saving config.org auto-retangles via `my/config-retangle` (after-save hook). Uses `org-babel-tangle-file` — blocks have no explicit `:tangle` header, so `org-babel-tangle` (no args) would tangle 0 blocks.

**Block structure:** Split large `#+begin_src` blocks into smaller sections with their own `**`/`***` subheadings — one coherent concern per block. Apply when editing a section, not as a separate pass. Naming pattern: `** Org-gcal`, `** Dashboard: greeting`, `** Side panels: agenda`.

**Reload without restart:** `SPC q r` calls `my/reload-config` which runs `org-babel-load-file`. Saves a daemon restart for most config changes.

---

### Gotchas

- `(setq evil-want-keybinding nil)` must be in `:init`, before evil-collection loads — not in `:config`.
- Unbind SPC from `evil-motion-state` **after** `(evil-mode 1)` in `:config`, not before.
- Never byte-compile config.el — `general-create-definer` macros resolve at runtime.
- `xdg.configFile."emacs/init.el".source = ...` in Nix bypasses Stylix's theme injection; use a standalone `ukiyo-theme.el` instead.
- `(setq org-roam-directory ...)` must come **before** the `use-package org-roam` form.
- Use **named functions** (not anonymous lambdas) on hooks that fire at startup (`after-make-frame-functions`, etc.) — anonymous lambdas accumulate on hot-reload and run multiple times.
- `elfeed-org`: call `(rmh-elfeed-org-process rmh-elfeed-org-files rmh-elfeed-org-tree-id)` directly — `(elfeed-org)` only installs a hook and does not populate the feed list immediately.
- `posframe-visible-p` does not exist in the installed version — use a `defvar` boolean to track panel state.
- org-gcal group calendars: advise `org-gcal--get-access-token` to always use `tidemanus@gmail.com`; oauth2-auto otherwise treats each calendar ID as a separate user requiring its own OAuth flow.
- If org-gcal fetches 0 events after re-auth, check for a stale sync token: `M-x org-gcal-sync-tokens-clear` then `M-x org-gcal--sync-unlock`.
- calfw uses the `calfw-` function prefix, not the older `cfw:` prefix.
- `general-auto-unbind-keys` is needed when promoting a leaf keybinding to a prefix group — add it to the `use-package general :config` block.
- Always verify paren balance in config.el after editing config.org — a missing `)` can silently nest all subsequent defuns inside the broken form.

---

### Hardware

```
card2 = Nvidia GTX 1060  Driver: legacy_535
KWIN_DRM_DEVICES fix is in hosts/desktop/default.nix — do NOT edit that file
Monitors at 100% scaling → Cairo/PGTK performance acceptable
```

---

## Log (session notes)

Old session notes for reference. Not needed for normal work.

### 2026-07-07

- **org-gcal group calendars**: oauth2-auto treated each calendar ID as a separate OAuth user. Fixed by advising `org-gcal--get-access-token` to route all through `tidemanus@gmail.com`. Stale sync token (June 26) cleared; `work.org` now has 3 events.
- **Posframe toggle**: `posframe-visible-p` void in installed version. Replaced with `defvar my/agenda-panel-visible`.
- **calfw colours**: replaced 15 hardcoded hex values with `:inherit` from `font-lock-*`, `org-level-1`, `hl-line`, `mode-line`.

### 2026-07-06

- **elfeed always empty**: `(elfeed-org)` only installs a hook; call `rmh-elfeed-org-process` directly.
- **news-view paren imbalance**: 4 closing parens instead of 3 after `switch-to-buffer`; caused everything after `my/news-view` to be silently swallowed.
- uni dashboard: olivetti 200, planning table converted to native org table.

### 2026-07-05

- Retangle fixed: `org-babel-tangle-file` not `org-babel-tangle`.
- Font shrinking on save: was stale config.el from broken retangle.
- Named `my/setup-frame` function replaces anonymous lambda (avoids accumulation).
- Ukiyo palette corrected: base08/0B/0C were wrong (red/green/teal instead of orange/salmon/gold).
- elfeed timer moved to `elfeed-org :config` with 5s delay.
- Shorts thumbnail fix: `my/yt--id` regex extended for `/shorts/` URLs.
