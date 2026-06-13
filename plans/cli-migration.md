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

### Rofi password picker (lastpass-cli)

A rofi script for system-wide password copy via keyboard shortcut. Not yet written.

```bash
# lpass-rofi: fuzzy-pick a LastPass entry and copy its password
entries=$(lpass ls --long 2>/dev/null)
selected=$(echo "$entries" | rofi -dmenu -p "Password:" -i -format 'i')
name=$(echo "$entries" | sed -n "$((selected+1))p" | sed 's/ \[id:.*\]//')
lpass show --clip "$name" && notify-send "LastPass" "Copied: $name" --expire-time=3000
```

Add keyboard shortcut in KDE or Sway (`Super+P`). Depends on `wl-clipboard`.

### vdirsyncer: architecture notes

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
