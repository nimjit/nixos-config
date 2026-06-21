# Wikilink Navigation

## What was built

Three features for navigating Obsidian-style `[[wikilinks]]` in neovim markdown files.

## Features

**Jump to wikilink** — `gf` or `<CR>` on `[[PageName]]` opens the file. Resolver
checks exact match, then case-insensitive, then partial. If the file doesn't exist:
prompts to create it (calls `:NewNote` flow).

**Backlinks** — `<leader>B` shows all files in the vault that reference the current note.
Rendered in a scratch buffer via `render_buffer()`. `<CR>` jumps to the matched line.

**Insert completion** — typing `[[` triggers a popup of all note titles in the current vault.
Selecting one inserts `[[NoteName]]`.

## Files

| File | What changed |
|------|-------------|
| `home/dotfiles/neovim/lua/dashboard.lua` | `M.resolve_wikilink()`, `M.backlinks()` |
| `home/dotfiles/neovim/init.lua` | `FileType markdown` autocmds for `gf`, `<CR>`, `[[` completion |

## Notes

- Vault root is detected from the current buffer path
- Attachments/ and Templates/ folders are excluded from search
- `[[Note|alias]]` syntax: strip everything after `|` before resolving
- `[[Note#Section]]` links: open file then search for the heading
