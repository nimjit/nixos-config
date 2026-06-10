# Quick Capture

## Goal

From anywhere in the terminal (not inside neovim), type a short thought and have
it appended to today's daily note. No editor opens; control returns immediately.

```bash
cap "Look into Fourier basis in the context of quantum circuits"
# → appended to ~/...Uni/Obsidian/Uni/Dailies/2026-06-10.md under ## Inbox
```

---

## Shell function `cap`

```bash
cap() {
    local text="$*"
    local date=$(date +%Y-%m-%d)
    local vault_personal=~/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure
    local vault_uni=~/Documents/BACKUP/Uni/Obsidian/Uni
    local daily="$vault_uni/Dailies/$date.md"

    # Create daily note if it doesn't exist yet
    if [ ! -f "$daily" ]; then
        printf -- "---\ndate: %s\n---\n\n## Inbox\n" "$date" > "$daily"
    fi

    # Append under ## Inbox section, or at end of file
    printf -- "\n- %s" "$text" >> "$daily"
    echo "→ captured to $date"
}
```

Add `capu` variant for personal vault:

```bash
capu() {
    # same but targets personal vault daily note
}
```

---

## Vault selection

The default target is the uni vault daily note (most frequent use case during
studies). A flag or separate command handles the personal vault.

Consider: `cap -p "personal thought"` or just `capu "personal thought"`.

---

## Inbox section

Captured items land under an `## Inbox` heading at the bottom of the daily note.
If the daily note was just created, the function writes the heading. If it
already exists, the function appends to the file (the `-a` append to file means
items go to the end; this is fine since the Inbox is always last).

For a smarter approach: use `awk` or `sed` to insert after `## Inbox` if that
heading exists mid-file. Keep it simple for now — append to end.

---

## Neovim variant

Inside neovim: `<leader>q` yanks the current line (or visual selection) and
appends it to the daily note buffer (or file directly).

```lua
vim.keymap.set({'n', 'v'}, '<leader>q', function()
    local line = vim.fn.getline('.')
    local date = os.date("%Y-%m-%d")
    local daily = UNI_VAULT .. "/Dailies/" .. date .. ".md"
    local f = io.open(daily, "a")
    if f then f:write("\n- " .. line); f:close() end
    vim.notify("Captured: " .. line:sub(1, 50))
end)
```

---

## Files to change

| File | Change |
|------|--------|
| `home/zsh.nix` | Add `cap` and `capu` shell functions |
| `home/dotfiles/neovim/init.lua` | Add `<leader>q` binding (optional neovim variant) |

---

## Notes

- `cap` without arguments could open a one-line `vim` prompt: `vim -c "startinsert" /tmp/cap_input.md` then append on save. More ergonomic for multi-word capture.
- If Obsidian is open at the same time, it will detect the file change and sync automatically — no conflict as long as appending (not rewriting).
- The daily note template in `Templates/Daily Note.md` should include an `## Inbox` section so new daily notes always have the target heading.
