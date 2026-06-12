# Theme & Workflow — Remaining Work

## 1. Ukiyo.nix palette update

The base16 palette in `themes/ukiyo.nix` still has colours that clash with the warm
brown direction. Neovim is now handled separately (hand-crafted `Ukiyo.lua` +
`set_color_overrides()` in init.lua), so these changes affect the terminal (kitty
ANSI colours), zathura, and other Stylix-themed apps.

| Slot   | Current     | Problem              | Target      |
|--------|-------------|----------------------|-------------|
| base08 | `#c72626`   | Harsh dark red       | `#ce631c`   |
| base0B | `#9aad6e`   | Green (ANSI color 2) | `#da7b5f`   |
| base0C | `#7ab5a0`   | Cyan (ANSI color 6)  | `#da9517`   |

**Caution:** base08/0B/0C are terminal ANSI colours 1/2/6. After changing, check that
`ls --color`, `git diff`, and other colour-coded CLI tools still look reasonable.
The three target values are already used in `home/dotfiles/neovim/colors/Ukiyo.lua`
so neovim itself won't change.

File: `themes/ukiyo.nix`

---

## 2. Khal appearance

khal works (12 Google calendars syncing via vdirsyncer), but the TUI visual style
needs refinement. The Ukiyo palette is partially applied but the overall layout/feel
could be better.

- Colours are set in the khal config under `[highlight]`, `[calendar]`, and
  `[color]` sections
- Goal: gold for today/highlights, dim for secondary text, warm red for past events
- Check `khal --version` for supported theme keys (0.14 added new options)

File: wherever khal config lives — likely `home/dotfiles/khal/config`

---

## 3. Zsh greeting update

The greeting in `home/zsh.nix` still says `cal → Calendar (calcurse)`.
Update to `cal → Calendar (khal)`.
