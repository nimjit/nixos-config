# Zsh Prompt Customization

## Current state

The zsh prompt is configured in `home/zsh.nix`. Currently using a custom prompt
or the default zsh prompt — confirm with `echo $PROMPT`.

Starship is an alternative: fast, Rust-based, highly configurable, in nixpkgs.

---

## Goals

- Show git status (branch + dirty indicator) — main signal during coding
- Keep Ukiyo palette: gold/dim for normal state, red for errors
- Remove noise: no Python version number, no Node version, no package manager info
- Minimal: two lines max, no powerline glyphs (they misalign in some fonts)

---

## Option A — Starship

```nix
# home/zsh.nix or separate home/starship.nix
programs.starship = {
  enable = true;
  settings = {
    format = "$directory$git_branch$git_status$character";
    right_format = "$cmd_duration";

    directory = {
      style = "bold #e0ba86";  # Ukiyo gold
      truncation_length = 3;
      truncate_to_repo = false;
    };

    git_branch = {
      format = "[$branch]($style) ";
      style = "#cc9966";  # Ukiyo accent
    };

    git_status = {
      format = "[$all_status$ahead_behind]($style) ";
      style = "#8a7a6e";  # Ukiyo dim
      modified = "~";
      untracked = "?";
      ahead = "↑";
      behind = "↓";
    };

    character = {
      success_symbol = "[❯](#cc9966)";
      error_symbol   = "[❯](#c0392b)";
    };

    cmd_duration.min_time = 2000;

    # Disable noisy modules
    python.disabled = true;
    nodejs.disabled = true;
    package.disabled = true;
    rust.disabled = true;
    nix_shell.disabled = false;  # keep — useful in nix-shell
  };
};
```

### Enable in zsh

Starship's home-manager module auto-wires `eval "$(starship init zsh)"` when
`programs.starship.enable = true` — no manual change to zsh.nix needed.

---

## Option B — Pure zsh PROMPT

Simpler: define `PROMPT` directly in `home/zsh.nix` initContent.

```zsh
autoload -U colors && colors
PROMPT='%F{#e0ba86}%3~%f %(?.%F{#cc9966}.%F{#c0392b})❯%f '
RPROMPT='$(git symbolic-ref --short HEAD 2>/dev/null | sed "s/.*/%F{#8a7a6e}&%f/")'
```

No dependency on starship. Git branch only; no git status indicator.

---

## Recommendation

Start with Option A (starship) — more maintainable, no manual escape code juggling,
and the config format is self-documenting. Disable in one line if it causes issues.
