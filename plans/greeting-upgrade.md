# Greeting Upgrade

## Goal

The zsh greeting (shown when a new terminal opens) should surface live data from
the vault and calendar rather than a static text block: upcoming deadlines,
today's events, and a countdown to the next exam/deadline.

---

## Current state

`home/zsh.nix` prints a static welcome message listing aliases. It does not read
any live data. There is also a `vault-work` neovim session that shows a dashboard,
but the terminal greeting itself is dumb.

---

## Proposed greeting layout

```
  Wednesday 10 June 2026 · 14:32

  Today          Algorithms lecture 10:45 · Study group 15:00
  Tomorrow       —

  Deadlines      Linear Algebra PSet    in 3 days  (13 Jun)
                 Thermodynamics lab     in 8 days  (18 Jun)

  vault          Sorting algorithms · Quantum gates · (3 more recent)

  today  vault-work  uni-work  music  messages  cal
```

---

## Data sources

| Section | Source | Command |
|---------|--------|---------|
| Today's events | khal | `khal list today today --format "{start-time} {title}"` |
| Tomorrow | khal | same with `tomorrow tomorrow` |
| Deadlines | vault front-matter or khal tags | grep YAML `deadline:` fields, or a dedicated khal calendar |
| Recent notes | vault | `ls -t <vault>/*.md \| head -5` stripped of path/extension |

### Deadlines

Two approaches:
1. **khal calendar tag** — create a "Deadlines" calendar in khal. Simple but
   requires maintaining a separate calendar.
2. **YAML front-matter scan** — grep `deadline:` fields in vault files.
   `grep -rl "deadline:" <vault> | xargs grep "deadline:" | sort -t: -k3` gives
   sorted upcoming deadlines from note metadata.

Option 2 is more Obsidian-native since the vault already uses YAML front-matter.

---

## Implementation

A small bash function `greeting()` in `home/zsh.nix` called at the end of `.zshrc`
via `zsh.initExtra`. It runs the data-gathering commands and prints formatted output.

Key points:
- Skip if not an interactive terminal (`[[ $- != *i* ]] && return`)
- Cache khal output for 5 minutes to avoid slowdowns on repeated terminal opens
  (`/tmp/khal_cache_$(date +%Y%m%d%H%M | head -c 11)`)
- Truncate long event titles at 40 characters
- Use the existing Ukiyo palette colours via ANSI escapes (gold = `\e[33m`, dim = `\e[2m`)

---

## Zsh greeting fix (minor, do first)

The current greeting says `cal → Calendar (calcurse)`. khal replaced calcurse.
Update to `cal → Calendar (khal)` in `home/zsh.nix`. This is a one-line fix that
can be done independently of the full greeting upgrade.

---

## Files to change

| File | Change |
|------|--------|
| `home/zsh.nix` | Replace static greeting with `greeting()` function; add khal commands to packages if missing |

---

## Notes

- The vault path has a redundant double-folder (`Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure/`) — grep paths must account for this
- `khal list` output format is configurable in `~/.config/khal/config` under `[view]` — align with whatever format is already set
- Birthday data could come from a khal `birthdays` calendar if one is configured
