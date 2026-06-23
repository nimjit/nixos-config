# Yazi File Manager

## What was built

Yazi configured as the primary file manager, launched from the shell and from
neovim. Configured in `home/yazi.nix`.

## How to open

| Method | Result |
|--------|--------|
| `y` | Open yazi in the current directory; shell `cd`s to wherever you quit |
| `nixos` / `backup` / `vault` / `uni` / `ricing` / `misc` / `books` | Open yazi in that specific directory |
| `<leader>f` in neovim | Open yazi in a neovim terminal split |

## Keybindings

Standard vim navigation works. Custom additions:

| Key | Action |
|-----|--------|
| `l` | Enter directory or open file (same as `Enter`) |

Check `?` in yazi for the full default keymap.

## Preview

Works out of the box in kitty — no extra config needed:

| Type | Renderer |
|------|----------|
| Images | Kitty graphics protocol (icat) |
| PDFs | poppler-utils (`pdftoppm`) |
| Text / code | `bat` (syntax highlighted) |

Preview cache resolution is set to 1200×1200 px to avoid blurriness on larger
panes. The preview column takes up its default proportion of the screen
(`[1, 3, 4]` ratio — parent / current / preview).

## Settings

- Hidden files shown
- Symlink targets shown
- Natural sort order, directories first

## Neovim integration

`<leader>f` opens yazi in a neovim terminal split (`:terminal`). It stays as a
neovim split rather than a kitty panel because `<C-h/j/k/l>` navigation requires
neovim splits — kitty panel navigation (which uses `<C-S-h/j/k/l>`) is a
separate layer and the two can't be bridged with the smart-window-movement plugin
(already tried; doesn't work on this setup).

## Config

**File**: `home/yazi.nix`
