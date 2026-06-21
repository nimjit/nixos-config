# Theme & Workflow

## Ukiyo palette (`themes/ukiyo.nix`)

The base16 palette drives Stylix theming for kitty, zathura, and other apps.
Neovim uses its own hand-crafted `Ukiyo.lua` + `set_color_overrides()` so
base16 changes don't affect it.

The slots flagged for review:

| Slot | Current | Target | Status |
|------|---------|--------|--------|
| base08 | `#c72626` | `#ce631c` | Not yet changed |
| base0B | `#9aad6e` | `#da7b5f` | Not yet changed |
| base0C | `#7ab5a0` | `#da9517` | Not yet changed |

**Caution**: these are terminal ANSI colors 1/2/6. After changing, verify that
`ls --color`, `git diff`, and other color-coded tools still look reasonable.

## khal appearance

khal works (12 Google calendars, vdirsyncer). Visual polish still rough.
Colors are set in `home/dotfiles/khal/config` under `[highlight]` and `[color]`.
Goal: gold for today/highlights, dim for secondary text, warm red for past events.

## Zsh greeting

Greeting now says `khal` not `calcurse`. Part of the greeting redesign (see `greeting.md`).
