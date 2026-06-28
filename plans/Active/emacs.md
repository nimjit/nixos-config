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

## Hardware note

```
card2 = Nvidia GTX 1060, PCI:1:0:0
Driver: legacy_535
KWIN_DRM_DEVICES fix is in hosts/desktop/default.nix — do NOT add prime.reverseSync.enable
```

Monitors at 100% scaling → performance acceptable.
