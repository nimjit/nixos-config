# Emacs — Fresh Start

## Approach

Build the config myself, incrementally, with a real purpose from the start.
Starting with **markdown** (not org-mode) so notes stay interchangeable with neovim.

The previous AI-generated config is archived in `done/emacs-impl-log.md` if any
of the bug notes (key binding order, byte-compile issue, etc.) are ever useful.

---

## Why start over

- The AI-built config was complete but opaque — I didn't understand what any of it did.
- Opening emacs gave no obvious next action, so I never used it.
- Need a purpose first, then add config to support that purpose.

---

## Starting purpose

Move one concrete task there: **lecture notes during class**.
- Markdown files in `~/org/` (compatible with current neovim vault workflow)
- One file per lecture, opened directly — no database, no dashboard yet
- Just get comfortable with the editor first

---

## Phase 0 — Minimal working config (do this first)

Goals: open emacs, move around, edit markdown, not be confused.

1. **Evil mode** — vim keybindings, so muscle memory transfers immediately
2. **which-key** — shows available keys after pressing a prefix; essential for learning
3. **Theme** — dark, ukiyo palette (already have `ukiyo-theme.el`)
4. **Line numbers** in code files, not prose
5. **No startup screen**

Nothing else. No org-roam, no perspectives, no dashboard. Just a text editor with vim keys.

---

## Phase 1 — Markdown workflow

Once phase 0 feels natural:

- `markdown-mode` — basic rendering, header folding
- A keybinding to open the notes directory (`SPC f n` or similar)
- Spell check (`jinx` or built-in `flyspell`) — English + Dutch

---

## Phase 2 — Add one more thing (decide later)

Once markdown feels good, pick the next actual pain point and add exactly that.
Candidates (not commitments):

- **Dired** — file browsing; may be enough without a sidebar plugin
- **Magit** — if git from emacs feels useful
- **PDF viewing** (pdf-tools) — if reading lecture PDFs alongside notes
- **org-mode** — if I want to stay in emacs long-term and markdown starts feeling limiting

---

## Key lessons from the previous attempt

These are specific gotchas to avoid when eventually adding packages back:

- `(setq evil-want-keybinding nil)` must be in `:init`, before `evil-collection` loads
- Unbind SPC from evil-motion-state AFTER `(evil-mode 1)` in `:config`:
  ```elisp
  (define-key evil-motion-state-map (kbd "SPC") nil)
  (define-key evil-normal-state-map (kbd "SPC") nil)
  ```
- Never byte-compile config.el — `general-create-definer` macros resolve at runtime
- `xdg.configFile."emacs/init.el".source = ...` bypasses Stylix theme injection; use standalone `ukiyo-theme.el`
- If adding org-roam: `(setq org-roam-directory ...)` must come BEFORE the `use-package org-roam` form

---

## Performance note

Monitors at 100% scaling → performance acceptable. The bottleneck was Cairo CPU
rasterization at 4K (emacs-pgtk has no GPU text renderer). At 100% scale this is fine.

---

## Hardware reference

```
card2 = Nvidia GTX 1060, PCI:1:0:0
Driver: legacy_535
KWIN_DRM_DEVICES fix is in hosts/desktop/default.nix — do NOT add prime.reverseSync.enable
```
