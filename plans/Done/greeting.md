# Zsh Greeting

## What was built

A dynamic zsh greeting shown on every new terminal. Replaces the old static
alias list. Implemented in gen 98 (2026-06-12).

## Layout

```
  Friday 12 June 2026

  🌤️ +16°C · Leiden          "The only way to do great work..."

  Today                                Tomorrow
  12:00  L. Sasja                      10:00  Meeting prof

         │ Schedule              Dailies
   09:00 │                       □ Brush teeth
   12:00 │ L. Sasja               □ Write in journal
   14:00 │ RQM homework          Deadlines
   19:00 │ L. Lotte                in  4d  (16 Jun)  aQM — pres.
         │ Kracht Training         ToDo
   20:00 │                         · Finish reading ch. 3

  today  vault-work  uni-work  messages  music  cal
```

## Implementation

**File**: `home/zsh.nix` — `_greeting()` and `_deadlines()` functions.

**Data sources**:
- Calendar events: `khal list today today` / `tomorrow tomorrow`
- Schedule items: `## Schedule` section in today's daily note (`HH:MM Description`)
- Habits/Dailies: `## Dailies` section in daily note
- Deadlines: YAML frontmatter in `UNI/Assignments/*.md`
- Todo: `## ToDo` section in daily note
- Weather: `curl wttr.in/Leiden?format=%c+%t` (cached 30 min at `/tmp/wttr_leiden_cache`)
- Quote: `fortune -s`

**Known gotchas fixed during implementation**:
- `local` declarations must be outside loops in zsh
- `printf '%s\n' "${empty_array[@]}"` emits empty line when array is empty — guard with length check
- `date -d "DD-MM-YYYY"` fails — detect format with regex, convert to ISO first
- `completed: True` / `"true"` — use `${val:l}` for case-insensitive matching
