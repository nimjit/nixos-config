# Dashboard Graphs

## What was built

Inline charts in the neovim vault dashboard rendered via matplotlib + kitty
graphics protocol.

## Weight chart

**Script**: `~/.local/bin/plot-weights` (installed via `home.file` in `home/default.nix`).
Parses `weights_list.md` markdown table, outputs a PNG to `/tmp/`, prints the path.

**Dashboard integration**: the vault dashboard calls `plot-weights` via `jobstart`
and renders the PNG via `image.nvim` at a fixed buffer position. The chart appears
next to the summary text on dashboard open.

**Colors**: Ukiyo palette (BG `#372d29`, FG `#ccc2b7`, accent `#cc9966`).

## Vault graph

**Current state**: `[g]` in the vault dashboard opens `vault_snowflake.html` in
Firefox. A neovim-native two-panel view (ASCII tree left, radial PNG right) is
planned but not yet built — see the saved plan at the top of the last conversation
or check `home/dotfiles/neovim/lua/dashboard.lua` for the current `[g]` binding.

## Related files

| File | Role |
|------|------|
| `home/dotfiles/plot-weights.py` | weight chart generator |
| `home/dotfiles/neovim/lua/dashboard.lua` | `show_weight_chart()`, `[g]` keymap |
| `home/default.nix` | `home.file` entry for plot-weights |
