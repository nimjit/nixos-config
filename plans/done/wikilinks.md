# Wikilink Navigation

## Goal

Make `[[wikilinks]]` navigable in neovim so moving through the vault feels like
Obsidian. Three features: jump to linked note, see what links back to the current
note, and autocomplete note titles when typing `[[`.

---

## Feature 1 — Jump to wikilink (`gf` / `<CR>`)

Pressing `gf` or `<CR>` on `[[PageName]]` or `[[PageName|alias]]` opens the file.

**Resolver order:**
1. Exact filename match (`PageName.md`) anywhere in vault or uni tree
2. Case-insensitive match
3. Partial match (first result)

Use `vim.fn.systemlist("find " .. VAULT .. " -iname " .. name .. ".md")` — no
plugins needed, same approach as `dashboard.lua`'s `scan_dir`.

**Behaviour:**
- If the file exists: `vim.cmd("edit " .. path)`
- If it does not exist: prompt `Create PageName.md? [y/n]` → if yes, create from
  a blank template or the default template (see `template-system.md`)

**Implementation:** `FileType markdown` autocmd that rebinds `gf` and `<CR>` for
lines matching `%[%[.-%]%]` pattern. Keep normal `<CR>` behaviour on non-link lines.

---

## Feature 2 — Backlinks buffer (`<leader>B`)

Shows all files in the current vault that contain `[[CurrentNoteName]]`.

```
 BACKLINKS — Sorting algorithms                    5 results

  Computation/MOC.md                   line 14
  Dailies/2026-05-03.md                line 7
  Physics/Quantum Computing.md         line 32
  ...
```

Implementation: `grep -r "\[\[CurrentName" VAULT` piped into a `render_buffer()`
scratch buffer using the existing dashboard infrastructure. `<CR>` opens at the
matched line number.

---

## Feature 3 — `[[` insert completion

Typing `[[` in insert mode triggers a popup of all note titles in the current vault.
Selecting one inserts `[[NoteName]]` and moves the cursor after `]]`.

Implementation: an `InsertCharPre` or `TextChangedI` autocmd that detects `[[` was
just typed, collects note titles via `find ... -name "*.md"`, strips the extension,
and feeds them to `vim.fn.complete(col, items)`. No popup plugin needed.

---

## Files to change

| File | Change |
|------|--------|
| `home/dotfiles/neovim/lua/dashboard.lua` | Add `M.resolve_wikilink(name)` and `M.backlinks(path)` |
| `home/dotfiles/neovim/init.lua` | Add FileType markdown autocmds for gf/CR and [[  completion |

---

## Notes

- Vault already has an `Attachments/` folder and `Templates/` — the resolver should
  skip these when searching for notes to jump to
- Obsidian's `[[Name|Display text]]` syntax should be handled: strip everything after `|`
- For links that include a heading (`[[Note#Section]]`), open the file then search
  for the heading with `/## Section`
