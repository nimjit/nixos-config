# Quick Capture

## What was built

`cap "text"` appends a thought to today's daily note without opening an editor.
Control returns immediately.

```bash
cap "Look into Fourier basis in the context of quantum circuits"
# → appended to Dailies/YYYY-MM-DD.md under ## Inbox
```

## Functions in `home/zsh.nix`

```bash
cap()   # targets uni vault daily note (most frequent use)
capu()  # targets personal vault daily note
```

Default target: `~/Documents/BACKUP/Uni/Obsidian/Uni/Dailies/<date>.md`.
Creates the daily note (with `## Inbox` header) if it doesn't exist yet.

## Notes

- Items append to the end of the file (Inbox section is always last)
- If Obsidian is open simultaneously, it detects the file change and syncs automatically
- Daily note template at `Templates/Daily Note.md` includes `## Inbox` heading
