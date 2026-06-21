# Yazi Customization

## Current state

yazi is installed and configured via `home/yazi.nix`. Basic vim navigation works.
Opened with `<leader>y` from neovim or the `y` shell alias.

---

## Open items

### File openers

Configure which program opens each file type. Edit `home/yazi.nix` opener section:

```nix
programs.yazi.settings.opener = {
  pdf     = [{ run = "zathura \"$@\""; desc = "Zathura"; }];
  video   = [{ run = "mpv \"$@\""; desc = "mpv"; }];
  audio   = [{ run = "mpv \"$@\""; desc = "mpv"; }];
  image   = [{ run = "kitten icat \"$@\""; desc = "kitty icat"; }];
  default = [{ run = "nvim \"$@\""; desc = "neovim"; }];
};
```

### Keymaps

Add vim-adjacent bindings in `home/yazi.nix`:

- `<C-h>/<C-l>` — back/forward in directory history (already default `<Alt-←/→>`)
- `H` — go to parent dir (same as `<backspace>`)
- `y` — yank / copy file
- `p` — paste

Check defaults first (`?` in yazi) before overriding.

### Preview improvements

- **PDF preview**: poppler-utils is in packages (`pdftoppm`) — yazi should preview PDFs automatically
- **Image preview**: kitty graphics protocol — works natively in kitty
- **Syntax highlighting**: `bat` is in packages — yazi uses it for text file preview

These may already work out of the box. Test before adding config.

### Plugins

Consider: `yazi-plugin-starship` for status bar, `flavors` for Ukiyo theme matching.
Both available via nixpkgs or yazi's own plugin manager.

### Neovim integration

Current: `<leader>y` opens yazi in a neovim terminal split. Consider moving to a
kitty split (see cli-migration.md — kitty splits discussion). yazi should stay
interactive (insert mode), not need normal mode access.
