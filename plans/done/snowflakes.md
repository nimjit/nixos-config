# Snowflake Visualizations Plan

## What they are

Snowflakes are static single-file HTML visualizations of directory trees, rendered as
D3.js radial graphs. Each node is a file or folder; edges are parent-child
relationships. Clicking a node opens the file via `file://`. The HTML is fully
self-contained (D3 is inlined) — no server, no dependencies, open in any browser.

The name comes from the visual: a central hub with branches radiating outward like a
snowflake. Each section (knowledge domain, vault section, NixOS module group) gets a
distinct color from the Ukiyo palette.

They serve as a high-level map of the structure — useful for orientation, for
presenting the vault to someone else, and for noticing when a section has grown
unwieldy.

---

## Current state

Three scripts exist and work. All output standalone `.html` files.

### 1. `nixos_snowflake.py`

**Location**: `/etc/nixos/nixos_snowflake.py`
**Output**: `/etc/nixos/nixos_snowflake.html`
**Open in Emacs**: `SPC o n`
**Regenerate**: `SPC o V` (runs all three scripts)

Maps the NixOS config directory. Four sections radiating from center:
- `modules/` (system-level config) — orange
- `home/` (Home Manager modules) — teal
- `hosts/` (machine-specific) — blue
- `plans/` (documentation) — yellow

Clicking a `.nix` or `.md` file opens it via `file://` in the browser.

**Status**: up to date, matches current repo structure.

---

### 2. `vault_snowflake.py`

**Location**: `/home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/vault_snowflake.py`
**Output**: `.../Renaissance_Vault_Structure/vault_snowflake.html`
**Open in Emacs**: `SPC o v`
**Regenerate**: `SPC o V`

Maps the **original Obsidian personal vault** (the BACKUP copy, still in Markdown).
Three satellites:
- Knowledge — center, subjects individually colored (Physics, Maths, Philosophy, etc.)
- Sources — left satellite (Books, Papers, YouTube)
- People — right satellite

**Status**: still works, but points to the archived BACKUP vault.
After vault conversion, the live personal notes are in `~/org/personal/` and
`~/org/knowledge/`. This script now maps the archive, not the active vault.
**Needs**: an updated/replacement script pointing to `~/org/` — see below.

---

### 3. `uni_snowflake.py`

**Location**: `/home/thijmen/Documents/BACKUP/Uni/Obsidian/uni_snowflake.py`
**Output**: `.../Uni/Obsidian/Uni/uni_snowflake.html`
**Open in Emacs**: `SPC o u`
**Regenerate**: `SPC o V`

Maps the **original Obsidian Uni vault** (BACKUP copy, Markdown). Three sections:
- Classes — center, colored by subject area (Quantum, Classical, Mathematics, CS, etc.)
- Lectures — left satellite, grouped by class
- Assignments — right satellite, grouped by class

A `CLASS_SUBJECTS` dict maps class names to subject colors for coloring consistency.

**Status**: same as vault_snowflake.py — points to the BACKUP. Active uni notes are
now in `~/org/uni/`. **Needs**: updated script pointing to `~/org/uni/`.

---

## The gap: (if emacs becomes the editor of choice) ~/org/ has no snowflake

After the Obsidian → org-roam conversion, the active vault is `~/org/`. The existing
snowflake scripts show the archived Markdown vaults. There is no live visualization
of the org vault structure.

**What to build**: `org_snowflake.py` at `/home/thijmen/org/org_snowflake.py` (or
wherever convenient) that maps `~/org/` and outputs `~/org/org_snowflake.html`.

---

## Building `org_snowflake.py`

The script is structurally identical to `vault_snowflake.py` — same D3.js radial
tree, same ukiyo palette, same standalone HTML output. Only the path config and
section layout differ.

### Structure of `~/org/` to visualize

```
~/org/                          ← root
  personal/                     ← left satellite (personal knowledge)
    concepts/                   ← sub
    knowledge/
      physics/
      mathematics/
      philosophy/
      ...
    essays/
    sources/books/
    sources/papers/
    people/
  uni/                          ← right satellite (academic)
    classes/
    lectures/
    assignments/
    summary/
    thesis/
  daily/                        ← small satellite (dailies)
  dashboard.org
  inbox.org
  agenda.org
```

### Recommended design

Three satellites from a `~/org/` center:
- `personal/` — left, teal (matches the home/ color in nixos snowflake)
  - knowledge sub-branches individually colored by subject
- `uni/` — right, blue (matches hosts/ color)
  - sub-branches colored by subject area (reuse `CLASS_SUBJECTS` from uni_snowflake)
- `daily/` — small top satellite, dim gray (low importance visually)

Core files (dashboard.org, inbox.org, agenda.org) as direct children of root.

### Config block (drop into the script)

```python
#!/usr/bin/env python3
"""
org_snowflake.py
Generates a radial snowflake of the ~/org/ org-roam vault.
Run:    python3 ~/org/org_snowflake.py
Output: ~/org/org_snowflake.html
"""
import json
from pathlib import Path

ROOT       = Path.home() / "org"
OUTPUT     = ROOT / "org_snowflake.html"
VAULT_NAME = "org"

SKIP_DIRS  = {".git", "__pycache__", ".attach", "auto"}
SKIP_FILES = {"org_snowflake.html", "org_snowflake.py", ".gitignore"}
CODE_EXTS  = {".org", ".bib", ".md"}

SECTION_COLORS = {
    "personal":  "#6abd9a",   # teal — personal knowledge
    "uni":       "#6a9fd4",   # blue — academic
    "daily":     "#868074",   # dim gray — dailies
    "knowledge": "#d4956a",   # orange — core knowledge
}

KNOWLEDGE_COLORS = {
    "physics":                  "#d4956a",
    "mathematics":              "#6a9fd4",
    "philosophy":               "#a07ec8",
    "computation":              "#6abd9a",
    "humanities-and-arts":      "#d4c04a",
    "body-and-movement":        "#9abd6a",
    "craft-and-material-culture": "#c87e6a",
    "languages":                "#d46a9a",
}
```

Copy the rest of the script from `nixos_snowflake.py` — the HTML template, D3.js
render code, and tree-builder functions are identical. Only the config block and
color mapping change.

### Adding to Emacs keybindings

Currently `config.org` has these bindings (in Snowflake Visualizations section):

```elisp
"ov"  'open-personal-snowflake   ; → vault_snowflake.html (OLD backup)
"ou"  'open-uni-snowflake        ; → uni_snowflake.html (OLD backup)
"on"  'open-nixos-snowflake      ; → nixos_snowflake.html
"oV"  'regenerate-snowflakes     ; runs all three scripts
```

Once `org_snowflake.py` exists, update `config.org`:

```elisp
;; Replace open-personal-snowflake:
(defun open-org-snowflake ()
  (interactive)
  (browse-url "file:///home/thijmen/org/org_snowflake.html"))

;; Update regenerate-snowflakes to include the new script:
(defun regenerate-snowflakes ()
  (interactive)
  (async-shell-command
   (mapconcat #'identity
     '("python3 /home/thijmen/org/org_snowflake.py"
       "python3 /etc/nixos/nixos_snowflake.py")
     " && ")
   "*snowflake-regen*"))

;; Keep vault/uni as archive viewers under different keys (optional):
"ov"  'open-org-snowflake         ; SPC o v → live org vault
"ou"  'open-uni-snowflake         ; SPC o u → uni vault (update this too)
"on"  'open-nixos-snowflake       ; SPC o n → nixos config
"oV"  'regenerate-snowflakes
```

---

## Emacs keybinding wiring (full picture)

The four `open-*-snowflake` and `regenerate-snowflakes` functions are defined in the
"Snowflake Visualizations" section of `config.org` (near the bottom). Their SPC
bindings are in the "Open, windows, toggles, workspaces" keybindings block. When
updating paths, update **both** the `defun` bodies AND the `spc!` calls.

---

## Future improvements (non-urgent)

**Search/filter**: add a search box to the HTML that highlights matching nodes. Useful
once the vault grows large. D3.js can do this with a text input that filters node
opacity.

**Count labels**: show file count per folder as a badge on folder nodes. Already
implicit from branch count but a number is clearer.

**Live links to Emacs/org**: instead of `file://` links, use `org-protocol://` links
that open the file in Emacs directly. Format:
`org-protocol://open-file?path=/home/thijmen/org/path/to/file.org`
Requires `org-protocol` to be active in Emacs and a `.desktop` file registered for
the `org-protocol://` URI scheme. Low priority but clean once Emacs is the main editor.

**Uni subject colors**: the `CLASS_SUBJECTS` dict in `uni_snowflake.py` maps class
names to subject colors. This will need updating each academic year as new classes
are added. A simpler approach: color by folder depth instead of class name. But named
colors per subject are more visually meaningful for physics/math heavy curricula.

**Automate on rebuild**: add a `home.activation` step in home-manager that regenerates
the org snowflake whenever the home config is rebuilt. Not critical since manual
regeneration via `SPC o V` is fast.

**Make the html interactive**: add the ability to click a node and open a neovim instance there. This currently does not work.

**Make html file scale aware**: the generated html looks different on different size windows.
In general the spacing between the flakes should be larger, but this size difference should also reflect the window size.

---

## Implementation order

1. Write `org_snowflake.py` (copy nixos_snowflake.py, change config block above)
2. Run once manually: `python3 ~/org/org_snowflake.py`
3. Open output in browser to verify structure looks correct
4. Update `open-personal-snowflake` → `open-org-snowflake` in config.org
5. Update `regenerate-snowflakes` to include the new script
6. Decide whether to keep `vault_snowflake.py` / `uni_snowflake.py` for the old
   BACKUP vaults or retire them (keeping them as archive viewers is harmless)
7. `rebuild && rm ~/.cache/emacs/config.el` to apply Emacs changes
