# Template System

## What was built

`:NewNote [name]` creates a new note in the current vault pre-filled from an
Obsidian-compatible template. Vault context is inferred from the current buffer.

## How it works

1. Detects current vault from `vim.fn.expand("%:p")`
2. Scans `Templates/` in that vault
3. Shows a `vim.ui.select` picker (no plugin)
4. Prompts for note name if not given
5. Reads template, substitutes `{{title}}`, `{{date}}`, `{{time}}`
6. Writes to `<vault>/<folder>/<NoteName>.md` and opens it

## Files

| File | What changed |
|------|-------------|
| `home/dotfiles/neovim/lua/dashboard.lua` | `M.new_note(name, vault_root)` |
| `home/dotfiles/neovim/init.lua` | `:NewNote` user command |

## Notes

- Skips Attachments/ and Templates/ when resolving the target directory
- `:DailyNote` is separate and date-named — not routed through `:NewNote`
- When a `[[wikilink]]` target doesn't exist, `gf` calls `M.new_note()` so the
  template picker also runs on link creation
- Template placeholders: `{{title}}`, `{{date}}` (YYYY-MM-DD), `{{time}}` (HH:MM)
