# Emacs — config plan

*Last updated: 2026-07-08*
*Config lives at `~/.config/emacs/config.org` (edit directly; saved → auto-retangles to `config.el`).*
*Nix packages: `home/emacs.nix`. Rebuild only when adding/removing packages.*

---

## Priorities

Ordered. Do these before anything else.

### 1. org/ migration

**Survey done 2026-07-08.** Most files are already converted. Work remaining is: 10 missing personal dailies, 3 missing assignments, wikilink repair across all lecture/class files, dataview → org-ql replacement in class/MOC files, and the "new lecture" capture workflow.

---

#### Current conversion state

**Personal daily notes** (`~/org/daily/`)
- Source: 80 files in `Dailies/`
- Converted: 70 files — all ≥ 2025 except last 10 (June–July 2026)
- **Missing** (need pandoc conversion):
  `2026-06-08`, `2026-06-10`, `2026-06-11`, `2026-06-12`, `2026-06-13`, `2026-06-14`, `2026-06-24`, `2026-06-25`, `2026-06-29`, `2026-07-06`
- Source format: `# YYYY-MM-DD`, then `## Schedule / ## ToDo / ## Inbox / ## Italian / ## Notes`. Simple markdown, no dataview in modern notes.
- **Template already set** in org-roam config (Schedule / ToDo / Inbox / Italian / Notes + `#+created` header) — matches source format exactly.

**Uni daily notes** (`~/org/uni/daily/`)
- 4 source files (2026 only), 4 converted — **complete**.

**Uni lecture notes** (`~/org/uni/lecture/`)
- Source: 77 files. Converted: 83 (6 extra including one `~` backup). All 77 source files are converted.
- **Quality issue: wikilinks stripped.** `[[../Assignments/Advanced QM Presentation|here]]` → bare text `here`. 0 org links exist where there were 16 wikilinks. Needs repair: convert to `[[file:~/org/uni/assignments/Advanced Quantum Mechanics Presentation.org][here]]`.
- Math ($..$ Typst notation) is preserved correctly — typst-preview handles it.
- filetags are garbled (topic names split on spaces incorrectly from `[[#Topic Name]]` links). Lower priority — filetags aren't essential for use.
- All 12 courses represented: Advanced QM (12), Applications QM (5), C++ (7), Complex Analysis (14), Computational Physics (6), Continuum Physics (1), Engineering/Ethics (5), Fundamentals QI (9), Interpretation QM (2), Mesoscopic Physics (1), PDE (1), Quantum Computer Architecture (10).

**Uni class files** (`~/org/uni/classes/`)
- 12 source, 12 converted — **complete**.
- **Quality issues**: dataview blocks replaced with placeholder `* [org-ql query goes here]` — not real queries. Need real org-ql blocks (see dataview section below). Wikilinks stripped (summary links missing).
- "ctrl+n → Lecture" prompt text is preserved but points to Obsidian. Replace with reference to `SPC n r c` (org-roam capture).

**Uni assignments** (`~/org/uni/assignments/`)
- 22 source, 19 converted.
- **Missing**: `Computational Physics project 1`, `project 2`, `project 3` — actual physics homework with heavy math. Need pandoc conversion.

**Uni summary, thesis, concepts** — all complete (6/6, 3/3, 17/17).

**Uni MOC** (`~/org/uni/Uni MOC.org`) — converted; planning table is a native org table (good). Dataview blocks replaced with placeholders.

---

#### Dataview → org-ql replacement

The converted files have `* [org-ql query goes here]` placeholders. Each needs a real replacement:

**1. Lecture list per class** (in each `classes/*.org` file):
```org
#+BEGIN: org-ql-block :query (and (property "CLASS" "Advanced Quantum Mechanics") (org-roam-file-p)) :columns (file lecture_number date)
#+END:
```
Or simpler: a `dired` link to `~/org/uni/lecture/` filtered by name is enough for now.

**2. Assignment list per class** (in each `classes/*.org` file):
```org
#+BEGIN: org-ql-block :query (and (property "CLASS" "Advanced Quantum Mechanics") (deadline))
#+END:
```

**3. All-classes table** (Uni MOC):
```org
#+BEGIN: org-ql-block :query (tags "class") :super-groups ((:auto-property "YEAR"))
#+END:
```

**4. Active deadlines** (Uni MOC):
```org
#+BEGIN: org-ql-block :query (and (deadline :to +60d) (not (done)))
#+END:
```

**5. Old Obsidian Tasks blocks** (`#+begin_src tasks`) in a few converted daily notes (2024–2025 era). These reference the previous day's incomplete tasks. No clean org-ql equivalent for "yesterday's tasks." Options:
- Delete them (historical notes; the tasks are done or abandoned).
- Replace with a static `* Carry-over` section if needed.
- Ignore — they render as an opaque code block in org and cause no harm.

**6. dataviewjs file tree** (classes): reads `~/Documents/BACKUP/Uni/Master/<ClassName>/` and builds a file tree. Replacement: a plain `dired` link:
```org
[[file:~/Documents/BACKUP/Uni/Master/Advanced Quantum Mechanics/][Project files]]
```

---

#### "Press n for new lecture/assignment" → org-roam capture

The class files say: *"Type ctrl+n → Lecture → [Class name] for a new lecture."*

In Emacs, the capture templates under `SPC n r c` already handle this (uni: class, lecture, assignment templates). The class-file prompt text should be replaced with the org-roam instruction, e.g.:

```org
/Use =SPC n r c= then =l= (lecture) to add a new lecture for this class./
```

The capture template should auto-fill the CLASS property from the current file. Verify that the lecture capture template prompts for class name and sets `:CLASS:` in PROPERTIES.

---

#### What's NOT done yet (personal vault)

Personal `Knowledge/`, `Concepts/`, `Essays/`, `Sources/` are in `~/org/` but largely skeleton or converted without wikilinks. **Hold on these** until wikilinks are sorted out:

- Wikilinks (`[[Note Name]]` → `[[file:~/org/path/to/Note Name.org][Note Name]]`) need either pandoc with the `--from markdown+wikilinks` flag + a post-processing script to fix paths, or a dedicated Emacs function using org-roam's database.
- YAML frontmatter is converted to PROPERTIES drawer — this is correct for org-roam, but dashboards (`my/vault-dashboard`, `my/uni-dashboard`) that currently query frontmatter need to be updated to query PROPERTIES instead.
- Personal vault frontmatter includes things like `tags:`, `date:`, `birthday:` that are used by the dashboard elisp. Do not migrate personal vault until the dashboards are adapted.

---

#### Immediate next actions

1. **Pandoc-convert the 10 missing personal dailies.** Simple: no dataview, no wikilinks. Command:
   ```bash
   for f in 2026-06-08 2026-06-10 2026-06-11 2026-06-12 2026-06-13 2026-06-14 2026-06-24 2026-06-25 2026-06-29 2026-07-06; do
     pandoc -f markdown -t org \
       ~/Documents/BACKUP/.../Dailies/$f.md \
       -o ~/org/daily/$f.org
     # prepend #+title: and #+filetags: :daily:
   done
   ```

2. **Pandoc-convert the 3 missing Computational Physics assignments.** Math-heavy but no dataview.

3. **Repair wikilinks in lecture notes.** Either a post-pandoc sed/python script, or an Emacs function using org-roam's DB to resolve note names to file paths. Decide on approach before converting more.

4. **Replace org-ql placeholders in class files.** Do this after deciding on the query syntax (test one class first).

5. **Update lecture capture template** to prompt for class name and set `:CLASS:` property automatically.

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
