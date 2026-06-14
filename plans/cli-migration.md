# CLI Migration

Replacing persistent browser tabs with focused terminal tools.

## Status

| Tool | Status | Notes |
|------|--------|-------|
| nchat (WhatsApp) | ✓ Done | `messages()` shell function; kitty tab |
| New tab page | ✓ Done | Served at `localhost:8080`; New Tab Override extension |
| lastpass-cli | ✓ Done | `LPASS_CLIPBOARD_COMMAND=wl-copy` set; no rofi script yet |
| khal + vdirsyncer | ✓ Done | 12 Google calendars; `cal` alias; look needs polish → see `theme-workflow.md` |
| MPD + rmpc | ✓ Done | `music()` shell function + `<leader>m` in neovim |
| Neovim dashboards | ✓ Done | `vault-work`, `uni-work`, course view, `:DailyNote` |
| Typst rendering | ✓ Done | `<leader>tp` / `<leader>ta`; math blocks supported |
| PDF/image viewer | ✓ Done | `<leader>z`; kitty vsplit with pre-rendered pages |

## Remaining open items

### Some quick notes on kitty splits
Currently yazi and claude open in neovim splits, when kitty splits are set up such that they can use the same ctrl+hjkl movement, these should probably be kitty terminals instead. Just because I don't want to be in normal mode for those terminals and I always want interactability with them.
The same goes for the normal zsh terminal. Using kitty terminals instead of neovim terminals would probably be preferable for anything that need not be neovim, though there may be exeptions to this, this should be discussed.

### Rofi password picker (lastpass-cli) - done

A rofi script for system-wide password copy via keyboard shortcut. Not yet written.

```bash
# lpass-rofi: fuzzy-pick a LastPass entry and copy its password
entries=$(lpass ls --long 2>/dev/null)
selected=$(echo "$entries" | rofi -dmenu -p "Password:" -i -format 'i')
name=$(echo "$entries" | sed -n "$((selected+1))p" | sed 's/ \[id:.*\]//')
lpass show --clip "$name" && notify-send "LastPass" "Copied: $name" --expire-time=3000
```

Add keyboard shortcut in KDE or Sway (`Super+P`). Depends on `wl-clipboard`.

### vdirsyncer: architecture notes - done

Google's CalDAV discovery only returns owned calendars. Shared calendars need
explicit pairs with hardcoded CalDAV URLs.

`~/.config/vdirsyncer/config` is NOT in git — it contains OAuth credentials and is
modified by `vdirsyncer discover`. Replicate manually on new machines.

Calendars syncing (12 total): Work, Sport, Fun, Semi-productive, Mindfulness,
Feestdagen (owned); D&D in Space, Lisan Shared 2, Lisan + Thijmen (writer access);
Bolk: Algemeen, TU Delft timetable (reader access); one unknown shared calendar.

### nchat keybindings

nchat ships with arrow-key defaults. Remap to vim keys in `~/.config/nchat/ui.conf`:
`ctrl+h/l` to move between panes, `j/k` to scroll, `i` for compose, `Escape` for
normal mode, `:q` to quit.

Would need to be done using zsh vim mode, would want to know all the reporcusions before doing this.


---

## Kitty ecosystem integrations

Tools and features from the kitty ecosystem worth adding. Ordered roughly by effort.

### kitten ssh (1 alias, no rebuild logic needed)

Drop-in replacement for `ssh`. `kitten ssh hostname` copies your zsh config, aliases,
starship prompt, and kitty graphics capabilities to the remote session automatically.
Nothing is permanently installed on the remote machine.

```nix
# home/zsh.nix shellAliases
ssh = "kitten ssh";
```

No new packages — built into kitty. Low effort, high payoff if university computing
servers or remote physics simulations ever come up.

### kitten diff (built-in, no install needed)

Side-by-side visual diff of any two files with syntax highlighting and image diffs.

```bash
kitten diff file1.py file2.py
```

Not git-specific — useful for comparing config versions, lecture notes, or code edits.
Already available, just needs to become a habit.

### kitten hints (already active in kitty)

Keyboard-driven selection of visible text on screen. No config changes needed — these
bindings are active by default:

- `ctrl+shift+e` → labels all visible URLs → press letter → opens in Firefox
- `ctrl+shift+p>f` → labels all visible file paths → press letter → inserts at prompt
- `ctrl+shift+p>n` → labels `path:line` patterns (Python tracebacks) → opens in neovim at that line

The traceback mode (`ctrl+shift+p>n`) is the most valuable for Python work: turns
error messages into one-keystroke navigation to the file and line.

**TODO:** Add these bindings to the `<leader>/` help popup in `init.lua` so they stay
visible and memorable.

### matplotlib kitty backend (1 line, needs rebuild)

Set `MPLBACKEND=kitty` so `plt.show()` renders plots inline in the terminal that runs
the Python script — i.e. in the `<leader>r` split — rather than opening a Qt/GTK window.
`<leader>r` still auto-saves the file before running (via `vim.cmd("w")`); this only
changes where the plot is displayed.

**Trade-off:** The kitty backend has no toolbar. GUI backends (Qt/GTK) give you an
interactive save dialog (like Okular's floppy icon) to export as PNG/SVG/PDF after
seeing the result. With the kitty backend that option is gone — saving requires
`plt.savefig('output.png')` explicitly in the script. If exploratory plotting where
you decide to save *after* seeing the result is part of the workflow, keep the GUI
backend as default and only switch to kitty when inline display is specifically wanted.

```nix
# home/default.nix or neovim.nix — home.sessionVariables
MPLBACKEND = "kitty";
```

Test: `python3 -c "import matplotlib.pyplot as plt; plt.plot([1,2,3]); plt.show()"` — plot
should appear inline in the terminal, no separate window.

### chawan (terminal web browser)

Terminal web browser with native kitty graphics protocol support — renders images
alongside text. Keyboard-driven, vim-like. Actively maintained. Listed on kitty's
official integrations page.

Useful for quick documentation/Wikipedia lookups without opening Firefox.
Not suited for JavaScript-heavy apps.

```nix
# modules/common.nix or home/default.nix
pkgs.chawan   # verify package name in nixpkgs
```

Note: `awrit` (full Chromium-in-terminal) was archived April 2026. chawan is the
actively maintained alternative.

### kitty-scrollback.nvim (plugin + config)

Press a key in any kitty terminal → entire scrollback buffer (the stored terminal
output history, up to 10,000 lines as configured) opens as a neovim buffer. Full vim
navigation, `/search`, yank with `y`, re-execute lines back to kitty. Close with `q`.

Currently scrollback is only navigable with `shift+pgup`. This gives full neovim search
through all terminal output — useful for long Python runs, git log, build output.

Prerequisites already met in `kitty.nix`:
- `allow_remote_control = "yes"` ✓
- `listen_on = "unix:/tmp/kitty-control"` ✓

Steps:
1. Add `shell_integration = "enabled"` to `programs.kitty.settings` in `kitty.nix`
2. Add plugin to `neovim.nix` (check nixpkgs name; may need `fetchFromGitHub`)
3. Run `:KittyScrollbackGenerateKittens` once → paste output into `kitty.nix` `extraConfig`
4. Add a trigger keybinding in `kitty.nix`

### bookokrat (EPUB reader)

No EPUB reader currently exists on the system. bookokrat is a terminal PDF/EPUB viewer
using kitty's graphics protocol. Fills the gap for academic textbooks and papers in EPUB
format.

```nix
# modules/common.nix or home/default.nix
pkgs.bookokrat  # verify package name in nixpkgs
```

Note: EPUB rendering quality varies by how the publisher encoded math (MathML vs images).
Test with an actual textbook before relying on it for heavy math content.

### vim-kitty-navigator kitten (seamless split navigation)

Currently `ctrl+hjkl` navigates neovim→kitty splits (via `smart_nav` in `init.lua`)
but NOT kitty terminal→neovim. Pressing `ctrl+h` in a bare kitty terminal sends raw
ctrl+h to the shell instead of navigating into an adjacent neovim window.

Fix: add the vim-kitty-navigator Python kitten to kitty config. It checks whether the
active kitty window is running neovim:
- If yes → passes the keypress through (neovim's `smart_nav` handles it)
- If no → navigates the kitty split directly

No neovim plugin needed — the neovim side is already handled by `smart_nav` in `init.lua`.

Steps:
1. Fetch `pass_keys.py` from vim-kitty-navigator repo into kitty config dir
2. Add to `kitty.nix` keybindings:
   ```nix
   "ctrl+h" = "kitten pass_keys.py left   ctrl+h";
   "ctrl+j" = "kitten pass_keys.py bottom ctrl+j";
   "ctrl+k" = "kitten pass_keys.py top    ctrl+k";
   "ctrl+l" = "kitten pass_keys.py right  ctrl+l";
   ```
3. Adjust or remove the `ctrl+shift+hjkl` kitty-only bindings once this is working

### mpv --vo=kitty (video in terminal / <leader>z extension)

`mpv --vo=kitty` renders video inside a kitty window using the graphics protocol.
Not a replacement for GUI mpv — resolution is cell-limited. Useful for quick clip
preview (recorded lecture, simulation output) without leaving the terminal context.

Extend `<leader>z` in `init.lua` to detect video files and open a kitty vsplit with mpv:

```lua
local VIDEO_EXTS = { "mp4", "mkv", "webm", "avi", "mov" }
-- open_video_split: kitty @ launch --type=window --location=vsplit
--   running: mpv --vo=kitty <path>
```

Add `open_video_split` case alongside the existing `open_pdf_split` and
`open_image_split` handlers in the `<leader>z` keymap.

### kitten panel / pawbar — Sway migration decision

`kitten panel` creates a persistent desktop panel running any shell script. Could display
the timetable/deadline data from `_greeting` in `zsh.nix` as a permanent sidebar.
`pawbar` is a pre-built status bar built on kitten panel for Sway-compatible compositors.

**Do not implement on KDE** — janky on X11. This is a Sway migration decision:

When migrating (see `plans/window-manager.md`), compare:
- **kitten panel / pawbar**: fully terminal-native, scripted in shell/Python, kitty
  graphics protocol support, tightly integrated with existing greeting data
- **waybar**: wider plugin ecosystem, CSS theming, more conventional, established in
  the Sway community

Add this comparison to `plans/window-manager.md` as an open decision point.

---

## Neovim math rendering

### Inline math conceal ($...$) + block rendering ($$...$$)

**Goal:** Make inline typst math in markdown readable without a separate compiled view.
Math stays part of the sentence; the `$` delimiters remain visible as anchors.

**Approach:**
- `$...$` → unicode conceal: typst keywords are replaced with unicode equivalents
  in-place via neovim's `conceal` feature. No images, no character shifting, no
  compilation. Source is revealed when cursor is on the line.
- `$$...$$` → keep existing `<leader>tp` block rendering (image-nvim via kitty
  graphics protocol). Display math is meant to stand alone so the virtual padding
  is acceptable there.

**What conceals cleanly (direct substitution):**
Greek: `alpha`→α, `beta`→β, `gamma`→γ, `delta`→δ, `epsilon`→ε, `zeta`→ζ, `eta`→η,
`theta`→θ, `kappa`→κ, `lambda`→λ, `mu`→μ, `nu`→ν, `xi`→ξ, `pi`→π, `rho`→ρ,
`sigma`→σ, `tau`→τ, `phi`→φ, `chi`→χ, `psi`→ψ, `omega`→ω (and uppercase variants).
Variants: `phi.alt`→ϕ, `theta.alt`→ϑ.

Quantum / physics: `hbar`→ℏ, `dagger`→†, `angle.l`→⟨, `angle.r`→⟩,
`times.circle`→⊗, `plus.circle`→⊕, `arrow.r`→→, `arrow.l`→←, `arrow.t`→↑,
`arrow.b`→↓, `arrow.r.double`→⇒, `arrow.lr.double`→⟺, `nabla`→∇, `partial`→∂,
`ell`→ℓ, `in`→∈, `subset`→⊂, `supset`→⊃.

Operators: `sum`→∑, `integral`→∫, `infty`→∞, `approx`→≈, `neq`→≠, `times`→×,
`dot`→·, `sqrt`→√, `pm`→±.

**What stays as source text (function-call notation):**
`hat(H)`, `vec(r)`, `bold(A)`, `mat(...)`, `frac(a,b)` — readable as typst, acceptable
tradeoff. Super/subscripts (`_i`, `^2`) also stay as source; user confirmed this is fine.

**Example:**
```
source:  $angle.l phi | hat(H) | psi angle.r = hbar omega (n + 1/2)$
display: $⟨φ|hat(H)|ψ⟩ = ℏω(n + 1/2)$
```

**Implementation:**
- `FileType markdown` autocmd in `init.lua` defining a `syntax region` for `$...$`
  and `syntax match` rules within it for each substitution (longer dot-notation
  patterns listed before shorter ones to avoid partial matches)
- `setlocal conceallevel=2` and `concealcursor=nc` for markdown buffers
  (hides conceal except on the cursor line in normal/insert mode)
- No new packages or plugins

---

## ZSH improvements

Tools already in `common.nix` that need wiring, plus small aliases and function fixes.

### zoxide — initialize in zsh (installed, not hooked)

`zoxide` is in packages but has no init hook in `initContent` — the `z` command does
nothing right now. Add alongside the direnv line:

```nix
eval "$(zoxide init zsh)"
```

`z foo` jumps to the most-visited directory matching "foo". `zi foo` opens an fzf-style
picker if fzf is installed.

**Recommended: alias `cd` to `z`**, not `ls`. Zoxide is a drop-in for `cd` — full paths
pass through unchanged, partial names jump to the best frecency match. Aliasing `cd` to
`z` is the standard way to adopt it without learning a new verb. `ls` stays as `ls` (or
aliased to `eza`). Two approaches:

```nix
# Option A: simple alias
cd = "z";

# Option B: use --cmd cd in the init hook (also renames zi → cdi)
# Replace: eval "$(zoxide init zsh)"
# With:    eval "$(zoxide init zsh --cmd cd)"
```

Option B is cleaner because it also renames `zi` to `cdi` for interactive mode.

### eza — alias ls (installed, ignored)

`eza` is in packages; current `ls` aliases still call plain `ls`. Minimal swap:

```nix
ls  = "eza";
ll  = "eza -la --git";
la  = "eza -a";
lt  = "eza -T";        # tree view; replaces the need for a separate tree package
```

`--git` adds a git-status column next to each file in `ll`. `lt` gives a tree layout.

### bat — syntax-highlighted viewer (installed, unused)

`bat` is in packages. Options from most to least impactful:

1. **Man pages** — `MANPAGER = "sh -c 'col -bx | bat -l man -p'"` in `sessionVariables`.
   Colored, searchable man pages automatically. Most universally useful.
2. **Cat replacement** — `cat = "bat -p"`. The `-p` flag (plain) drops line numbers and
   the filename header, making it behave like `cat` but with syntax highlighting.
   Without `-p`, bat adds decorations and paging — useful for reading, less for piping.
3. **Default pager** — `PAGER = "bat"`. Makes all pager output (git log, man, help)
   use bat. More intrusive — test before committing to it. `BAT_PAGER = "less -RF"` can
   soften this by keeping bat's highlight but less's familiar scroll behaviour.
4. **Git diffs** — requires `delta` (separate package, not installed). Not needed now;
   note for later if terminal git diffs become part of the workflow.

Theming: bat follows its own themes (`bat --list-themes`). `BAT_THEME` env var sets a
default. Stylix does not theme bat automatically.

### nix-status — hash-based rebuild check (replaces time-based version)

Time comparison has a known false-positive: if you rebuild then commit, the commit
timestamp is newer than the generation and the function incorrectly reports changes
need building.

Fix: save the current git hash whenever `rebuild` runs, and also auto-append a row to
`generations.md`. Convert the `rebuild` alias to a shell function:

```bash
rebuild() {
  nh os switch /etc/nixos -H desktop || return 1

  # Record hash for nix-status
  git -C /etc/nixos rev-parse HEAD > ~/.config/nixos-last-build-hash

  # Append row to generations.md
  local gen=$(nixos-rebuild list-generations 2>/dev/null | awk '/True/{print $1}')
  local dt=$(date "+%Y-%m-%d  %H:%M")
  local hash=$(git -C /etc/nixos rev-parse --short HEAD 2>/dev/null)
  local prev=$(tail -1 /etc/nixos/generations.md | awk -F'|' '{print $4}' | tr -d ' ')
  local desc
  if [[ "$hash" == "$prev" ]]; then
    desc="(same commit, re-run)"
  else
    desc=$(git -C /etc/nixos log -1 --format="%s" 2>/dev/null)
  fi
  printf "| %3d | %s | %-7s | %s |\n" "$gen" "$dt" "$hash" "$desc" \
    >> /etc/nixos/generations.md
}
```

Description is pulled from the last git commit subject line automatically. If the commit
hash matches the previous generations.md row it writes "(same commit, re-run)" instead —
matching the existing manual convention.

Then `nix-status` compares hashes instead of timestamps:

```bash
nix-status() {
  local last=$(cat ~/.config/nixos-last-build-hash 2>/dev/null)
  local head=$(git -C /etc/nixos rev-parse HEAD 2>/dev/null)
  local dirty=$(git -C /etc/nixos status --short -- '*.nix' 'flake.*')

  [[ -n "$dirty" ]] && printf "Uncommitted changes:\n%s\n\n" "$dirty"

  if [[ -z "$last" ]]; then
    echo "No build record found. Run rebuild once to start tracking."
  elif [[ "$last" == "$head" ]]; then
    echo "Up to date (last build = HEAD)."
  else
    local log=$(git -C /etc/nixos log --oneline "$last..$head" \
      -- home/ modules/ hosts/ flake.nix flake.lock 2>/dev/null)
    if [[ -n "$log" ]]; then
      printf "Committed but not built:\n%s\n" "$log"
    else
      echo "Up to date (no .nix changes since last build)."
    fi
  fi
}
```

First run after adding this will find no hash file — rebuild once to initialize it.

### Aliases worth adding

```nix
ssh  = "kitten ssh";    # from kitty plan; copies zsh config to remote sessions
cat  = "bat -p";        # bat in plain mode; syntax highlighting, behaves like cat
py   = "python3";       # quick Python runs
ipy  = "ipython";       # interactive Python (ipython is installed)
```

### History: deduplicate all, not just consecutive

`ignoreDups = true` only removes back-to-back duplicates. If you run `rebuild`, then
something else, then `rebuild` again, both entries stay. Adding:

```nix
history.ignoreAllDups = true;
```

keeps only the most recent occurrence of any repeated command.

---

## Wikipedia — wiki-tui

Wikipedia is underrated as a reference for factual and conceptual lookups. 90% of
physics/maths questions have a Wikipedia article that is faster and more reliable than
a Google search. The goal is to make it easy enough to actually use instead of opening
a browser.

### Package

`wiki-tui` is in nixpkgs at 0.9.2. Add to `modules/common.nix`:

```nix
pkgs.wiki-tui
```

### What it looks like

Two-pane TUI: left is the article's table of contents (navigable), right is the article
text with styled headers and highlighted links. Press Enter on a link to follow it to
another article, `b` to go back. Vim keys throughout (`j/k` scroll, `gg`/`G`, `/` to
search within the article). Launch directly on an article:

```bash
wiki-tui "Schrödinger equation"
```

### Fuzzy finding

Passing a term that isn't an exact article title triggers Wikipedia's search API and
shows a ranked list of matching articles to pick from. So `wiki-tui "wave function"`
finds the right article even with capitalisation differences, and ambiguous terms like
`operator` show a picker. The word under cursor always works as input — worst case you
get a search results screen.

### Neovim binding — `K` in markdown

Vim's `K` already means "look up the word under the cursor" (default: `man`; in code
files: LSP hover). In markdown buffers it does nothing useful. A filetype-specific
remap is the most idiomatic fit:

```lua
-- inside FileType markdown autocmd in init.lua
vim.keymap.set('n', 'K', function()
  local word = vim.fn.expand('<cWORD>')
  vim.fn.system('kitty @ launch --type=window --location=vsplit -- wiki-tui '
    .. vim.fn.shellescape(word))
end, { buffer = true, desc = "Wikipedia lookup" })
```

`<cWORD>` (capital W) grabs the full whitespace-delimited token, which handles
hyphenated terms like `spin-orbit` better than `<cword>`.

Result: cursor on any term in a physics note → `K` → article opens in a kitty vsplit.
In code files `K` stays as LSP hover. No new leader chord to remember.

**Alternative keybindings** if `K` feels wrong or you want it outside markdown:

| Key | Notes |
|-----|-------|
| `K` (markdown filetype only) | Most idiomatic — existing vim semantic |
| `<leader>W` | Keeps `<leader>w` free; uppercase W = Wikipedia |
| `<leader>fw` | Fits a "find X" pattern if used elsewhere |

Add whichever is chosen to the `<leader>/` help popup so it stays visible.
