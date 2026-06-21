# Ereader Export

## Status

**Not implemented.** The tools are available (typst and pandoc in packages), but
the neovim `<leader>E` binding has not been written.

## What's needed

A neovim binding that compiles the current typst or markdown file to PDF and copies
it to the ereader. Detect filetype, run compile, copy on success.

**Device**: Kobo Aura H2O. Mounts at `/run/media/thijmen/KOBOeReader/` via USB.
A5 page size fits the screen well (`#set page(paper: "a5")` in typst).

**Compile**:
- `.typ` → `typst compile file.typ file.pdf`
- `.md` → `pandoc file.md -o file.pdf --pdf-engine=typst`

**Transfer**: `cp file.pdf /run/media/thijmen/KOBOeReader/` or drop into a Syncthing
shared folder (Syncthing is already running; KOReader supports it natively).

## If/when to implement

The keybinding is ~30 lines in `init.lua` and can be done in one session.
Only implement when the ereader is in regular use for study notes.
