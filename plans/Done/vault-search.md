# Vault Search

## What was built

`<leader>s` opens a fuzzy search across all note content in the current vault.
Results show filename + matched line; `<CR>` jumps to that line. No plugins.

## Implementation

**File**: `home/dotfiles/neovim/lua/dashboard.lua` — `M.vault_search()`

Prompts via `vim.ui.input`, runs `grep -rn -i --include="*.md"` with
`--exclude-dir=Attachments --exclude-dir=Templates --exclude-dir=.obsidian`,
renders results in a `render_buffer()` scratch buffer.

Each result line stores `{file, lnum}` so `<CR>` can open with `edit +lnum file`.

Vault is detected from the current buffer path (personal vault or uni vault root).

## Keybinding

`<leader>s` — wired in `home/dotfiles/neovim/init.lua`.

## Notes

- Round-trip on SSD vault is under 100ms — no async needed
- For uni vault: could extend with `--include="*.tex"` and `--include="*.typ"` if desired
- `<leader>S` for title-only search: `find ... -iname "*query*"` (faster, separate binding)
