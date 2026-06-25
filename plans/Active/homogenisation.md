# UI Homogenisation

Maps the current state of each terminal tool against the intended UI conventions.
Central principle: **modifier weight maps to scope distance from the cursor.**

## Key hierarchy

```
Thumb row:  [Super] [Alt] [Ctrl/Space]       [Shift/Enter] [Fn] [Super]
               │      │        │                               │
               │      │        └─ ctrl+hjkl  pane/tab/panel    │
               │      │           ctrl+q     quit (non-modal)  │
               │      │           tap        space             │
               │      └─ alt+hjkl  switch to app in direction  │
               └─ super+…  WM: desktops, windows               └─ fn+hjkl = ↑↓←→
                                                                   (hardware layer)

  Scope       Modifier     hjkl meaning          When it applies
  ──────────────────────────────────────────────────────────────────
  WM          Super        desktop / window       always
  App         Alt          switch application     always (KDE app switcher)
  Structure   Ctrl         tab / pane / panel     always
  ──────────  ───────────  ────────────────────   ──────────────────────────
  Cursor      bare         navigate items         modal apps only
  Cursor      fn (= ↑↓←→)  navigate items         non-modal apps
  ──────────  ───────────  ────────────────────   ──────────────────────────
```

fn is hardware-level: the OS sees arrow keycodes, not "fn+j". It cannot carry
additional software bindings — its only role is arrows.

The one inversion: in non-modal apps (nchat), ctrl drops to cursor level because
bare keys are unsafe. Safety overrides scope there, but the key family is the same.

---

## Verb vocabulary

All interaction types and their intended bindings. Modal = no persistent text
entry (neomutt, rmpc, yt-feed, ikhal). Non-modal = persistent text box (nchat).

### Movement

| Action           | Modal      | Non-modal   | Notes |
|------------------|------------|-------------|-------|
| Navigate items   | hjkl       | fn+hjkl     | arrows on this keyboard |
| First / last     | gg / G     | —           | no non-modal equivalent |
| Next / prev      | n / p      | n / p       | different modality: next result, next unread, next occurrence |
| Pane / tab       | Ctrl+hjkl  | Ctrl+hjkl   | always safe; same binding regardless of modal state |
| Half-page scroll | Ctrl+u/d   | —           | useful where lists are long (rmpc has this) |

### Open / confirm

| Action           | Key   | Notes |
|------------------|-------|-------|
| Enter context    | l     | drill down, open in place; reverse with h or q |
| Execute on item  | \<CR\>  | play, launch, run — not a navigation move |
| Open externally  | o     | xdg-open, browser, player |
| Open in new tab  | O     | same but in new context (qutebrowser `O`) |

The distinction: if you can go back with `h` or `q`, use `l`. If it launches
something external or irreversible, use `<CR>`. Both can exist in the same app.

### Edit / modify

| Action           | Modal      | Non-modal    | Notes |
|------------------|------------|--------------|-------|
| Select           | v / V      | mouse        | v = item, V = block/range |
| Yank / copy      | y / yy     | Ctrl+y / Ctrl+c | yy = whole item without prior selection (like qutebrowser `yy` for URL, neovim `yy` for line) |
| Delete           | d / dd     | —            | d = mark for deletion where possible; dd = confirm/immediate |
| Fold / collapse  | J          | —            | also: reorder/restructure (rmpc queue) |
| Sort             | s          | —            | rarely used; reserve the key |
| Mark / flag      | Space?     | —            | undecided — some apps use Space, no convention yet |

### Actions

| Action           | Key   | Notes |
|------------------|-------|-------|
| Lookup           | K     | get more context from external source (LSP hover, Wikipedia, web search) |
| Refresh          | r     | reload data from source, where applicable |
| Compose / create | m / n | m = mail (neomutt); n = new item (app-dependent) |

### Meta

| Action          | Modal  | Non-modal |
|-----------------|--------|-----------|
| Help            | ?      | —         |
| Quit / back     | q / :q | Ctrl+q    |
| Search / filter | /      | —         |

---

## Tool matrix

|                    | neomutt | nchat  | rmpc | yt-feed | ikhal | neovim | dashboards | QuteBrowser |
|--------------------|---------|--------|------|---------|-------|--------|------------|-------------|
| j/k nav            | ✓       | ✗      | ✓    | ✓       | ✓     | ✓      | ✓          | ✓           |
| h/l or q back/open | ✓       | ✗      | ✓    | <CR>, q | ✓     | ✓      | <CR>, :q   | <CR>, :q    |
| g/G first/last     | ✓       | ✗      | ✓    | ✓       | ✗     | ✓      | ✓          | ✓           |
| dd delete          | ✗ (d)   | ✓      | N/A  | N/A     | N/A   | ✓      | N/A        | ✓           |
| ? help             | ✓ (bar) | Ctrl+g | ✓    | ✓ (bar) | ✓     | ✓      | ✓          | ✓           |
| Sidebar ctrl+jk    |Ctrl+j/k |Ctrl+j/k| N/A  | N/A     | N/A   | N/A    | N/A        | N/A         |
| Quit   q           | ✓       | Ctrl+q | ✓    | ✓       | ✓     | :q     | :q         | :q          |
| Ukiyo colours      | ✓       | ~ okay | ✓    | ✓       | ✓     | ✓      | ✓          | ✓  where possible |

---

## Per-tool analysis

### neomutt — email

**Vim-style:** Fully configured. j/k/l/gg/G all work. `q` exits pager back to index.

**Sidebar:** Ctrl+J/K move cursor, Ctrl+L opens folder, Ctrl+H toggles. Matches convention.

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
view. `gg`/`G` first/last added. Reasonably vim-style for a custom TUI.

**Missing:** `?` help screen (currently a one-line hint bar only).

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
| No g/G first/last | yt-feed | Done | Added to getch() handler |
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
| neomutt | Sidebar + index/pager | Ctrl+L opens sidebar item; no "tab" concept | Sidebar is always visible, not a tab |
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

- [x] yt-feed: add `g`/`G` first/last
- [x] neomutt sidebar: J/K → Ctrl+J/K, `o` → Ctrl+L, `b` → Ctrl+H
- [ ] yt-feed: add `?` help popup
