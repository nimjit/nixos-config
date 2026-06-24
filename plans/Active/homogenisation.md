# UI Homogenisation

Maps the current state of each terminal tool against the intended UI conventions
(defined in CLAUDE.md § UI conventions). For each gap: is it fixable or a hard
constraint?

---

## Intended conventions (from CLAUDE.md)

| Convention | Rule |
|------------|------|
| Navigation | `j`/`k` up/down, `h`/`l` or `q` back/open, `g`/`G` first/last |
| Help | `?` opens a personal cheatsheet |
| Sidebar | `J`/`K` to move, `b` to toggle |
| Quit | `q` to exit/back |
| Entry alias | Opens in a kitty tab |
| Notify | `notify-send` → mako on relevant events |

---

## Tool matrix

| | neomutt | nchat | rmpc | yt-feed | ikhal | neovim |
|--|---------|-------|------|---------|-------|--------|
| j/k nav | ✓ | ✗ arrow | ✓ | ✓ | ✗ arrow | ✓ |
| h/l or q back/open | l=open, q=back | ✗ | h/l=pane | b=back, q=quit | ✗ | ✓ |
| g/G first/last | ✓ | ✗ | ✓ | ✗ | ✗ | ✓ |
| ? help | ✓ (custom) | Ctrl+G | ✓ | ✗ (hint bar only) | built-in | ✓ |
| Sidebar J/K | ✓ | Ctrl+J/K | N/A (tabs) | N/A | N/A | N/A |
| Quit `q` | q=back | **Ctrl+Q** | ✓ | ✓ | ✓ | **:q** |
| Ukiyo colours | ✓ | ✗ yellow | ✗ default | ~ approx | ✓ | ✓ |

---

## Per-tool analysis

### neomutt — email

**Vim-style:** Fully configured. j/k/l/gg/G all work. `q` exits pager back to index.

**Sidebar:** J/K move cursor, `o` opens folder, `b` toggles. Matches convention.

**Colours:** Ukiyo via base16 terminal colors (color0–color15). Fully themed.

**Quit:** `q` in pager goes back to index. From index, `q` exits neomutt.
Convention met.

**Gaps:** None.

---

### nchat — WhatsApp (messages)

**Vim-style:** ✗ Hard constraint. `up`/`down` are arrow keys. The reason: nchat
has a persistent text entry box at the bottom. Unlike email or music, you are
*always* one keypress away from typing in a conversation. Binding `j`/`k` to
navigation would fire whenever you start typing a word with j or k at the
start. nchat does have separate nav/entry modes, but the mode switch is
implicit (you start typing and it enters edit mode), making modal j/k
unreliable in practice. Arrow keys are the safe choice here.

**Sidebar (contact list):** Ctrl+J / Ctrl+K to move between chats. This is the
same *family* as neomutt's J/K, just modifier-shifted to avoid the text entry
conflict above. Acceptable divergence — both use j/k as the base key.

**Colours:** ✗ Yellow only. Sent messages: yellow. Unread: yellow. Everything
else: terminal default. nchat's color.conf supports named colors (black, white,
red, yellow, gray, etc.) — not 256-color or RGB codes. This means an exact
Ukiyo palette is not possible, only an approximation using the 8 named colors.
The closest mapping:
- `yellow` → amber (the only warm color available)
- `gray` → dim/muted (quoted text, attachments)
The result would still feel different from the other tools. **Low priority** —
WhatsApp is glanced at, not read deeply.

**Quit:** Ctrl+Q. Hard constraint. `q` would type the letter q in the entry
box. Ctrl+Q is the conventional escape in apps with persistent text entry.

**Fixable:**
- Color.conf could be improved to use `yellow`/`gray` more consistently

**Not fixable:** j/k nav, Ctrl+Q quit — text entry context makes these
necessary divergences.

---

### rmpc — music

**Vim-style:** ✓ Fully configured. j/k/h/l, gg/G, Ctrl+u/d half-page, / search.

**Sidebar:** rmpc has no traditional sidebar. It uses *tabs* (Queue,
Directories, Artists, Albums, etc.) and *panes* within tabs. Navigation between
them:
- `Tab` / `Shift+Tab` or `Ctrl+l` / `Ctrl+h` — next/previous tab
- `H` / `L` — move focus between left/right panes within a tab
- `J` / `K` — reorder items in a list (move up/down, not navigate)

`J`/`K` meaning is different here than in neomutt (where they navigate the
sidebar). In rmpc, J/K *reorder* the queue. This is a context-appropriate
divergence — rmpc has no sidebar to navigate.

**Colours:** ✗ `theme: None` in config.ron. rmpc uses its built-in default
colors, which are unrelated to Ukiyo. rmpc supports custom themes via a
separate theme file. This is a fixable gap.

**Quit:** `q` — matches convention.

**Fixable:**
- Add a Ukiyo theme file for rmpc (same palette approach as khal's [palette]
  section). rmpc's theme format is RON with color fields like `text_color`,
  `highlight_color`, `border_color`, etc.

---

### yt-feed — YouTube

**Vim-style:** ✓ j/k scrolling, Enter to play, q to quit, / to filter, c for
category picker (which also uses j/k internally). `b` goes back from detail
view. Reasonably vim-style for a custom TUI.

**Missing:** `g`/`G` first/last, `?` help screen (currently a one-line hint
bar only).

**Sidebar:** N/A — linear card list, no sidebar. Categories accessed via `c`
popup, which uses j/k. This is fine; the structure doesn't call for a sidebar.

**Colours:** ~ Close but not exact. Hard-coded RGB in the Python source:
```python
ACCENT  = fg(204, 153, 102)   # ≈ amber (ba945f is the Ukiyo value)
MUTED   = fg(140, 120, 110)   # ≈ dim brown-gray
HILIGHT = fg(230, 210, 190)   # ≈ light warm white
```
These were clearly chosen to match the Ukiyo mood but aren't the exact palette
values. Because yt-feed uses raw RGB escapes (not terminal color slots), it
bypasses the Stylix base16 mapping. This means it won't automatically update if
the theme changes. Fixable but low priority — the visual result is already
close.

**Quit:** `q` — matches convention.

**Fixable:**
- Update ACCENT/MUTED/HILIGHT to exact Ukiyo hex values
- Add `g`/`G` for first/last
- Add `?` help popup (already consistent with neomutt's pattern)

---

### ikhal — calendar

**Vim-style:** ✗ Hard constraint. ikhal (khal's interactive TUI) uses built-in
keybindings that cannot be reconfigured. Navigation is arrow-key based:
- Arrow keys: move between days/events
- Enter: open event
- `n`: new event
- `d`: delete
- `e`: edit
- `q`: quit

No way to remap these without patching khal itself.

**Sidebar:** N/A — ikhal is a two-pane (calendar grid + event list) app with
no sidebar concept. Navigation is purely arrow-key between the two panes.

**Colours:** ✓ Ukiyo palette configured in `home/dotfiles/khal/config` via the
`[palette]` section, using 256-color codes that match the base16 values.
Well-themed.

**Quit:** `q` — matches convention.

**Not fixable:** j/k navigation, h/l pane switching — khal's interactive UI
has no key config file.

---

### neovim — editor

**Vim-style:** ✓ It is vim.

**Sidebar:** No persistent sidebar. Splits navigated with `Ctrl+h/j/k/l`.
`<leader>f` opens yazi file picker in a split.

**Colours:** ✓ Custom Ukiyo colorscheme (hand-crafted, not Stylix auto-managed
to avoid mini.base16 override issues).

**Quit:** `:q` — a necessary divergence. neovim is modal; `:q` is the correct
paradigm. `q` in normal mode is a macro recorder, not quit. No fix appropriate.

---

## Summary of divergences

| Divergence | Tool | Fixable? | Reason |
|------------|------|----------|--------|
| j/k navigation | nchat, ikhal | No | Text entry / no config |
| Ctrl+Q quit | nchat | No | Text entry context |
| :q quit | neovim | No | Modal editor paradigm |
| Ctrl+J/K sidebar | nchat | No (justified) | Same family, different modifier |
| J/K = reorder not navigate | rmpc | No (appropriate) | No sidebar; J/K reorders queue |
| No Ukiyo theme | rmpc | **Yes** | theme: None → write a theme file |
| Approximate Ukiyo colors | yt-feed | Yes (low priority) | Update RGB constants |
| No g/G first/last | yt-feed | Yes | Add to getch() handler |
| No ? help popup | yt-feed | Yes | Already done in neomutt; add here |
| Yellow-only colors | nchat | Partial | color.conf only supports named colors |

---

## What genuinely cannot be homogenised

Two root causes explain all the hard constraints:

1. **Persistent text entry** (nchat): any non-modifier key is potentially
   typed text. Ctrl-modified keys are the only safe navigation keys. This
   is a fundamental UI model difference from read-only tools like email and
   music.

2. **No config** (ikhal): khal's TUI doesn't expose keybinding configuration.
   The only fix would be switching calendar TUI (e.g. calcurse, which IS
   configurable — see `home/dotfiles/calcurse/keys`).

Everything else — rmpc colors, yt-feed precision, yt-feed g/G and ? — is fixable
if it ever feels worth the effort.

---

## Status

- [ ] rmpc: write Ukiyo theme file
- [ ] yt-feed: update ACCENT/MUTED/HILIGHT to exact Ukiyo values
- [ ] yt-feed: add g/G first/last
- [ ] yt-feed: add ? help popup
- [ ] nchat: improve color.conf (yellow → amber approximation, gray for muted)
- [ ] Consider: calcurse as ikhal replacement (has `home/dotfiles/calcurse/keys` already)
