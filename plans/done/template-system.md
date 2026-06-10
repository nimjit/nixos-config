# Template System

## Goal

`:NewNote [name]` creates a new note in the current vault pre-filled from an
Obsidian-compatible template. Works from any markdown buffer so the vault context
is inferred automatically.

---

## Vault templates

Both vaults already have a `Templates/` folder with `.md` files. The template
format is standard Obsidian: `{{title}}`, `{{date}}`, `{{time}}` placeholders.

```
Renaissance_Vault_Structure/Templates/
├── Daily Note.md
├── Book Note.md
├── Person.md
├── Project.md
└── ...

Uni/Templates/
├── Lecture.md
├── Problem Set.md
├── Paper Summary.md
└── ...
```

The implementation just reads these files from disk — no template engine needed
beyond simple string replacement of `{{title}}`, `{{date}}`, `{{time}}`.

---

## `:NewNote` command

```
:NewNote                 → pick template interactively, prompt for name
:NewNote "Book Title"    → pick template interactively, name pre-filled
```

**Flow:**

1. Determine current vault from `vim.fn.expand("%:p")` — check if path contains
   the personal vault root or uni vault root.
2. Scan `Templates/` in that vault with `vim.fn.glob(vault .. "/Templates/*.md", false, true)`.
3. Show template picker via `vim.ui.select(template_names, ...)` — built-in, no
   plugin needed.
4. If no name given: prompt with `vim.ui.input({ prompt = "Note name: " }, ...)`.
5. Resolve target directory: default is vault root; if current file is in a
   subfolder, offer to create in the same subfolder.
6. Read template file, substitute `{{title}}` → note name, `{{date}}` →
   `os.date("%Y-%m-%d")`, `{{time}}` → `os.date("%H:%M")`.
7. Write to `<vault>/<folder>/<NoteName>.md` and `vim.cmd("edit " .. path)`.

---

## Integration with wikilinks

If invoked from a `[[PageName]]` that does not exist (see `wikilinks.md` Feature 1),
the "Create?" prompt should call `M.new_note(name)` from `dashboard.lua` rather
than creating a blank file. This means the template picker also runs on link creation.

---

## Files to change

| File | Change |
|------|--------|
| `home/dotfiles/neovim/lua/dashboard.lua` | Add `M.new_note(name, vault_root)` |
| `home/dotfiles/neovim/init.lua` | Add `:NewNote` user command + wire wikilink "create" path to it |

---

## Notes

- Skip `Templates/` and `Attachments/` folders when resolving target directory
- Daily note is a special case: date-named file already handled by `:DailyNote`; no
  need to unify these
- Template files may themselves contain `[[wikilinks]]` — that is fine, they are
  plain text until the note is opened
