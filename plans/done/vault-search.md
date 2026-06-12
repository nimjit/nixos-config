# Vault Search

## Goal

`<leader>s` opens a live fuzzy search across all note content in the current
vault. Results show filename + matched line; `<CR>` jumps to that line.

---

## Why not telescope/fzf.lua

The rest of the neovim setup avoids plugins. The dashboard already renders custom
scratch buffers and reads shell output. A simple `grep -r` piped into a scored
filter is enough for the vault sizes involved (a few thousand files at most).

---

## Implementation: two modes

### Mode A — static grep list (simpler, good enough)

Run `grep -rn --include="*.md" <query> <vault>` once and show results in a
render_buffer. Re-invoke to search again.

Bind: `<leader>s` → prompt `vim.ui.input({ prompt = "Search: " }, ...)` → grep
→ render results → `<CR>` opens file at line.

### Mode B — incremental (nicer UX)

Use `vim.fn.complete()` or a minimal input loop that re-runs grep on each
keystroke and updates a split buffer live. Harder to implement cleanly without
plugins.

**Recommendation:** start with Mode A. The round-trip on a SSD vault is <100ms.

---

## Result buffer format

```
 SEARCH — "sorting algorithms"                       12 results

  Computation/MOC.md:14          ...in sorting algorithms, the key insight...
  Dailies/2026-05-03.md:7        ...reviewed sorting algorithms today...
  Physics/Quantum Computing.md:32 ...unlike classical sorting algorithms...
  ...
```

Reuse `render_buffer()` from `dashboard.lua`. Each result line stores
`{file, lnum}` metadata so `<CR>` can do `vim.cmd("edit +" .. lnum .. " " .. file)`.

---

## Vault detection

Same logic as wikilinks and template-system: check `vim.fn.expand("%:p")` against
known vault roots. Fall back to prompting if the current buffer is not inside a
vault.

Both vaults:
- Personal: `~/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure/`
- Uni: `~/Documents/BACKUP/Uni/Obsidian/Uni/`

---

## grep flags

```bash
grep -rn --include="*.md" \
     --exclude-dir=Attachments \
     --exclude-dir=Templates \
     --exclude-dir=.obsidian \
     -i "<query>" <vault>
```

`-i` for case-insensitive. `-n` for line numbers. `--exclude-dir` skips noise.

---

## Files to change

| File | Change |
|------|--------|
| `home/dotfiles/neovim/lua/dashboard.lua` | Add `M.vault_search(query)` |
| `home/dotfiles/neovim/init.lua` | Bind `<leader>s` (global or FileType markdown) |

---

## Notes

- For the uni vault, also search `.tex` and `.typ` files if desired (`--include="*.tex"`)
- Combine with backlinks (`<leader>B` from `wikilinks.md`) for full graph navigation:
  search finds notes by content, backlinks finds notes by reference
- Consider adding `<leader>S` for title-only search (faster: `find ... -iname "*query*"`)
