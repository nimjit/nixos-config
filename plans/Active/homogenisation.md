# UI Homogenisation

Maps the current state of each terminal tool against the intended UI conventions
(defined in CLAUDE.md § UI conventions). For each gap: is it fixable or a hard
constraint?

---

## Intended conventions (from CLAUDE.md)

| Convention | Rule |
|------------|------|
| Navigation | `j`/`k` up/down, `h`/`l` or `q` back/open, `gg`/`G` first/last |
| Help | `?` opens a personal cheatsheet |
| Sidebar | `J`/`K` to move, `b` to toggle |
| Quit | `q` to exit/back |
| Entry alias | Opens in a kitty tab |
| Notify | `notify-send` → mako on relevant events |

---

## Tool matrix

| | neomutt | nchat | rmpc | yt-feed | ikhal | neovim |
|--|---------|-------|------|---------|-------|--------|
| j/k nav | ✓ | ✗ arrow | ✓ | ✓ | ✓ h/j/k/l | ✓ |
| h/l or q back/open | ✓ | ✗ | ✓ | b=back, q=quit | ✓ | ✓ |
| g/G first/last | ✓ | ✗ | ✓ | ✗ | ✗ | ✓ |
| ? help | ✓ (custom) | Ctrl+G | ✓ | ✗ (hint bar only) | built-in | ✓ |
| Sidebar J/K | ✓ | Ctrl+J/K | N/A (tabs) | N/A | N/A | N/A |
| Quit `q` | ✓ | **Ctrl+Q** | ✓ | ✓ | ✓ | **:q** |
| Ukiyo colours | ✓ | ~ okay | ✓ via terminal | ✓ visually | ✓ | ✓ |

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

**Colours:** ✓ `theme: None` in config.ron means rmpc inherits the terminal's
color palette directly. Since the terminal is Stylix base16 Ukiyo, rmpc gets
the right colors automatically — no separate theme file needed.

**Quit:** `q` — matches convention.

**Gaps:** None.

---

### yt-feed — YouTube

**Vim-style:** ✓ j/k scrolling, Enter to play, q to quit, / to filter, c for
category picker (which also uses j/k internally). `b` goes back from detail
view. Reasonably vim-style for a custom TUI.

**Missing:** `g`/`G` first/last, `?` help screen (currently a one-line hint
bar only).

**Sidebar:** N/A — linear card list, no sidebar. Categories accessed via `c`
popup, which uses j/k. This is fine; the structure doesn't call for a sidebar.

**Colours:** ✓ Visually correct. Hard-coded RGB in the Python source:
```python
ACCENT  = fg(204, 153, 102)   # amber — close to Ukiyo base0A ba945f
MUTED   = fg(140, 120, 110)   # dim brown-gray
HILIGHT = fg(230, 210, 190)   # warm near-white
```
Uses raw RGB rather than terminal color slots, so it bypasses Stylix base16.
Won't auto-update with a theme change, but the values are stable and the visual
result matches. Not a concern in practice.

**Quit:** `q` — matches convention.

**Fixable:**
- Add `g`/`G` for first/last
- Add `?` help popup (same pattern as neomutt's cheatsheet)

---

### ikhal — calendar

**Vim-style:** ✓ ikhal supports h/j/k/l for date navigation alongside arrow keys.
`q` to quit. `Tab` switches between the calendar grid and the event list.

**Missing:** `g`/`G` (not really applicable to a calendar grid). `?` uses
ikhal's own built-in help, not a personal cheatsheet.

**Sidebar:** N/A — two-pane layout (grid + event list), `Tab` to switch.

**Colours:** ✓ Ukiyo palette configured in `home/dotfiles/khal/config` via the
`[palette]` section, using 256-color codes matching the base16 values.

**Quit:** `q` — matches convention.

**Gaps:** Minor. The built-in ? help is fine.

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
| j/k navigation | nchat | No | Persistent text entry |
| Ctrl+Q quit | nchat | No | Text entry context |
| :q quit | neovim | No | Modal editor paradigm |
| Ctrl+J/K sidebar | nchat | No (justified) | Same family, different modifier |
| J/K = reorder not navigate | rmpc | No (appropriate) | No sidebar; J/K reorders queue |
| No g/G first/last | yt-feed | Yes | Add to getch() handler |
| No ? help popup | yt-feed | Yes | Already done in neomutt; add here |
| Yellow-only colors | nchat | Partial | color.conf only supports named colors |

---

## What genuinely cannot be homogenised

One root cause explains all hard constraints:

**Persistent text entry** (nchat): any non-modifier key is potentially typed
text. Ctrl-modified keys are the only safe navigation bindings. This is a
fundamental UI model difference from every other tool here.

Everything else is either already consistent or has a small fixable gap.

---

## Tab / pane movement

How each tool moves between its internal sections (tabs, panes, splits).

| Tool | Sections | Move between | Notes |
|------|----------|-------------|-------|
| neomutt | Sidebar + index/pager | `o` opens sidebar item; no "tab" concept | Sidebar is always visible, not a tab |
| nchat | Contact list + chat view | Ctrl+H toggles the list; no tabs | Two-pane, not tab-based |
| rmpc | 7 named tabs | `Tab`/`Shift+Tab`, `Ctrl+l`/`Ctrl+h`, `gt`/`gT`, `1`–`7` | Rich tab navigation |
| yt-feed | Single view + category popup | `c` for popup, Esc/q to close | No persistent tabs |
| ikhal | Calendar grid + event list | `Tab` to switch panes | Two fixed panes |
| neovim | Splits / buffers | `Ctrl+h/j/k/l` between splits; no tab bar used | No kitty-tab integration from inside |

**Pattern that exists:** rmpc and ikhal both use `Tab` to move between sections. neovim uses `Ctrl+hjkl` for splits (directional, not cyclic). neomutt and nchat don't have tabs — their "sections" are always co-visible.

**The missing piece:** there's no consistent "cycle through sections" key. rmpc has the fullest tab system (7 tabs, multiple ways to reach them). ikhal has the simplest (2 panes, one Tab). The others don't apply.

**Kitty tabs vs. internal tabs:** the tools themselves run *in* kitty tabs (email, music, messages). Movement between kitty tabs uses `Ctrl+Shift+hjkl` (configured in kitty). This is a separate layer above the tool's own internal navigation and doesn't conflict.

**Verdict:** no homogenisation needed here. The tools that have internal tabs (rmpc) or panes (ikhal) each use `Tab`/`Ctrl+hjkl` consistently with the rest of the system. The tools that don't have internal sections (neomutt, yt-feed) simply don't need tab movement.

---

## Status

- [ ] yt-feed: add `g`/`G` first/last
- [ ] yt-feed: add `?` help popup
