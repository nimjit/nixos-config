# Emacs — Current State

*Last updated: 2026-06-29*

---

## History

A previous AI-generated config was built with evil, doom-style leader bindings,
org-roam, magit, and a full package set. It was opaque — I didn't understand what
any of it did. At 4K resolution (200% scaling) it was also slow because Cairo CPU
rasterization in emacs-pgtk can't GPU-accelerate at that scale. Both issues together
led to never using it.

That config is no longer in the repo. At 100% scaling the performance bottleneck
disappears (Cairo scales linearly with pixel count, not screen size). The new
approach: build incrementally, understand each piece before adding the next.

The key gotchas from the old config that still apply:
- `(setq evil-want-keybinding nil)` must be in `:init`, before evil-collection loads
- Unbind SPC from evil-motion-state AFTER `(evil-mode 1)` in `:config`
- Never byte-compile config.el — `general-create-definer` macros resolve at runtime
- `xdg.configFile."emacs/init.el".source = ...` bypasses Stylix; use standalone `ukiyo-theme.el`
- If adding org-roam later: `(setq org-roam-directory ...)` must come BEFORE the `use-package` form
- `org-typst-preview--render` had a missing `)` that nested all subsequent defuns inside it — fixed 2026-06-29. Always check config.el paren balance directly, not config.org src blocks.

---

## What is built and working

### Core

| Feature | Status | Notes |
|---------|--------|-------|
| Evil + evil-collection + evil-goggles | ✅ | SPC leader via general.el |
| Ukiyo theme | ✅ | From `~/.config/emacs/themes/ukiyo-theme.el` |
| Font | ✅ | CMU Typewriter Text 14 |
| Auto-revert (inotify) | ✅ | No polling; buffers sync with external changes instantly |
| Server/daemon | ✅ | Systemd user service; `emacsclient -c` connects in ~100ms |
| which-key | ✅ | 0.4s delay |
| Backup/lockfiles | ✅ | `make-backup-files nil`, `create-lockfiles nil` — no scattered files |
| Completion stack | ✅ | vertico + marginalia + orderless + consult + embark |
| Avy + projectile | ✅ | `C-;` for char jump |
| Jinx spell check | ✅ | en_UK + nl_NL via enchant2/hunspell |
| Dired | ✅ | Reasonable defaults set |
| recentf | ✅ | 200 items |

### Writing / Notes

| Feature | Status | Notes |
|---------|--------|-------|
| Org-mode | ✅ | Full config: todo keywords, agenda, babel, folding |
| Org-roam | ✅ | `~/org/` root; dailies in `~/org/daily/` |
| Org-roam-ui | ✅ | Graph view via `SPC n g` |
| Org-ql | ✅ | Loaded; used for deadline queries |
| Org-gcal | ✅ | 10 Google calendars syncing to `~/org/calendars/`; auto-syncs every 10min |
| Org capture templates | ✅ | Personal (concept, essay, book, paper, person ×2) + uni (class, lecture, assignment) + inbox |
| Org-modern | ✅ | Custom stars, modern tag/table rendering |
| Org-transclusion | ✅ | `SPC t t` toggle; used for lecture→summary workflow |
| Citar + org-roam-bibtex | ✅ | BibTeX at `~/org/library.bib`; fuzzy search |
| Typst math preview | ✅ | `$...$` renders as inline SVG overlay; `SPC t p` toggle mode |
| Markdown reading mode | ✅ | `SPC t r` in markdown: hides markup, read-only, `q` to exit |
| Magit + diff-hl | ✅ | `SPC g g` for status; gutter indicators in prog-mode |

### Media / External tools

| Feature | Status | Notes |
|---------|--------|-------|
| elfeed + elfeed-org + elfeed-tube | ✅ configured | Feeds in `~/.config/emacs/elfeed.org`; YouTube UULF URLs included. **Runtime status unknown** — needs `M-x elfeed-update` test |
| Music (mpdel) | ✅ | Artists → Albums → Tracks; `SPC m m` browser, `SPC m SPC` play/pause |
| Email (mu4e) | ✅ configured | Reads `~/Mail/`; msmtp send; 3 accounts; evil keybindings. **Needs `mu init` + `mu index` first time** |
| Calendar | ✅ | `SPC a` → org-agenda (org-gcal keeps it synced) |
| PDF tools | ✅ | `pdf-tools-install`; evil keybindings (hjkl, H/W fit, +/- zoom) |

### Dashboard system

All implemented in the `* Dashboard` section of config.org.

| Component | Status | Notes |
|-----------|--------|-------|
| `my/dashboard` (greeting) | ✅ | Date/weather/fortune header; today/tomorrow khal events; timetable 09–22; birthdays/deadlines/todo/mail/messages right column; footer with all shortcuts |
| Olivetti centering | ✅ | 140 char body width |
| Evil keybindings (greeting) | ✅ | Set after `switch-to-buffer` to avoid evil reinit clobber |
| Weight chart (async PNG) | X | `my/dash--insert-weight-chart`; runs plot-weights async, inserts at end, but not shown |
| Weight logging | ✅ | `my/dash-log-weight` (`w`); computes 7/21/30 day moving averages |
| Birthday reader | ✅ | Parses People/ YAML frontmatter; YYYY-MM-DD and DD-MM-YYYY |
| Mail count | ✅ | Scans `~/Mail/*/INBOX/new/`; shows sender names |
| Messages count | ✅ | Reads `/tmp/nchat-unread` |
| `my/vault-dashboard` | ✅ | Birthdays, recent folders, projects, daily notes, knowledge dir counts; org-mode rendering with clickable links |
| `my/uni-dashboard` | ✅ | Deadlines, assignments, courses, planning table; org-mode rendering |
| `my/uni-course-view` | ✅ | Summary, assignments, lectures per course |
| `my/news-view` | X | One headline per country from elfeed; 16 countries; org-mode, news update not working yet |
| `my/render-md-table` | X | Box-drawing table renderer with optional max-width shrink, Table is wider than the window, window should be made wider. |
| Planning table | ✅ | Reads `# Planning` from Uni MOC.md; renders as box-drawing via `my/render-md-table` |
| `my/uni-new-lecture` | ✅ | Creates from template or default YAML |
| Auto-open on client frame | ✅ | `server-after-make-frame-hook` opens dashboard in new client |

### Workspaces

| Perspective | Status | Notes |
|-------------|--------|-------|
| personal | ✅ | `TAB p` → switches to "personal" + opens `my/vault-dashboard` |
| uni | ✅ | `TAB u` → switches to "uni" + opens `my/uni-dashboard` |
| emacs-conf | ✅ | `TAB e` → vterm (claude) left + config.org right |
| nixos-conf | ✅ | `TAB n` → dired + vterm (claude) + magit |

### WhatsApp (wuzapi)

wuzapi runs as a user systemd service (`home/wuzapi.nix`). Emacs has the setup flow:

| Step | Status | Notes |
|------|--------|-------|
| wuzapi user service | ✅ | Port 8089; data at `~/.local/share/wuzapi/`; `.env` auto-loaded |
| `my/wuzapi-create-user` | X | `M-x my/wuzapi-create-user` — run once; saves token to `my/wuzapi-token`, gives 404 Error. |
| `my/wuzapi-connect` | ✅ | `M-x my/wuzapi-connect` — renders QR PNG via `find-file` |
| `my/dash-messages` | ✅ | `m` in dashboard: calls create-user if no token, else connect |
| WhatsApp linked | ❌ | QR scan not done yet. Run setup flow (see below). |

---

## First-time setup still needed

These are one-time commands, not config changes.

### 1. mu4e — `mu init` + `mu index`

```bash
mu init --maildir=~/Mail \
        --my-address=tidemanus@gmail.com \
        --my-address=thijmen.nouwens@gmail.com \
        --my-address=thijmen@nouwens-lindemans.nl
mu index
```

After that, `M-x mu4e` should open to inbox. mbsync already runs on a 5-minute timer so subsequent syncs are automatic.

### 2. wuzapi — QR scan

```
M-x my/wuzapi-create-user    ; creates user, saves token (run once)
M-x my/wuzapi-connect        ; fetches QR code PNG, opens it in Emacs
```

Scan the QR code in WhatsApp → Linked Devices. Session persists in `~/.local/share/wuzapi/`.

### 3. elfeed — verify feeds load

```
M-x elfeed          ; open elfeed
R                   ; trigger update
```

If the list stays empty after a minute: check `*Messages*` for elfeed-org errors.
The expected path is `~/.config/emacs/elfeed.org`; check `rmh-elfeed-org-files` with `C-h v`.

elfeed-update did nothing, and nothing was printed to *Messages*

---

## What's still missing or deferred

### Wasabi (WhatsApp Emacs client)

`codeberg.org/vifon/wasabi` is a native Emacs WhatsApp frontend that sits on top of
wuzapi. Not in nixpkgs. Packaging it requires a `trivialBuild` derivation. The current
wuzapi functions (`my/wuzapi-create-user`, `my/wuzapi-connect`) are a minimal bridge
for initial setup only — they don't provide a conversation view.

When ready to pursue: research the repo coords, write `home/wuzapi.nix` with a
`trivialBuild` for wasabi, add a `use-package wasabi` block to config.org with evil
keybindings.

### org vault (`~/org/`)

The config has full org-roam, org-ql, org-gcal, and capture templates wired up, but
`~/org/` is mostly empty.

Currently the markdown vault is still used, but the ~/org/ directory is a possible future direction.

### nouwens.org email

The third email account (`thijmen@nouwens-lindemans.nl`) is declared in mu4e's
`mu4e-user-mail-address-list` but the actual mbsync sync for it needs verification
(`ls ~/Mail/Lindemans/INBOX/`). Check `home/email.nix` for the mbsync config.

### Email quality of life

mu4e is configured but not yet used daily — no muscle memory. Gaps to address when
it becomes a friction point:
- `h` key in headers mode (currently unbound — should go back or prev-unread)
- `gg` / first-message binding (omitted to avoid mapping complexity)
- HTML rendering via w3m — test with real messages

---

## Hardware note

```
card2 = Nvidia GTX 1060, PCI:1:0:0
Driver: legacy_535
KWIN_DRM_DEVICES fix is in hosts/desktop/default.nix — do NOT change
```

Monitors at 100% scaling → performance acceptable for Cairo/PGTK.

---

## Known annoyances


### 1. elfeed feeds automatic settings are quite difficult to parse

Currently (after fixing elfeed), I just see a large list of entries.
Nothing to identify them. 
I would like the youtube specific feed to work kind of like the youtube terminal function, but instead in a GUI.
That should make it better than the terminal version.


