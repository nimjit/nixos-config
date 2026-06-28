# Emacs — Fresh Start

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

---

## Starting purpose

One concrete task: **lecture notes during class**.
Markdown files, one per lecture, opened directly. No dashboard yet.
Get comfortable with the editor first, then add to support actual pain points.

---

## Phase 0 — Minimal working config

Goals: open emacs, move around, edit markdown, not be confused.

1. **Evil mode** — vim keybindings
2. **which-key** — shows available keys after a prefix
3. **Theme** — ukiyo-theme.el (dark, warm palette)
4. **Line numbers** in code files, not prose
5. **No startup screen**

---

## Phase 1 — Markdown workflow

Once phase 0 feels natural:

- `markdown-mode` — header folding, syntax highlighting
- A keybinding to open the notes directory
- Spell check via `jinx` (enchant backend, already in packages: `enchant_2` + hunspell dicts)

---

## Phase 2 — Add one more thing (decide when phase 1 is solid)

Candidates — not commitments:

- **Dired** — file browsing; may be enough without a sidebar
- **Magit** — if git from emacs feels useful
- **PDF tools** — if reading PDFs alongside notes
- **org-mode** — if markdown starts feeling limiting long-term

---

---

## Current state (as of 2026-06-28)

The config is now fairly large — evil, completion stack, org-roam, org-gcal (10 calendars),
elfeed + elfeed-org + elfeed-tube, EMMS, pdf-tools, magit, jinx, and a dashboard. The
dashboard mirrors the zsh greeting in structure (weather, clock, khal output, mail count,
vault todos, footer shortcuts).

### What works
- Evil + leader bindings (SPC)
- Org-roam, org-gcal (syncs 10 calendars; credentials loaded silently from ~/.authinfo)
- elfeed + elfeed-org (feed list in elfeed.org, includes all yt-feed channels via UULF URLs)
- magit, pdf-tools, jinx

### Known gaps / broken things

**EMMS** — functional but the interface feels alien. It doesn't map cleanly to the
rmpc mental model (library browse → queue → play). The `emms-smart-browse` view is
disorienting compared to a simple TUI list. Not yet comfortable to use daily.
Options when returning to this: try `emms-browser` directly, or investigate whether
there's an MPD client package that talks to the running MPD daemon instead.

**Email** — `my/dash-email` currently opens neomutt in an `ansi-term` buffer. That
works but it's not an Emacs-native approach. The intended future state is `mu4e` or
`notmuch` (mu4e is more common, notmuch is more search-oriented). Neither is configured
yet. Defer until the terminal approach becomes a real friction point.

**Messages (WhatsApp)** — `my/dash-messages` tries to attach to an nchat dtach session.
Not working yet. The Emacs-native path is **Wasabi**: a native Emacs WhatsApp client
that bridges to WhatsApp via **wuzapi**, a Go-based JSON-RPC background daemon built
on whatsmeow (same library as nchat). Individual and group chats, no official API
needed. Architecture: wuzapi runs as a background service; Wasabi talks to it from
Emacs. Worth setting up properly rather than the nchat-in-ansi-term workaround.

---

## Terminal → Emacs translation gap

What the neovim+terminal setup does that Emacs doesn't yet do as well, or at all.

### Dashboards (biggest gap)

The neovim personal and uni dashboards are Lua programs that run at buffer-open time:
they call `khal list`, read markdown YAML frontmatter, compute deadlines, and render
everything inline without any user action. The result is a live, read-only status
view that opens instantly with `vault-work` or `uni-work`.

The current Emacs dashboard does the same in principle — `my/dashboard` runs shell
commands via `shell-command-to-string` and renders into a buffer — but several
specific features from the neovim version aren't wired up yet:

- **Birthdays** — the neovim vault dashboard reads People/ note frontmatter for
  birthday fields and highlights upcoming ones. The Emacs dashboard doesn't do this.
  Would need a shell script or elisp to parse the markdown files, or migration of
  People/ notes to org with a `:BIRTHDAY:` property (then org-agenda can surface them).

- **Deadline parsing from markdown** — the uni dashboard reads YAML frontmatter
  (`deadline:` field) from assignment notes and renders a sorted list. In Emacs this
  only works for org files (via org-ql or org-agenda). If the uni vault stays in
  markdown, a custom parser would be needed.

- **The `~/org/` variant** — the alternative dashboard block (`:tangle no`) uses
  org-ql for deadline queries, which is correct for an org-native workflow. But the
  actual vault is markdown, so this path isn't active yet. It becomes relevant if/when
  notes migrate to org.

### Music

`rmpc` is a clean modal TUI: browse artists → albums → tracks, add to queue, play.
EMMS in Emacs has the same capabilities but the interface is unfamiliar. The keybindings
don't follow the established `hjkl` navigation convention. This will probably improve
with familiarity, but it's currently a regression from the terminal setup.

### YouTube feed

`yt-feed` shows thumbnails (via kitty icat), channel avatars, and video cards in a
purpose-built layout. elfeed + elfeed-tube are configured but **not yet working** —
the feeds load but elfeed-tube integration isn't rendering correctly. The RSS data
(all yt-feed channels via UULF URLs) is in elfeed.org and correct; the issue is in
the elfeed-tube setup. Needs a debugging pass.

When it works: elfeed will be text-only (no thumbnails, no card layout), which is a
visual regression from yt-feed. `elfeed-tube` can at least fetch video descriptions
inline. Whether that's good enough is an open question.

### Email

neomutt is barely used — no muscle memory built up. Switching to `mu4e` or `notmuch`
inside Emacs is therefore low-cost. `mu4e` is the more common choice and integrates
with org-agenda for flagged messages. Worth trying during the summer Emacs push
rather than deferring indefinitely.

### What translates well (for reference)

- **Org-roam** — better than the neovim wiki plugin, the graph is richer
- **magit** — strictly better than running git commands in a split terminal
- **org-agenda** — once all deadlines are in org files, better than the neovim deadline list
- **elfeed** — the feed reading experience is good; keyboard-driven, filterable
- **pdf-tools** — works well for papers; annotations are native
- **jinx** — spell check is seamless; better than the neovim workaround

---

## Known annoyances — causes and fixes

These are quality-of-life issues that come up in daily use. They're all solvable
with small, well-understood config changes.

---

### 1. Input error on close / restart

**What happens:** Closing Emacs or running `restart-emacs` prints an error like
`"Error in process sentinel"` or `"Error running timer"` or an X input-related
warning. Sometimes the window freezes briefly before closing.

**Likely causes:**
- `desktop-save-mode` is running a save hook during shutdown that races against
  the window being unmapped. The hook tries to write state after Emacs has already
  started tearing down the display connection.
- Some package's `kill-emacs-hook` raises a non-fatal error (e.g., a sentinel
  waiting on a process that's already dead, or the `make-process` calls from
  `my/dash--insert-weight-chart` not being cleaned up).
- Less likely: an X grab or modifier key state issue from evil-mode on the last
  keypress before quit.

**Fix:**

First, get the exact error: run `M-x toggle-debug-on-error`, then close with
`M-x save-buffers-kill-emacs`. The backtrace will appear in `*Messages*` or a
`*Backtrace*` buffer before the window closes — redirect it with:
```elisp
(add-hook 'kill-emacs-hook
          (lambda () (with-current-buffer (get-buffer-create "*kill-log*")
                       (insert (format-time-string "%T ") "kill-emacs\n"))))
```
Or run `emacs 2>/tmp/emacs-err.log` from a terminal and check the log after closing.

Once the error is identified, the fix is usually one of:
- Add `:after-kill t` or a guard to the offending hook
- Move desktop-save earlier: `(add-hook 'kill-emacs-hook #'desktop-save-in-desktop-dir -90)`
  so it runs before other hooks unmount things
- Wrap the problematic hook body in `(ignore-errors ...)`

In the server/client setup (see §4 below), this partially resolves itself —
`emacsclient` frames close silently and the server only shuts down on explicit
`kill-emacs`, reducing the surface area.

---

### 2. Buffer and directory changes not reflected automatically

**What happens:** If a file is modified outside Emacs (e.g., mbsync writes a new
mail file, mu updates the database, a git operation modifies a tracked file), the
Emacs buffer still shows the old content. Dired buffers similarly don't update when
files are created or deleted.

**Cause:** Emacs does not watch the filesystem by default. Buffers hold a snapshot
of the file at open time. `auto-revert-mode` can be enabled per-buffer, or globally.

**Fix:** Add to config.org `* Core Settings`:

```elisp
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)   ; also update dired and special buffers
(setq auto-revert-verbose nil)                  ; no "Reverting buffer" messages
```

`global-auto-revert-non-file-buffers t` covers dired (folder listings update when
files appear or disappear), mu4e header lists, and other special buffers.

By default, auto-revert polls every 5 seconds. On Linux, Emacs can use inotify
instead (no polling, instant, cheaper):
```elisp
(setq auto-revert-use-notify t)
```
This is the default on recent Emacs builds but worth making explicit. If `inotify`
isn't available for some buffer type, it falls back to polling.

**Note on mu4e specifically:** mu4e has its own update mechanism (`mu4e-update-interval`
is already set to 300s in the config). File-level auto-revert won't help with the mu4e
headers view — that requires `mu index` to run and mu4e to call `mu4e-headers-revert`.
The existing mbsync + mu systemd integration should handle this automatically.

---

### 3. Backup files scattered in wrong directories

**What happens:** Emacs creates `filename~` (backup) and `#filename#` (auto-save)
files in the same directory as the file being edited. These appear in dired, confuse
git status, and pollute the vault and notes directories.

**Cause:** Default Emacs behavior — backups go next to the original file unless
configured otherwise.

**Fix:** Add to config.org `* Core Settings`:

```elisp
(let ((backup-dir  (expand-file-name "backups/"   user-emacs-directory))
      (autosave-dir (expand-file-name "auto-saves/" user-emacs-directory)))
  (dolist (dir (list backup-dir autosave-dir))
    (unless (file-exists-p dir) (make-directory dir t)))
  (setq backup-directory-alist         `(("." . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,autosave-dir t))
        backup-by-copying              t    ; don't break hard links
        delete-old-versions            t
        kept-new-versions              6
        kept-old-versions              2
        version-control                t))  ; numbered backups
```

This centralises everything in `~/.config/emacs/backups/` and `~/.config/emacs/auto-saves/`.
Neither directory ends up in the git repo (they're not in `/etc/nixos/`). The
`backup-by-copying t` avoids breaking symlinks in the Nix store.

Also suppress the lock files (`.#filename` symlinks that appear when a file is open):
```elisp
(setq create-lockfiles nil)
```
Lock files exist to warn other processes that a file is being edited. On a single-user
machine they're mostly noise, especially when the vault and notes dirs are synced by
Syncthing (Syncthing sees `.#filename` as a new file to sync).

---

### 4. White screen on startup (server/client approach)

**What happens:** Opening Emacs shows a blank white frame for 1–3 seconds while the
config tangles and loads. This is the most visible performance annoyance on this machine.

**Cause:** Every `emacs` invocation loads the entire config from scratch: tangles
`config.org` → reads `config.el` → evaluates all `use-package` forms → connects to org-gcal,
sets up elfeed, initialises evil, etc. This is unavoidable in a fresh-start model.

**Solution: emacs daemon + emacsclient**

Run a persistent Emacs server in the background. Client frames connect to it
instantly — the config is already loaded.

```
emacs --daemon          ; starts once, loads full config, stays in background
emacsclient -c          ; opens a new frame in ~100ms (no startup cost)
emacsclient -c -e '(my/dashboard)'   ; opens directly to dashboard
```

**NixOS integration** — two options:

**Option A: systemd user service (recommended)**

Add to `home/emacs.nix` or a new `home/emacs-server.nix`:

```nix
services.emacs = {
  enable  = true;
  package = pkgs.emacs-pgtk;
  client.enable = true;   ; creates an emacsclient wrapper
};
```

Home Manager's `services.emacs` starts an Emacs daemon as a systemd user service
and creates a `emacsclient` wrapper that opens frames in the running server.

Rebuild, then `systemctl --user start emacs` to start immediately, or log out/in
for the service to auto-start.

**Option B: socket activation (lazier start)**

Don't auto-start; instead let the first `emacsclient` call start the server:
```bash
emacsclient -c --alternate-editor='emacs'
```
The `--alternate-editor='emacs'` means: if no server is running, start a full `emacs`
instead. Once that Emacs is running, subsequent `emacsclient` calls connect to it
instantly.

**Shell alias integration**

Replace the current `emacs` entry point with `emacsclient`:
```nix
home.shellAliases.emacs = "emacsclient -c";
```
Or keep the existing aliases and change what they invoke internally.

**config.org change** — add near the top, after core settings:

```elisp
(server-start)   ; idempotent — does nothing if server is already running
```

This lets the config also work when invoked directly as `emacs` (not as a daemon),
since it self-promotes to a server on first use.

**Trade-offs to know:**
- The first server start still takes the full startup time (1–3 seconds). Subsequent
  frames are instant.
- `kill-emacs` kills the server and all clients. Use `delete-frame` (or `C-x 5 0`)
  to close a client frame without killing the server.
- The white-screen issue (§4) partially improves §1 (close/restart errors): client
  frames close cleanly via `delete-frame`; the server only shuts down deliberately.
- Consider adding `(setq server-kill-new-buffers nil)` if you want buffers opened in
  a client frame to persist in the server after the frame closes.

**Relation to the white-screen:** Not fully solved — the first server start still
shows white. But since the server starts at login (systemd option A), the white
screen happens in the background once, not every time you open Emacs.

---

## Hardware note

```
card2 = Nvidia GTX 1060, PCI:1:0:0
Driver: legacy_535
KWIN_DRM_DEVICES fix is in hosts/desktop/default.nix — do NOT add prime.reverseSync.enable
```

Monitors at 100% scaling → performance acceptable.
