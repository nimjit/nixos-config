# Emacs UI conventions

Design decisions shared across the custom Emacs viewers.
Use the checklist below when building a new feature. Detailed rationale follows.

---

## Protocol: decisions for every new viewer

1. **Name the buffer(s)** — `*Title Case*`, human-readable, no abbreviations
2. **Choose window layout** — full frame, split, or overlay (see Window layout)
3. **Write the drawing skeleton** — erase → draw → read-only (see Drawing pattern)
4. **Register keybindings** — evil-local + emacs-state fallback (see Keybindings)
5. **Place keybind hints** — in negative space, not content (see Footers)
6. **Set selection highlight** — `hl-line` face
7. **Hide cursor if needed** — images, grids, or non-text content (see Cursor)
8. **Set olivetti width** — 200 standard; side panels sit in the negative space
9. **Decide thumbnail strategy** — if the feature has images (see Thumbnails)
10. **Decide auto-redraw strategy** — context-specific; document per feature

---

## Buffer naming

Convention: `*Title Case*` — human-readable words, no hyphens or abbreviations.

```
*Dashboard*
*YouTube List*
*Music Browser*
*MPD Now Playing*
```

Note: `*mpd-browser*` in the current code is a deviation from this; fix when touching that function.

---

## Window layout

Three modes, chosen by what the feature is:

**Full frame** — the viewer takes over the whole frame.
- Open: `delete-other-windows`, then `switch-to-buffer`
- Close: kill the buffer and restore the saved window config (`set-window-configuration`)
- Examples: YouTube viewer, dashboard

**Split main panel** — the main content is full-frame but a second window carries
informative, non-interactive content alongside it.
- Open: `delete-other-windows`, split with `split-window-right`, place the informative panel in the right window
- The side window in a split is read-only and passively updated (e.g. now-playing); it is not the primary interaction target
- Close: kill buffer(s) and restore window config
- Example: music browser (grid left, now-playing right)

**Overlay side panel** — shown beside the current buffer without taking over the frame.
- Implemented as a posframe
- Width = the olivetti negative space (frame width minus olivetti body width, divided by 2)
- The panel floats at `x = olivetti_body_width * char_width` from the left edge
- Close: `posframe-hide`; track visibility with a `defvar` boolean (not `posframe-visible-p` — not available in the installed version)
- Examples: agenda side panel (`SPC a s`), planned deadline panel (`SPC a d`)

---

## Drawing pattern

Every custom buffer follows this skeleton:

```elisp
(with-current-buffer (get-buffer-create "*Buffer Name*")
  (let ((inhibit-read-only t))
    (erase-buffer)
    ;; insert content here
    (read-only-mode 1)))
```

This pattern should eventually be extracted into a macro or helper so new features
start from a single call rather than copying the boilerplate. Until then, copy it
exactly — deviations (e.g. forgetting `read-only-mode 1`) cause subtle edit bugs.

---

## Keybindings

Register local keybindings in two ways so they work in both evil and emacs state:

```elisp
;; Evil normal (and motion) state — primary
(evil-local-set-key 'normal (kbd "j") #'my/feature--next)
(evil-local-set-key 'motion (kbd "j") #'my/feature--next)  ; only if needed

;; Emacs-state fallback (e.g. if evil is not active in this buffer)
(use-local-map (make-sparse-keymap))
(local-set-key (kbd "j") #'my/feature--next)
```

The dashboard registers both `normal` and `motion` because it can be reached
from either state. Most interactive viewers only need `normal`.

Always end the entry point with `(evil-normal-state)` to ensure the buffer opens
in the right state.

---

## Keybind footer placement

**Principle: hints belong in negative space, not content.**

| Layout | Where to put hints |
|--------|--------------------|
| Full-frame list (no sidebar) | `after-string` overlay below the *current entry*; moves with the cursor |
| Full-frame viewer with a split side panel | In the side panel, as a static line at the bottom |
| Overlay side panel | At the bottom of the posframe |
| Dashboard | Clickable button row in the footer area below all content |

The cursor-tied overlay and the static side-panel line solve the same problem for
different layouts. Choose based on where the negative space is.

---

## Selection highlight

Use `hl-line` face for all selections. Do not hardcode colors.

`hl-line` is theme-adaptive — if the Ukiyo palette changes, highlights update
automatically. Hardcoded hex values drift out of sync.

Applies to:
- The selected row in a list (YouTube: image+title line)
- The artist text below the selected cell in a grid (music browser)
- Track rows in an expanded tracklist

---

## Cursor hiding

Hide the cursor in buffers with images or grid content where Evil's block cursor
would expand image cells or look wrong:

```elisp
(setq-local cursor-type nil)
(setq-local evil-normal-state-cursor '(nil))
(add-hook 'evil-normal-state-entry-hook
          (lambda () (setq-local cursor-type nil)) nil t)
(evil-refresh-cursor evil-state)
```

Also used in the dashboard (`cursor-type nil`) since it is a read-only overview
with no meaningful point position.

---

## Olivetti

Standard body width: **200 characters**.

```elisp
(when (fboundp 'olivetti-mode)
  (setq-local olivetti-body-width 200)
  (olivetti-mode 1))
```

Overlay side panels (posframe) are positioned in the negative space to the right
of the olivetti body. Split side panels (music now-playing) occupy roughly 1/3 of
the frame width (`(/ (frame-width) 3)`).

---

## Thumbnails

Two strategies depending on the image source:

**Network-fetched (YouTube):**
- Download async with `make-process` + `curl`; write to `~/.cache/yt-feed/`
- Shared cache with the terminal `yt-feed` tool
- Missing thumbnails fetched automatically on open; debounced redraw (1.5s timer) fires after the last download finishes
- `M` in the viewer wipes and rebuilds the cache

**Filesystem pre-scaled (music):**
- Scale source covers to 150×150 with ImageMagick `convert`; write to `~/.cache/mpd-thumbs/`
- Cache key = MD5 of the source cover path
- Generation is **manual** — `my/mpd--generate-thumbs` or `u` in the browser
- Rationale: library changes rarely; synchronous generation would block on open; manual control avoids surprise freezes

Choose based on: does the source change frequently (network → auto), or rarely (filesystem → manual)?

---

## Auto-redraw

There is no single rule — document the strategy per feature. Questions to answer:

- What triggers a redraw? (user action, hook, timer, external event)
- Should redraws be debounced? (yes if triggered by many rapid events, e.g. per-feed elfeed updates)
- Is the buffer always visible, or only sometimes? (only redraw if the buffer has a window)
- What is the cost of a redraw? (full erase+redraw vs. targeted overlay update)
