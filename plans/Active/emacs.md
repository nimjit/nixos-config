# Emacs — config plan

*Last updated: 2026-07-08 (migration complete)*
*Config lives at `~/.config/emacs/config.org` (edit directly; saved → auto-retangles to `config.el`).*
*Nix packages: `home/emacs.nix`. Rebuild only when adding/removing packages.*

---

## Priorities

Ordered. Do these before anything else.

### 1. org/ migration — config changes still needed

**File conversion complete (2026-07-08).** Files are done. The remaining work is updating the Emacs config to use org files instead of markdown. This section documents exactly what needs to change.

---

#### What was done (2026-07-08)

- **Personal dailies**: all 80 converted. The 10 June–July 2026 files were missing; custom Python converter (no pandoc, handles YAML/H1 variation, strips HTML comments, fixes markdown horizontal rules).
- **Uni daily notes**: deleted (4 files, all empty).
- **Lecture notes**: re-converted all 77 from source with `pandoc -f markdown+wikilinks_title_after_pipe`. Links now properly resolved to `[[file:~/org/uni/...]]`. Cross-file: assignments, summaries, concepts, classes. Internal `[[#Section]]` → `[[*Section Name]]`. Math preserved as `$...$`.
- **Class files**: fully rewritten with `my-ql` dynamic blocks for lectures and assignments, dired links for project files, `SPC n r c` capture prompt.
- **Lecture capture template**: fixed path (`uni/lecture/`), fixed to use PROPERTIES drawers (`:CLASS:`, `:DATE:`, `:LECTURE_NUMBER:`) not `#+class:` keywords.
- **`org-update-all-dblocks` hook**: added to org-ql config block — class files now auto-render their lecture/assignment tables on open.
- **`org-dblock-write:my-ql`**: custom dynamic block writer in config.org. Extends `#+BEGIN: org-ql` with `:files` parameter for cross-file queries.

---

#### Config changes still needed (uni dashboard)

The uni dashboard functions still read from the **markdown vault** (`my/dash-uni` = `~/Documents/BACKUP/Uni/Obsidian/Uni/`). They need to be updated to read from `~/org/uni/`.

The core issue: `my/dash--fm-from-file` reads YAML frontmatter. Org files have PROPERTIES drawers. A new helper is needed first:

```elisp
(defun my/dash--prop-from-file (file prop)
  "Read PROP from the PROPERTIES drawer of FILE (first 2000 bytes)."
  (with-temp-buffer
    (insert-file-contents file nil 0 2000)
    (goto-char (point-min))
    (when (search-forward ":PROPERTIES:" nil t)
      (let ((end (save-excursion (search-forward ":END:" nil t) (point))))
        (goto-char (point-min))
        (when (re-search-forward
               (concat "^:" (upcase (regexp-quote prop)) ":[ \t]+\\(.+\\)$")
               end t)
          (string-trim (match-string 1)))))))
```

**Functions to update:**

1. **`my/dash--uni-courses`** — scan `~/org/uni/classes/*.org`, read `:Q:`, `:CODE:`, `:SHORTHAND:`, `:YEAR:` from PROPERTIES drawers.

2. **`my/dash--uni-assignments`** — scan `~/org/uni/assignments/*.org`, read `:CLASS:`, `:DEADLINE:`, `:GRADE:` from PROPERTIES drawers. Filter: `:GRADE:` empty.

3. **`my/dash--uni-deadlines`** — currently reads from `UNI/Deadines/` (note the typo — "Deadines"). Replace with org-ql query on `~/org/uni/assignments/`:
   ```elisp
   (org-ql-select (directory-files (expand-file-name "uni/assignments/" org-roam-directory)
                                    t "\\.org$")
     '(and (not (property "GRADE")) ...)
   ```
   Or simply reuse `my/dash--uni-assignments` and filter for upcoming deadlines.

4. **`my/uni-course-view`** — replace all `lec-dir` / `.md` reads with `~/org/uni/lecture/*.org` using `my/dash--prop-from-file`. The `:CLASS:` PROPERTIES value in lecture files now matches the query values. Summary path changes from `.md` to `.org`.

5. **`my/uni-dashboard-org`** — currently a stub ("implement as org migration proceeds"). Once functions above are updated, this should call the same layout as `my/uni-dashboard`, using the new functions.

**Ordering**: implement `my/dash--prop-from-file` → update `my/dash--uni-courses` → `my/dash--uni-assignments` → `my/dash--uni-deadlines` → `my/uni-course-view` → update `my/uni-dashboard` to call `my/uni-dashboard-org`.

---

#### Personal vault — on hold

`Knowledge/`, `Concepts/`, `Essays/`, `Sources/` in `~/org/` are skeleton or have stripped wikilinks. Do not migrate until the dashboards (`my/vault-dashboard`) are updated to query PROPERTIES drawers instead of YAML frontmatter — `birthday:`, `tags:`, `date:` are currently read from frontmatter by `my/dash--fm-from-file`.

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
