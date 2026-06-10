# Greeting Upgrade

## Goal

The zsh greeting (shown when a new terminal opens) should surface live data from
the vault and calendar rather than a static text block: upcoming deadlines,
today's events, and a countdown to the next exam/deadline.
Potentially also with visual improvements like centered text, a small weather ascii text block, a nice daily quote.

---

## Current state

`home/zsh.nix` prints a static welcome message listing aliases. It does not read
any live data. There is also a `vault-work` neovim session that shows a dashboard,
but the terminal greeting itself is dumb.

---

## Proposed greeting layout

```
  Wednesday 10 June 2026 · 14:32

  🌤️  +16°C  |  Leiden          "The only way to do great work is to love what you do."

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
| Weather | wttr.in via curl | `curl -s --max-time 2 "wttr.in/Leiden?format=%c+%t"` → `🌤️  +16°C` |
| Daily quote | fortune package | `fortune -s` (short quotes, nixpkgs `fortune` package) |

### Deadlines

Two approaches:
1. **khal calendar tag** — create a "Deadlines" calendar in khal. Simple but
   requires maintaining a separate calendar.
2. **YAML front-matter scan** — grep `deadline:` fields in vault files.
   `grep -rl "deadline:" <vault> | xargs grep "deadline:" | sort -t: -k3` gives
   sorted upcoming deadlines from note metadata.

Option 2 is more Obsidian-native since the vault already uses YAML front-matter, but requires more manual upkeep.

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

### Weather (cached 30 min)

```bash
WTTR_CACHE=/tmp/wttr_leiden_cache
if [ ! -f "$WTTR_CACHE" ] || find "$WTTR_CACHE" -mmin +30 -print -quit 2>/dev/null | grep -q .; then
    curl -s --max-time 2 "wttr.in/Leiden?format=%c+%t" > "$WTTR_CACHE" 2>/dev/null \
        || echo "  " > "$WTTR_CACHE"
fi
WEATHER=$(cat "$WTTR_CACHE")
```

### Centering

```bash
center() {
    local text="$1"
    local pad=$(( (COLUMNS - ${#text}) / 2 ))
    printf "%*s%s\n" "$pad" "" "$text"
}
```

Use for the date/time line and the weather+quote line so the greeting is visually
balanced regardless of terminal width.

### Daily quote

```bash
QUOTE=$(fortune -s 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-80)
```

`fortune -s` returns a short (≤160 char) quote. The pipeline collapses newlines and
trims to 80 chars so it fits alongside the weather on one line.

---

## Files to change

| File | Change |
|------|--------|
| `home/zsh.nix` | Replace static greeting with `greeting()` function |
| `modules/common.nix` | Add `fortune` to packages |

---

## Notes

- The vault path has a redundant double-folder (`Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure/`) — grep paths must account for this
- `khal list` output format is configurable in `~/.config/khal/config` under `[view]` — align with whatever format is already set
- Birthday data could come from a khal `birthdays` calendar if one is configured
