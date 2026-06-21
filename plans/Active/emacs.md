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

## Hardware note

```
card2 = Nvidia GTX 1060, PCI:1:0:0
Driver: legacy_535
KWIN_DRM_DEVICES fix is in hosts/desktop/default.nix — do NOT add prime.reverseSync.enable
```

Monitors at 100% scaling → performance acceptable.
