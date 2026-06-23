# Zsh Prompt (Starship)

## What was built

Starship prompt enabled via home-manager. Stylix themes it automatically —
no hardcoded colors in the config.

## What it shows

```
nixos on  master [!⇡] via ❯
```

- **Directory** — current folder, truncated
- **Git branch + status** — branch name, dirty indicator (`!`), ahead/behind arrows
- **Prompt character** — `❯`, turns red on non-zero exit
- **Command duration** — shown after long-running commands (built-in behavior)

## Modules

Enabled (contextual — only appear when relevant):

| Module | Shows when |
|--------|-----------|
| `nix_shell` | Inside `nix-shell` or `nix develop` |
| `direnv` | A `.envrc` is loaded or blocked |

Disabled to reduce noise:

| Module |
|--------|
| `python` |
| `nodejs` |
| `rust` |
| `package` |

## Config

**File**: `home/zsh.nix` — bottom of file, `programs.starship` block.

Colors are controlled entirely by Stylix. To change the prompt palette, change
the theme in `modules/stylix.nix` and rebuild — no changes to the starship
config needed.
